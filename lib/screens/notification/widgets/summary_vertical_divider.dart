import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';

class SummaryVerticalDivider extends StatelessWidget {
  final AppColors colors;
  const SummaryVerticalDivider({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: colors.border.withValues(alpha: 0.1),
    );
  }
}
