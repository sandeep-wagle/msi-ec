import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/widgets/glass_container.dart';

class AlertList extends StatelessWidget {
  final List<_AlertData> alerts;
  final void Function(String id) onMarkAsRead;
  const AlertList({
    super.key,
    required this.alerts,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 48,
              color: colors.textTertiary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'SYSTEM_NOMINAL',
              style: TextStyle(
                color: Colors.white24,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 2.0,
              ),
            ),
            const Text(
              'NO UNREAD INCIDENTS DETECTED',
              style: TextStyle(color: Colors.white10, fontSize: 10),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      itemCount: alerts.length,
      itemBuilder: (context, i) {
        final alert = alerts[i];
        final severityColor = alert.severity > 0.8
            ? colors.performance
            : (alert.severity > 0.4 ? colors.warning : colors.success);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Opacity(
            opacity: alert.isRead ? 0.6 : 1.0,
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: InkWell(
                onTap: () => onMarkAsRead(alert.id),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: AppRadius.pillAll,
                        boxShadow: [
                          BoxShadow(
                            color: severityColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                alert.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: severityColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatTime(alert.timestamp),
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white24,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            alert.description,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          if (!alert.isRead) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: severityColor.withValues(alpha: 0.1),
                                borderRadius: AppRadius.xsAll,
                              ),
                              child: Text(
                                'NEW_INCIDENT',
                                style: TextStyle(
                                  color: severityColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'JUST_NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M_AGO';
    if (diff.inHours < 24) return '${diff.inHours}H_AGO';
    return '${diff.inDays}D_AGO';
  }
}

class _AlertData {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final double severity;
  bool isRead;
  _AlertData({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.severity,
  }) : isRead = false;
}
