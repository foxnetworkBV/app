class ApiConfig {
  // Android emulator: http://10.0.2.2:8080
  // Windows/Chrome test: http://127.0.0.1:8080
  // Production: https://your-site-domain.example
  static const String baseUrl = 'http://127.0.0.1:8080';
  static const bool demoMode = false;
  static const String oauthCallbackScheme = 'foxnetwork';
  static const String oauthCallbackHost = 'oauth';
  static const String oauthCallbackPath = '/callback';
}
