import 'package:flutter/material.dart';
import 'package:msi_controller/screens/mystic_light/widgets/mystic_light_color_slider.dart';

class MysticLightColorControls extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const MysticLightColorControls({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  MysticLightColorSlider(
                    label: 'R',
                    value: color.r,
                    color: Colors.red,
                    onChanged: (v) => _updateColor(r: v),
                  ),
                  MysticLightColorSlider(
                    label: 'G',
                    value: color.g,
                    color: Colors.green,
                    onChanged: (v) => _updateColor(g: v),
                  ),
                  MysticLightColorSlider(
                    label: 'B',
                    value: color.b,
                    color: Colors.blue,
                    onChanged: (v) => _updateColor(b: v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateColor({double? r, double? g, double? b}) {
    onColorChanged(Color.fromARGB(
      255,
      ((r ?? color.r) * 255).round(),
      ((g ?? color.g) * 255).round(),
      ((b ?? color.b) * 255).round(),
    ));
  }
}