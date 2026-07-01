import 'package:flutter/material.dart';

class SidebarRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool isAlt;

  const SidebarRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.isAlt = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isAlt
          ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
          : Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SsdRowWidget extends StatelessWidget {
  final double diskUsage;

  const SsdRowWidget({
    super.key,
    required this.diskUsage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SSD',
                style: TextStyle(fontSize: 13),
              ),
              Text(
                '${(diskUsage * 100).toInt()}% Full',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: diskUsage.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }
}