import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';

class DiagnosisProGauge extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;
  final AppColors colors;
  final String? customValue;
  final String suffix;

  const DiagnosisProGauge({
    super.key,
    required this.label,
    required this.percent,
    required this.color,
    required this.colors,
    this.customValue,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                strokeWidth: 6,
                backgroundColor: colors.gaugeTrack,
                color: color,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  customValue ?? '${(percent * 100).toInt()}$suffix',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                    fontFamily: 'monospace',
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: colors.textTertiary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}