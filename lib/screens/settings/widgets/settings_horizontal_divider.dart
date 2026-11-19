import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';

class SettingsHorizontalDivider extends StatelessWidget {
  final AppColors colors;
  const SettingsHorizontalDivider({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: colors.border.withValues(alpha: 0.05));
  }
}
