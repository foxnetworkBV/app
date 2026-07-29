import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/session_service.dart';

class ServiceDetailScreen extends StatefulWidget {
  final CustomerService service;
  final SessionService session;

  const ServiceDetailScreen({
    super.key,
    required this.service,
    required this.session,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServerResources? resources;
  String? error;
  String? message;
  bool loadingResources = true;
  String? activeAction;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _loadResources();
    timer = Timer.periodic(const Duration(seconds: 10), (_) => _loadResources(silent: true));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadResources({bool silent = false}) async {
    if (!silent && mounted) setState(() => loadingResources = true);
    try {
      final value = await widget.session.getServerResources(widget.service.id);
      if (!mounted) return;
      setState(() {
        resources = value;
        error = null;
        loadingResources = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loadingResources = false;
      });
    }
  }

  Future<void> _power(String action) async {
    if (activeAction != null) return;

    if (action == 'stop' || action == 'kill') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${_title(action)} server?'),
          content: Text(
            action == 'kill'
                ? 'This immediately terminates the server process and may cause data loss.'
                : 'The server will be shut down.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_title(action)),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      activeAction = action;
      message = null;
      error = null;
    });
    try {
      await widget.session.sendPowerAction(widget.service.id, action);
      if (!mounted) return;
      setState(() => message = '${_title(action)} command sent successfully.');
      await Future<void>.delayed(const Duration(seconds: 2));
      await _loadResources(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => activeAction = null);
    }
  }

  String _title(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
  String _bytes(int bytes) {
    if (bytes >= 1073741824) return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
  String _uptime(int ms) {
    final duration = Duration(milliseconds: ms);
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    return days > 0 ? '${days}d ${hours}h ${minutes}m' : '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final state = resources?.state ?? service.status;
    final online = state.toLowerCase() == 'running' || state.toLowerCase() == 'online';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service'),
        actions: [IconButton(onPressed: () => _loadResources(), icon: const Icon(Icons.refresh_rounded))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(service.product),
          const SizedBox(height: 4),
          Text(service.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Icon(online ? Icons.check_circle : Icons.cancel, color: online ? Colors.green : Colors.orange),
            const SizedBox(width: 8),
            Text(_title(state)),
          ]),
          const SizedBox(height: 24),
          _InfoRow(label: 'Renewal', value: service.renewalDate.isEmpty ? 'No expiry' : service.renewalDate),
          const SizedBox(height: 10),
          _InfoRow(label: 'Price', value: 'EUR ${service.price.toStringAsFixed(2)}'),
          const SizedBox(height: 24),
          Text('Live resources', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (loadingResources && resources == null)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (resources != null) ...[
            _InfoRow(label: 'CPU', value: '${resources!.cpuAbsolute.toStringAsFixed(1)}%'),
            const SizedBox(height: 10),
            _InfoRow(label: 'Memory', value: _bytes(resources!.memoryBytes)),
            const SizedBox(height: 10),
            _InfoRow(label: 'Disk', value: _bytes(resources!.diskBytes)),
            const SizedBox(height: 10),
            _InfoRow(label: 'Network RX / TX', value: '${_bytes(resources!.networkRxBytes)} / ${_bytes(resources!.networkTxBytes)}'),
            const SizedBox(height: 10),
            _InfoRow(label: 'Uptime', value: _uptime(resources!.uptimeMs)),
          ],
          const SizedBox(height: 24),
          Text('Power controls', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PowerButton(action: 'start', icon: Icons.play_arrow, activeAction: activeAction, enabled: !online, onPressed: _power),
              _PowerButton(action: 'restart', icon: Icons.refresh, activeAction: activeAction, enabled: online, onPressed: _power),
              _PowerButton(action: 'stop', icon: Icons.stop, activeAction: activeAction, enabled: online, onPressed: _power),
              _PowerButton(action: 'kill', icon: Icons.power_settings_new, activeAction: activeAction, enabled: online, onPressed: _power),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

class _PowerButton extends StatelessWidget {
  final String action;
  final IconData icon;
  final String? activeAction;
  final bool enabled;
  final Future<void> Function(String) onPressed;
  const _PowerButton({required this.action, required this.icon, required this.activeAction, required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final loading = activeAction == action;
    return OutlinedButton.icon(
      onPressed: activeAction == null && enabled ? () => onPressed(action) : null,
      icon: loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon),
      label: Text('${action[0].toUpperCase()}${action.substring(1)}'),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Text(label),
          const Spacer(),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }
}
