import 'dart:async';
import 'package:flutter/material.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'package:msi_controller/screens/hardware_monitoring/widgets/hardware_monitoring_widgets.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/core/ui/widgets/screen_header.dart';

class HardwareMonitoringScreen extends StatefulWidget {
  const HardwareMonitoringScreen({super.key});

  @override
  State<HardwareMonitoringScreen> createState() =>
      _HardwareMonitoringScreenState();
}

class _HardwareMonitoringScreenState extends State<HardwareMonitoringScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final MsiRepository _repository = getIt<MsiRepository>();
  StreamSubscription? _systemInfoSub;
  StreamSubscription? _fanInfoSub;

  SystemInfo? _systemInfo;
  List<FanInfo> _fans = [];
  bool _isLoadingMemory = false;
  bool _isLoadingDisk = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  DateTime _lastSystemUpdate = DateTime.now();
  DateTime _lastFanUpdate = DateTime.now();
  static const _minUpdateInterval = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();

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
    _animController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_systemInfo == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
        ),
      );
    }

    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'Monitor',
              subtitle: 'Live telemetry from your machine.',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.grid_view, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  const Icon(Icons.settings, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  const CircleAvatar(
                    radius: 12,
                    child: Icon(Icons.person, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Monitor Cards
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildGaugeCard(
                              'GPU Usage',
                              _systemInfo!.gpuUsage ?? 0,
                              100,
                              '%',
                              [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ],
                              temperature: _systemInfo!.gpuTemperature,
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _buildGaugeCard(
                              'CPU Usage',
                              _systemInfo!.cpuUsage ?? 0,
                              100,
                              '%',
                              [Colors.white70, Colors.white24],
                              temperature: _systemInfo!.cpuTemperature,
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _buildGaugeCard(
                              'VRAM Usage',
                              _systemInfo!.vramUsage ?? 0,
                              _systemInfo!.vramTotal ?? 8192,
                              'MB',
                              [Colors.grey.shade400, Colors.grey.shade700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBarCard(
                              'Disk',
                              '${_systemInfo!.ssdTemp.toInt()}°c',
                              _systemInfo!.diskUsage,
                              'Clean up the disk',
                              () async {
                                setState(() => _isLoadingDisk = true);
                                await _repository.cleanUpDisk();
                                setState(() => _isLoadingDisk = false);
                              },
                              isLoading: _isLoadingDisk,
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _buildBarCard(
                              'Memory',
                              '${((_systemInfo!.ramUsage ?? 0) / (_systemInfo!.ramTotal ?? 1) * 100).toInt()}%',
                              (_systemInfo!.ramUsage ?? 0) /
                                  (_systemInfo!.ramTotal ?? 1),
                              'Free Up Memory',
                              () async {
                                setState(() => _isLoadingMemory = true);
                                await _repository.freeUpMemory();
                                setState(() => _isLoadingMemory = false);
                              },
                              isLoading: _isLoadingMemory,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                // Right Column: System Details Sidebar
                Expanded(flex: 2, child: _buildDetailsSidebar(theme)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeCard(
    String label,
    int value,
    int max,
    String unit,
    List<Color> colors, {
    int? temperature,
  }) {
    final percent = max > 0 ? value / max : 0.0;
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 10,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                      color: colors.isNotEmpty ? colors.first : Colors.blue,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$value',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (temperature != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getTempBgColor(temperature).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getTempBgColor(temperature).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.thermostat,
                      size: 14,
                      color: _getTempBgColor(temperature),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$temperature°C',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getTempBgColor(temperature),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getTempBgColor(int temp) {
    if (temp < 50) return Colors.green;
    if (temp < 70) return Colors.orange;
    return Colors.red;
  }

  Widget _buildBarCard(
    String label,
    String valueText,
    double percent,
    String buttonText,
    VoidCallback onTap, {
    bool isLoading = false,
  }) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  valueText,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: isLoading ? null : onTap,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isLoading ? Colors.grey : Colors.blue.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.bolt,
                                size: 12,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSidebar(ThemeData theme) {
    final fans = _fans;
    final totalGb = ((_systemInfo?.ramTotal ?? 0) / 1024).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _systemInfo?.cpuModel ?? 'Intel Core i7-11800H @ 2.30GHz',
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          child: Text(
            _systemInfo?.gpuModel ?? 'NVIDIA GeForce RTX 3080',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        SidebarRowWidget(label: 'RAM', value: '$totalGb GB'),
        SidebarRowWidget(
          label: 'VRAM',
          value: '${_systemInfo?.vramUsage ?? 0} / ${_systemInfo?.vramTotal ?? 8192} MB',
          isAlt: true,
        ),
        SidebarRowWidget(
          label: 'Fan 1',
          value: '${fans.isNotEmpty ? fans[0].currentRpm : 0} RPM',
        ),
        SidebarRowWidget(
          label: 'Fan 2',
          value: '${fans.length > 1 ? fans[1].currentRpm : 0} RPM',
          isAlt: true,
        ),
        SidebarRowWidget(label: 'GPU Clock', value: '${_systemInfo?.gpuCoreClock ?? 0} MHz'),
        SidebarRowWidget(
          label: 'CPU Temp',
          value: '${_systemInfo?.cpuTemperature ?? 0} °C',
          isAlt: true,
        ),
        SidebarRowWidget(label: 'GPU Temp', value: '${_systemInfo?.gpuTemperature ?? 0} °C'),
        SsdRowWidget(diskUsage: 0.16),
        SidebarRowWidget(
          label: 'Power Plan',
          value: _systemInfo?.powerPlan ?? 'Balance',
          isAlt: true,
        ),
      ],
    );
  }

}


