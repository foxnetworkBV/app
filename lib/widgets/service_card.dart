import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class ServiceCard extends StatelessWidget {
  final CustomerService service;
  const ServiceCard({super.key, required this.service});
  IconData get _icon { final p=service.product.toLowerCase(); if(p.contains('minecraft')) return Icons.view_in_ar_rounded; if(p.contains('discord')) return Icons.forum_rounded; if(p.contains('web')) return Icons.language_rounded; return Icons.dns_rounded; }
  @override Widget build(BuildContext context) { final theme=Theme.of(context); final scheme=theme.colorScheme; return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: scheme.outlineVariant), boxShadow: theme.brightness==Brightness.light ? const [BoxShadow(color: Color(0x090F1A30), blurRadius: 16, offset: Offset(0, 7))] : const []),
    child: Row(children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(gradient: FoxColors.primaryGradient, borderRadius: BorderRadius.circular(16)), child: Icon(_icon, color: Colors.white, size: 27)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(service.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3), Text(service.product, maxLines: 1, overflow: TextOverflow.ellipsis),
        if(service.hostname.isNotEmpty)...[const SizedBox(height: 5), Text(service.hostname, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)],
      ])),
      const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [StatusBadge(service.status), const SizedBox(height: 9), Icon(Icons.chevron_right_rounded, color: theme.textTheme.bodyMedium?.color)]),
    ]),
  ); }
}
