import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class PaymenterCredentials {
  final String accessToken;
  final String? refreshToken;
  final String clientId;
  final DateTime expiresAt;
  const PaymenterCredentials(
      {required this.accessToken,
      required this.refreshToken,
      required this.clientId,
      required this.expiresAt});
  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'client_id': clientId,
        'expires_at': expiresAt.toUtc().toIso8601String()
      };
  factory PaymenterCredentials.fromJson(Map<String, dynamic> json) =>
      PaymenterCredentials(
          accessToken: json['access_token'] as String,
          refreshToken: json['refresh_token'] as String?,
          clientId: json['client_id'] as String,
          expiresAt: DateTime.parse(json['expires_at'] as String));
}

class PaymenterAuthService {
  static const _key = 'paymenter_client_foxnetwork_credentials_v1';
  final FlutterAppAuth _appAuth;
  final FlutterSecureStorage _storage;
  PaymenterAuthService({FlutterAppAuth? appAuth, FlutterSecureStorage? storage})
      : _appAuth = appAuth ?? const FlutterAppAuth(),
        _storage = storage ?? const FlutterSecureStorage();
  static const _configuration = AuthorizationServiceConfiguration(
    authorizationEndpoint: '${ApiConfig.baseUrl}/oauth/authorize',
    tokenEndpoint: '${ApiConfig.baseUrl}/api/oauth/token',
  );
  Future<PaymenterCredentials> signIn() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      throw const ApiException(
          'Use the Android or iPhone app to sign in, or open the customer portal in your browser.');
    }
    final config = await ApiService.request('config');
    final clientId = config['client_id']?.toString() ?? '';
    if (clientId.isEmpty) {
      throw const ApiException(
          'Mobile sign-in is not configured yet. Please contact support.');
    }
    // AppAuth validates OAuth state and uses PKCE. Paymenter handles password,
    // CAPTCHA and two-factor authentication in the system browser.
    final response =
        await _appAuth.authorizeAndExchangeCode(AuthorizationTokenRequest(
      clientId,
      ApiConfig.oauthRedirectUri,
      serviceConfiguration: _configuration,
      scopes: const ['profile', 'foxnetwork:customer'],
    ));
    return _credentials(response, clientId);
  }

  Future<PaymenterCredentials> refresh(PaymenterCredentials previous) async {
    if (previous.refreshToken == null || previous.refreshToken!.isEmpty) {
      throw const ApiException(
          'Your session has expired. Please sign in again.', 401);
    }
    try {
      final response = await _appAuth.token(TokenRequest(
          previous.clientId, ApiConfig.oauthRedirectUri,
          refreshToken: previous.refreshToken,
          serviceConfiguration: _configuration));
      return _credentials(response, previous.clientId, previous.refreshToken);
    } on FlutterAppAuthPlatformException catch (error) {
      if (error.platformErrorDetails.error ==
          FlutterAppAuthOAuthError.invalidGrant) {
        throw const ApiException(
            'Your session has expired. Please sign in again.', 401);
      }
      throw const ApiException(
          'Could not renew your session. Please try again.');
    }
  }

  PaymenterCredentials _credentials(TokenResponse response, String clientId,
      [String? previousRefresh]) {
    final token = response.accessToken;
    final expiry = response.accessTokenExpirationDateTime;
    if (token == null || token.isEmpty || expiry == null) {
      throw const ApiException(
          'Paymenter did not return a valid login session.');
    }
    return PaymenterCredentials(
        accessToken: token,
        refreshToken: response.refreshToken ?? previousRefresh,
        clientId: clientId,
        expiresAt: expiry);
  }

  Future<PaymenterCredentials?> read() async {
    final saved = await _storage.read(key: _key);
    if (saved == null) return null;
    try {
      return PaymenterCredentials.fromJson(
          jsonDecode(saved) as Map<String, dynamic>);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> save(PaymenterCredentials value) =>
      _storage.write(key: _key, value: jsonEncode(value.toJson()));
  Future<void> clear() => _storage.delete(key: _key);
}
