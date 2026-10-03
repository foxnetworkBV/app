class ApiConfig {
  static const String customerPortalUrl = 'https://client.foxnetwork.be';

  static const String baseUrl = customerPortalUrl;
  static const String mobileApiPath = '/api/foxnetwork';
  static const String oauthRedirectUri = 'foxnetwork://oauth/callback';
  static const bool demoMode = false;
  static const String oauthCallbackScheme = 'foxnetwork';
  static const String oauthCallbackHost = 'oauth';
  static const String oauthCallbackPath = '/callback';
}
