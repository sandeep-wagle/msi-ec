import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/widgets/glass_container.dart';

class FanEmptyState extends StatelessWidget {
  final AppColors colors;

  const FanEmptyState({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.air_rounded,
              size: 48,
              color: colors.textTertiary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'NO FAN MODULES DETECTED',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: Colors.white38,
              ),
            ),
            Text(
              'VERIFY MSI-EC DRIVER STATUS',
              style: TextStyle(color: colors.textTertiary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
