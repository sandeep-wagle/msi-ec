import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class FloatingActionMenu extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onAddPassword;
  final VoidCallback onAddFile;
  final VoidCallback onAddNote;

  const FloatingActionMenu({
    super.key,
    required this.colors,
    required this.onAddPassword,
    required this.onAddFile,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: AppSpacing.xxxl,
      right: AppSpacing.xxxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _FabActionItem(
            icon: Icons.key_rounded,
            label: 'PASS',
            onTap: onAddPassword,
            colors: colors,
          ),
          const SizedBox(height: 12),
          _FabActionItem(
            icon: Icons.file_present_rounded,
            label: 'FILE',
            onTap: onAddFile,
            colors: colors,
          ),
          const SizedBox(height: 12),
          _FabActionItem(
            icon: Icons.note_add_rounded,
            label: 'NOTE',
            onTap: onAddNote,
            colors: colors,
            primary: true,
          ),
        ],
      ),
    );
  }
}

class _FabActionItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppColors colors;
  final bool primary;

  const _FabActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colors,
    this.primary = false,
  });

  @override
  State<_FabActionItem> createState() => _FabActionItemState();
}

class _FabActionItemState extends State<_FabActionItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.colors.glassBg.withValues(alpha: 0.9)
                : widget.colors.glassBg.withValues(alpha: 0.6),
            borderRadius: AppRadius.smAll,
            border: Border.all(color: widget.colors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.primary
                    ? widget.colors.superBattery
                    : widget.colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: widget.colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}