import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class EffectCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final AppColors colors;
  final bool isSelected;
  final VoidCallback onTap;

  const EffectCard({
    super.key,
    required this.name,
    required this.icon,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdAll,
          color: isSelected
              ? colors.performance.withValues(alpha: 0.15)
              : colors.glassBg,
          border: Border.all(
            color: isSelected
                ? colors.performance
                : colors.glassHighlight.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.performance.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? colors.performance : colors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? colors.textPrimary : colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
