import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/widgets/glass_container.dart';

class GaugeCardWidget extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final String unit;
  final List<Color> gaugeColors;
  final int? temperature;

  const GaugeCardWidget({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.unit,
    required this.gaugeColors,
    this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    final percent = max > 0 ? value / max : 0.0;
    final ac = Theme.of(context).extension<AppColors>()!;
    Color getTempColor(int temp) {
      if (temp < 50) return ac.tempCool;
      if (temp < 70) return ac.tempWarm;
      return ac.tempHot;
    }

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.bodySmall.fontSize,
              color: ac.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(value: 0, strokeWidth: 10),
                  ),
                  Positioned(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 10,
                      backgroundColor: ac.gaugeTrack,
                      color: gaugeColors.isNotEmpty
                          ? gaugeColors.first
                          : ac.performance,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$value',
                        style: AppTypography.displayMedium.copyWith(
                          fontFamily: 'monospace',
                          color: ac.textPrimary,
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: AppTypography.bodySmall.fontSize,
                          color: ac.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (temperature != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxxs,
                ),
                decoration: BoxDecoration(
                  color: getTempColor(temperature!).withValues(alpha: 0.1),
                  borderRadius: AppRadius.pillAll,
                  border: Border.all(
                    color: getTempColor(temperature!).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.thermostat,
                      size: 14,
                      color: getTempColor(temperature!),
                    ),
                    const SizedBox(width: AppSpacing.xxxs),
                    Text(
                      '$temperature°C',
                      style: TextStyle(
                        fontSize: AppTypography.bodySmall.fontSize,
                        fontWeight: FontWeight.bold,
                        color: getTempColor(temperature!),
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
}

class BarCardWidget extends StatelessWidget {
  final String label;
  final String valueText;
  final double percent;
  final String buttonText;
  final VoidCallback? onTap;
  final bool isLoading;

  const BarCardWidget({
    super.key,
    required this.label,
    required this.valueText,
    required this.percent,
    required this.buttonText,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.bodySmall.fontSize,
              color: ac.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  valueText,
                  style: AppTypography.displayMedium.copyWith(
                    fontFamily: 'monospace',
                    color: ac.performance,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppRadius.xsAll,
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    backgroundColor: ac.gaugeTrack,
                    color: ac.performance,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: AppTypography.labelSmall.fontSize,
                        color: ac.textTertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    InkWell(
                      onTap: isLoading ? null : onTap,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xxxs),
                        decoration: BoxDecoration(
                          color: isLoading
                              ? ac.surfaceElevated
                              : ac.performance,
                          shape: BoxShape.circle,
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    ac.performance,
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
}

class SidebarRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool isAlt;

  const SidebarRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.isAlt = false,
  });

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      color: isAlt
          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.bodySmall.fontSize,
              color: ac.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.bodySmall.fontSize,
              fontWeight: FontWeight.w500,
              color: ac.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class SsdRowWidget extends StatelessWidget {
  final double diskUsage;
  final double? diskTotalGb;
  final double? diskUsedGb;

  const SsdRowWidget({
    super.key,
    required this.diskUsage,
    this.diskTotalGb,
    this.diskUsedGb,
  });

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final total = diskTotalGb ?? 512.0;
    final used = diskUsedGb ?? (diskUsage * total);
    final free = total - used;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      child: Row(
        children: [
          Text(
            'SSD',
            style: TextStyle(
              fontSize: AppTypography.bodySmall.fontSize,
              color: ac.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Icon(Icons.storage, size: 14, color: ac.textSecondary),
          const Spacer(),
          Text(
            '${free.toStringAsFixed(1)} GB available',
            style: TextStyle(
              fontSize: AppTypography.labelSmall.fontSize,
              color: ac.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(
              value: diskUsage,
              minHeight: 4,
              backgroundColor: ac.gaugeTrack,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${(diskUsage * 100).toInt()} %',
            style: TextStyle(
              fontSize: AppTypography.labelSmall.fontSize,
              color: ac.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
