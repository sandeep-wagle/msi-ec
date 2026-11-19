import 'package:flutter/material.dart';

class EffectControl extends StatelessWidget {
  final String label;
  final bool isEnabled;
  final double value;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double>? onSliderChanged;
  final double min;
  final double max;

  const EffectControl({
    super.key,
    required this.label,
    required this.isEnabled,
    required this.value,
    required this.onToggle,
    this.onSliderChanged,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Switch(value: isEnabled, onChanged: onToggle),
          ],
        ),
        if (isEnabled && onSliderChanged != null)
          Slider(
            value: value.isNaN ? min : value.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min) >= 10 ? 10 : null,
            label: value.isNaN
                ? min.toStringAsFixed(1)
                : value.toStringAsFixed(1),
            onChanged: onSliderChanged,
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}