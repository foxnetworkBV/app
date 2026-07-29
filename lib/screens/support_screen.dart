import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/session_service.dart';
import 'ticket_detail_screen.dart';

class SupportScreen extends StatefulWidget {
  final SessionService session;

  const SupportScreen({super.key, required this.session});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late Future<List<SupportTicket>> _tickets;

  @override
  void initState() {
    super.initState();
    _tickets = widget.session.getTickets();
  }

  Future<void> _reload() async {
    final future = widget.session.getTickets();
    setState(() => _tickets = future);
    await future;
  }

  Future<void> _showNewTicket() async {
    final subject = TextEditingController();
    final message = TextEditingController();
    var sending = false;
    String? error;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('New support ticket', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: subject,
                maxLength: 190,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: message,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: sending
                      ? null
                      : () async {
                          if (subject.text.trim().isEmpty || message.text.trim().isEmpty) {
                            setSheetState(() => error = 'Enter a subject and message.');
                            return;
                          }
                          setSheetState(() { sending = true; error = null; });
                          try {
                            await widget.session.createTicket(
                              subject: subject.text.trim(),
                              message: message.text.trim(),
                            );
                            if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                          } catch (e) {
                            setSheetState(() {
                              sending = false;
                              error = e.toString().replaceFirst('Exception: ', '');
                            });
                          }
                        },
                  icon: sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: Text(sending ? 'Sending…' : 'Send ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    subject.dispose();
    message.dispose();
    if (created == true) {
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support ticket created.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded)),
          IconButton(onPressed: _showNewTicket, icon: const Icon(Icons.add_rounded)),
        ],
      ),
      body: FutureBuilder<List<SupportTicket>>(
        future: _tickets,
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
                    const Icon(Icons.support_agent_rounded, size: 52),
                    const SizedBox(height: 12),
                    Text(snapshot.error.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Try again')),
                  ],
                ),
              ),
            );
          }
          final tickets = snapshot.data ?? const <SupportTicket>[];
          if (tickets.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  const Icon(Icons.support_agent_rounded, size: 58),
                  const SizedBox(height: 14),
                  const Center(child: Text('No support tickets yet.')),
                  const SizedBox(height: 16),
                  Center(child: FilledButton.icon(onPressed: _showNewTicket, icon: const Icon(Icons.add), label: const Text('Create ticket'))),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return Card(
                  child: ListTile(
                    onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
                      MaterialPageRoute(
                        builder: (_) => TicketDetailScreen(
                          ticket: ticket,
                          session: widget.session,
                        ),
                      ),
                    ),
                    leading: const Icon(Icons.confirmation_number_outlined),
                    title: Text(ticket.subject),
                    subtitle: ticket.updatedAt.isEmpty ? null : Text('Updated ${ticket.updatedAt}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ticket.status),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewTicket,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
