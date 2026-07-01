import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/widgets/glass_container.dart';

class ScenarioModeCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final bool isApplying;
  final VoidCallback? onTap;

  const ScenarioModeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    this.isApplying = false,
    this.onTap,
  });

  @override
  State<ScenarioModeCard> createState() => _ScenarioModeCardState();
}

class _ScenarioModeCardState extends State<ScenarioModeCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovering ? 1.02 : 1.0,
          duration: AppDurations.fast,
          curve: Curves.easeOut,
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      color: widget.selected
                          ? colors.performance
                          : colors.textSecondary,
                      size: 38,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.selected
                            ? colors.textPrimary
                            : colors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (widget.selected) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.performance,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.isApplying)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}