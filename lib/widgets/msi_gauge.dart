import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class MsiGauge extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final String unit;
  final Color color;
  final int? temperature;

  const MsiGauge({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.unit,
    required this.color,
    this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    final percent = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    final colors = context.extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _GaugePainter(
                      percent: percent,
                      color: color,
                      trackColor: colors.gaugeTrack,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontFamily: 'monospace',
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (temperature != null) ...[
          const SizedBox(height: 10),
          _buildTempBadge(temperature!, colors),
        ],
      ],
    );
  }

  Widget _buildTempBadge(int temp, AppColors colors) {
    final tempColor = temp < 50
        ? colors.tempCool
        : temp < 70
            ? colors.tempWarm
            : colors.tempHot;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tempColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tempColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.thermostat, size: 13, color: tempColor),
          const SizedBox(width: 4),
          Text(
            '$temp°C',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tempColor,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color trackColor;

  _GaugePainter({
    required this.percent,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * 3.1415927 * percent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415927 / 2,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.percent != percent;
}
