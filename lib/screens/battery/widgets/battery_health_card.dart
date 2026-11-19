import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/widgets/glass_container.dart';

class BatteryHealthCard extends StatelessWidget {
  final AppColors colors;

  const BatteryHealthCard({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CELLULAR HEALTH INDEX',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time electrochemical state analysis.',
                  style: TextStyle(color: colors.textTertiary, fontSize: 11),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  children: [
                    _HealthStat('98%', 'HEALTH', colors.success, colors),
                    const SizedBox(width: AppSpacing.xxxl),
                    _HealthStat('34°C', 'THERMAL', colors.balanced, colors),
                    const SizedBox(width: AppSpacing.xxxl),
                    _HealthStat(
                      '12.4V',
                      'VOLTAGE',
                      colors.textSecondary,
                      colors,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: 0.98,
              strokeWidth: 8,
              backgroundColor: colors.gaugeTrack,
              color: colors.success,
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final AppColors colors;

  const _HealthStat(this.value, this.label, this.color, this.colors);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Colors.white24,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
