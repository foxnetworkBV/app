import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/session_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;
  final SessionService session;

  const InvoiceDetailScreen({
    super.key,
    required this.invoice,
    required this.session,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late Future<InvoiceDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.session.getInvoice(widget.invoice.id);
  }

  Future<void> _reload() async {
    final future = widget.session.getInvoice(widget.invoice.id);
    setState(() => _detail = future);
    await future;
  }

  String _date(String value) {
    if (value.isEmpty) return '—';
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return value;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} '
        '${two(parsed.hour)}:${two(parsed.minute)}';
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
        title: Text(widget.invoice.number),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<InvoiceDetail>(
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
                    const Icon(Icons.receipt_long_outlined, size: 52),
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

          final invoice = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  invoice.number,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(invoice.status)),
                    Chip(
                      label: Text(
                        '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _row('Invoice ID', '#${invoice.id}'),
                        _row('Status', invoice.status),
                        _row('Issued At', _date(invoice.issuedAt)),
                        _row('Due At', _date(invoice.dueAt)),
                        if (invoice.paidAt.isNotEmpty)
                          _row('Paid At', _date(invoice.paidAt)),
                        _row('Updated At', _date(invoice.updatedAt)),
                        _row('Currency', invoice.currency),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Invoice items', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (invoice.items.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('No invoice items were returned by Paymenter.'),
                    ),
                  )
                else
                  ...invoice.items.map(
                    (item) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            _row('Quantity', item.quantity.toString()),
                            _row('Unit price', '${item.currency} ${item.price.toStringAsFixed(2)}'),
                            _row('Line total', '${item.currency} ${item.total.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: _row(
                      'Total',
                      '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                    ),
                  ),
                ),
                if (invoice.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Notes', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(invoice.notes),
                    ),
                  ),
                ],
                if (invoice.pdfUrl.isNotEmpty || invoice.webUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Links', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (invoice.webUrl.isNotEmpty) ...[
                            const Text('Paymenter invoice', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            SelectableText(invoice.webUrl),
                          ],
                          if (invoice.pdfUrl.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            const Text('PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            SelectableText(invoice.pdfUrl),
                          ],
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
