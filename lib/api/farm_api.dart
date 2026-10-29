import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/farm.dart';
import '../models/inspection.dart';

/// A failure the UI can act on. [isNetworkError] is what triggers the offline
/// fallback to local filtering.
class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);

  bool get isNetworkError => status == 0;

  @override
  String toString() => message;
}

/// Client for the mock aquaculture API.
///
/// There is no login in this build, so the "session" is just the demo farmer
/// id the app picked. Every call sends it in `X-Farmer-Id`; on a real backend
/// this becomes the bearer token and the rest of the client is unchanged.
class FarmApi {
  FarmApi(this.farmerId, {http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final String farmerId;
  final http.Client _client;
  final String _baseUrl;

  static const _timeout = Duration(seconds: 15);

  Future<dynamic> _get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final http.Response res;
    try {
      res = await _client
          .get(uri, headers: {
            'Accept': 'application/json',
            'X-Farmer-Id': farmerId,
          })
          .timeout(_timeout);
    } on TimeoutException {
      throw ApiException(0, 'The server took too long to respond.');
    } on http.ClientException {
      throw ApiException(0, 'Cannot reach the server. Check your connection.');
    }

    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } on FormatException {
      data = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data is Map ? data['data'] ?? data : data;
    }
    final message = data is Map ? data['message']?.toString() : null;
    throw ApiException(res.statusCode, message ?? 'Request failed (${res.statusCode}).');
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    final http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'X-Farmer-Id': farmerId,
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw ApiException(0, 'The server took too long to respond.');
    } on http.ClientException {
      throw ApiException(0, 'Cannot reach the server. Check your connection.');
    }

    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } on FormatException {
      data = null;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data is Map ? data['data'] ?? data : data;
    }
    final message = data is Map ? data['message']?.toString() : null;
    throw ApiException(res.statusCode, message ?? 'Request failed (${res.statusCode}).');
  }

  Future<List<Farm>> farms() async {
    final rows = await _get('/api/farms') as List;
    return rows
        .map((e) => Farm.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Pond>> ponds({String? farmId}) async {
    final rows = await _get('/api/ponds', query: {
      if (farmId != null) 'farm_id': farmId,
    }) as List;
    return rows
        .map((e) => Pond.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Inspection>> inspections({String? pondId}) async {
    final rows = await _get('/api/inspections', query: {
      if (pondId != null) 'pond_id': pondId,
    }) as List;
    return rows
        .map((e) => Inspection.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Inspection> createInspection(Map<String, dynamic> payload) async {
    final row = await _post('/api/inspections', payload) as Map;
    return Inspection.fromJson(Map<String, dynamic>.from(row));
  }

  void close() => _client.close();
}
