import 'package:flutter/material.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class PremiumToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const PremiumToggleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}