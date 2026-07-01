import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class IconToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;
  final String? tooltip;

  const IconToggleButton({
    super.key,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final button = InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : colors.surfaceElevated.withValues(alpha: 0.3),
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.3)
                : colors.border.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? activeColor : colors.textTertiary,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    return button;
  }
}