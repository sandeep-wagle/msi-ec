import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/core/widgets/app_button.dart';
import 'package:msi_controller/widgets/glass_container.dart';

class DiagnosisCheckerItem extends StatelessWidget {
  final String label;
  final double percent;
  final VoidCallback onPressed;
  final String buttonLabel;
  final Color color;
  final AppColors appColors;
  final bool isLoading;

  const DiagnosisCheckerItem({
    super.key,
    required this.label,
    required this.percent,
    required this.onPressed,
    required this.buttonLabel,
    required this.color,
    required this.appColors,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: appColors.textTertiary,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '${(percent * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: appColors.textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.xsAll,
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: appColors.gaugeTrack,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: buttonLabel,
            onPressed: isLoading ? null : onPressed,
            isOutline: true,
            isOval: false,
            isPrimary: false,
            backgroundColor: color.withValues(alpha: 0.3),
            foregroundColor: appColors.textPrimary,
            isLoading: isLoading,
            width: double.infinity,
            height: 40,
            fontSize: 11,
          ),
        ],
      ),
    );
  }
}