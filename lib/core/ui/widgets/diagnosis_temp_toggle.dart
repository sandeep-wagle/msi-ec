import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class DiagnosisTempToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppColors colors;

  const DiagnosisTempToggle({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? colors.performance.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: active
                ? colors.performance.withValues(alpha: 0.3)
                : colors.border.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: active ? colors.textPrimary : colors.textTertiary,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}