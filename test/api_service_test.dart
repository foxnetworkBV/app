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

    expect(result.token, 'abc123');
    expect(result.user.email, 'test@example.com');
  });
}
