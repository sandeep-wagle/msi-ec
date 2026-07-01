import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/core/ui/widgets/smart_priority_ai_hud.dart';
import 'package:msi_controller/core/ui/widgets/smart_priority_app_list_header.dart';
import 'package:msi_controller/core/ui/widgets/smart_priority_app_pool.dart';
import 'package:msi_controller/core/ui/widgets/smart_priority_priority_queue.dart';
import 'package:msi_controller/core/ui/widgets/smart_priority_apply_button.dart';
import 'package:msi_controller/screens/smart_priority/smart_priority_models.dart';

class SmartPriorityMainConsole extends StatelessWidget {
  final SmartPriorityMode mode;
  final TextEditingController searchController;
  final List<AppEntryData> filteredApps;
  final List<AppEntryData> priorityApps;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AppEntryData> onAddToPriority;
  final ValueChanged<AppEntryData> onRemoveFromPriority;
  final void Function(int oldIndex, int newIndex) onReorderPriority;
  final VoidCallback onApply;
  final AppColors colors;

  const SmartPriorityMainConsole({
    super.key,
    required this.mode,
    required this.searchController,
    required this.filteredApps,
    required this.priorityApps,
    required this.onSearchChanged,
    required this.onAddToPriority,
    required this.onRemoveFromPriority,
    required this.onReorderPriority,
    required this.onApply,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mode == SmartPriorityMode.smartPriority)
          Expanded(flex: 2, child: SmartPriorityAiHud(colors: colors)),
        if (mode == SmartPriorityMode.smartPriority)
          const SizedBox(width: AppSpacing.xxxl),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmartPriorityAppListHeader(
                searchController: searchController,
                onSearchChanged: onSearchChanged,
                colors: colors,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SmartPriorityAppPool(
                      apps: filteredApps,
                      onAddToPriority: onAddToPriority,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: SmartPriorityPriorityQueue(
                      apps: priorityApps,
                      onReorder: onReorderPriority,
                      onRemove: onRemoveFromPriority,
                      colors: colors,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxl),
              SmartPriorityApplyButton(
                colors: colors,
                onPressed: onApply,
              ),
            ],
          ),
        ),
      ],
    );
  }
}