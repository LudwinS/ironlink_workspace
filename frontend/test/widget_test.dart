import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('IronLink app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const IronLinkApp());
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}