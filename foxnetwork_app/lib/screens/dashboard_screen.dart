import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/session_service.dart';
import '../widgets/service_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  final SessionService session;

  const DashboardScreen({
    super.key,
    required this.session,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<CustomerService>> _services;

  @override
  void initState() {
    super.initState();
    _services = widget.session.getServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FoxNetwork')),
      body: FutureBuilder<List<CustomerService>>(
        future: _services,
        builder: (context, snapshot) {
          final services = snapshot.data ?? const <CustomerService>[];
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text('Welcome back,', style: Theme.of(context).textTheme.bodyLarge),
              Text(
                widget.session.user?.name ?? 'Customer',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Services',
                      value: snapshot.connectionState == ConnectionState.waiting
                          ? '…'
                          : services.length.toString(),
                      icon: Icons.dns_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: StatCard(
                      title: 'Account',
                      value: 'Active',
                      icon: Icons.verified_user_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Service status', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ))
              else if (snapshot.hasError)
                Text(snapshot.error.toString().replaceFirst('Exception: ', ''))
              else if (services.isEmpty)
                const Text('No Paymenter services found.')
              else
                ...services.take(3).map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ServiceCard(service: service),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
