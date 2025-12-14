import 'package:flutter_test/flutter_test.dart';
import 'package:ncb_shop/main.dart';

void main() {
  testWidgets('App startup test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NCBShopApp());

    // Verify that the app shows the splash screen with app name
    expect(find.text('NCB Shop'), findsOneWidget);
  });
}
