import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:foxnetwork_app/services/api_service.dart';

void main() {
  test('profile uses Paymenter customer API with bearer authentication',
      () async {
    final client = MockClient((request) async {
      expect(request.url.toString(),
          'https://client.foxnetwork.be/api/foxnetwork/me');
      expect(request.headers['authorization'], 'Bearer customer-token');
      return http.Response(
          '{"data":{"id":5,"name":"Customer","email":"test@example.com"}}',
          200);
    });
    expect(
        (await ApiService.getCurrentUser('customer-token', client: client)).id,
        5);
  });
  test('services follow pages on our origin and preserve capabilities',
      () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      expect(request.url.host, 'client.foxnetwork.be');
      final page = int.parse(request.url.queryParameters['page']!);
      return http.Response(
          jsonEncode({
            'last_page': 2,
            'next_page_url': 'https://untrusted.example',
            'data': [
              {
                'id': page,
                'name': 'Hosting',
                'price': '12.50',
                'currency': 'USD',
                'can_control': page == 2
              }
            ]
          }),
          200);
    });
    final rows = await ApiService.getServices('token', client: client);
    expect(requests, 2);
    expect(rows.map((r) => r.id), [1, 2]);
    expect(rows.first.price, 12.5);
    expect(rows.first.currency, 'USD');
    expect(rows.first.canControl, false);
    expect(rows.last.canControl, true);
  });
  test('malformed collections do not silently appear empty', () async {
    final client = MockClient(
        (_) async => http.Response('{"data":{},"last_page":1}', 200));
    await expectLater(ApiService.getInvoices('token', client: client),
        throwsA(isA<ApiException>()));
  });
  test('invalid pagination cannot return a partial list', () async {
    final client = MockClient(
        (_) async => http.Response('{"data":[],"last_page":5000}', 200));
    await expectLater(ApiService.getTickets('token', client: client),
        throwsA(isA<ApiException>()));
  });
  test('invoice detail requests the selected invoice directly', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/foxnetwork/invoices/81');
      return http.Response(
          '{"data":{"id":81,"total":"15.50","items":[{"id":1,"description":"Hosting","quantity":1,"price":15.5,"total":15.5}]}}',
          200);
    });
    final invoice = await ApiService.getInvoice('token', 81, client: client);
    expect(invoice.total, 15.5);
    expect(invoice.items.single.description, 'Hosting');
  });
  test('missing invoice errors instead of fabricating an invoice', () async {
    final client =
        MockClient((_) async => http.Response('{"message":"Not found"}', 404));
    await expectLater(
        ApiService.getInvoice('token', 81, client: client),
        throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 404)));
  });
  test('new ticket is sent to Paymenter with its message', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/foxnetwork/tickets');
      expect(jsonDecode(request.body),
          {'subject': 'Help', 'message': 'Please help.'});
      return http.Response(
          '{"data":{"id":7,"subject":"Help","status":"open"}}', 201);
    });
    expect(
        (await ApiService.createTicket('token',
                subject: 'Help', message: 'Please help.', client: client))
            .id,
        7);
  });
  test('HTML errors do not expose server diagnostics', () async {
    final client = MockClient((_) async =>
        http.Response('<html>Private server diagnostics</html>', 500));
    await expectLater(
        ApiService.getCurrentUser('token', client: client),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', isNot(contains('Private')))));
  });
  test('expired authentication is distinguishable from network errors',
      () async {
    final client = MockClient((_) async => http.Response('{}', 401));
    await expectLater(
        ApiService.getCurrentUser('token', client: client),
        throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
  });
  test('console rejects insecure websocket credentials', () {
    expect(
        () => ConsoleCredentials.fromJson(
            {'socket': 'ws://panel.example/ws', 'token': 'token'}),
        throwsA(isA<ApiException>()));
  });
}
