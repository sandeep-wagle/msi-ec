import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/injection.dart';
import '../core/theme/theme_provider.dart';
import '../domain/repositories/msi_repository.dart';
import '../logic/blocs/settings/settings_bloc.dart';
import '../logic/blocs/sound/sound_bloc.dart';
import 'hardware_monitoring_screen.dart';
import 'features_screen.dart';
import 'user_scenario_screen.dart';
import 'system_diagnosis_screen.dart';
import 'notification_screen.dart';
import 'settings_screen.dart';
import '../widgets/sdk_initialization_loader.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isInitialized = false;
  String? _initError;
  bool _isTabLoading = false;
  double _loadProgress = 0.0;
  Timer? _progressTimer;
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    HardwareMonitoringScreen(),
    UserScenarioScreen(),
    NotificationScreen(),
    SystemDiagnosisScreen(),
    FeaturesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeService() async {
    setState(() {
      _isTabLoading = true;
      _loadProgress = 0.1;
    });

    final repository = getIt<MsiRepository>();
    final success = await repository.initialize();

    if (mounted) {
      setState(() {
        _isInitialized = success;
        _loadProgress = 0.4;
        if (!success) {
          _initError =
              'Failed to initialize MSI driver. Make sure msi-ec is installed.';
        }
      });
    }

    final settingsBloc = context.read<SettingsBloc>();
    final soundBloc = context.read<SoundBloc>();

    await Future.delayed(const Duration(milliseconds: 100));

    var waitTime = 0;
    while ((settingsBloc.state.isLoading || soundBloc.state.isLoading) && waitTime < 10000 && mounted) {
      setState(() {
        _loadProgress = (_loadProgress + 0.05).clamp(0.4, 0.9);
      });
      await Future.delayed(const Duration(milliseconds: 200));
      waitTime += 200;
    }

    if (mounted) {
      setState(() {
        _loadProgress = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isTabLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'MSI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Center', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _navigateToSettings(context),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              getIt<ThemeProvider>().toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundColor: Colors.redAccent,
            radius: 14,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          if (!_isInitialized && _initError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade800,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _initError!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
                if (_isTabLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: SdkInitializationLoader(progress: _loadProgress),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.speed_outlined),
            selectedIcon: Icon(Icons.speed),
            label: 'Monitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Scenarios',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Diagnosis',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Features',
          ),
        ],
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: const _SettingsScreenWrapper(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _SettingsScreenWrapper extends StatelessWidget {
  const _SettingsScreenWrapper();

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}
