import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  Color _color(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'active':
      case 'online':
      case 'open':
        return Colors.green;
      case 'pending':
      case 'unpaid':
      case 'waiting':
        return Colors.orange;
      case 'cancelled':
      case 'canceled':
      case 'closed':
      case 'offline':
      case 'suspended':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        status.isEmpty ? 'Unknown' : status,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
