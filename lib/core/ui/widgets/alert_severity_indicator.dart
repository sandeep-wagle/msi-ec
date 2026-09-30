import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';

class AlertSeverityIndicator extends StatelessWidget {
  final double severity;
  final double height;
  final double width;

  const AlertSeverityIndicator({
    super.key,
    required this.severity,
    this.height = 40,
    this.width = 4,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final severityColor = severity > 0.8
        ? colors.performance
        : (severity > 0.4 ? colors.warning : colors.success);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: severityColor,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}