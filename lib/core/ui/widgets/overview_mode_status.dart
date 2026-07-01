import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/widgets/glass_container.dart';

class OverviewModeStatus extends StatelessWidget {
  final SystemInfo? info;
  final AppColors colors;

  const OverviewModeStatus({
    super.key,
    this.info,
    required this.colors,
  });

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
        return colors.performance;
      case PerformanceMode.balanced:
        return colors.balanced;
      case PerformanceMode.silent:
        return colors.silent;
      case PerformanceMode.superBattery:
        return colors.superBattery;
      default:
        return colors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = info?.currentMode ?? PerformanceMode.balanced;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIVE_PROTOCOL',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white24,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                Icon(
                  _getModeIcon(mode),
                  color: _getModeColor(mode),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  mode.displayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _getModeColor(mode),
                    letterSpacing: 1.0,
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