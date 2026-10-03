import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foxnetwork_app/models/models.dart';
import 'package:foxnetwork_app/screens/services_screen.dart';
import 'package:foxnetwork_app/screens/service_detail_screen.dart';
import 'package:foxnetwork_app/services/session_service.dart';

class ServiceSession extends SessionService {
  List<CustomerService> services;
  int resourceRequests = 0;
  ServiceSession(this.services) : super(restore: false);
  @override
  Future<List<CustomerService>> getServices() async => services;
  @override
  Future<ServerResources> getServerResources(int id) async {
    resourceRequests++;
    throw StateError('Webhosting must not request gameserver resources');
  }
}

CustomerService service(int id, String category, String name) => CustomerService.fromJson({
  'id': id, 'category': category, 'name': name, 'product': 'Starter',
  'status': 'active', 'price': '4.50', 'can_control': false,
});

void main() {
  testWidgets('categories from Paymenter filter services including new categories', (tester) async {
    final session = ServiceSession([
      service(1, 'WEB', 'Website hosting'),
      service(2, 'Game', 'Minecraft server'),
      service(3, 'Backups', 'Daily backup'),
    ]);
    await tester.pumpWidget(MaterialApp(home: ServicesScreen(session: session)));
    await tester.pumpAndSettle();
    expect(find.text('Order a new service'), findsOneWidget);
    await tester.tap(find.text('WEB (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Website hosting'), findsOneWidget);
    expect(find.text('Minecraft server'), findsNothing);
    expect(find.text('Daily backup'), findsNothing);
    await tester.tap(find.text('All (3)'));
    await tester.pumpAndSettle();
    expect(find.text('Daily backup'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets('webhosting uses portal management without console or resource polling', (tester) async {
    final hosting = service(1, 'WEB', 'Website hosting');
    final session = ServiceSession([hosting]);
    await tester.pumpWidget(MaterialApp(home: ServiceDetailScreen(service: hosting, session: session)));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 15));
    expect(session.resourceRequests, 0);
    expect(find.text('Manage in customer portal'), findsOneWidget);
    expect(find.text('Open console'), findsNothing);
    expect(find.text('Power controls'), findsNothing);
    expect(find.text('WEB'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  test('missing and blank categories remain visible as Other', () {
    expect(CustomerService.fromJson({'id': 1}).category, 'Other');
    expect(service(2, '  ', 'Uncategorised').category, 'Other');
    expect(service(3, ' WEB ', 'Hosting').category, 'WEB');
  });
}
