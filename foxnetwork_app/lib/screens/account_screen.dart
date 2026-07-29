import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../widgets/foxnetwork_logo.dart';
import '../theme/app_theme.dart';

class AccountScreen extends StatelessWidget {
  final SessionService session;

  const AccountScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FoxNetworkLogo(size: 28, showWordmark: true, compact: true),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      gradient: FoxColors.brandGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const FoxNetworkLogo(size: 38),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.user?.name ?? 'Customer',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(session.user?.email ?? ''),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Customer portal'),
                  subtitle: Text('billing.foxnetwork.be'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.dns),
                  title: Text('Service panel'),
                  subtitle: Text('panel.foxnetwork.be'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.monitor_heart),
                  title: Text('Status page'),
                  subtitle: Text('status.foxnetwork.be'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: session.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
