import 'package:flutter/material.dart';

class UserScenarioTelemetryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const UserScenarioTelemetryItem({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
