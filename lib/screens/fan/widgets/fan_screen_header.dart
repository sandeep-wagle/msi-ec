import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class FanScreenHeader extends StatelessWidget {
  const FanScreenHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 24,
              decoration: BoxDecoration(
                color: colors.warning,
                borderRadius: AppRadius.xsAll,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text(
              'Thermal Management',
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
          'Precise control over rotational velocity to maintain hardware stability under peak load.',
          style: TextStyle(color: colors.textTertiary, fontSize: 13),
        ),
      ],
    );
  }
}
