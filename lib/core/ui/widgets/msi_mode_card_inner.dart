import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class MsiModeCardInner extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool selected;
  final String? badge;
  final bool glass;

  const MsiModeCardInner({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.selected,
    this.badge,
    this.glass = true,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (badge != null)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xxs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: AppRadius.xsAll,
            ),
            child: Text(
              badge!,
              style: TextStyle(
                fontSize: AppTypography.labelSmall.fontSize,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        Icon(
          icon,
          size: 32,
          color: selected ? color : _getTextTertiary(context),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          title,
          style: TextStyle(
            fontSize: AppTypography.bodySmall.fontSize,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? color : _getTextSecondary(context),
          ),
        ),
      ],
    );

    if (!glass) {
      return AnimatedContainer(
        duration: AppDurations.normal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.1)
              : _getCardBackground(context),
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: selected ? color : _getBorder(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: inner,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: 0.15)
            : _getCardBackground(context),
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: selected ? color : _getBorder(context),
          width: selected ? 2 : 1,
        ),
      ),
      child: inner,
    );
  }

  Color _getTextTertiary(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!.textTertiary;
  }

  Color _getTextSecondary(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!.textSecondary;
  }

  Color _getCardBackground(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!.cardBackground;
  }

  Color _getBorder(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!.border;
  }
}