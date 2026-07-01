import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';

class ProceduralRadar extends StatelessWidget {
  final double progress;
  final AnimationController rotateController;
  final Animation<double> scanAnimation;

  const ProceduralRadar({
    super.key,
    required this.progress,
    required this.rotateController,
    required this.scanAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.performance.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.performance.withValues(alpha: 0.05),
                  width: 2,
                ),
              ),
            ),
          ),
          RotationTransition(
            turns: rotateController,
            child: CustomPaint(
              size: const Size(140, 140),
              painter: _HudPainter(colors.performance),
            ),
          ),
          AnimatedBuilder(
            animation: scanAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(140, 140),
                painter: _ScanBeamPainter(
                  colors.performance,
                  scanAnimation.value,
                ),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  letterSpacing: -1,
                ),
              ),
              const Text(
                'LINKED',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HudPainter extends CustomPainter {
  final Color color;
  _HudPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      3.14159 / 2,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159,
      3.14159 / 2,
      false,
      paint,
    );

    paint.strokeWidth = 4;
    for (var i = 0; i < 4; i++) {
      final angle = i * 3.14159 / 2;
      canvas.drawLine(
        Offset(
          center.dx + (radius - 5) * _cos(angle),
          center.dy + (radius - 5) * _sin(angle),
        ),
        Offset(
          center.dx + radius * _cos(angle),
          center.dy + radius * _sin(angle),
        ),
        paint,
      );
    }
  }

  double _cos(double angle) {
    if (angle < 3.14159 / 2) return 1;
    if (angle < 3.14159) return 0;
    if (angle < 3 * 3.14159 / 2) return -1;
    return 0;
  }

  double _sin(double angle) {
    if (angle < 3.14159) return 1;
    return 0;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanBeamPainter extends CustomPainter {
  final Color color;
  final double value;
  _ScanBeamPainter(this.color, this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanBeamPainter oldDelegate) => false;
}
