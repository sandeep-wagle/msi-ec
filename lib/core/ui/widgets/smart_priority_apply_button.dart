import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/widgets/app_button.dart';

class SmartPriorityApplyButton extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onPressed;

  const SmartPriorityApplyButton({
    super.key,
    required this.colors,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: 'SYNC PRIORITY SETTINGS',
      onPressed: onPressed,
      backgroundColor: colors.performance,
      foregroundColor: Colors.white,
      isOval: false,
      width: double.infinity,
      height: 48,
    );
  }
}