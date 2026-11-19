import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';

class SectionTitleWidget extends StatelessWidget {
  final String title;
  final AppColors colors;

  const SectionTitleWidget({
    super.key,
    required this.title,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: colors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}
