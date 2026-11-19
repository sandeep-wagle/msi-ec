import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/screens/notification/widgets/summary_item.dart';
import 'package:msi_controller/screens/notification/widgets/summary_vertical_divider.dart';

class NotificationSummaryHeaderView extends StatelessWidget {
  final int unreadCount;
  final int ssdHealth;
  const NotificationSummaryHeaderView({
    super.key,
    required this.unreadCount,
    required this.ssdHealth,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Row(
          children: [
            SummaryItem(
              label: 'ACTIVE_ALERTS',
              val: unreadCount.toString().padLeft(2, '0'),
              color: colors.performance,
            ),
            SummaryVerticalDivider(colors: colors),
            SummaryItem(
              label: 'HEALTH_INDEX',
              val: '${ssdHealth.toInt()}%',
              color: colors.success,
            ),
            SummaryVerticalDivider(colors: colors),
            SummaryItem(
              label: 'UPTIME_STABLE',
              val: '99.9%',
              color: colors.balanced,
            ),
          ],
        ),
      ),
    );
  }
}
