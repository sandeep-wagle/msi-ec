import 'package:flutter/material.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class SettingsModeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  const SettingsModeOption({
    super.key,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = accentColor;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: isSelected
                ? colors.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 16,
              color: isSelected ? colors : Colors.white24,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : Colors.white54,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
