import 'package:flutter/material.dart';
import '../sound_tune_theme.dart';

class NeuralHeadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Draw main circle
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.8, paint..strokeWidth = 0.5);

    // Draw "Neural" dots and links
    final points = [
      Offset(center.dx, center.dy - radius),
      Offset(center.dx + radius * 0.8, center.dy - radius * 0.4),
      Offset(center.dx + radius * 0.8, center.dy + radius * 0.4),
      Offset(center.dx, center.dy + radius),
      Offset(center.dx - radius * 0.8, center.dy + radius * 0.4),
      Offset(center.dx - radius * 0.8, center.dy - radius * 0.4),
    ];

    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3, paint..style = PaintingStyle.fill..color = kAccent);
      canvas.drawLine(center, points[i], paint..style = PaintingStyle.stroke..color = kAccent.withValues(alpha: 0.2));
      
      final nextPoint = points[(i + 1) % points.length];
      canvas.drawLine(points[i], nextPoint, paint..color = kAccent.withValues(alpha: 0.3));
    }

    // Person silhouette
    final headPaint = Paint()..color = kTextSub.withValues(alpha: 0.3)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy - radius * 0.1), radius * 0.25, headPaint);
    final path = Path()
      ..moveTo(center.dx - radius * 0.4, center.dy + radius * 0.4)
      ..quadraticBezierTo(center.dx, center.dy + radius * 0.2, center.dx + radius * 0.4, center.dy + radius * 0.4)
      ..lineTo(center.dx + radius * 0.5, center.dy + radius)
      ..lineTo(center.dx - radius * 0.5, center.dy + radius)
      ..close();
    canvas.drawPath(path, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WaveformPainter extends CustomPainter {
  final Color color;
  WaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final waves = [0.2, 0.5, 0.8, 0.6, 0.9, 0.7, 0.4, 0.6, 0.8, 0.5, 0.3];
    final spacing = size.width / (waves.length + 1);

    for (var i = 0; i < waves.length; i++) {
      final x = spacing * (i + 1);
      final h = size.height * waves[i];
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AtomicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kAccent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height / 2);
    
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * 1.047); // 60 degrees
      final rect = Rect.fromCenter(center: Offset.zero, width: size.width, height: size.height * 0.4);
      canvas.drawOval(rect, paint);
      
      final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width / 2, 0), 4, dotPaint);
      canvas.drawCircle(Offset(size.width / 2, 0), 8, dotPaint..color = kAccent.withValues(alpha: 0.3));
      
      canvas.restore();
    }
    
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
    canvas.drawCircle(center, 12, Paint()..color = kAccent.withValues(alpha: 0.2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
