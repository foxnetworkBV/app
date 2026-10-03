import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';
import 'paymenter_auth_service.dart';

class SessionService extends ChangeNotifier {
  final PaymenterAuthService _auth;
  PaymenterCredentials? _credentials;
  Future<void>? _refreshing;
  int _generation = 0;
  User? user;
  bool isAuthenticated = false;
  bool isLoading = true;
  String? restoreError;

  SessionService({PaymenterAuthService? auth, bool restore = true})
      : _auth = auth ?? PaymenterAuthService() {
    if (restore) {
      restoreSession();
    } else {
      isLoading = false;
    }
  }

  Future<void> restoreSession() async {
    isLoading = true;
    restoreError = null;
    notifyListeners();
    try {
      // Never send a token from the retired backend to Paymenter.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      _credentials = await _auth.read();
      if (_credentials != null) {
        user = await _withToken(ApiService.getCurrentUser);
        isAuthenticated = true;
      }
    } catch (_) {
      restoreError = 'Could not restore your session. Retry or sign in again.';
      isAuthenticated = false;
      user = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn() async {
    final credentials = await _auth.signIn();
    final profile = await ApiService.getCurrentUser(credentials.accessToken);
    await _auth.save(credentials);
    _credentials = credentials;
    user = profile;
    isAuthenticated = true;
    restoreError = null;
    notifyListeners();
  }

  Future<void> _refresh() async {
    final generation = _generation;
    final credentials = _credentials;
    if (credentials == null) {
      throw const ApiException('Please sign in again.', 401);
    }
    final refreshed = await _auth.refresh(credentials);
    if (generation != _generation) {
      throw const ApiException('You have signed out.', 401);
    }
    await _auth.save(refreshed);
    _credentials = refreshed;
  }

  Future<T> _withToken<T>(Future<T> Function(String) operation) async {
    try {
      final credentials = _credentials;
      if (credentials == null) {
        throw const ApiException('Please sign in again.', 401);
      }
      if (!credentials.expiresAt
          .isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
        final refresh = _refreshing ??= _refresh();
        try {
          await refresh;
        } finally {
          if (identical(_refreshing, refresh)) _refreshing = null;
        }
      }
      final current = _credentials;
      if (current == null) {
        throw const ApiException('Please sign in again.', 401);
      }
      return await operation(current.accessToken);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _auth.clear();
        _credentials = null;
        user = null;
        isAuthenticated = false;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<List<CustomerService>> getServices() =>
      _withToken(ApiService.getServices);
  Future<List<Invoice>> getInvoices() => _withToken(ApiService.getInvoices);
  Future<InvoiceDetail> getInvoice(int id) =>
      _withToken((token) => ApiService.getInvoice(token, id));
  Future<List<SupportTicket>> getTickets() => _withToken(ApiService.getTickets);
  Future<TicketDetail> getTicket(int id) =>
      _withToken((token) => ApiService.getTicket(token, id));
  Future<SupportTicket> createTicket(
          {required String subject, required String message}) =>
      _withToken((token) =>
          ApiService.createTicket(token, subject: subject, message: message));
  Future<void> sendPowerAction(int id, String action) =>
      _withToken((token) => ApiService.sendPowerAction(token, id, action));
  Future<ServerResources> getServerResources(int id) =>
      _withToken((token) => ApiService.getServerResources(token, id));
  Future<ConsoleCredentials> getConsoleCredentials(int id) =>
      _withToken((token) => ApiService.getConsoleCredentials(token, id));

  Future<void> logout() async {
    // Wait for token rotation before revoking the resulting token pair.
    try {
      await _refreshing;
    } catch (_) {/* Continue with local sign-out. */}
    final current = _credentials;
    _generation++;
    _credentials = null;
    user = null;
    isAuthenticated = false;
    restoreError = null;
    await _auth.clear();
    notifyListeners();
    if (current != null) {
      try {
        await ApiService.logout(current.accessToken);
      } catch (_) {
        /* Offline sign-out still removes credentials from this device. */
      }
    }
  }
}
