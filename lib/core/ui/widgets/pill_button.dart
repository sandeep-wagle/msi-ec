import 'package:flutter/material.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  const PillButton({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    required this.onTap,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: AppRadius.pillAll,
          border: Border.all(
            color: isActive ? color : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isActive ? color : Colors.white38,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isActive ? color : Colors.white38,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}