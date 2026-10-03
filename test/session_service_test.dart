import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foxnetwork_app/services/api_service.dart';
import 'package:foxnetwork_app/services/paymenter_auth_service.dart';
import 'package:foxnetwork_app/services/session_service.dart';

class MemoryAuth extends PaymenterAuthService {
  PaymenterCredentials? stored;
  int refreshes = 0;
  Completer<void>? refreshGate;
  @override
  Future<PaymenterCredentials?> read() async => stored;
  @override
  Future<void> save(PaymenterCredentials value) async {
    stored = value;
  }

  @override
  Future<void> clear() async {
    stored = null;
  }

  @override
  Future<PaymenterCredentials> signIn() async => PaymenterCredentials(
      accessToken: 'old',
      refreshToken: 'refresh',
      clientId: 'public',
      expiresAt: DateTime.utc(2020));
  @override
  Future<PaymenterCredentials> refresh(PaymenterCredentials previous) async {
    refreshes++;
    await refreshGate?.future;
    return PaymenterCredentials(
        accessToken: 'new',
        refreshToken: 'new-refresh',
        clientId: previous.clientId,
        expiresAt: DateTime.now().add(const Duration(hours: 1)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('old backend tokens are discarded without sending them to Paymenter',
      () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'legacy-secret'});
    final auth = MemoryAuth();
    final session = SessionService(auth: auth, restore: false);
    await http.runWithClient(session.restoreSession,
        () => MockClient((_) async => throw StateError('No request expected')));
    expect(session.isAuthenticated, false);
    expect((await SharedPreferences.getInstance()).getString('auth_token'),
        isNull);
  });
  test('concurrent API calls share one refresh and use the rotated token',
      () async {
    final auth = MemoryAuth()..refreshGate = Completer<void>();
    final session = SessionService(auth: auth, restore: false);
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/me')) {
        return http.Response(
            '{"data":{"id":1,"name":"Customer","email":"test@example.com"}}',
            200);
      }
      expect(request.headers['authorization'], 'Bearer new');
      return http.Response('{"data":[],"last_page":1}', 200);
    });
    await http.runWithClient(() async {
      await session.signIn();
      final services = session.getServices();
      final invoices = session.getInvoices();
      expect(auth.refreshes, 1);
      auth.refreshGate!.complete();
      await Future.wait([services, invoices]);
      expect(auth.stored!.refreshToken, 'new-refresh');
    }, () => client);
  });
  test('revoked token clears authentication and secure storage', () async {
    final auth = MemoryAuth()
      ..stored = PaymenterCredentials(
          accessToken: 'revoked',
          refreshToken: 'refresh',
          clientId: 'public',
          expiresAt: DateTime.utc(2100));
    final session = SessionService(auth: auth, restore: false);
    await http.runWithClient(session.restoreSession,
        () => MockClient((_) async => http.Response('{}', 401)));
    expect(session.isAuthenticated, false);
    expect(auth.stored, isNull);
    expect(session.isLoading, false);
  });
  test('temporary outage preserves saved credentials for retry', () async {
    final auth = MemoryAuth()
      ..stored = PaymenterCredentials(
          accessToken: 'valid',
          refreshToken: 'refresh',
          clientId: 'public',
          expiresAt: DateTime.utc(2100));
    final session = SessionService(auth: auth, restore: false);
    await http.runWithClient(session.restoreSession,
        () => MockClient((_) async => http.Response('{}', 503)));
    expect(auth.stored, isNotNull);
    expect(session.restoreError, isNotNull);
    expect(session.isLoading, false);
  });
  test('offline sign-out still removes device credentials', () async {
    final auth = MemoryAuth()
      ..stored = PaymenterCredentials(
          accessToken: 'valid',
          refreshToken: 'refresh',
          clientId: 'public',
          expiresAt: DateTime.utc(2100));
    final session = SessionService(auth: auth, restore: false);
    await http.runWithClient(() async {
      await session.restoreSession();
      await session.logout();
    },
        () => MockClient((request) async {
              if (request.url.path.endsWith('/logout')) {
                throw const ApiException('Offline');
              }
              return http.Response(
                  '{"data":{"id":1,"name":"Customer","email":"test@example.com"}}',
                  200);
            }));
    expect(auth.stored, isNull);
    expect(session.isAuthenticated, false);
  });
}
