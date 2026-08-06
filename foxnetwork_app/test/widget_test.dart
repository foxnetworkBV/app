import 'package:flutter_test/flutter_test.dart';
import 'package:foxnetwork_app/app.dart';

void main() {
  testWidgets('FoxNetwork app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const FoxNetworkApp());

    expect(find.byType(FoxNetworkApp), findsOneWidget);
  });
}
