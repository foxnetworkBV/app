import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/session_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final SupportTicket ticket;
  final SessionService session;

  const TicketDetailScreen({
    super.key,
    required this.ticket,
    required this.session,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late Future<TicketDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.session.getTicket(widget.ticket.id);
  }

  Future<void> _reload() async {
    final future = widget.session.getTicket(widget.ticket.id);
    setState(() => _detail = future);
    await future;
  }

  String _date(String raw) {
    if (raw.isEmpty) return '—';
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return raw;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label)),
            const SizedBox(width: 18),
            Expanded(
              child: SelectableText(
                value.isEmpty ? '—' : value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${widget.ticket.id.abs()}'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<TicketDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 52),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final detail = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  detail.subject,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(detail.status)),
                    if (detail.priority.isNotEmpty)
                      Chip(label: Text(detail.priority)),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _row('Ticket ID', '#${detail.id.abs()}'),
                        _row('Status', detail.status),
                        _row('Priority', detail.priority),
                        _row('Department', detail.department),
                        _row('Created At', _date(detail.createdAt)),
                        _row('Updated At', _date(detail.updatedAt)),
                        if (detail.closedAt.isNotEmpty)
                          _row('Closed At', _date(detail.closedAt)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Conversation', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (detail.messages.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No messages were returned by Paymenter.'),
                    ),
                  )
                else
                  ...detail.messages.map(
                    (message) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: message.isStaff
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.author,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(message.message),
                                  if (message.createdAt.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      _date(message.createdAt),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (detail.webUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Paymenter ticket', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          SelectableText(detail.webUrl),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
