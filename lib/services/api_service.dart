import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';

class LoginResult {
  final String token;
  final User user;

  const LoginResult({
    required this.token,
    required this.user,
  });
}

class ApiService {
  static Uri _uri(String path) =>
      Uri.parse('${ApiConfig.baseUrl}/${path.replaceFirst(RegExp(r"^/"), "")}');

  static Map<String, String> _headers([String? token]) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<LoginResult> login(
    String email,
    String password, {
    http.Client? client,
  }) async {
    final requestClient = client ?? http.Client();
    try {
      final response = await requestClient.post(
        _uri('api/mobile-auth.php'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      _ensureSuccess(response);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return LoginResult(
        token: data['token']?.toString() ?? '',
        user: User.fromJson(data['user'] as Map<String, dynamic>),
      );
    } finally {
      if (client == null) {
        requestClient.close();
      }
    }
  }

  static Future<User> getCurrentUser(String token) async {
    final response = await http.get(
      _uri('api/mobile-me.php'),
      headers: {
        ..._headers(token),
        'X-Session-Token': token,
      },
    );

    _ensureSuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  static Future<List<CustomerService>> getServices(String token) async {
    Object? lastError;

    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http
            .get(
              _uri('api/mobile-services.php'),
              headers: {
                ..._headers(token),
                'X-Session-Token': token,
              },
            )
            .timeout(const Duration(seconds: 35));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body);
          final data = decoded is List<dynamic>
              ? decoded
              : (decoded is Map<String, dynamic> && decoded['data'] is List<dynamic>
                  ? decoded['data'] as List<dynamic>
                  : <dynamic>[]);
          return data
              .whereType<Map<String, dynamic>>()
              .map(CustomerService.fromJson)
              .toList();
        }

        lastError = Exception(_errorMessage(response));
        if (response.statusCode < 500 || attempt == 3) {
          throw lastError;
        }
      } on TimeoutException {
        lastError = Exception('The API took too long to respond. Please try again.');
      } on http.ClientException catch (error) {
        lastError = Exception('Network connection failed: ${error.message}');
      }

      if (attempt < 3) {
        await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
      }
    }

    throw lastError ?? Exception('Could not load services.');
  }

  static Future<List<Invoice>> getInvoices(String token) async {
    final response = await http
        .get(
          _uri('api/mobile-invoices.php'),
          headers: {
            ..._headers(token),
            'X-Session-Token': token,
          },
        )
        .timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    final data = decoded is List<dynamic>
        ? decoded
        : (decoded is Map<String, dynamic> && decoded['data'] is List<dynamic>
            ? decoded['data'] as List<dynamic>
            : <dynamic>[]);
    return data
        .whereType<Map<String, dynamic>>()
        .map(Invoice.fromJson)
        .toList();
  }


  static Future<InvoiceDetail> getInvoice(String token, int invoiceId) async {
    final response = await http
        .get(
          _uri('api/mobile-invoices.php'),
          headers: {
            ..._headers(token),
            'X-Session-Token': token,
          },
        )
        .timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw Exception('Invalid invoice response.');
    final list = decoded['data'] is List<dynamic> ? decoded['data'] as List<dynamic> : <dynamic>[];
    final match = list.whereType<Map<String, dynamic>>().firstWhere(
      (entry) => int.tryParse(entry['id']?.toString() ?? '') == invoiceId,
      orElse: () => <String, dynamic>{},
    );
    if (match.isEmpty) {
      return InvoiceDetail.fromInvoice(Invoice(id: invoiceId, number: 'Invoice #$invoiceId', amount: 0, status: 'Unknown', issuedAt: '', currency: 'EUR'));
    }
    return InvoiceDetail.fromJson(match);
  }

  static Future<List<SupportTicket>> getTickets(String token) async {
    final response = await http
        .get(
          _uri('api/mobile-tickets.php'),
          headers: {
            ..._headers(token),
            'X-Session-Token': token,
          },
        )
        .timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    final data = decoded is List<dynamic>
        ? decoded
        : (decoded is Map<String, dynamic> && decoded['data'] is List<dynamic>
            ? decoded['data'] as List<dynamic>
            : <dynamic>[]);
    return data
        .whereType<Map<String, dynamic>>()
        .map(SupportTicket.fromJson)
        .toList();
  }

  static Future<TicketDetail> getTicket(String token, int ticketId) async {
    final response = await http
        .get(
          _uri('api/mobile-ticket.php?id=$ticketId'),
          headers: {
            ..._headers(token),
            'X-Session-Token': token,
          },
        )
        .timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) throw Exception('Invalid ticket response.');
    final data = decoded['data'] is Map<String, dynamic> ? decoded['data'] as Map<String, dynamic> : decoded;
    return TicketDetail.fromJson(data);
  }

  static Future<SupportTicket> createTicket(
    String token, {
    required String subject,
    required String message,
  }) async {
    final response = await http
        .post(
          _uri('api/mobile-create-ticket.php'),
          headers: {
            ..._headers(token),
            'X-Session-Token': token,
          },
          body: jsonEncode({'subject': subject, 'message': message}),
        )
        .timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] is Map<String, dynamic> ? decoded['data'] as Map<String, dynamic> : decoded;
    return SupportTicket.fromJson(data);
  }

  static Future<ServerResources> getServerResources(
    String token,
    int serviceId,
  ) async {
    final response = await http
        .get(
          _uri('api/mobile-resources.php?service_id=$serviceId'),
          headers: {
            ..._headers(token),
            'X-Session-Token': token,
          },
        )
        .timeout(const Duration(seconds: 25));
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] is Map<String, dynamic> ? decoded['data'] as Map<String, dynamic> : decoded;
    return ServerResources.fromJson(data);
  }

  static Future<void> sendPowerAction(
    String token,
    int serviceId,
    String action,
  ) async {
    final response = await http.post(
      _uri('api/power.php'),
      headers: {
        ..._headers(token),
        'X-Session-Token': token,
        'X-CSRF-Token': 'mobile',
      },
      body: jsonEncode({'id': serviceId.toString(), 'signal': action}),
    );

    _ensureSuccess(response);
  }

  static String _errorMessage(http.Response response) {
    if (response.body.isEmpty) {
      return 'Server error (${response.statusCode})';
    }

    try {
      final value = jsonDecode(response.body);
      if (value is Map<String, dynamic>) {
        return (value['message'] ?? value['error'] ?? response.body).toString();
      }
    } catch (_) {
      // Return the original body when it is not JSON.
    }

    return response.body;
  }

  static void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response));
    }
  }
}
