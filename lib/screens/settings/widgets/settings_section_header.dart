import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final AppColors colors;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: colors.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }
}
