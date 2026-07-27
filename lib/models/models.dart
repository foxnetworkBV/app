class User {
  final int id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: (json['name'] ?? 'Service').toString(),
      email: json['email'] as String,
    );
  }
}

class CustomerService {
  final int id;
  final String name;
  final String product;
  final String status;
  final String hostname;
  final String renewalDate;
  final double price;

  const CustomerService({
    required this.id,
    required this.name,
    required this.product,
    required this.status,
    required this.hostname,
    required this.renewalDate,
    required this.price,
  });

  bool get isOnline => status.toLowerCase() == 'online';

  static String _renewal(Map<String, dynamic> json) {
    final value = (json['renewal_date'] ?? json['renewalDate'] ??
            json['expires_at'] ?? json['expiresAt'] ?? '')
        .toString();
    if (value.startsWith('9998-') || value.startsWith('9999-')) return '';
    return value;
  }

  factory CustomerService.fromJson(Map<String, dynamic> json) {
    return CustomerService(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: (json['name'] ?? 'Service').toString(),
      product: (json['product'] ?? json['product_name'] ?? '').toString(),
      status: (json['status'] ?? 'Unknown').toString(),
      hostname: (json['hostname'] ?? json['slug'] ?? '').toString(),
      renewalDate: _renewal(json),
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Invoice {
  final int id;
  final String number;
  final double amount;
  final String status;
  final String dueDate;
  final String currency;

  const Invoice({
    required this.id,
    required this.number,
    required this.amount,
    required this.status,
    required this.dueDate,
    required this.currency,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: int.tryParse(json['id'].toString()) ?? 0,
      number: json['number'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: (json['status'] ?? 'Unknown').toString(),
      dueDate: (json['due_date'] ?? json['dueDate'] ?? '').toString(),
      currency: (json['currency_code'] ?? json['currency'] ?? 'EUR').toString(),
    );
  }
}

class SupportTicket {
  final int id;
  final String subject;
  final String status;
  final String updatedAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: int.tryParse(json['id'].toString()) ?? 0,
      subject: json['subject'] as String,
      status: (json['status'] ?? 'Unknown').toString(),
      updatedAt: json['updated_at'] as String,
    );
  }
}


class ServerResources {
  final String state;
  final bool isSuspended;
  final int memoryBytes;
  final double cpuAbsolute;
  final int diskBytes;
  final int networkRxBytes;
  final int networkTxBytes;
  final int uptimeMs;

  const ServerResources({
    required this.state,
    required this.isSuspended,
    required this.memoryBytes,
    required this.cpuAbsolute,
    required this.diskBytes,
    required this.networkRxBytes,
    required this.networkTxBytes,
    required this.uptimeMs,
  });

  factory ServerResources.fromJson(Map<String, dynamic> json) {
    final resources = json['resources'] is Map<String, dynamic>
        ? json['resources'] as Map<String, dynamic>
        : <String, dynamic>{};
    int integer(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;
    double decimal(Object? value) => double.tryParse(value?.toString() ?? '') ?? 0;
    return ServerResources(
      state: (json['current_state'] ?? 'unknown').toString(),
      isSuspended: json['is_suspended'] == true,
      memoryBytes: integer(resources['memory_bytes']),
      cpuAbsolute: decimal(resources['cpu_absolute']),
      diskBytes: integer(resources['disk_bytes']),
      networkRxBytes: integer(resources['network_rx_bytes']),
      networkTxBytes: integer(resources['network_tx_bytes']),
      uptimeMs: integer(resources['uptime']),
    );
  }
}
