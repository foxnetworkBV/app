import 'package:flutter/material.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _signIn() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await widget.session.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (exception) {
      if (mounted) {
        setState(() {
          loading = false;
          error = exception.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                            color: FoxColors.cyan.withValues(alpha: 0.16),
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
                      'Sign in with your FoxNetwork account to manage hosting, invoices and support.',
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
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email address'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      onSubmitted: (_) => _signIn(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: loading ? null : _signIn,
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
                                    Text('Signing in…'),
                                  ],
                                )
                              : const Text('Sign in'),
                        ),
                      ),
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
