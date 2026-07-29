import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/foxnetwork_logo.dart';

class LoginScreen extends StatefulWidget {
  final SessionService session;

  const LoginScreen({
    super.key,
    required this.session,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool loading = false;
  bool _cancelPolling = false;
  String? error;

  Future<void> loginWithPaymenter() async {
    _cancelPolling = true;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final authorization = await widget.session.beginPaymenterLogin();

      final opened = await launchUrl(
        authorization.authorizationUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception('Could not open the Paymenter login page.');
      }

      _cancelPolling = false;
      await _waitForLogin(authorization.state);
    } catch (exception) {
      if (mounted) {
        setState(() {
          loading = false;
          error = exception.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _waitForLogin(String state) async {
    const maxAttempts = 100;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (_cancelPolling || !mounted) return;

      final complete = await widget.session.pollPaymenterLogin(state);
      if (complete) {
        if (mounted) {
          setState(() {
            loading = false;
            error = null;
          });
        }
        return;
      }

      await Future<void>.delayed(const Duration(seconds: 3));
    }

    throw Exception('The login request timed out. Please try again.');
  }

  @override
  void dispose() {
    _cancelPolling = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.15,
            colors: [Color(0x242ED4F4), FoxColors.navy900],
          ),
        ),
        child: SafeArea(
          child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    width: 118,
                    height: 118,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: FoxColors.navy800,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: FoxColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: FoxColors.cyan.withOpacity(0.16),
                          blurRadius: 34,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const FoxNetworkLogo(size: 74),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'FoxNetwork',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in securely with your existing Paymenter account.',
                    textAlign: TextAlign.center,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: loading ? null : loginWithPaymenter,
                      icon: const Icon(Icons.login_rounded),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: loading
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Waiting for authorization…'),
                                ],
                              )
                            : const Text('Sign in with FoxNetwork'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Authorize in Paymenter, then return to this tab. Login completes automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
