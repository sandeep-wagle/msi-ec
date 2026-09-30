import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class InfoPanel extends StatelessWidget {
  final String message;
  final String version;
  final double progress;
  const InfoPanel({
    super.key,
    required this.message,
    required this.version,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'CORE PROTOCOL INITIALIZATION',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message.toUpperCase(),
          style: TextStyle(
            color: colors.performance,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Stack(
          children: [
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              width: 250 * progress,
              decoration: BoxDecoration(
                color: colors.performance,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MSI-EC DRIVER: ATTACHED',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              version,
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
