import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/core/ui/widgets/animated_gauge.dart';

class OverviewStorageConsole extends StatelessWidget {
  final SystemInfo? info;
  final AppColors colors;

  const OverviewStorageConsole({
    super.key,
    this.info,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STORAGE_INDEX',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white24,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NVMe SSD',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              Text(
                '${((info?.diskUsage ?? 0) * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedGauge(value: info?.diskUsage ?? 0, color: colors.balanced),
          const SizedBox(height: 12),
          Text(
            'TEMP: ${info?.ssdTemp.toInt() ?? "--"}°C',
            style: TextStyle(
              fontSize: 9,
              color: colors.textTertiary,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}