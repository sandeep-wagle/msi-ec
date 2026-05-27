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
import '../widgets/sdk_initialization_loader.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  bool _isInitialized = false;
  String? _initError;
  late TabController _tabController;
  bool _isTabLoading = false;
  double _loadProgress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initializeService();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
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
    while ((settingsBloc.state.isLoading || soundBloc.state.isLoading) &&
        waitTime < 10000 &&
        mounted) {
      setState(() {
        _loadProgress = (_loadProgress + 0.05).clamp(0.4, 0.9);
      });
      await Future.delayed(const Duration(milliseconds: 200));
      waitTime += 200;
    }

    if (mounted) {
      setState(() => _loadProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _isTabLoading = false);
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEB1D24), Color(0xFFD31A20)],
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEB1D24).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'MSI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'CENTER',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 1.2,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F0F2E)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: isDark ? const Color(0xFFEB1D24) : const Color(0xFFC41E24),
              unselectedLabelColor: isDark
                  ? const Color(0xFF475569)
                  : Colors.grey.shade500,
              indicator: BoxDecoration(
                color: isDark
                    ? const Color(0xFFEB1D24).withValues(alpha: 0.12)
                    : const Color(0xFFC41E24).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed, size: 16),
                      SizedBox(width: 6),
                      Text('Monitor'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology, size: 16),
                      SizedBox(width: 6),
                      Text('Scenarios'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics_outlined, size: 16),
                      SizedBox(width: 6),
                      Text('Diagnosis'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.grid_view, size: 16),
                      SizedBox(width: 6),
                      Text('Features'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () {},
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: () => getIt<ThemeProvider>().toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEB1D24).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 16,
              child: Icon(Icons.person, size: 18, color: Color(0xFFEB1D24)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isInitialized && _initError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade900.withValues(alpha: 0.9),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _initError!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      HardwareMonitoringScreen(),
                      UserScenarioScreen(),
                      SystemDiagnosisScreen(),
                      FeaturesScreen(),
                    ],
                  ),
                ),
                if (_isTabLoading)
                  Container(
                    color: const Color(0xFF050510).withValues(alpha: 0.9),
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: SdkInitializationLoader(
                          progress: _loadProgress,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
