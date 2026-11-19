import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';

class FeatureToggleRow extends StatelessWidget {
  final String label;
  final String description;
  final bool isOn;
  final Color color;
  final ValueChanged<bool> onChanged;

  const FeatureToggleRow({
    super.key,
    required this.label,
    required this.description,
    required this.isOn,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 14,
            color: isOn ? color : colors.textTertiary.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isOn ? colors.textPrimary : colors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  description.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOn,
            activeTrackColor: color.withValues(alpha: 0.3),
            activeThumbColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}