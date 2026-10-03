import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/core/ui/widgets/screen_header.dart';
import 'package:msi_controller/core/widgets/app_button.dart';
import 'package:msi_controller/screens/system_diagnosis/widgets/section_title_widget.dart';
import 'package:msi_controller/screens/system_diagnosis/widgets/status_badge_widget.dart';

class SystemDiagnosisScreen extends StatefulWidget {
  const SystemDiagnosisScreen({super.key});

  @override
  State<SystemDiagnosisScreen> createState() => _SystemDiagnosisScreenState();
}

class _SystemDiagnosisScreenState extends State<SystemDiagnosisScreen>
    with AutomaticKeepAliveClientMixin {
  final MsiRepository _repository = getIt<MsiRepository>();
  bool _isCelsius = true;
  bool _isLoadingMemory = false;
  bool _isLoadingDisk = false;
  final List<String> _kernelLogs = [
    '[INFO] KERNEL_DIAGNOSTIC_READY',
    '[INFO] MSI_HARDWARE_MONITOR_STABLE',
  ];

  void _addLog(String msg) {
    setState(() {
      _kernelLogs.insert(0, '[${DateTime.now().second}s] $msg');
      if (_kernelLogs.length > 5) _kernelLogs.removeLast();
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'System Diagnosis',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: StreamBuilder<SystemInfo>(
        stream: _repository.systemInfoStream,
        initialData: _repository.lastSystemInfo,
        builder: (context, snapshot) {
          final info = snapshot.data;

          if (info == null) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEB1D24)),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxxl,
                    AppSpacing.xxxl,
                    AppSpacing.xxxl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScreenHeader(
                        title: 'System Health',
                        subtitle:
                            'Deep diagnostics and storage analysis for your MSI machine.',
                        trailing: Icon(
                          Icons.monitor_heart_outlined,
                          color: colors.performance,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxxl,
                ),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      return Column(
                        children: [
                          if (isWide)
                            _buildWideLayout(info, colors)
                          else
                            _buildNarrowLayout(info, colors),
                          const SizedBox(height: AppSpacing.xxxl),
                          SectionTitleWidget(
                            title: 'KERNEL_DIAGNOSTIC_OUTPUT',
                            colors: colors,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildLogConsole(colors),
                          const SizedBox(height: AppSpacing.xxxl),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogConsole(AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _kernelLogs
            .map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  log,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildWideLayout(SystemInfo info, AppColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitleWidget(title: 'RESOURCE MAINTENANCE', colors: colors),
              const SizedBox(height: AppSpacing.md),
              _buildCheckerItem(
                label: 'SSD CAPACITY',
                percent: info.diskUsage,
                buttonLabel: 'OPTIMIZE DISK',
                isLoading: _isLoadingDisk,
                color: colors.success,
                onPressed: () async {
                  setState(() => _isLoadingDisk = true);
                  _addLog('INITIATING_DISK_VACUUM...');
                  await _repository.cleanUpDisk();
                  _addLog('CLEANUP_SUCCESS_FREE_NODES_RELEASED');
                  await _repository.refreshSystemInfo();
                  setState(() => _isLoadingDisk = false);
                },
                colors: colors,
                index: 0,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildCheckerItem(
                label: 'MEMORY LOAD',
                percent: (info.ramUsage ?? 0) / (info.ramTotal ?? 100),
                buttonLabel: 'PURGE RAM',
                isLoading: _isLoadingMemory,
                color: colors.performance,
                onPressed: () async {
                  setState(() => _isLoadingMemory = true);
                  _addLog('EXECUTING_RAM_PURGE_0x3...');
                  await _repository.freeUpMemory();
                  _addLog('MEMORY_NORMALIZED_CACHES_DROPPED');
                  await _repository.refreshSystemInfo();
                  setState(() => _isLoadingMemory = false);
                },
                colors: colors,
                index: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitleWidget(title: 'STORAGE ARCHITECTURE', colors: colors),
              const SizedBox(height: AppSpacing.md),
              _buildStorageProCard(info, colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(SystemInfo info, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitleWidget(title: 'RESOURCE MAINTENANCE', colors: colors),
        const SizedBox(height: AppSpacing.md),
        _buildCheckerItem(
          label: 'DISK',
          percent: info.diskUsage,
          buttonLabel: 'CLEAN UP',
          isLoading: _isLoadingDisk,
          color: colors.success,
          onPressed: () async {
            setState(() => _isLoadingDisk = true);
            await _repository.cleanUpDisk();
            await _repository.refreshSystemInfo();
            setState(() => _isLoadingDisk = false);
          },
          colors: colors,
          index: 0,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildCheckerItem(
          label: 'MEMORY',
          percent: (info.ramUsage ?? 0) / (info.ramTotal ?? 100),
          buttonLabel: 'FREE UP',
          isLoading: _isLoadingMemory,
          color: colors.performance,
          onPressed: () async {
            setState(() => _isLoadingMemory = true);
            await _repository.freeUpMemory();
            await _repository.refreshSystemInfo();
            setState(() => _isLoadingMemory = false);
          },
          colors: colors,
          index: 1,
        ),
        const SizedBox(height: AppSpacing.xxxl),
        SectionTitleWidget(title: 'STORAGE ARCHITECTURE', colors: colors),
        const SizedBox(height: AppSpacing.md),
        _buildStorageProCard(info, colors),
      ],
    );
  }

  Widget _buildCheckerItem({
    required String label,
    required double percent,
    required VoidCallback onPressed,
    required String buttonLabel,
    required Color color,
    required AppColors colors,
    bool isLoading = false,
    int index = 0,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: colors.textTertiary,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '${(percent * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.xsAll,
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: colors.gaugeTrack,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: buttonLabel,
            onPressed: isLoading ? null : onPressed,
            isOutline: true,
            isOval: false,
            isPrimary: false,
            backgroundColor: color.withValues(alpha: 0.3),
            foregroundColor: colors.textPrimary,
            isLoading: isLoading,
            width: double.infinity,
            height: 40,
            fontSize: 11,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageProCard(SystemInfo info, AppColors colors) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NVMe SSD MASTER',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: colors.textPrimary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '/DEV/NVME0N1P2',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 9,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              StatusBadgeWidget(label: 'HEALTHY', color: colors.success, colors: colors),
            ],
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Row(
            children: [
              Expanded(
                child: _buildProGauge(
                  'STORAGE',
                  info.diskUsage,
                  colors.balanced,
                  colors,
                  suffix: '%',
                ),
              ),
              Container(
                height: 80,
                width: 1,
                color: colors.border.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _buildProGauge(
                  'THERMAL',
                  _isCelsius
                      ? info.ssdTemp / 100
                      : ((info.ssdTemp * 9 / 5 + 32) / 212),
                  colors.performance,
                  colors,
                  customValue:
                      '${_isCelsius ? info.ssdTemp.toInt() : (info.ssdTemp * 9 / 5 + 32).toInt()}°',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTempToggle(
                'CELSIUS',
                _isCelsius,
                () => setState(() => _isCelsius = true),
                colors,
              ),
              const SizedBox(width: AppSpacing.xl),
              _buildTempToggle(
                'FAHRENHEIT',
                !_isCelsius,
                () => setState(() => _isCelsius = false),
                colors,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProGauge(
    String label,
    double percent,
    Color color,
    AppColors colors, {
    String? customValue,
    String suffix = '',
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                strokeWidth: 6,
                backgroundColor: colors.gaugeTrack,
                color: color,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  customValue ?? '${(percent * 100).toInt()}$suffix',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                    fontFamily: 'monospace',
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: colors.textTertiary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTempToggle(
    String label,
    bool active,
    VoidCallback onTap,
    AppColors colors,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? colors.performance.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: active
                ? colors.performance.withValues(alpha: 0.3)
                : colors.border.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: active ? colors.textPrimary : colors.textTertiary,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
