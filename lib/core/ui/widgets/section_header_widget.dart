import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class SectionHeaderWidget extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onActionTap;
  final Widget? trailing;

  const SectionHeaderWidget({
    super.key,
    required this.title,
    this.icon,
    this.accentColor,
    this.onActionTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final color = accentColor ?? colors.textPrimary;

    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.xsAll,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: colors.textPrimary,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ] else if (onActionTap != null) ...[
          const Spacer(),
          IconButton(
            icon: Icon(Icons.more_horiz_rounded, color: colors.textTertiary),
            onPressed: onActionTap,
          ),
        ],
      ],
    );
  }
}