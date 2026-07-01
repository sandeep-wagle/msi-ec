import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/screens/smart_priority/widgets/smart_priority_mode_card.dart';
import 'package:msi_controller/screens/smart_priority/smart_priority_models.dart';

class SmartPriorityModeGrid extends StatelessWidget {
  final SmartPriorityMode currentMode;
  final ValueChanged<SmartPriorityMode> onModeSelected;
  final AppColors colors;

  const SmartPriorityModeGrid({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SmartPriorityModeCard(
            title: 'USER LIST',
            icon: Icons.person_outline,
            mode: SmartPriorityMode.userPriority,
            accentColor: colors.performance,
            colors: colors,
            isSelected: currentMode == SmartPriorityMode.userPriority,
            onSelected: onModeSelected,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: SmartPriorityModeCard(
            title: 'REAL-TIME',
            icon: Icons.show_chart,
            mode: SmartPriorityMode.realtime,
            accentColor: colors.balanced,
            colors: colors,
            isSelected: currentMode == SmartPriorityMode.realtime,
            onSelected: onModeSelected,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: SmartPriorityModeCard(
            title: 'SMART AI',
            icon: Icons.auto_awesome,
            mode: SmartPriorityMode.smartPriority,
            accentColor: colors.performance,
            colors: colors,
            isSelected: currentMode == SmartPriorityMode.smartPriority,
            onSelected: onModeSelected,
          ),
        ),
      ],
    );
  }
}