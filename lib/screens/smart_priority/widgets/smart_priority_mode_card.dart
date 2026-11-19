import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/screens/smart_priority/smart_priority_models.dart';

class SmartPriorityModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final SmartPriorityMode mode;
  final Color accentColor;
  final AppColors colors;
  final bool isSelected;
  final ValueChanged<SmartPriorityMode> onSelected;

  const SmartPriorityModeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.mode,
    required this.accentColor,
    required this.colors,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(mode),
      child: AnimatedContainer(
        duration: AppDurations.medium,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.1)
              : colors.glassBg,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: isSelected
                ? accentColor
                : colors.glassHighlight.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? accentColor : colors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isSelected ? colors.textPrimary : colors.textTertiary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
