import 'package:flutter/material.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class KeyboardBrightnessSlider extends StatelessWidget {
  final int value;
  final Color accentColor;
  final ValueChanged<int> onChanged;
  final ValueChanged<int>? onChangeEnd;

  const KeyboardBrightnessSlider({
    super.key,
    required this.value,
    required this.accentColor,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'KEYBOARD_LUMINANCE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            Text(
              'LVL_0$value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: accentColor,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            activeTrackColor: accentColor,
            thumbColor: accentColor,
            overlayColor: accentColor.withValues(alpha: 0.1),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 7,
            ),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 3,
            divisions: 3,
            onChanged: (v) => onChanged(value.round()),
            onChangeEnd: onChangeEnd != null
                ? (v) => onChangeEnd!(value.round())
                : null,
          ),
        ),
      ],
    );
  }
}