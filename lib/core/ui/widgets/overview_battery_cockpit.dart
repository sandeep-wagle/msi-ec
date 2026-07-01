import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/core/ui/widgets/animated_gauge.dart';

class OverviewBatteryCockpit extends StatelessWidget {
  final SystemInfo? info;
  final AppColors colors;

  const OverviewBatteryCockpit({
    super.key,
    this.info,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final level = info?.batteryLevel ?? 0;
    final chargeColor = level > 50 ? colors.success : colors.warning;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENERGY_CELL_STATE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: colors.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Text(
                '$level%',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: chargeColor,
                  fontFamily: 'monospace',
                  letterSpacing: -2.0,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info?.isCharging ?? false ? 'CHARGING' : 'DISCHARGING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: chargeColor,
                      ),
                    ),
                    Text(
                      'LIMIT: ${info?.batteryLimit ?? 100}%',
                      style: TextStyle(
                        fontSize: 9,
                        color: colors.textTertiary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedGauge(value: level / 100, color: chargeColor),
        ],
      ),
    );
  }
}