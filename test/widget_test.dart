import 'package:flutter_test/flutter_test.dart';
import 'package:foxnetwork_app/app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('FoxNetwork app starts', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const FoxNetworkApp());
    await tester.pumpAndSettle();

    expect(find.byType(FoxNetworkApp), findsOneWidget);
    expect(find.text('Sign in with Paymenter'), findsOneWidget);
    expect(find.text('Password'), findsNothing);
  });
}
