import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/session_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final SupportTicket ticket;
  final SessionService session;
  const TicketDetailScreen({super.key, required this.ticket, required this.session});
  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  TicketDetail? _detail;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _detail = TicketDetail.fromTicket(widget.ticket);
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final value = await widget.session.getTicket(widget.ticket.id);
      if (mounted) setState(() => _detail = value);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _date(String value) {
    if (value.trim().isEmpty) return '—';
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return value;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} ${two(parsed.hour)}:${two(parsed.minute)}';
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(label)), const SizedBox(width: 16),
      Expanded(child: SelectableText(value.trim().isEmpty ? '—' : value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
    ]),
  );

  Future<void> _openWeb(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open this ticket.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail ?? TicketDetail.fromTicket(widget.ticket);
    return Scaffold(
      appBar: AppBar(title: Text('Ticket #${detail.id.abs()}'), actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded))]),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_loading) const SizedBox(height: 12),
            Text(detail.subject, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [Chip(label: Text(detail.status)), if (detail.priority.isNotEmpty) Chip(label: Text(detail.priority))]),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('The ticket opened, but live details could not be loaded', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6), Text(_error.toString().replaceFirst('Exception: ', '')),
                const SizedBox(height: 8), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
              ]))),
            ],
            const SizedBox(height: 16),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              _row('Ticket ID', '#${detail.id.abs()}'), _row('Subject', detail.subject), _row('Status', detail.status),
              _row('Priority', detail.priority), _row('Department', detail.department), _row('Created At', _date(detail.createdAt)),
              _row('Updated At', _date(detail.updatedAt)), if (detail.closedAt.isNotEmpty) _row('Closed At', _date(detail.closedAt)),
            ]))),
            const SizedBox(height: 18),
            Text('Conversation', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (detail.messages.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No messages were returned yet. Pull down or press Retry to refresh.')))
            else
              ...detail.messages.map((message) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Align(
                alignment: message.isStaff ? Alignment.centerLeft : Alignment.centerRight,
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 580), child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(message.author, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
                  SelectableText(message.message), if (message.createdAt.isNotEmpty) ...[const SizedBox(height: 10), Text(_date(message.createdAt), style: Theme.of(context).textTheme.bodySmall)],
                ])))),
              ))),
            if (detail.webUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              FilledButton.icon(onPressed: () => _openWeb(detail.webUrl), icon: const Icon(Icons.open_in_browser), label: const Text('Open in customer portal')),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
