import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/core/theme/theme_provider.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'package:msi_controller/logic/blocs/settings/settings_bloc.dart';
import 'package:msi_controller/logic/blocs/sound/sound_bloc.dart';
import 'hardware_monitoring_screen.dart';
import 'features_screen.dart';
import 'user_scenario_screen.dart';
import 'system_diagnosis_screen.dart';
import 'notification_screen.dart';
import 'settings_screen.dart';
import 'package:msi_controller/widgets/sdk_initialization_loader.dart';
import 'package:msi_controller/widgets/glass_bottom_nav.dart';

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
    if (!mounted) return;
    setState(() {
      _isTabLoading = true;
      _loadProgress = 0.1;
    });

    final repository = getIt<MsiRepository>();
    final success = await repository.initialize();

    if (!mounted) return;
    setState(() {
      _isInitialized = success;
      _loadProgress = 0.4;
      if (!success) {
        _initError =
            'Failed to initialize MSI driver. Make sure msi-ec is installed.';
      }
    });

    if (!mounted) return;
    final settingsBloc = context.read<SettingsBloc>();
    final soundBloc = context.read<SoundBloc>();

    await Future.delayed(const Duration(milliseconds: 100));

    var waitTime = 0;
    while ((settingsBloc.state.isLoading || soundBloc.state.isLoading) &&
        waitTime < 10000 &&
        mounted) {
      if (mounted) {
        setState(() {
          _loadProgress = (_loadProgress + 0.05).clamp(0.4, 0.9);
        });
      }
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
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxs,
                vertical: AppSpacing.xxxs,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFEB1D24),
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.xs)),
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
            const SizedBox(width: AppSpacing.xs),
            const Text('Center', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _navigateToNotifications(context),
            tooltip: 'Notifications',
          ),
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
          const SizedBox(width: AppSpacing.xxs),
          CircleAvatar(
            backgroundColor: colors.performance,
            radius: 14,
            child: const Icon(Icons.person, size: 18, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          if (!_isInitialized && _initError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xs),
              color: colors.warning.withValues(alpha: 0.9),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white),
                  const SizedBox(width: AppSpacing.xxs),
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
                AnimatedSwitcher(
                  duration: AppDurations.medium,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Container(
                    key: ValueKey(_selectedIndex),
                    child: _screens[_selectedIndex],
                  ),
                ),
                if (_isTabLoading)
                  Container(
                    color: theme.scaffoldBackgroundColor.withValues(
                      alpha: 0.95,
                    ),
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
      bottomNavigationBar: GlassBottomNav(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          GlassBottomNavDestination(
            icon: Icons.show_chart_outlined,
            selectedIcon: Icons.show_chart,
            label: 'Monitor',
          ),
          GlassBottomNavDestination(
            icon: Icons.auto_awesome_outlined,
            selectedIcon: Icons.auto_awesome,
            label: 'Scenarios',
          ),
          GlassBottomNavDestination(
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications_active,
            label: 'Alerts',
          ),
          GlassBottomNavDestination(
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment,
            label: 'Diagnosis',
          ),
          GlassBottomNavDestination(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
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
            body: const SettingsScreen(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToNotifications(BuildContext context) {
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
            body: const NotificationScreen(),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
