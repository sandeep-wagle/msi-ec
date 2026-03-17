import 'package:flutter_test/flutter_test.dart';
import 'package:msi_controller/main.dart';
import 'package:msi_controller/core/di/injection.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await configureDependencies();
  });

  testWidgets('App builds correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MsiControllerApp());
    await tester.pump(); // Use pump instead of pumpAndSettle due to animations
    expect(find.text('MSI Center'), findsOneWidget);
  });
}
