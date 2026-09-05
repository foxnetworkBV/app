import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';

class SessionService extends ChangeNotifier {
  User? user;
  String? _token;
  bool isAuthenticated = false;
  bool isLoading = true;

  SessionService() {
    restoreSession();
  }

  String? get token => _token;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');

    if (savedToken == null || savedToken.isEmpty) {
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      user = await ApiService.getCurrentUser(savedToken);
      _token = savedToken;
      isAuthenticated = true;
    } catch (_) {
      await prefs.remove('auth_token');
      _token = null;
      user = null;
      isAuthenticated = false;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<TwoFactorChallenge?> signIn(String email, String password) async {
    final attempt = await ApiService.login(email, password);
    if (attempt.requiresTwoFactor) return attempt.challenge;
    final result = attempt.result!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', result.token);
    _token = result.token;
    user = result.user;
    isAuthenticated = true;
    notifyListeners();
    return null;
  }

  Future<TwoFactorChallenge?> verifyTwoFactor(
    String email,
    String password,
    String code,
    String challengeToken,
  ) async {
    final attempt = await ApiService.login(
      email,
      password,
      twoFactorCode: code,
      challengeToken: challengeToken,
    );
    if (attempt.requiresTwoFactor) return attempt.challenge;
    final result = attempt.result!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', result.token);
    _token = result.token;
    user = result.user;
    isAuthenticated = true;
    notifyListeners();
    return null;
  }

  Future<TwoFactorChallenge> resendTwoFactor(
    String email,
    String password,
    String challengeToken,
  ) async {
    final attempt = await ApiService.login(
      email,
      password,
      challengeToken: challengeToken,
      resend: true,
    );
    if (attempt.challenge == null) {
      throw Exception('Could not resend the verification code.');
    }
    return attempt.challenge!;
  }

  Future<List<CustomerService>> getServices() async {
    final currentToken = _token;
    if (currentToken == null || currentToken.isEmpty) {
      throw Exception('You are not signed in.');
    }
    return ApiService.getServices(currentToken);
  }

  Future<List<Invoice>> getInvoices() async {
    final currentToken = _token;
    if (currentToken == null || currentToken.isEmpty) {
      throw Exception('You are not signed in.');
    }
    return ApiService.getInvoices(currentToken);
  }


  Future<InvoiceDetail> getInvoice(int invoiceId) async {
    final currentToken = token;
    if (currentToken == null) throw Exception('Not signed in');
    return ApiService.getInvoice(currentToken, invoiceId);
  }

  Future<List<SupportTicket>> getTickets() async {
    final currentToken = _token;
    if (currentToken == null || currentToken.isEmpty) {
      throw Exception('You are not signed in.');
    }
    return ApiService.getTickets(currentToken);
  }

  Future<TicketDetail> getTicket(int ticketId) async {
    final currentToken = _token;
    if (currentToken == null || currentToken.isEmpty) {
      throw Exception('You are not signed in.');
    }
    return ApiService.getTicket(currentToken, ticketId);
  }

  Future<SupportTicket> createTicket({
    required String subject,
    required String message,
  }) async {
    final currentToken = _token;
    if (currentToken == null || currentToken.isEmpty) {
      throw Exception('You are not signed in.');
    }
    return ApiService.createTicket(
      currentToken,
      subject: subject,
      message: message,
    );
  }

  Future<void> sendPowerAction(int serviceId, String action) async {
    final currentToken = _token;
    if (currentToken == null || currentToken.isEmpty) {
      throw Exception('You are not signed in.');
    }
    await ApiService.sendPowerAction(currentToken, serviceId, action);
  }

  Future<ServerResources> getServerResources(int serviceId) async {
    final currentToken = _token;
    if (currentToken == null || currentToken.isEmpty) {
      throw Exception('You are not signed in.');
    }
    return ApiService.getServerResources(currentToken, serviceId);
  }

  Future<ConsoleCredentials> getConsoleCredentials(int serviceId) async {
    final currentToken = _token;
    if (currentToken == null || currentToken.isEmpty) {
      throw Exception('You are not signed in.');
    }
    return ApiService.getConsoleCredentials(currentToken, serviceId);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    user = null;
    isAuthenticated = false;
    notifyListeners();
  }
}
