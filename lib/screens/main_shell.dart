import 'package:flutter/material.dart';
import '../services/session_service.dart';
import 'account_screen.dart';
import 'billing_screen.dart';
import 'dashboard_screen.dart';
import 'services_screen.dart';
import 'support_screen.dart';

class MainShell extends StatefulWidget {
  final SessionService session;

  const MainShell({
    super.key,
    required this.session,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(session: widget.session),
      ServicesScreen(session: widget.session),
      BillingScreen(session: widget.session),
      const SupportScreen(),
      AccountScreen(session: widget.session),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.dns_rounded), label: 'Services'),
          NavigationDestination(icon: Icon(Icons.credit_card_rounded), label: 'Billing'),
          NavigationDestination(icon: Icon(Icons.support_agent_rounded), label: 'Support'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Account'),
        ],
      ),
    );
  }
}
