import 'package:flutter_test/flutter_test.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/widgets/msi_card.dart';
import 'package:msi_controller/widgets/glass_bottom_nav.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:flutter/material.dart';

void main() {
  Widget wrapWithApp(Widget child) {
    return MaterialApp(
      theme: ThemeData(extensions: const [AppColors.dark]),
      home: Scaffold(body: child),
    );
  }

  group('GlassContainer', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const GlassContainer(child: Text('Hello')),
      ));
      expect(find.text('Hello'), findsOneWidget);
    });
  });

  group('MsiCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const MsiCard(glass: false, child: Text('Card Content')),
      ));
      expect(find.text('Card Content'), findsOneWidget);
    });
  });

  group('MsiSectionHeader', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const MsiSectionHeader(title: 'Test Section'),
      ));
      expect(find.text('Test Section'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const MsiSectionHeader(title: 'Title', subtitle: 'v1.0'),
      ));
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('v1.0'), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const MsiSectionHeader(
          title: 'Title',
          trailing: Icon(Icons.refresh),
        ),
      ));
      expect(find.text('Title'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('MsiInfoRow', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const MsiInfoRow(label: 'CPU', value: '45°C'),
      ));
      expect(find.text('CPU'), findsOneWidget);
      expect(find.text('45°C'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const MsiInfoRow(label: 'CPU', value: '45°C', icon: Icons.thermostat),
      ));
      expect(find.byIcon(Icons.thermostat), findsOneWidget);
    });
  });

  group('GlassBottomNav', () {
    testWidgets('renders all destinations', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AppColors.dark]),
        home: Scaffold(
          body: GlassBottomNav(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: const [
              GlassBottomNavDestination(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
              ),
              GlassBottomNavDestination(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('MsiProgressCard', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(wrapWithApp(
        const MsiProgressCard(
          label: 'CPU',
          value: '75%',
          progress: 0.75,
          color: Colors.red,
          icon: Icons.speed,
        ),
      ));
      expect(find.text('CPU'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });
  });
}
