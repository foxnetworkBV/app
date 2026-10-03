import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../models/models.dart';
import '../services/session_service.dart';
import '../widgets/service_card.dart';
import 'service_detail_screen.dart';

class ServicesScreen extends StatefulWidget {
  final SessionService session;

  const ServicesScreen({
    super.key,
    required this.session,
  });

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> with WidgetsBindingObserver {
  late Future<List<CustomerService>> _services;
  String? _category;
  bool _returningFromStore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _services = widget.session.getServices();
  }

  Future<void> _reload() async {
    final future = widget.session.getServices();
    setState(() => _services = future);
    try {
      await future;
    } catch (_) {
      // The FutureBuilder displays the request error and a retry button.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _returningFromStore) {
      _returningFromStore = false;
      _reload();
    }
  }

  Future<void> _addService() async {
    _returningFromStore = true;
    try {
      if (await launchUrl(Uri.parse(ApiConfig.customerPortalUrl), mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Show the same error for unsupported platforms and failed launches.
    }
    _returningFromStore = false;
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the customer portal.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: FilledButton.icon(
            onPressed: _addService,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Order a new service'),
          ),
        ),
      ),
      body: FutureBuilder<List<CustomerService>>(
        future: _services,
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

          final services = snapshot.data ?? const <CustomerService>[];
          if (services.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Icon(Icons.dns_outlined, size: 56),
                  SizedBox(height: 14),
                  Center(child: Text('No services found yet.')),
                ],
              ),
            );
          }

          final categories = services.map((service) => service.category).toSet().toList()..sort();
          final selected = categories.contains(_category) ? _category : null;
          final visible = selected == null ? services : services.where((service) => service.category == selected).toList();
          return Column(children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: Row(children: [
                ChoiceChip(label: Text('All (${services.length})'), selected: selected == null, onSelected: (_) => setState(() => _category = null)),
                for (final category in categories) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('$category (${services.where((service) => service.category == category).length})'),
                    selected: selected == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
                ],
              ]),
            ),
            Expanded(child: RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final service = visible[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailScreen(service: service, session: widget.session),
                      ),
                    );
                  },
                  child: ServiceCard(service: service),
                );
              },
            ),
          )),
          ]);
        },
      ),
    );
  }
}
