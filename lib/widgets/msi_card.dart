import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/core/ui/widgets/msi_mode_card_inner.dart';
import 'glass_container.dart';

class MsiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final bool glass;

  const MsiCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.glass = true,
  });

  @override
  Widget build(BuildContext context) {
    if (glass) {
      return GlassCard(padding: padding, height: height, child: child);
    }
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

class MsiSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const MsiSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final header = Row(
      mainAxisAlignment: trailing != null
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFEB1D24),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: AppTypography.labelSmall.fontSize,
                    color: colors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      child: header,
    );
  }
}

class MsiInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  const MsiInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.textTertiary),
            const SizedBox(width: AppSpacing.xxxs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.bodySmall.fontSize,
              color: colors.textTertiary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: valueColor ?? colors.textPrimary,
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
  final Color color;
  final IconData icon;

  const MsiProgressCard({
    super.key,
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.bodySmall.fontSize,
                color: colors.textTertiary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                color: color,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _AnimatedProgressBar(progress: progress.clamp(0.0, 1.0), color: color),
      ],
    );

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: inner,
    );
  }
}

class _AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final Color color;

  const _AnimatedProgressBar({required this.progress, required this.color});

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.verySlow,
    );
    _anim = CurvedAnimation(parent: _controller, curve: const CurveSpring());
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: AppRadius.xsAll,
          child: LinearProgressIndicator(
            value: (_anim.value * widget.progress).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: colors.gaugeTrack,
            valueColor: AlwaysStoppedAnimation<Color>(widget.color),
          ),
        );
      },
    );
  }
}

class MsiModeCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final int animationDelay;
  final bool glass;

  const MsiModeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.badge,
    this.animationDelay = 0,
    this.glass = true,
  });

  @override
  State<MsiModeCard> createState() => _MsiModeCardState();
}

class _MsiModeCardState extends State<MsiModeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    _entryAnim = CurvedAnimation(
      parent: _entryController,
      curve: const CurveSpring(),
    );
    if (widget.animationDelay > 0) {
      Future.delayed(Duration(milliseconds: widget.animationDelay), () {
        if (mounted) _entryController.forward();
      });
    } else {
      _entryController.forward();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entryAnim,
      builder: (context, _) {
        return Transform.scale(
          scale: 0.92 + (_entryAnim.value * 0.08),
          child: Opacity(
            opacity: _entryAnim.value,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              onTap: widget.onTap,
              child: AnimatedScale(
                scale: _pressed ? 0.96 : 1.0,
                duration: AppDurations.fast,
                curve: Curves.easeOut,
                child: MsiModeCardInner(
                  title: widget.title,
                  icon: widget.icon,
                  color: widget.color,
                  selected: widget.selected,
                  badge: widget.badge,
                  glass: widget.glass,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CurveSpring extends Curve {
  const CurveSpring();

  @override
  double transformInternal(double t) {
    const s = 1.70158;
    return t * t * ((s + 1) * t - s);
  }
}
