import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  ApiConfig._();

  static const _preferenceKey = 'api_base_url';
  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
  static String _baseUrl = defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> initialize() async {
    _baseUrl = defaultBaseUrl;
    final preferences = await SharedPreferences.getInstance();
    final savedUrl = preferences.getString(_preferenceKey);
    if (savedUrl != null) _baseUrl = normalizeBaseUrl(savedUrl);
  }

  static Future<void> setBaseUrl(String value) async {
    final normalizedUrl = normalizeBaseUrl(value);
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_preferenceKey, normalizedUrl);
    if (!saved) {
      throw StateError('No se pudo guardar la dirección de la API.');
    }
    _baseUrl = normalizedUrl;
  }

  static String normalizeBaseUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'Ingresa una dirección válida, por ejemplo http://192.168.1.25:8080.',
      );
    }
    return uri.replace(path: '', query: null, fragment: null).toString();
  }
}
