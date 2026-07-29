import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/session_service.dart';

class AccountScreen extends StatelessWidget {
  final SessionService session;

  const AccountScreen({
    super.key,
    required this.session,
  });

  Future<void> _open(BuildContext context, String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link.')),
        );
      }
    }
  }

  Widget _linkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new_rounded),
      onTap: () => _open(context, url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = session.user?.email ?? '';

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.user?.name ?? 'Customer',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (email.isNotEmpty)
                          InkWell(
                            onTap: () => _open(context, 'mailto:$email'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                email,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _linkTile(
                  context,
                  icon: Icons.language,
                  title: 'Customer portal',
                  subtitle: 'billing.foxnetwork.be',
                  url: 'https://billing.foxnetwork.be',
                ),
                const Divider(height: 1),
                _linkTile(
                  context,
                  icon: Icons.dns,
                  title: 'Service panel',
                  subtitle: 'panel.foxnetwork.be',
                  url: 'https://panel.foxnetwork.be',
                ),
                const Divider(height: 1),
                _linkTile(
                  context,
                  icon: Icons.monitor_heart,
                  title: 'Status page',
                  subtitle: 'status.foxnetwork.be',
                  url: 'https://status.foxnetwork.be',
                ),
                const Divider(height: 1),
                _linkTile(
                  context,
                  icon: Icons.support_agent_rounded,
                  title: 'Support',
                  subtitle: 'Open the customer portal',
                  url: 'https://billing.foxnetwork.be',
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
