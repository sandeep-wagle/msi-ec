import 'package:flutter/material.dart';

class ResourceMetric extends StatelessWidget {
  final String label;
  final String val;
  final Color color;
  const ResourceMetric({
    super.key,
    required this.label,
    required this.val,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Colors.white24,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
