import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/screens/smart_priority/smart_priority_models.dart';

class AppTile extends StatelessWidget {
  final AppEntryData app;
  final Widget trailing;
  final bool isPriority;

  const AppTile({
    super.key,
    required this.app,
    required this.trailing,
    this.isPriority = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isPriority ? colors.glassBg : Colors.transparent,
        borderRadius: AppRadius.smAll,
        border: Border.all(
          color: isPriority
              ? colors.performance.withValues(alpha: 0.2)
              : colors.border.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: app.color.withValues(alpha: 0.1),
              borderRadius: AppRadius.xsAll,
            ),
            child: Icon(app.icon, size: 16, color: app.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              app.name.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}