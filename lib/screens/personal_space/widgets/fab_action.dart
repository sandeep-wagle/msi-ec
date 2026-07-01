import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class FabAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppColors colors;
  final bool primary;

  const FabAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colors,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: primary ? colors.performance : Colors.black,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: primary ? colors.performance : Colors.white10,
          ),
          boxShadow: [
            if (primary)
              BoxShadow(
                color: colors.performance.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
