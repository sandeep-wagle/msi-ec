import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class GamingModeToggle extends StatelessWidget {
  final bool isActive;
  final bool isApplying;
  final AppColors colors;
  final ValueChanged<bool> onChanged;

  const GamingModeToggle({
    super.key,
    required this.isActive,
    required this.isApplying,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.medium,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? colors.performance.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: isActive
              ? colors.performance
              : colors.border.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isActive ? 'MODE: ACTIVE' : 'MODE: STANDBY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isActive ? colors.textPrimary : colors.textTertiary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 12),
          isApplying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: isActive,
                  activeThumbColor: colors.performance,
                  onChanged: onChanged,
                ),
        ],
      ),
    );
  }
}
