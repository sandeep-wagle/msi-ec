import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class BatteryHeader extends StatelessWidget {
  final AppColors colors;

  const BatteryHeader({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 24,
              decoration: BoxDecoration(
                color: colors.success,
                borderRadius: AppRadius.xsAll,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text(
              'Battery Optimization',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Hardware-level charging thresholds to maximize cell longevity and thermal health.',
          style: TextStyle(color: colors.textTertiary, fontSize: 13),
        ),
      ],
    );
  }
}
