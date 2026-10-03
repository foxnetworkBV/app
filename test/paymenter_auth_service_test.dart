import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:foxnetwork_app/services/api_service.dart';
import 'package:foxnetwork_app/services/paymenter_auth_service.dart';

class FakeAppAuth extends FlutterAppAuth {
  AuthorizationTokenRequest? authorization;
  TokenRequest? refreshRequest;
  bool emptyToken = false;
  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
      AuthorizationTokenRequest request) async {
    authorization = request;
    return AuthorizationTokenResponse(
        emptyToken ? '' : 'access',
        'refresh',
        DateTime.now().add(const Duration(hours: 1)),
        null,
        'Bearer',
        null,
        null,
        null);
  }

  @override
  Future<TokenResponse> token(TokenRequest request) async {
    refreshRequest = request;
    return TokenResponse(
        'rotated-access',
        'rotated-refresh',
        DateTime.now().add(const Duration(hours: 1)),
        null,
        'Bearer',
        null,
        null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  final client = MockClient((request) async {
    expect(request.url.toString(),
        'https://client.foxnetwork.be/api/foxnetwork/config');
    expect(request.headers['authorization'], isNull);
    return http.Response('{"client_id":"public-client"}', 200);
  });
  test('browser OAuth uses customer scopes without a client secret', () async {
    final plugin = FakeAppAuth();
    final auth = PaymenterAuthService(appAuth: plugin);
    final credentials = await http.runWithClient(auth.signIn, () => client);
    final request = plugin.authorization!;
    expect(request.clientId, 'public-client');
    expect(request.clientSecret, isNull);
    expect(request.redirectUrl, 'foxnetwork://oauth/callback');
    expect(request.scopes, ['profile', 'foxnetwork:customer']);
    expect(request.serviceConfiguration!.authorizationEndpoint,
        'https://client.foxnetwork.be/oauth/authorize');
    expect(credentials.accessToken, 'access');
  });
  test('missing public client fails before opening the browser', () async {
    final plugin = FakeAppAuth();
    final auth = PaymenterAuthService(appAuth: plugin);
    await expectLater(
        http.runWithClient(auth.signIn,
            () => MockClient((_) async => http.Response('{}', 200))),
        throwsA(isA<ApiException>()));
    expect(plugin.authorization, isNull);
  });
  test('empty OAuth token cannot establish a session', () async {
    final auth =
        PaymenterAuthService(appAuth: FakeAppAuth()..emptyToken = true);
    await expectLater(http.runWithClient(auth.signIn, () => client),
        throwsA(isA<ApiException>()));
  });
  test('refresh rotates both tokens using the original public client',
      () async {
    final plugin = FakeAppAuth();
    final auth = PaymenterAuthService(appAuth: plugin);
    final previous = PaymenterCredentials(
        accessToken: 'old',
        refreshToken: 'old-refresh',
        clientId: 'client',
        expiresAt: DateTime.now());
    final next = await auth.refresh(previous);
    expect(plugin.refreshRequest!.refreshToken, 'old-refresh');
    expect(plugin.refreshRequest!.clientId, 'client');
    expect(next.refreshToken, 'rotated-refresh');
  });
  test('secure storage round-trip and logout remove credentials', () async {
    final auth = PaymenterAuthService();
    final original = PaymenterCredentials(
        accessToken: 'access',
        refreshToken: 'refresh',
        clientId: 'client',
        expiresAt: DateTime.utc(2030));
    await auth.save(original);
    expect((await auth.read())!.toJson(), original.toJson());
    await auth.clear();
    expect(await auth.read(), isNull);
  });
}
