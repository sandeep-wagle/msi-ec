import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class FanModeToggle extends StatelessWidget {
  final bool autoMode;
  final int fanIndex;
  final AppColors colors;
  final ValueChanged<bool> onToggle;

  const FanModeToggle({
    super.key,
    required this.autoMode,
    required this.fanIndex,
    required this.colors,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!autoMode),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: autoMode
              ? colors.superBattery.withValues(alpha: 0.1)
              : colors.warning.withValues(alpha: 0.1),
          borderRadius: AppRadius.pillAll,
          border: Border.all(
            color: autoMode ? colors.superBattery : colors.warning,
            width: 1.5,
          ),
        ),
        child: Text(
          autoMode ? 'AUTO' : 'MANUAL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: autoMode ? colors.superBattery : colors.warning,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
