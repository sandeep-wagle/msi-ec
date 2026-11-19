import 'package:flutter/material.dart';

class HardwareMonitorGaugeCard extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final String unit;
  final List<Color> colors;
  final int? temperature;

  const HardwareMonitorGaugeCard({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.unit,
    required this.colors,
    this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    final percent = max > 0 ? value / max : 0.0;
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 10,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                      color: colors.isNotEmpty ? colors.first : Colors.blue,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$value',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (temperature != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getTempBgColor(temperature!).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getTempBgColor(temperature!).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.thermostat,
                      size: 14,
                      color: _getTempBgColor(temperature!),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$temperature°C',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getTempBgColor(temperature!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getTempBgColor(int temp) {
    if (temp < 50) return Colors.green;
    if (temp < 70) return Colors.orange;
    return Colors.red;
  }
}