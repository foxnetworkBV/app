import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:foxnetwork_app/services/api_service.dart';

void main() {
  test('login posts credentials to the new API endpoint', () async {
    final client = MockClient((request) async {
      expect(request.method, equals('POST'));
      expect(request.url.path, equals('/api/mobile-auth.php'));
      expect(request.body, equals('{"email":"test@example.com","password":"secret"}'));

      return http.Response(
        '{"token":"abc123","user":{"id":1,"name":"Test User","email":"test@example.com"}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await ApiService.login('test@example.com', 'secret', client: client);

    expect(result.result!.token, 'abc123');
    expect(result.result!.user.email, 'test@example.com');
  });

  test('login exposes the site two-factor challenge on a 401 response', () async {
    final client = MockClient((request) async => http.Response(
      '{"ok":false,"two_factor_required":true,"challenge_token":"challenge","method":"totp","expires_in":600}',
      401,
    ));

    final attempt = await ApiService.login('test@example.com', 'secret', client: client);

    expect(attempt.requiresTwoFactor, isTrue);
    expect(attempt.challenge!.token, 'challenge');
    expect(attempt.challenge!.method, 'totp');
  });

  test('two-factor verification resumes the site challenge session', () async {
    final client = MockClient((request) async {
      expect(request.headers['authorization'], equals('Bearer challenge'));
      expect(request.body, equals('{"two_factor_code":"123456"}'));
      return http.Response(
        '{"ok":true,"token":"signed-in","user":{"id":1,"name":"Test User","email":"test@example.com"}}',
        200,
      );
    });

    final attempt = await ApiService.login(
      'test@example.com',
      'secret',
      twoFactorCode: '123456',
      challengeToken: 'challenge',
      client: client,
    );

    expect(attempt.result!.token, 'signed-in');
  });
}
