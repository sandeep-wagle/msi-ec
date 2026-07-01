import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class LanDivider extends StatelessWidget {
  final AppColors colors;

  const LanDivider({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      color: colors.border.withValues(alpha: 0.05),
    );
  }
}
