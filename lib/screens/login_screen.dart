import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class LoginScreen extends StatefulWidget {
  final SessionService session;
  const LoginScreen({super.key, required this.session});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool loading = false;
  String? error;
  Future<void> _signIn() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.session.signIn();
    } on FlutterAppAuthUserCancelledException {
      // Closing the browser is a normal cancellation.
    } on ApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (_) {
      if (mounted) {
        setState(
            () => error = 'Sign-in could not be completed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openPortal() async {
    try {
      if (await launchUrl(Uri.parse(ApiConfig.customerPortalUrl),
          mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {/* Show a readable launch error. */}
    if (mounted) setState(() => error = 'Could not open the customer portal.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(children: [
            Image.asset('assets/foxnetwork_logo.png', width: 118, height: 118),
            const SizedBox(height: 24),
            Text('Welcome to FoxNetwork',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text(
                'Sign in with your Paymenter account to manage your hosting, invoices and support.',
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 36),
                          const SizedBox(height: 16),
                          const Text(
                              'Continue securely on client.foxnetwork.be, then return to the app.',
                              textAlign: TextAlign.center),
                          if (error != null ||
                              widget.session.restoreError != null) ...[
                            const SizedBox(height: 16),
                            Text(error ?? widget.session.restoreError!,
                                style:
                                    TextStyle(color: theme.colorScheme.error),
                                textAlign: TextAlign.center),
                          ],
                          const SizedBox(height: 20),
                          FilledButton.icon(
                              onPressed: loading ? null : _signIn,
                              icon: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.login_rounded),
                              label: Text(loading
                                  ? 'Signing in…'
                                  : 'Sign in with Paymenter')),
                          if (widget.session.restoreError != null)
                            TextButton(
                                onPressed: loading
                                    ? null
                                    : widget.session.restoreSession,
                                child: const Text('Retry saved session')),
                        ]))),
            const SizedBox(height: 12),
            TextButton(
                onPressed: loading ? null : _openPortal,
                child: const Text('Open customer portal')),
          ])),
    ))));
  }
}
