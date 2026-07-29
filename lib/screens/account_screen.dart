import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/session_service.dart';

class AccountScreen extends StatelessWidget {
  final SessionService session;
  const AccountScreen({super.key, required this.session});

  Future<void> _open(BuildContext context, String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open this link.')));
    }
  }

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied.')));
  }

  Widget _linkTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required String url}) {
    return ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.open_in_new_rounded), onTap: () => _open(context, url));
  }

  @override Widget build(BuildContext context) {
    final name = session.user?.name ?? 'Customer';
    final email = session.user?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
          CircleAvatar(radius: 32, child: Text(name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(), style: Theme.of(context).textTheme.headlineMedium)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            if (email.isNotEmpty) ...[const SizedBox(height: 5), InkWell(onTap: () => _open(context, 'mailto:$email'), onLongPress: () => _copy(context, email, 'Email'), child: Text(email, style: TextStyle(color: Theme.of(context).colorScheme.primary)))],
            const SizedBox(height: 8),
            const Row(children: [Icon(Icons.verified_rounded, size: 17), SizedBox(width: 6), Text('FoxNetwork customer')]),
          ])),
        ]))),
        const SizedBox(height: 16),
        Text('FoxNetwork', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Card(clipBehavior: Clip.antiAlias, child: Column(children: [
          _linkTile(context, icon: Icons.language_rounded, title: 'Customer portal', subtitle: 'Manage orders, invoices and profile', url: 'https://billing.foxnetwork.be'),
          const Divider(height: 1),
          _linkTile(context, icon: Icons.dns_rounded, title: 'Service panel', subtitle: 'Manage game and hosting services', url: 'https://panel.foxnetwork.be'),
          const Divider(height: 1),
          _linkTile(context, icon: Icons.monitor_heart_rounded, title: 'System status', subtitle: 'Check incidents and maintenance', url: 'https://status.foxnetwork.be'),
          const Divider(height: 1),
          _linkTile(context, icon: Icons.public_rounded, title: 'FoxNetwork website', subtitle: 'foxnetwork.be', url: 'https://foxnetwork.be'),
        ])),
        const SizedBox(height: 16),
        Text('Help & legal', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Card(clipBehavior: Clip.antiAlias, child: Column(children: [
          _linkTile(context, icon: Icons.support_agent_rounded, title: 'Contact support', subtitle: 'Open the support portal', url: 'https://billing.foxnetwork.be/tickets'),
          const Divider(height: 1),
          _linkTile(context, icon: Icons.mail_outline_rounded, title: 'Email support', subtitle: 'support@foxnetwork.be', url: 'mailto:support@foxnetwork.be'),
          const Divider(height: 1),
          _linkTile(context, icon: Icons.gavel_rounded, title: 'Terms and conditions', subtitle: 'View online', url: 'https://foxnetwork.be/terms'),
          const Divider(height: 1),
          _linkTile(context, icon: Icons.privacy_tip_outlined, title: 'Privacy policy', subtitle: 'View online', url: 'https://foxnetwork.be/privacy'),
        ])),
        const SizedBox(height: 18),
        OutlinedButton.icon(onPressed: session.logout, icon: const Icon(Icons.logout), label: const Text('Sign out')),
        const SizedBox(height: 8),
        const Center(child: Text('FoxNetwork app • Version 1.2.0 (24)', style: TextStyle(fontSize: 12))),
      ]),
    );
  }
}
