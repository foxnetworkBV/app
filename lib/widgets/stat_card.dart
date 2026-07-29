import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title; final String value; final IconData icon;
  const StatCard({super.key, required this.title, required this.value, required this.icon});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: FoxColors.border), boxShadow: const [BoxShadow(color: Color(0x0B0F1A30), blurRadius: 18, offset: Offset(0, 8))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: FoxColors.orange.withValues(alpha: .1), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: FoxColors.orange)),
      const SizedBox(height: 16),
      Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: FoxColors.navy)),
      const SizedBox(height: 2), Text(title, style: const TextStyle(color: FoxColors.muted, fontWeight: FontWeight.w600)),
    ]),
  );
}
