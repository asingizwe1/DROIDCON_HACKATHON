import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/inspection.dart';

/// Thrown when search cannot be completed. The UI catches this and falls back
/// to filtering the already-loaded inspections locally.
class SearchException implements Exception {
  final String message;

  /// True when search is unreachable (server down, offline, CORS, timeout), as
  /// opposed to the query itself being wrong. This is the case that should
  /// silently degrade to local search rather than showing an error.
  final bool isUnavailable;

  SearchException(this.message, {this.isUnavailable = false});

  @override
  String toString() => message;
}

/// A cached scoped search key and where to use it.
class SearchKey {
  final String key;
  final String host;
  final int port;
  final String protocol;
  final String collection;
  final DateTime expiresAt;

  SearchKey({
    required this.key,
    required this.host,
    required this.port,
    required this.protocol,
    required this.collection,
    required this.expiresAt,
  });

  /// Treat a key as stale five minutes early so it can never expire mid-flight.
  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  String get baseUrl => '$protocol://$host:$port';

  factory SearchKey.fromJson(Map<String, dynamic> json) {
    final expires = json['expiresAt'];
    return SearchKey(
      key: json['key']?.toString() ?? '',
      host: json['host']?.toString() ?? AppConfig.fallbackTypesenseHost,
      port: (json['port'] as num?)?.toInt() ?? AppConfig.fallbackTypesensePort,
      protocol: json['protocol']?.toString() ?? 'http',
      collection:
          json['collection']?.toString() ?? AppConfig.inspectionsCollection,
      expiresAt: expires is num
          ? DateTime.fromMillisecondsSinceEpoch(expires.toInt() * 1000)
          : DateTime.now().add(const Duration(hours: 24)),
    );
  }
}

/// Search over past inspections, backed by Typesense.
///
/// The app never holds the Typesense admin key or the raw search-only parent
/// key. It asks the backend for a short-lived key that is already scoped to
/// this farmer, and Typesense enforces that scope server-side.
class InspectionSearchService {
  InspectionSearchService._();
  static final InspectionSearchService instance = InspectionSearchService._();

  http.Client _client = http.Client();
  final Map<String, SearchKey> _cacheByFarmer = {};

  /// Test seam: swap the HTTP client.
  void setClientForTesting(http.Client client) => _client = client;

  /// Drop the cached key, e.g. on logout so a key never outlives a session.
  void clearCache() {
    _cacheByFarmer.clear();
  }

  Future<SearchKey> _fetchKey(String farmerId) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/search-key');
    final http.Response res;
    try {
      res = await _client
          .get(uri, headers: {
        'Accept': 'application/json',
        'X-Farmer-Id': farmerId,
      })
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw SearchException('Search key request timed out.', isUnavailable: true);
    } on http.ClientException {
      throw SearchException('Cannot reach the search service.',
          isUnavailable: true);
    }

    if (res.statusCode != 200) {
      throw SearchException('Could not get a search key (${res.statusCode}).',
          isUnavailable: res.statusCode >= 500);
    }

    dynamic data;
    try {
      data = jsonDecode(res.body);
    } on FormatException {
      throw SearchException('The search key response was not valid JSON.',
          isUnavailable: true);
    }
    final payload = data is Map && data['data'] is Map ? data['data'] : data;
    if (payload is! Map) {
      throw SearchException('The search key response was empty.',
          isUnavailable: true);
    }
    final key = SearchKey.fromJson(Map<String, dynamic>.from(payload));
    if (key.key.isEmpty) {
      throw SearchException('The server returned an empty search key.',
          isUnavailable: true);
    }
    return key;
  }

  /// Returns a valid key, fetching one if none is cached or the cached one is
  /// about to expire. Pass [forceRefresh] after a 401/403 from Typesense.
  Future<SearchKey> getSearchKey(String farmerId,
      {bool forceRefresh = false}) async {
    final cached = _cacheByFarmer[farmerId];
    if (!forceRefresh && cached != null && !cached.isExpired) {
      return cached;
    }
    final fresh = await _fetchKey(farmerId);
    _cacheByFarmer[farmerId] = fresh;
    return fresh;
  }

  /// Run a search.
  ///
  /// [query] is the raw text the farmer typed. [pondId] optionally narrows to
  /// one pond; it is applied as an extra `filter_by`. If Typesense rejects the
  /// key (401/403, e.g. it was revoked or the clock skewed), the key is
  /// refetched once and the search retried.
  Future<List<InspectionSearchResult>> search(
    String query, {
    required String farmerId,
    String? pondId,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    var key = await getSearchKey(farmerId);
    try {
      return await _runSearch(key, trimmed, pondId: pondId);
    } on _KeyRejected {
      key = await getSearchKey(farmerId, forceRefresh: true);
      try {
        return await _runSearch(key, trimmed, pondId: pondId);
      } on _KeyRejected {
        throw SearchException('Search was rejected. Please sign in again.');
      }
    }
  }

  Future<List<InspectionSearchResult>> _runSearch(
    SearchKey key,
    String query, {
    String? pondId,
  }) async {
    final params = <String, String>{
      'q': query,
      'query_by': 'notes,pond_name,species',
      'num_typos': '2',
      'prefix': 'true',
      'typo_tokens_threshold': '1',
      'highlight_full_fields': 'notes',
      'per_page': '20',
      'sort_by': '_text_match:desc,inspection_date:desc',
      if (pondId != null && pondId.isNotEmpty) 'filter_by': 'pond_id:=$pondId',
    };

    final uri = Uri.parse(
      '${key.baseUrl}/collections/${key.collection}/documents/search',
    ).replace(queryParameters: params);

    final http.Response res;
    try {
      res = await _client.get(uri, headers: {
        'X-TYPESENSE-API-KEY': key.key,
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw SearchException('Search timed out.', isUnavailable: true);
    } on http.ClientException {
      throw SearchException('Cannot reach the search service.',
          isUnavailable: true);
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw _KeyRejected();
    }
    if (res.statusCode != 200) {
      throw SearchException('Search failed (${res.statusCode}).',
          isUnavailable: res.statusCode >= 500);
    }

    dynamic data;
    try {
      data = jsonDecode(res.body);
    } on FormatException {
      throw SearchException('Search returned an invalid response.',
          isUnavailable: true);
    }
    if (data is! Map || data['hits'] is! List) {
      throw SearchException('Search returned an unexpected response.',
          isUnavailable: true);
    }

    return (data['hits'] as List)
        .whereType<Map>()
        .map((hit) => _resultFromHit(Map<String, dynamic>.from(hit)))
        .toList();
  }

  InspectionSearchResult _resultFromHit(Map<String, dynamic> hit) {
    final doc = Map<String, dynamic>.from(hit['document'] as Map);
    final highlight = hit['highlight'];
    var snippet = doc['notes']?.toString() ?? '';
    if (highlight is Map) {
      final notes = highlight['notes'];
      if (notes is Map && notes['value'] != null) {
        snippet = notes['value'].toString();
      } else if (notes is String) {
        snippet = notes;
      }
    }
    return InspectionSearchResult(
      inspection: Inspection.fromJson(doc),
      snippet: snippet,
    );
  }
}

/// Internal marker: Typesense refused the key itself, so a refetch is worth
/// trying. Never escapes this file.
class _KeyRejected implements Exception {}
