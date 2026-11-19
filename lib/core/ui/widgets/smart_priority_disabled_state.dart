import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/widgets/glass_container.dart';

class SmartPriorityDisabledState extends StatelessWidget {
  final AppColors colors;

  const SmartPriorityDisabledState({
    super.key,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.block_flipped,
              size: 48,
              color: colors.textTertiary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'PROTOCOL STANDBY',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: Colors.white38,
              ),
            ),
            Text(
              'ENABLE MASTER SWITCH TO ACTIVATE AI PRIORITY',
              style: TextStyle(color: colors.textTertiary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}