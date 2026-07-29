import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/session_service.dart';
import '../widgets/service_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  final SessionService session;
  const DashboardScreen({super.key, required this.session});
  @override State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<CustomerService>> _services;
  @override void initState() { super.initState(); _services = widget.session.getServices(); }
  Future<void> _reload() async { final next = widget.session.getServices(); setState(() => _services = next); await next; }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FoxNetwork'), actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh')]),
      body: FutureBuilder<List<CustomerService>>(
        future: _services,
        builder: (context, snapshot) {
          final services = snapshot.data ?? const <CustomerService>[];
          final active = services.where((s) => ['active', 'online'].contains(s.status.toLowerCase())).length;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(18), children: [
              Text('Welcome back,', style: Theme.of(context).textTheme.bodyLarge),
              Text(widget.session.user?.name ?? 'Customer', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Everything you need, in one place.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: StatCard(title: 'Services', value: snapshot.connectionState == ConnectionState.waiting ? '…' : services.length.toString(), icon: Icons.dns_rounded)),
                const SizedBox(width: 12),
                Expanded(child: StatCard(title: 'Active', value: snapshot.connectionState == ConnectionState.waiting ? '…' : active.toString(), icon: Icons.check_circle_rounded)),
              ]),
              const SizedBox(height: 24),
              Row(children: [Expanded(child: Text('Your services', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))), if (services.length > 3) Text('${services.length} total')]),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
              else if (snapshot.hasError)
                Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [const Icon(Icons.cloud_off_rounded, size: 42), const SizedBox(height: 10), Text(snapshot.error.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Try again'))])))
              else if (services.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(24), child: Column(children: [Icon(Icons.dns_outlined, size: 46), SizedBox(height: 10), Text('No services found.') ])))
              else
                ...services.take(3).map((service) => Padding(padding: const EdgeInsets.only(bottom: 12), child: ServiceCard(service: service))),
              const SizedBox(height: 16),
            ]),
          );
        },
      ),
    );
  }
}
