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
  final String issuedAt;
  final String currency;

  const Invoice({
    required this.id,
    required this.number,
    required this.amount,
    required this.status,
    required this.issuedAt,
    required this.currency,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: int.tryParse(json['id'].toString()) ?? 0,
      number: (json['number'] ?? json['invoice_number'] ?? 'Invoice #${json['id'] ?? ''}').toString(),
      amount: double.tryParse((json['amount'] ?? json['total'] ?? 0).toString()) ?? 0,
      status: (json['status'] ?? 'Unknown').toString(),
      issuedAt: (json['issued_at'] ?? json['issuedAt'] ?? json['created_at'] ?? json['due_date'] ?? json['dueDate'] ?? '').toString(),
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
      subject: (json['subject'] ?? 'Support ticket').toString(),
      status: (json['status'] ?? 'Unknown').toString(),
      updatedAt: (json['updated_at'] ?? json['updatedAt'] ?? '').toString(),
    );
  }
}


class TicketMessage {
  final int id;
  final String message;
  final String author;
  final bool isStaff;
  final String createdAt;

  const TicketMessage({
    required this.id,
    required this.message,
    required this.author,
    required this.isStaff,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      message: (json['message'] ?? json['content'] ?? '').toString(),
      author: (json['author'] ?? (json['is_staff'] == true ? 'Support' : 'You')).toString(),
      isStaff: json['is_staff'] == true,
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
    );
  }
}

class TicketDetail {
  final int id;
  final String subject;
  final String status;
  final String priority;
  final String department;
  final String createdAt;
  final String updatedAt;
  final String closedAt;
  final String webUrl;
  final List<TicketMessage> messages;

  const TicketDetail({
    required this.id,
    required this.subject,
    required this.status,
    required this.priority,
    required this.department,
    required this.createdAt,
    required this.updatedAt,
    required this.closedAt,
    required this.webUrl,
    required this.messages,
  });

  factory TicketDetail.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] is List<dynamic>
        ? json['messages'] as List<dynamic>
        : const <dynamic>[];
    return TicketDetail(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      subject: (json['subject'] ?? 'Support ticket').toString(),
      status: (json['status'] ?? 'Unknown').toString(),
      priority: (json['priority'] ?? '').toString(),
      department: (json['department'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? json['updatedAt'] ?? '').toString(),
      closedAt: (json['closed_at'] ?? json['closedAt'] ?? '').toString(),
      webUrl: (json['web_url'] ?? '').toString(),
      messages: rawMessages
          .whereType<Map<String, dynamic>>()
          .map(TicketMessage.fromJson)
          .toList(),
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


class InvoiceItem {
  final int id; final String description; final double quantity; final double price; final double total; final String currency;
  const InvoiceItem({required this.id,required this.description,required this.quantity,required this.price,required this.total,required this.currency});
  factory InvoiceItem.fromJson(Map<String,dynamic> j)=>InvoiceItem(
    id:int.tryParse('${j['id']??0}')??0, description:'${j['description']??'Item'}',
    quantity:double.tryParse('${j['quantity']??1}')??1, price:double.tryParse('${j['price']??0}')??0,
    total:double.tryParse('${j['total']??0}')??0, currency:'${j['currency']??'EUR'}');
}
class InvoiceDetail {
  final int id;
  final String number;
  final String status;
  final String currency;
  final String issuedAt;
  final String dueAt;
  final String updatedAt;
  final String paidAt;
  final String pdfUrl;
  final String webUrl;
  final String notes;
  final double total;
  final List<InvoiceItem> items;

  const InvoiceDetail({
    required this.id,
    required this.number,
    required this.status,
    required this.currency,
    required this.issuedAt,
    required this.dueAt,
    required this.updatedAt,
    required this.paidAt,
    required this.pdfUrl,
    required this.webUrl,
    required this.notes,
    required this.total,
    required this.items,
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) => InvoiceDetail(
        id: int.tryParse('${json['id'] ?? 0}') ?? 0,
        number: '${json['number'] ?? json['invoice_number'] ?? 'Invoice'}',
        status: '${json['status'] ?? 'Unknown'}',
        currency: '${json['currency'] ?? json['currency_code'] ?? 'EUR'}',
        issuedAt: '${json['issued_at'] ?? json['issuedAt'] ?? ''}',
        dueAt: '${json['due_at'] ?? json['dueDate'] ?? ''}',
        updatedAt: '${json['updated_at'] ?? json['updatedAt'] ?? ''}',
        paidAt: '${json['paid_at'] ?? json['paidAt'] ?? ''}',
        pdfUrl: '${json['pdf_url'] ?? ''}',
        webUrl: '${json['web_url'] ?? ''}',
        notes: '${json['notes'] ?? ''}',
        total: double.tryParse('${json['total'] ?? json['amount'] ?? 0}') ?? 0,
        items: json['items'] is List
            ? (json['items'] as List)
                .whereType<Map<String, dynamic>>()
                .map(InvoiceItem.fromJson)
                .toList()
            : <InvoiceItem>[],
      );
}

