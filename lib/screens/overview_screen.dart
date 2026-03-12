import 'dart:async';
import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import '../domain/entities/system_info.dart';
import '../domain/repositories/msi_repository.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen>
    with SingleTickerProviderStateMixin {
  final MsiRepository _repository = getIt<MsiRepository>();
  StreamSubscription? _systemInfoSub;
  StreamSubscription? _fanInfoSub;
  SystemInfo? _systemInfo;
  List<FanInfo> _fans = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  DateTime _lastSystemUpdate = DateTime.now();
  DateTime _lastFanUpdate = DateTime.now();
  static const _minUpdateInterval = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();

    _systemInfoSub = _repository.systemInfoStream.listen((info) {
      final now = DateTime.now();
      if (now.difference(_lastSystemUpdate) < _minUpdateInterval) return;
      _lastSystemUpdate = now;
      if (mounted) setState(() => _systemInfo = info);
    });
    _fanInfoSub = _repository.fanInfoStream.listen((fans) {
      final now = DateTime.now();
      if (now.difference(_lastFanUpdate) < _minUpdateInterval) return;
      _lastFanUpdate = now;
      if (mounted) setState(() => _fans = fans);
    });
  }

  @override
  void dispose() {
    _systemInfoSub?.cancel();
    _fanInfoSub?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('System Status'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.memory,
                      label: 'CPU',
                      value: _systemInfo?.cpuTemperature != null
                          ? '${_systemInfo!.cpuTemperature}°C'
                          : '--°C',
                      color: _getTempColor(_systemInfo?.cpuTemperature),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.videocam,
                      label: 'GPU',
                      value: _systemInfo?.gpuTemperature != null
                          ? '${_systemInfo!.gpuTemperature}°C'
                          : '--°C',
                      color: _getTempColor(_systemInfo?.gpuTemperature),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Battery'),
              const SizedBox(height: 8),
              _buildBatteryCard(),
              const SizedBox(height: 16),
              _buildSectionTitle('Performance Mode'),
              const SizedBox(height: 8),
              _buildModeCard(),
              const SizedBox(height: 16),
              _buildSectionTitle('Fan Speed'),
              const SizedBox(height: 8),
              ..._buildFanCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryCard() {
    final level = _systemInfo?.batteryLevel ?? 0;
    final isCharging = _systemInfo?.isCharging ?? false;
    final color = level > 50
        ? Colors.green
        : level > 20
        ? Colors.orange
        : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isCharging ? Icons.battery_charging_full : _getBatteryIcon(level),
              size: 48,
              color: color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$level%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    isCharging ? 'Charging' : 'Discharging',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (_systemInfo?.batteryLimit != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Charge Limit'),
                  Text(
                    '${_systemInfo!.batteryLimit}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard() {
    final mode = _systemInfo?.currentMode ?? PerformanceMode.unknown;
    return Card(
      child: ListTile(
        leading: Icon(_getModeIcon(mode), size: 32, color: _getModeColor(mode)),
        title: Text(
          mode.displayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getModeColor(mode),
          ),
        ),
        subtitle: const Text('Current performance mode'),
      ),
    );
  }

  List<Widget> _buildFanCards() {
    if (_fans.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.air, size: 32),
                const SizedBox(width: 16),
                Text(
                  'No fans detected',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return _fans.asMap().entries.map((entry) {
      final fan = entry.value;
      final percentage = fan.maxRpm != null && fan.maxRpm! > 0
          ? (fan.currentRpm / fan.maxRpm! * 100).clamp(0, 100)
          : 0.0;

      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: percentage / 100),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.air, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Fan ${fan.fanIndex + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${fan.currentRpm} RPM',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getTempColor(
                          fan.maxRpm != null
                              ? (fan.currentRpm / fan.maxRpm! * 100).round()
                              : 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fan.autoMode ? 'Auto Mode' : 'Manual Mode',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (fan.maxRpm != null)
                        Text(
                          'Max: ${fan.maxRpm} RPM',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Color _getTempColor(int? temp) {
    if (temp == null) return Colors.grey;
    if (temp < 50) return Colors.green;
    if (temp < 70) return Colors.orange;
    return Colors.red;
  }

  IconData _getBatteryIcon(int level) {
    if (level > 90) return Icons.battery_full;
    if (level > 70) return Icons.battery_6_bar;
    if (level > 50) return Icons.battery_4_bar;
    if (level > 30) return Icons.battery_2_bar;
    if (level > 10) return Icons.battery_1_bar;
    return Icons.battery_0_bar;
  }

  IconData _getModeIcon(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.highPerformance:
        return Icons.speed;
      case PerformanceMode.balanced:
        return Icons.balance;
      case PerformanceMode.silent:
        return Icons.volume_off;
      case PerformanceMode.superBattery:
        return Icons.battery_saver;
      default:
        return Icons.help_outline;
    }
  }

  Color _getModeColor(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.highPerformance:
        return Colors.red;
      case PerformanceMode.balanced:
        return Colors.blue;
      case PerformanceMode.silent:
        return Colors.green;
      case PerformanceMode.superBattery:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
