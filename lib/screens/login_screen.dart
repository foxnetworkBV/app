import 'package:flutter/material.dart';
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
                              child: DecoratedBox(
                                decoration: BoxDecoration(gradient: FoxColors.primaryGradient, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color(0x40EA5411), blurRadius: 18, offset: Offset(0, 8))]),
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                                  onPressed: loading ? null : _signIn,
                                  icon: loading
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.login_rounded),
                                  label: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(loading ? 'Signing in…' : 'Sign in')),
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
}
