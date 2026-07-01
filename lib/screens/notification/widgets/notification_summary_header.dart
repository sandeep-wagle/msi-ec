import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/widgets/glass_container.dart';

class NotificationSummaryHeader extends StatelessWidget {
  final SystemInfo info;
  final int unreadCount;
  final AppColors colors;

  const NotificationSummaryHeader({
    super.key,
    required this.info,
    required this.unreadCount,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Row(
          children: [
            _SummaryItem(
              'ACTIVE_ALERTS',
              unreadCount.toString().padLeft(2, '0'),
              colors.performance,
            ),
            _SummaryDivider(colors),
            _SummaryItem(
              'HEALTH_INDEX',
              '${info.ssdHealth.toInt()}%',
              colors.success,
            ),
            _SummaryDivider(colors),
            _SummaryItem('UPTIME_STABLE', '99.9%', colors.balanced),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String val;
  final Color color;

  const _SummaryItem(this.label, this.val, this.color);

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

class _SummaryDivider extends StatelessWidget {
  final AppColors colors;
  const _SummaryDivider(this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: colors.border.withValues(alpha: 0.1),
    );
  }
}
