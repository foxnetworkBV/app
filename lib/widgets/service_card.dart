import 'package:flutter/material.dart';
import '../models/models.dart';

class ServiceCard extends StatelessWidget {
  final CustomerService service;

  const ServiceCard({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              child: Icon(
                service.isOnline ? Icons.check : Icons.close,
                color: service.isOnline ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(service.product),
                  const SizedBox(height: 4),
                  Text(
                    service.hostname,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(service.status),
          ],
        ),
      ),
    );
  }
}
