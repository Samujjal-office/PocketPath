import 'package:flutter_test/flutter_test.dart';
import 'package:pocketapp/main.dart';

void main() {
  testWidgets('PocketPath app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PocketPathApp());
    expect(find.text('Sign in to your PocketPath account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
