import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/core/ui/widgets/app_tile.dart';
import 'package:msi_controller/screens/smart_priority/smart_priority_models.dart';

class SmartPriorityPriorityQueue extends StatelessWidget {
  final List<AppEntryData> apps;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<AppEntryData> onRemove;
  final AppColors colors;

  const SmartPriorityPriorityQueue({
    super.key,
    required this.apps,
    required this.onReorder,
    required this.onRemove,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRIORITY QUEUE',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: colors.performance,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 400,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.performance.withValues(alpha: 0.05),
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: colors.performance.withValues(alpha: 0.1),
            ),
          ),
          child: apps.isEmpty
              ? Center(
                  child: Text(
                    'EMPTY QUEUE',
                    style: TextStyle(
                      fontSize: 9,
                      color: colors.textTertiary.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  itemCount: apps.length,
                  onReorder: onReorder,
                  itemBuilder: (_, i) {
                    final app = apps[i];
                    return AppTile(
                      key: ValueKey(app.name),
                      app: app,
                      isPriority: true,
                      trailing: IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline_rounded,
                          size: 16,
                          color: colors.textTertiary.withValues(alpha: 0.5),
                        ),
                        onPressed: () => onRemove(app),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}