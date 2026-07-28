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

  Future<PaymenterAuthorization> beginPaymenterLogin() {
    return ApiService.createPaymenterAuthorization();
  }

  Future<bool> pollPaymenterLogin(String state) async {
    final result = await ApiService.getPaymenterLoginStatus(state);

    if (result.status == 'pending') return false;

    if (result.status == 'complete' &&
        result.token != null &&
        result.token!.isNotEmpty &&
        result.user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', result.token!);
      _token = result.token;
      user = result.user;
      isAuthenticated = true;
      notifyListeners();
      return true;
    }

    throw Exception(
      result.message ??
          (result.status == 'expired'
              ? 'The login request expired. Please try again.'
              : 'Paymenter login failed.'),
    );
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


  Future<List<SupportTicket>> getTickets() async {
    final currentToken = _token;
    if (currentToken == null || currentToken.isEmpty) {
      throw Exception('You are not signed in.');
    }
    return ApiService.getTickets(currentToken);
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    user = null;
    isAuthenticated = false;
    notifyListeners();
  }
}
