import 'package:flutter/material.dart';

enum NoticeCategory { all, system, app }

class _NoticeItem {
  final String id;
  final String title;
  final String description;
  final NoticeCategory category;
  final IconData icon;
  final Color iconColor;
  final DateTime timestamp;
  final String? actionLabel;

  const _NoticeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.iconColor,
    required this.timestamp,
    this.actionLabel,
  });
}

DateTime _now({int minutes = 0, int hours = 0, int days = 0}) {
  return DateTime.now().subtract(Duration(minutes: minutes, hours: hours, days: days));
}

final _sampleNotices = [
  _NoticeItem(
    id: 'n1',
    title: 'CPU temperature high',
    description: 'CPU has reached 92°C. Consider switching to Cooler Boost or adjusting fan profile.',
    category: NoticeCategory.system,
    icon: Icons.thermostat,
    iconColor: const Color(0xFFEF4444),
    timestamp: _now(minutes: 3),
    actionLabel: 'Enable Cooler Boost',
  ),
  _NoticeItem(
    id: 'n2',
    title: 'Battery charged to limit',
    description: 'Battery has reached the 80% charge limit and is now bypassing.',
    category: NoticeCategory.system,
    icon: Icons.battery_charging_full,
    iconColor: const Color(0xFF22C55E),
    timestamp: _now(minutes: 15),
  ),
  _NoticeItem(
    id: 'n3',
    title: 'Fan 2 running at max',
    description: 'Fan 2 (CPU) is at 5400 RPM under sustained load. Normal under heavy usage.',
    category: NoticeCategory.system,
    icon: Icons.air,
    iconColor: const Color(0xFFF59E0B),
    timestamp: _now(hours: 1),
  ),
  _NoticeItem(
    id: 'n4',
    title: 'Driver updated',
    description: 'msi-ec driver v6.5 has been applied. New performance modes available.',
    category: NoticeCategory.app,
    icon: Icons.system_update,
    iconColor: const Color(0xFF3B82F6),
    timestamp: _now(hours: 2),
    actionLabel: 'View Changes',
  ),
  _NoticeItem(
    id: 'n5',
    title: 'Sound Tune profile switched',
    description: 'Profile changed to "Voice Call" — AI noise cancellation active.',
    category: NoticeCategory.app,
    icon: Icons.graphic_eq,
    iconColor: const Color(0xFF8B5CF6),
    timestamp: _now(hours: 4),
  ),
  _NoticeItem(
    id: 'n6',
    title: 'Diagnostic complete',
    description: 'System health check passed. No issues detected in RAM, storage, or thermal sensors.',
    category: NoticeCategory.app,
    icon: Icons.health_and_safety,
    iconColor: const Color(0xFF22C55E),
    timestamp: _now(hours: 6),
  ),
  _NoticeItem(
    id: 'n7',
    title: 'Performance mode: Balanced',
    description: 'System switched to Balanced mode. Fan curve adjusted for quiet operation.',
    category: NoticeCategory.system,
    icon: Icons.balance,
    iconColor: const Color(0xFF3B82F6),
    timestamp: _now(hours: 8),
  ),
  _NoticeItem(
    id: 'n8',
    title: 'Mystic Light sync lost',
    description: 'OpenRGB connection dropped. RGB may be out of sync until reconnected.',
    category: NoticeCategory.system,
    icon: Icons.lightbulb_outline,
    iconColor: const Color(0xFFEF4444),
    timestamp: _now(hours: 12),
    actionLabel: 'Reconnect',
  ),
  _NoticeItem(
    id: 'n9',
    title: 'Feature update available',
    description: 'LAN Manager v4.0 is ready. New traffic shaping and per-app bandwidth controls.',
    category: NoticeCategory.app,
    icon: Icons.network_check,
    iconColor: const Color(0xFF06B6D4),
    timestamp: _now(days: 1),
    actionLabel: 'Update',
  ),
  _NoticeItem(
    id: 'n10',
    title: 'Gaming Mode saved preset',
    description: 'Preset "Cyberpunk 2077 — Ultra" applied. GPU overclock + max fan profile loaded.',
    category: NoticeCategory.app,
    icon: Icons.gamepad,
    iconColor: const Color(0xFFF97316),
    timestamp: _now(days: 2),
  ),
];

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with AutomaticKeepAliveClientMixin {
  NoticeCategory _selected = NoticeCategory.all;
  final Set<String> _readIds = {};

  @override
  bool get wantKeepAlive => true;

  List<_NoticeItem> get _filtered {
    if (_selected == NoticeCategory.all) return _sampleNotices;
    return _sampleNotices.where((n) => n.category == _selected).toList();
  }

  int get _unreadCount => _sampleNotices.where((n) => !_readIds.contains(n.id)).length;

  void _markRead(String id) {
    setState(() => _readIds.add(id));
  }

  void _markAllRead() {
    setState(() => _readIds.addAll(_sampleNotices.map((n) => n.id)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notices = _filtered;

    return Column(
      children: [
        _buildHeader(context),
        _buildCategoryChips(isDark),
        const Divider(height: 1),
        Expanded(
          child: notices.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    final isRead = _readIds.contains(notice.id);
                    return _NoticeCard(
                      notice: notice,
                      isRead: isRead,
                      onTap: () => _markRead(notice.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined, size: 22),
          const SizedBox(width: 10),
          Text(
            'Notification Center',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Mark all read', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD32F2F),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    final categories = <(NoticeCategory, String, IconData)>[
      (NoticeCategory.all, 'All', Icons.all_inclusive),
      (NoticeCategory.system, 'System Notices', Icons.warning_amber_rounded),
      (NoticeCategory.app, 'App Notifications', Icons.info_outline),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((c) {
          final isSelected = _selected == c.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              avatar: Icon(c.$3, size: 16),
              label: Text(c.$2, style: const TextStyle(fontSize: 12)),
              onSelected: (_) => setState(() => _selected = c.$1),
              selectedColor: const Color(0xFFD32F2F).withValues(alpha: 0.12),
              checkmarkColor: const Color(0xFFD32F2F),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFFD32F2F) : null,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined, size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'All clear',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No notifications in this category',
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final _NoticeItem notice;
  final bool isRead;
  final VoidCallback onTap;

  const _NoticeCard({
    required this.notice,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isRead
            ? Colors.transparent
            : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFD32F2F).withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: notice.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(notice.icon, size: 18, color: notice.iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notice.title,
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD32F2F),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notice.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _formatTime(notice.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                          if (notice.actionLabel != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                notice.actionLabel!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFD32F2F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
