import '../models/models.dart';

class DemoData {
  static const user = User(
    id: 1,
    name: 'Louis Beke',
    email: 'louis@foxnetwork.be',
  );

  static const services = [
    CustomerService(
      id: 1,
      name: 'Minecraft Server',
      product: 'Game Hosting',
      status: 'Online',
      hostname: 'mc.foxnetwork.be',
      renewalDate: '30 July 2026',
      price: 12.99,
    ),
    CustomerService(
      id: 2,
      name: 'Fox VPS 2',
      product: 'VPS Hosting',
      status: 'Offline',
      hostname: 'vps2.foxnetwork.be',
      renewalDate: '6 August 2026',
      price: 19.99,
    ),
  ];

  static const invoices = [
    Invoice(
      id: 1,
      number: 'INV-2026-1042',
      amount: 12.99,
      status: 'Paid',
      dueDate: '30 July 2026',
      currency: 'EUR',
    ),
    Invoice(
      id: 2,
      number: 'INV-2026-1043',
      amount: 19.99,
      status: 'Unpaid',
      dueDate: '6 August 2026',
      currency: 'EUR',
    ),
  ];

  static const tickets = [
    SupportTicket(
      id: 1,
      subject: 'Server performance question',
      status: 'Open',
      updatedAt: 'Today',
    ),
    SupportTicket(
      id: 2,
      subject: 'Domain configuration',
      status: 'Answered',
      updatedAt: 'Yesterday',
    ),
  ];
}
