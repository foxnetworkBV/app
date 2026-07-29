import 'package:flutter/material.dart';
import '../services/session_service.dart';

class AccountScreen extends StatelessWidget {
  final SessionService session;

  const AccountScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 34),
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
