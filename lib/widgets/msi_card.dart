import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class MsiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const MsiCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.extension<AppColors>()!;
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

class MsiSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const MsiSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: context.extension<AppColors>()!.performance,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

class MsiInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool alt;

  const MsiInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.alt = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      color: alt ? colors.surfaceElevated : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFCBD5E1),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class MsiProgressCard extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color barColor;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool isLoading;

  const MsiProgressCard({
    super.key,
    required this.label,
    required this.value,
    required this.progress,
    required this.barColor,
    this.actionLabel = '',
    this.onAction,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: colors.gaugeTrack,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          if (actionLabel.isNotEmpty) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: isLoading ? null : onAction,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.performance,
                          ),
                        ),
                      )
                    else
                      const Icon(Icons.bolt, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MsiModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  const MsiModeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.12 : 0.08)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.5)
                : (isDark
                      ? const Color(0x1AFFFFFF)
                      : Colors.black.withValues(alpha: 0.08)),
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(icon, size: 36, color: selected ? color : null),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? color : const Color(0xFF475569),
                      width: selected ? 2 : 1.5,
                    ),
                    color: selected ? color : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? color : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
