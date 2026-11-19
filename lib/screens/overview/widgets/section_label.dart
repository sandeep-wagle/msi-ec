import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';

class SectionLabel extends StatelessWidget {
  final String title;
  const SectionLabel({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: colors.textSecondary,
        letterSpacing: 2.0,
      ),
    );
  }
}
