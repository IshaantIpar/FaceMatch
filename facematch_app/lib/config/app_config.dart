class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String matchEndpoint = '$baseUrl/match';

  static const Duration requestTimeout = Duration(seconds: 60);
}
