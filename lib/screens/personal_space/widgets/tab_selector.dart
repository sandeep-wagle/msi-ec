import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class TabSelector extends StatelessWidget {
  final List<String> tabs;
  final String activeTab;
  final AppColors colors;
  final ValueChanged<String> onTabChanged;

  const TabSelector({
    super.key,
    required this.tabs,
    required this.activeTab,
    required this.colors,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = activeTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(tab),
              child: AnimatedContainer(
                duration: AppDurations.fast,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.superBattery.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: AppRadius.pillAll,
                ),
                child: Center(
                  child: Text(
                    tab.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? colors.superBattery : Colors.white24,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
