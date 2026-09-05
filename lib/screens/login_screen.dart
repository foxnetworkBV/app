import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final SessionService session;
  const LoginScreen({super.key, required this.session});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _twoFactorController = TextEditingController();
  bool loading = false;
  String? error;
  TwoFactorChallenge? twoFactorChallenge;

  Future<void> _signIn() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final challenge = await widget.session.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted && challenge != null) {
        setState(() {
          loading = false;
          twoFactorChallenge = challenge;
        });
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          loading = false;
          error = exception.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _verifyTwoFactor() async {
    final challenge = twoFactorChallenge;
    if (challenge == null) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final nextChallenge = await widget.session.verifyTwoFactor(
        _emailController.text.trim(),
        _passwordController.text,
        _twoFactorController.text.trim(),
        challenge.token,
      );
      if (mounted && nextChallenge != null) {
        setState(() {
          loading = false;
          twoFactorChallenge = nextChallenge;
        });
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          loading = false;
          error = exception.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _resendTwoFactor() async {
    final challenge = twoFactorChallenge;
    if (challenge == null) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final nextChallenge = await widget.session.resendTwoFactor(
        _emailController.text.trim(),
        _passwordController.text,
        challenge.token,
      );
      if (mounted) {
        setState(() {
          loading = false;
          twoFactorChallenge = nextChallenge;
        });
      }
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
    _twoFactorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = theme.textTheme.bodyMedium?.color ?? FoxColors.muted;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: theme.scaffoldBackgroundColor)),
          Positioned(top: -110, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(color: FoxColors.orange.withValues(alpha: isDark ? .16 : .09), shape: BoxShape.circle))),
          Positioned(bottom: -150, left: -120, child: Container(width: 360, height: 360, decoration: BoxDecoration(color: (isDark ? FoxColors.blue : FoxColors.navy).withValues(alpha: isDark ? .10 : .05), shape: BoxShape.circle))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      Image.asset('assets/foxnetwork_logo.png', width: 118, height: 118),
                      const SizedBox(height: 20),
                      Text('Welcome to FoxNetwork', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -.7)),
                      const SizedBox(height: 9),
                      Text('Sign in with your FoxNetwork account to manage hosting, invoices and support.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.5)),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: scheme.outlineVariant), boxShadow: isDark ? const [] : const [BoxShadow(color: Color(0x120F1A30), blurRadius: 30, offset: Offset(0, 14))]),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(width: 44, height: 44, decoration: BoxDecoration(color: FoxColors.orange.withValues(alpha: .1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.shield_outlined, color: FoxColors.orange)),
                                const SizedBox(width: 13),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Secure customer login', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text('Powered by your FoxNetwork account', style: theme.textTheme.bodySmall?.copyWith(fontSize: 12))]))
                              ],
                            ),
                            if (error != null) ...[
                              const SizedBox(height: 18),
                              Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(13)), child: Text(error!, style: TextStyle(color: Colors.red.shade800), textAlign: TextAlign.center)),
                            ],
                            const SizedBox(height: 22),
                            if (twoFactorChallenge == null) ...[
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
                            ] else ...[
                              Text(
                                'Two-factor authentication',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _twoFactorHint(twoFactorChallenge!),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _twoFactorController,
                                autofocus: true,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(labelText: 'Verification or recovery code'),
                                onSubmitted: (_) => _verifyTwoFactor(),
                              ),
                              if (twoFactorChallenge!.method == 'sms' || twoFactorChallenge!.method == 'whatsapp')
                                TextButton(onPressed: loading ? null : _resendTwoFactor, child: const Text('Resend code')),
                              TextButton(
                                onPressed: loading
                                    ? null
                                    : () => setState(() {
                                          twoFactorChallenge = null;
                                          _twoFactorController.clear();
                                          error = null;
                                        }),
                                child: const Text('Use a different account'),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: DecoratedBox(
                                decoration: BoxDecoration(gradient: FoxColors.primaryGradient, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color(0x40EA5411), blurRadius: 18, offset: Offset(0, 8))]),
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                                  onPressed: loading
                                      ? null
                                      : (twoFactorChallenge == null ? _signIn : _verifyTwoFactor),
                                  icon: loading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.login_rounded),
                                  label: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(loading
                                        ? 'Signing in…'
                                        : twoFactorChallenge == null
                                            ? 'Sign in'
                                            : 'Verify code'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock_outline_rounded, size: 15, color: mutedColor), const SizedBox(width: 6), Text('Your password is never stored in this app', style: TextStyle(fontSize: 12, color: mutedColor))]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _twoFactorHint(TwoFactorChallenge challenge) {
    switch (challenge.method) {
      case 'sms':
        return 'Enter the code sent to your phone, or use a recovery code.';
      case 'whatsapp':
        return 'Enter the code sent through WhatsApp, or use a recovery code.';
      default:
        return 'Enter the code from your authenticator app, or use a recovery code.';
    }
  }
}
