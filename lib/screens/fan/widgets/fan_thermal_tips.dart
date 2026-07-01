import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class FanThermalTips extends StatelessWidget {
  final AppColors colors;

  const FanThermalTips({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THERMAL ARCHITECTURE TIPS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: colors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _TipBox(
          'COOLER BOOST',
          'Forces maximum fan velocity regardless of temperature. Use only for peak sustained workloads.',
          colors,
        ),
        const SizedBox(height: AppSpacing.md),
        _TipBox(
          'DUAL EXHAUST',
          'MSI hardware targets balanced thermal extraction between CPU and GPU zones.',
          colors,
        ),
      ],
    );
  }
}

class _TipBox extends StatelessWidget {
  final String title;
  final String desc;
  final AppColors colors;

  const _TipBox(this.title, this.desc, this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.glassBg,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.glassHighlight.withValues(alpha: 0.1)),
      ),
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
          const SizedBox(height: 2),
          Text(
            desc,
            style: TextStyle(color: colors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
