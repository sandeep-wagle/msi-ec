import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/core/ui/widgets/app_tile.dart';
import 'package:msi_controller/screens/smart_priority/smart_priority_models.dart';

class SmartPriorityAppPool extends StatelessWidget {
  final List<AppEntryData> apps;
  final ValueChanged<AppEntryData> onAddToPriority;
  final AppColors colors;

  const SmartPriorityAppPool({
    super.key,
    required this.apps,
    required this.onAddToPriority,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AVAILABLE PROTOCOLS',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: colors.textTertiary.withValues(alpha: 0.5),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 400,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.glassBg.withValues(alpha: 0.3),
            borderRadius: AppRadius.mdAll,
          ),
          child: ListView.builder(
            itemCount: apps.length,
            itemBuilder: (_, i) {
              final app = apps[i];
              return AppTile(
                app: app,
                trailing: IconButton(
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    size: 16,
                    color: colors.textTertiary.withValues(alpha: 0.5),
                  ),
                  onPressed: () => onAddToPriority(app),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}