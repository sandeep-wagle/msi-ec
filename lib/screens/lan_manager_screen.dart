import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'package:msi_controller/services/persistence_service.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/screens/lan_manager/widgets/lan_metric_card.dart';
import 'package:msi_controller/screens/lan_manager/widgets/lan_divider.dart';
import 'package:msi_controller/screens/lan_manager/widgets/info_row.dart';
import 'package:msi_controller/screens/lan_manager/widgets/tool_button.dart';

class LanManagerScreen extends StatefulWidget {
  const LanManagerScreen({super.key});

  @override
  State<LanManagerScreen> createState() => _LanManagerScreenState();
}

class _LanManagerScreenState extends State<LanManagerScreen>
    with SingleTickerProviderStateMixin {
  final PersistenceService _storage = GetIt.I<PersistenceService>();
  Timer? _refreshTimer;
  bool _aiPriorityEnabled = true;
  Map<String, dynamic> _networkStats = {};

  @override
  void initState() {
    super.initState();
    _aiPriorityEnabled = _storage.loadLanAiPriority();
    _refreshNetworkStats();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _refreshNetworkStats();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshNetworkStats() async {
    if (mounted) {
      setState(() {
        _networkStats = {
          'downloadSpeed': '${(10 + (DateTime.now().second % 50))} Mbps',
          'uploadSpeed': '${(5 + (DateTime.now().second % 20))} Mbps',
          'ping': '${20 + (DateTime.now().millisecond % 30)} ms',
          'packetsSent': 125000 + DateTime.now().second * 100,
          'packetsReceived': 98000 + DateTime.now().second * 80,
          'connectionType': 'Ethernet',
          'ipAddress': '192.168.1.100',
          'gateway': '192.168.1.1',
          'dns': '8.8.8.8, 8.8.4.4',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'LAN Manager',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxxl,
          AppSpacing.md,
          AppSpacing.xxxl,
          AppSpacing.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.balanced,
                    borderRadius: AppRadius.xsAll,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Text(
                  'Network Optimization',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Icon(Icons.network_check, color: colors.balanced, size: 24),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Real-time traffic analysis and low-latency network optimization.',
              style: TextStyle(color: colors.textTertiary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // AI Priority Control
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.balanced.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: colors.balanced,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI LAN PRIORITY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Automatically prioritizes gaming and streaming traffic to ensure minimum jitter.',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Switch(
                    value: _aiPriorityEnabled,
                    activeThumbColor: colors.balanced,
                    onChanged: (value) async {
                      setState(() => _aiPriorityEnabled = value);
                      _storage.saveLanAiPriority(value);
                      final repository = GetIt.instance<MsiRepository>();
                      await repository.setAiLanPriority(value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Speed Stats
            Row(
              children: [
                Expanded(
                  child: LanMetricCard(
                    label: 'DOWNLOAD',
                    value: _networkStats['downloadSpeed'] ?? '0 Mbps',
                    icon: Icons.download_rounded,
                    color: colors.balanced,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: LanMetricCard(
                    label: 'UPLOAD',
                    value: _networkStats['uploadSpeed'] ?? '0 Mbps',
                    icon: Icons.upload_rounded,
                    color: colors.textSecondary,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: LanMetricCard(
                    label: 'LATENCY',
                    value: _networkStats['ping'] ?? '0 ms',
                    icon: Icons.timer_outlined,
                    color: colors.warning,
                    colors: colors,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Network Details & Tools
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NETWORK INTERFACE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          children: [
                            InfoRow(
                              label: 'Connection',
                              value: _networkStats['connectionType'] ?? '--',
                            ),
                            LanDivider(colors: colors),
                            InfoRow(
                              label: 'IP Address',
                              value: _networkStats['ipAddress'] ?? '--',
                            ),
                            LanDivider(colors: colors),
                            InfoRow(
                              label: 'Gateway',
                              value: _networkStats['gateway'] ?? '--',
                            ),
                            LanDivider(colors: colors),
                            InfoRow(
                              label: 'DNS',
                              value: _networkStats['dns'] ?? '--',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUICK TOOLS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ToolButton(
                        label: 'Diagnostic Ping',
                        icon: Icons.radar_outlined,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ToolButton(
                        label: 'Speed Analysis',
                        icon: Icons.speed_outlined,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ToolButton(
                        label: 'Route Optimization',
                        icon: Icons.alt_route_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
