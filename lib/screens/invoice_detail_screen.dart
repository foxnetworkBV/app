import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/session_service.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;
  final SessionService session;

  const InvoiceDetailScreen({super.key, required this.invoice, required this.session});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  InvoiceDetail? _detail;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _detail = InvoiceDetail.fromInvoice(widget.invoice);
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final value = await widget.session.getInvoice(widget.invoice.id);
      if (mounted) setState(() => _detail = value);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(label)),
      const SizedBox(width: 16),
      Expanded(child: SelectableText(value.trim().isEmpty ? '—' : value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
    ]),
  );

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open this link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _detail ?? InvoiceDetail.fromInvoice(widget.invoice);
    return Scaffold(
      appBar: AppBar(title: Text(invoice.number), actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded))]),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_loading) const SizedBox(height: 12),
            Text(invoice.number, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              StatusBadge(invoice.status),
              Chip(label: Text(AppFormatters.money(invoice.total, invoice.currency))),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Some live information could not be loaded', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(_error.toString().replaceFirst('Exception: ', '')),
                const SizedBox(height: 8),
                FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
              ]))),
            ],
            const SizedBox(height: 16),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              _row('Invoice ID', '#${invoice.id}'),
              _row('Invoice number', invoice.number),
              _row('Status', invoice.status),
              _row('Total', AppFormatters.money(invoice.total, invoice.currency)),
              _row('Issued At', AppFormatters.dateTime(invoice.issuedAt)),
              _row('Due At', AppFormatters.dateTime(invoice.dueAt)),
              _row('Paid At', AppFormatters.dateTime(invoice.paidAt)),
              _row('Updated At', AppFormatters.dateTime(invoice.updatedAt)),
            ]))),
            const SizedBox(height: 18),
            Text('Invoice items', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (invoice.items.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No invoice items were returned. The invoice total and general information are still shown above.')))
            else
              ...invoice.items.map((item) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _row('Quantity', item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)),
                _row('Unit price', AppFormatters.money(item.price, item.currency)),
                _row('Line total', AppFormatters.money(item.total, item.currency)),
              ])))),
            if (invoice.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Notes', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: SelectableText(invoice.notes))),
            ],
            if (invoice.webUrl.isNotEmpty || invoice.pdfUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(spacing: 10, runSpacing: 10, children: [
                if (invoice.webUrl.isNotEmpty) FilledButton.icon(onPressed: () => _openUrl(invoice.webUrl), icon: const Icon(Icons.open_in_browser), label: const Text('Open invoice')),
                if (invoice.pdfUrl.isNotEmpty) OutlinedButton.icon(onPressed: () => _openUrl(invoice.pdfUrl), icon: const Icon(Icons.picture_as_pdf), label: const Text('Open PDF')),
              ]),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
