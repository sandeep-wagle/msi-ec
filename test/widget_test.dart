import 'package:flutter_test/flutter_test.dart';
import 'package:msi_controller/main.dart';

void main() {
  testWidgets('App builds correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MsiControllerApp());
    await tester.pumpAndSettle();
    expect(find.text('MSI Controller'), findsOneWidget);
  });
}
