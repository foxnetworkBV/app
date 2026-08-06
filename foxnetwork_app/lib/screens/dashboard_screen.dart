import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/session_service.dart';
import '../widgets/service_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/foxnetwork_logo.dart';
import '../theme/app_theme.dart';

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
      appBar: AppBar(
        title: const FoxNetworkLogo(size: 30, showWordmark: true, compact: true),
      ),
      body: FutureBuilder<List<CustomerService>>(
        future: _services,
        builder: (context, snapshot) {
          final services = snapshot.data ?? const <CustomerService>[];
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: FoxColors.brandGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: FoxColors.cyan.withValues(alpha: 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: FoxColors.navy950.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const FoxNetworkLogo(size: 38),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back,',
                            style: TextStyle(color: FoxColors.navy950),
                          ),
                          Text(
                            widget.session.user?.name ?? 'Customer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: FoxColors.navy950,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                const Text('No services found yet.')
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
