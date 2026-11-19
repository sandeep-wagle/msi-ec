import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/widgets/glass_container.dart';

class SmartPriorityAiHud extends StatelessWidget {
  final AppColors colors;

  const SmartPriorityAiHud({
    super.key,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.psychology_outlined, size: 48, color: colors.performance),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'AI PREDICTIVE ENGINE',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Analyzing hardware signatures to dynamically scale thread priority for active creative processes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          _ResourceMetric(
            label: 'CORE_BIAS',
            val: 'HIGH',
            color: colors.performance,
          ),
          const SizedBox(height: AppSpacing.md),
          _ResourceMetric(
            label: 'VRAM_LINK',
            val: 'READY',
            color: colors.balanced,
          ),
          const SizedBox(height: AppSpacing.md),
          _ResourceMetric(
            label: 'IO_LATENCY',
            val: '0.4ms',
            color: colors.success,
          ),
        ],
      ),
    );
  }
}

class _ResourceMetric extends StatelessWidget {
  final String label;
  final String val;
  final Color color;

  const _ResourceMetric({
    required this.label,
    required this.val,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.7),
            letterSpacing: 1.0,
          ),
        ),
        const Spacer(),
        Text(
          val,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}