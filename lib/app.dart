import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';

class FoxNetworkApp extends StatefulWidget {
  const FoxNetworkApp({super.key});

  @override
  State<FoxNetworkApp> createState() => _FoxNetworkAppState();
}

class _FoxNetworkAppState extends State<FoxNetworkApp> {
  final SessionService session = SessionService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoxNetwork',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: AnimatedBuilder(
        animation: session,
        builder: (context, _) {
          if (session.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (session.isAuthenticated) {
            return MainShell(session: session);
          }

          return LoginScreen(session: session);
        },
      ),
    );
  }
}
