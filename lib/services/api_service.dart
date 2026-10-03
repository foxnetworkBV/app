import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ConsoleCredentials {
  final String socket;
  final String token;
  final String server;
  const ConsoleCredentials(
      {required this.socket, required this.token, required this.server});
  factory ConsoleCredentials.fromJson(Map<String, dynamic> json) {
    var socket = (json['socket'] ?? '').toString();
    if (socket.startsWith('https://')) socket = 'wss://${socket.substring(8)}';
    final uri = Uri.tryParse(socket);
    final token = (json['token'] ?? '').toString();
    if (uri == null ||
        uri.scheme != 'wss' ||
        uri.host.isEmpty ||
        token.isEmpty) {
      throw const ApiException(
          'Secure console access is unavailable for this service.');
    }
    return ConsoleCredentials(
        socket: socket, token: token, server: '${json['server'] ?? ''}');
  }
}

class ApiService {
  static Future<Map<String, dynamic>> request(String path,
      {String? token, Map<String, dynamic>? body, http.Client? client}) async {
    final transport = client ?? http.Client();
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.mobileApiPath}/$path');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token'
    };
    try {
      final response = await (body == null
              ? transport.get(uri, headers: headers)
              : transport.post(uri, headers: headers, body: jsonEncode(body)))
          .timeout(const Duration(seconds: 30));
      Map<String, dynamic>? data;
      try {
        final value = jsonDecode(response.body);
        if (value is Map<String, dynamic>) data = value;
      } on FormatException {/* Do not display HTML error pages. */}
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = switch (response.statusCode) {
          401 => 'Your session has expired. Please sign in again.',
          429 => 'Too many requests. Please wait a moment and try again.',
          _ => data?['message'] is String
              ? data!['message'] as String
              : 'The customer portal is unavailable (${response.statusCode}). Please try again.',
        };
        throw ApiException(message, response.statusCode);
      }
      if (data == null) {
        throw const ApiException(
            'The customer portal returned an invalid response.');
      }
      return data;
    } on TimeoutException {
      throw const ApiException(
          'The customer portal took too long to respond. Please try again.');
    } on http.ClientException {
      throw const ApiException(
          'Could not connect to the customer portal. Check your connection.');
    } finally {
      if (client == null) transport.close();
    }
  }

  static Map<String, dynamic> object(Map<String, dynamic> response) {
    if (response['data'] is! Map<String, dynamic>) {
      throw const ApiException(
          'The customer portal returned an invalid response.');
    }
    return response['data'] as Map<String, dynamic>;
  }

  // Follow page numbers on our own origin; never send tokens to a response URL.
  static Future<List<Map<String, dynamic>>> _list(String path, String token,
      {http.Client? client}) async {
    final rows = <Map<String, dynamic>>[];
    for (var page = 1; page <= 1000; page++) {
      final response =
          await request('$path?page=$page', token: token, client: client);
      if (response['data'] is! List ||
          (response['data'] as List).any((row) => row is! Map<String, dynamic>)) {
        throw const ApiException(
            'The customer portal returned an invalid list.');
      }
      rows.addAll((response['data'] as List).cast<Map<String, dynamic>>());
      final lastPage = int.tryParse('${response['last_page']}');
      if (lastPage == null || lastPage < page || lastPage > 1000) {
        throw const ApiException(
            'The customer portal returned invalid pagination.');
      }
      if (page == lastPage) return rows;
    }
    throw const ApiException(
        'Too many results. Please use the customer portal.');
  }

  static Future<User> getCurrentUser(String token,
          {http.Client? client}) async =>
      User.fromJson(object(await request('me', token: token, client: client)));
  static Future<List<CustomerService>> getServices(String token,
          {http.Client? client}) async =>
      (await _list('services', token, client: client))
          .map(CustomerService.fromJson)
          .toList();
  static Future<List<Invoice>> getInvoices(String token,
          {http.Client? client}) async =>
      (await _list('invoices', token, client: client))
          .map(Invoice.fromJson)
          .toList();
  static Future<InvoiceDetail> getInvoice(String token, int id,
          {http.Client? client}) async =>
      InvoiceDetail.fromJson(
          object(await request('invoices/$id', token: token, client: client)));
  static Future<List<SupportTicket>> getTickets(String token,
          {http.Client? client}) async =>
      (await _list('tickets', token, client: client))
          .map(SupportTicket.fromJson)
          .toList();
  static Future<TicketDetail> getTicket(String token, int id,
          {http.Client? client}) async =>
      TicketDetail.fromJson(
          object(await request('tickets/$id', token: token, client: client)));
  static Future<SupportTicket> createTicket(String token,
          {required String subject,
          required String message,
          http.Client? client}) async =>
      SupportTicket.fromJson(object(await request('tickets',
          token: token,
          body: {'subject': subject, 'message': message},
          client: client)));
  static Future<ServerResources> getServerResources(
          String token, int id) async =>
      ServerResources.fromJson(
          object(await request('services/$id/resources', token: token)));
  static Future<void> sendPowerAction(
      String token, int id, String action) async {
    await request('services/$id/power', token: token, body: {'action': action});
  }

  static Future<ConsoleCredentials> getConsoleCredentials(
          String token, int id) async =>
      ConsoleCredentials.fromJson(
          object(await request('services/$id/console', token: token)));
  static Future<void> logout(String token) async {
    await request('logout', token: token, body: {});
  }
}
