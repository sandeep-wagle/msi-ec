import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'package:msi_controller/services/persistence_service.dart';
import 'package:msi_controller/core/widgets/app_button.dart';
import 'package:msi_controller/screens/notification/widgets/notification_summary_header_view.dart';
import 'package:msi_controller/screens/notification/widgets/notification_alert_list.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  final MsiRepository _repository = getIt<MsiRepository>();
  final PersistenceService _storage = getIt<PersistenceService>();

  final List<AlertEntry> _alerts = [
    AlertEntry(
      id: '01',
      title: 'THERMAL_THRESHOLD_EXCEEDED',
      description:
          'CPU package temperature reached 92°C during high-load task.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      severity: 0.9,
    ),
    AlertEntry(
      id: '02',
      title: 'BATTERY_HEALTH_OPTIMIZED',
      description:
          'Charge limit protocol enforced at 80% to maximize cell lifespan.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      severity: 0.2,
    ),
    AlertEntry(
      id: '03',
      title: 'GPU_MODE_SYNCHRONIZED',
      description: 'Discrete graphics engine engaged for SteamVR.service.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      severity: 0.4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadReadState();
  }

  void _loadReadState() {
    final readIds = _storage.loadReadIds();
    setState(() {
      for (var alert in _alerts) {
        if (readIds.contains(alert.id)) alert.isRead = true;
      }
    });
  }

  void _markAsRead(String id) {
    setState(() {
      final alert = _alerts.firstWhere((a) => a.id == id);
      alert.isRead = true;
      final readIds = _alerts.where((a) => a.isRead).map((a) => a.id).toSet();
      _storage.saveReadIds(readIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;
    final unreadCount = _alerts.where((a) => !a.isRead).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Incident Logs',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          AppButton(
            text: 'CLEAR_ALL',
            onPressed: () {
              setState(() {
                for (var a in _alerts) {
                  a.isRead = true;
                }
                _storage.saveReadIds(_alerts.map((a) => a.id).toSet());
              });
            },
            isElevated: false,
            isPrimary: false,
            foregroundColor: colors.performance,
            fontSize: 10,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: StreamBuilder<SystemInfo>(
        stream: _repository.systemInfoStream,
        initialData: _repository.lastSystemInfo,
        builder: (context, snapshot) {
          final info = snapshot.data;
          return Column(
            children: [
              if (info != null)
                NotificationSummaryHeaderView(
                  unreadCount: unreadCount,
                  ssdHealth: info.ssdHealth.toInt(),
                ),
              Expanded(
                child: NotificationAlertList(
                  alerts: _alerts,
                  onMarkAsRead: _markAsRead,
                  onMarkAllRead: (_) {},
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
