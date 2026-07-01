import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class MysticLightBrightnessControl extends StatelessWidget {
  final double brightness;
  final ValueChanged<double> onBrightnessChanged;

  const MysticLightBrightnessControl({
    super.key,
    required this.brightness,
    required this.onBrightnessChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${(brightness * 100).round()}%',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Slider(
          value: brightness,
          onChanged: onBrightnessChanged,
          activeColor: colors.performance,
        ),
      ],
    );
  }
}