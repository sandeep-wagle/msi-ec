import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class MysticLightApplyButton extends StatelessWidget {
  final AppColors colors;

  const MysticLightApplyButton({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        color: colors.performance,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: AppRadius.mdAll,
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sync_alt, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'SYNC SETTINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
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
