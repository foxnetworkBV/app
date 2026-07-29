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

class PaymenterAuthorization {
  final Uri authorizationUrl;
  final String state;

  const PaymenterAuthorization({
    required this.authorizationUrl,
    required this.state,
  });
}

class PaymenterLoginStatus {
  final String status;
  final String? token;
  final User? user;
  final String? message;

  const PaymenterLoginStatus({
    required this.status,
    this.token,
    this.user,
    this.message,
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

  static Future<PaymenterAuthorization> createPaymenterAuthorization() async {
    final response = await http.get(
      _uri('api/paymenter/authorize'),
      headers: _headers(),
    );

    _ensureSuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return PaymenterAuthorization(
      authorizationUrl: Uri.parse(data['authorization_url'] as String),
      state: data['state'] as String,
    );
  }

  static Future<PaymenterLoginStatus> getPaymenterLoginStatus(
    String state,
  ) async {
    http.Client? client;

    try {
      client = http.Client();
      final uri = _uri('api/paymenter/status').replace(
        queryParameters: {'state': state},
      );

      final response = await client
          .get(
            uri,
            headers: {
              ..._headers(),
              'Cache-Control': 'no-cache',
              'Connection': 'close',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        return const PaymenterLoginStatus(status: 'expired');
      }

      if (response.statusCode >= 500) {
        // Cloudflare/origin interruptions are temporary during OAuth polling.
        return const PaymenterLoginStatus(status: 'pending');
      }

      _ensureSuccess(response);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return PaymenterLoginStatus(
        status: data['status']?.toString() ?? 'failed',
        token: data['token']?.toString(),
        user: data['user'] is Map<String, dynamic>
            ? User.fromJson(data['user'] as Map<String, dynamic>)
            : null,
        message: data['message']?.toString(),
      );
    } on SocketException {
      return const PaymenterLoginStatus(status: 'pending');
    } on TimeoutException {
      return const PaymenterLoginStatus(status: 'pending');
    } on http.ClientException {
      return const PaymenterLoginStatus(status: 'pending');
    } on FormatException {
      return const PaymenterLoginStatus(status: 'pending');
    } finally {
      client?.close();
    }
  }

  static Future<User> getCurrentUser(String token) async {
    final response = await http.get(
      _uri('api/me'),
      headers: _headers(token),
    );

    _ensureSuccess(response);
    return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<List<CustomerService>> getServices(String token) async {
    Object? lastError;

    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http
            .get(_uri('api/services'), headers: _headers(token))
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
        .get(_uri('api/invoices'), headers: _headers(token))
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
    final response = await http.get(_uri('api/invoices/$invoiceId'), headers: _headers(token)).timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
    return InvoiceDetail.fromJson(jsonDecode(response.body) as Map<String,dynamic>);
  }

  static Future<List<SupportTicket>> getTickets(String token) async {
    final response = await http
        .get(_uri('api/tickets'), headers: _headers(token))
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
        .get(_uri('api/tickets/$ticketId'), headers: _headers(token))
        .timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
    return TicketDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<SupportTicket> createTicket(
    String token, {
    required String subject,
    required String message,
  }) async {
    final response = await http
        .post(
          _uri('api/tickets'),
          headers: _headers(token),
          body: jsonEncode({'subject': subject, 'message': message}),
        )
        .timeout(const Duration(seconds: 30));
    _ensureSuccess(response);
    return SupportTicket.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<ServerResources> getServerResources(
    String token,
    int serviceId,
  ) async {
    final response = await http
        .get(
          _uri('api/services/$serviceId/resources'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 25));
    _ensureSuccess(response);
    return ServerResources.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<void> sendPowerAction(
    String token,
    int serviceId,
    String action,
  ) async {
    final response = await http.post(
      _uri('api/services/$serviceId/power'),
      headers: _headers(token),
      body: jsonEncode({'action': action}),
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
