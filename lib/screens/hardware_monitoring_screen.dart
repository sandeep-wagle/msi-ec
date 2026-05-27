import 'dart:async';
import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import '../core/app_colors.dart';
import '../domain/entities/system_info.dart';
import '../domain/repositories/msi_repository.dart';
import '../widgets/msi_gauge.dart';
import '../widgets/msi_card.dart';

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
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEB1D24)),
        ),
      );
    }

    final colors = context.extension<AppColors>()!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Monitor',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                _buildTimeBadge(),
              ],
            ),
            const SizedBox(height: 32),
            // Gauge Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MsiGauge(
                    label: 'GPU Usage',
                    value: _systemInfo!.gpuUsage ?? 0,
                    max: 100,
                    unit: '%',
                    color: colors.performance,
                    temperature: _systemInfo!.gpuTemperature,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: MsiGauge(
                    label: 'CPU Usage',
                    value: _systemInfo!.cpuUsage ?? 0,
                    max: 100,
                    unit: '%',
                    color: _systemInfo!.cpuTemperature != null &&
                            _systemInfo!.cpuTemperature! > 70
                        ? colors.tempHot
                        : colors.tempWarm,
                    temperature: _systemInfo!.cpuTemperature,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: MsiGauge(
                    label: 'VRAM Usage',
                    value: _systemInfo!.vramUsage ?? 0,
                    max: _systemInfo!.vramTotal ?? 8192,
                    unit: 'MB',
                    color: colors.superBattery,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Progress Cards Row
            Row(
              children: [
                Expanded(
                  child: MsiProgressCard(
                    label: 'Memory',
                    value:
                        '${((_systemInfo!.ramUsage ?? 0) / (_systemInfo!.ramTotal ?? 1) * 100).toInt()}%',
                    progress: (_systemInfo!.ramUsage ?? 0) /
                        (_systemInfo!.ramTotal ?? 1),
                    barColor: colors.performance,
                    actionLabel: 'Free Up Memory',
                    isLoading: _isLoadingMemory,
                    onAction: () async {
                      setState(() => _isLoadingMemory = true);
                      await _repository.freeUpMemory();
                      setState(() => _isLoadingMemory = false);
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: MsiProgressCard(
                    label: 'Disk',
                    value: '${_systemInfo!.ssdTemp.toInt()}°C',
                    progress: _systemInfo!.diskUsage,
                    barColor: colors.success,
                    actionLabel: 'Clean up the disk',
                    isLoading: _isLoadingDisk,
                    onAction: () async {
                      setState(() => _isLoadingDisk = true);
                      await _repository.cleanUpDisk();
                      setState(() => _isLoadingDisk = false);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // System Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: MsiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MsiSectionHeader(title: 'Performance Details'),
                        const SizedBox(height: 20),
                        _buildPerfDetails(colors),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: MsiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MsiSectionHeader(title: 'System Info'),
                        const SizedBox(height: 20),
                        _buildSystemDetails(colors),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F2E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: const Text(
        'Live',
        style: TextStyle(
          fontSize: 11,
          color: Color(0xFF22C55E),
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildPerfDetails(AppColors colors) {
    final fans = _fans;
    return Column(
      children: [
        _buildPerfRow('Fan 1', '${fans.isNotEmpty ? fans[0].currentRpm : 0} RPM', colors),
        _buildPerfRow('Fan 2', '${fans.length > 1 ? fans[1].currentRpm : 0} RPM', colors, alt: true),
        _buildPerfRow('GPU Clock', '${_systemInfo?.gpuCoreClock ?? 0} MHz', colors),
        _buildPerfRow('CPU Temp', '${_systemInfo?.cpuTemperature ?? 0} °C', colors, alt: true),
        _buildPerfRow('GPU Temp', '${_systemInfo?.gpuTemperature ?? 0} °C', colors),
        _buildSsdRow(colors),
        _buildPerfRow(
          'Power Plan',
          _systemInfo?.powerPlan ?? 'Balanced',
          colors,
          alt: true,
        ),
      ],
    );
  }

  Widget _buildPerfRow(String label, String value, AppColors colors,
      {bool alt = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: alt ? colors.surfaceElevated : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFCBD5E1),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSsdRow(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          const Text('SSD', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(width: 6),
          const Icon(Icons.storage, size: 14, color: Color(0xFF475569)),
          const Spacer(),
          const Text(
            '400.67 GB available',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: 0.16,
                minHeight: 4,
                backgroundColor: colors.gaugeTrack,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('16%', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildSystemDetails(AppColors colors) {
    return Column(
      children: [
        MsiInfoRow(
          label: 'CPU',
          value: _systemInfo?.cpuModel ?? 'Intel Core i7-11800H @ 2.30GHz',
        ),
        MsiInfoRow(
          label: 'GPU',
          value: _systemInfo?.gpuModel ?? 'NVIDIA GeForce RTX 3080',
          alt: true,
        ),
        MsiInfoRow(
          label: 'RAM',
          value: '${((_systemInfo?.ramTotal ?? 0) / 1024).toInt()} GB',
        ),
        MsiInfoRow(
          label: 'VRAM',
          value:
              '${_systemInfo?.vramUsage ?? 0} / ${_systemInfo?.vramTotal ?? 8192} MB',
          alt: true,
        ),
        MsiInfoRow(
          label: 'Battery',
          value:
              '${_systemInfo?.batteryLevel ?? 0}% ${_systemInfo?.isCharging == true ? '(Charging)' : '(Discharging)'}',
        ),
      ],
    );
  }
}
