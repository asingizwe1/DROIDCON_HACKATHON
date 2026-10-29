/// Where everything lives. Override at build time without editing code:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
class AppConfig {
  static const String _apiOverride = String.fromEnvironment('API_BASE_URL');
  static const String _typesenseHostOverride =
      String.fromEnvironment('TYPESENSE_HOST');
  static const String _typesensePortOverride =
      String.fromEnvironment('TYPESENSE_PORT');

  /// The mock aquaculture API. It is the only thing that knows the Typesense
  /// admin key; the app only ever receives a scoped search key from it.
  static String get apiBaseUrl =>
      _apiOverride.isNotEmpty ? _apiOverride : 'http://localhost:8080';

  /// Typesense is reached directly from the browser for search. In production
  /// this comes from the `/api/search-key` response so it can change without
  /// an app update; these are the fallbacks used locally.
  static String get fallbackTypesenseHost =>
      _typesenseHostOverride.isNotEmpty ? _typesenseHostOverride : 'localhost';
  static int get fallbackTypesensePort {
    final raw = _typesensePortOverride;
    if (raw.isNotEmpty) return int.tryParse(raw) ?? 8108;
    return 8108;
  }

  static const String inspectionsCollection = 'inspections';
  static const Duration searchDebounce = Duration(milliseconds: 300);
}
