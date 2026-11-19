import 'package:flutter/material.dart';

class SummaryItem extends StatelessWidget {
  final String label;
  final String val;
  final Color color;
  const SummaryItem({
    super.key,
    required this.label,
    required this.val,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Colors.white24,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
