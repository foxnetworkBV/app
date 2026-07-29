import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/session_service.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';
import 'invoice_detail_screen.dart';

class BillingScreen extends StatefulWidget {
  final SessionService session;
  const BillingScreen({super.key, required this.session});
  @override State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  late Future<List<Invoice>> _invoices;
  final _search = TextEditingController();
  String _status = 'All';

  @override void initState() { super.initState(); _invoices = widget.session.getInvoices(); }
  @override void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _reload() async {
    final future = widget.session.getInvoices();
    setState(() => _invoices = future);
    await future;
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing'), actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh')]),
      body: FutureBuilder<List<Invoice>>(
        future: _invoices,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _ErrorState(message: snapshot.error.toString(), retry: _reload);
          final all = snapshot.data ?? const <Invoice>[];
          final query = _search.text.trim().toLowerCase();
          final invoices = all.where((invoice) {
            final matchesSearch = query.isEmpty || invoice.number.toLowerCase().contains(query) || invoice.status.toLowerCase().contains(query);
            final matchesStatus = _status == 'All' || invoice.status.toLowerCase() == _status.toLowerCase();
            return matchesSearch && matchesStatus;
          }).toList();

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Search invoices', suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.clear))),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: ['All', 'Paid', 'Unpaid', 'Pending'].map((value) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(value), selected: _status == value, onSelected: (_) => setState(() => _status = value)),
                  )).toList()),
                ),
                const SizedBox(height: 18),
                if (invoices.isEmpty) const _EmptyState() else ...invoices.map((invoice) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context, rootNavigator: true).push<void>(MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: invoice, session: widget.session))),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Expanded(child: Text(invoice.number, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))), StatusBadge(invoice.status)]),
                          const SizedBox(height: 14),
                          Text(AppFormatters.money(invoice.amount, invoice.currency), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                          if (invoice.issuedAt.isNotEmpty) ...[const SizedBox(height: 7), Row(children: [const Icon(Icons.calendar_today_outlined, size: 16), const SizedBox(width: 7), Text('Issued ${AppFormatters.relativeDate(invoice.issuedAt)}')])],
                          const SizedBox(height: 8),
                          const Align(alignment: Alignment.centerRight, child: Icon(Icons.chevron_right_rounded)),
                        ]),
                      ),
                    ),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override Widget build(BuildContext context) => const Padding(padding: EdgeInsets.only(top: 100), child: Column(children: [Icon(Icons.receipt_long_outlined, size: 58), SizedBox(height: 14), Text('No matching invoices found.') ]));
}
class _ErrorState extends StatelessWidget {
  final String message; final Future<void> Function() retry;
  const _ErrorState({required this.message, required this.retry});
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline_rounded, size: 52), const SizedBox(height: 12), Text(message.replaceFirst('Exception: ', ''), textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Try again'))])));
}
