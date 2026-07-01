import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/widgets/glass_container.dart';

class BatteryTipGrid extends StatelessWidget {
  final AppColors colors;

  const BatteryTipGrid({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TipRow(
          Icons.eco_outlined,
          'STAY IN THE 20-80% ZONE',
          'Ideal range for lithium-ion cell stability.',
          colors,
        ),
        const SizedBox(height: AppSpacing.md),
        _TipRow(
          Icons.thermostat_auto_outlined,
          'THERMAL MANAGEMENT',
          'High heat is the primary cause of battery degradation.',
          colors,
        ),
        const SizedBox(height: AppSpacing.md),
        _TipRow(
          Icons.power_rounded,
          'DC MODE BIAS',
          'On AC power, bypass is active to protect internal cells.',
          colors,
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final AppColors colors;

  const _TipRow(this.icon, this.title, this.desc, this.colors);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, color: colors.success.withValues(alpha: 0.6), size: 18),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(color: colors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
