import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../core/app_colors.dart';
import '../domain/repositories/msi_repository.dart';
import '../services/toast_service.dart';
import '../widgets/msi_card.dart';

class LanManagerScreen extends StatefulWidget {
  const LanManagerScreen({super.key});

  @override
  State<LanManagerScreen> createState() => _LanManagerScreenState();
}

class _LanManagerScreenState extends State<LanManagerScreen>
    with SingleTickerProviderStateMixin {
  Timer? _refreshTimer;
  bool _aiPriorityEnabled = true;
  Map<String, dynamic> _networkStats = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _refreshNetworkStats();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _refreshNetworkStats();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
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
    final colors = context.extension<AppColors>()!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('LAN Manager', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(width: 12),
                Icon(Icons.network_check, color: colors.performance, size: 26),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Monitor network traffic and connection quality.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 28),

            MsiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const MsiSectionHeader(title: 'Real-time Statistics'),
                      IconButton(
                        onPressed: _refreshNetworkStats,
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AI LAN Priority',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Prioritize gaming and streaming traffic',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _aiPriorityEnabled,
                          onChanged: (value) async {
                            setState(() => _aiPriorityEnabled = value);
                            final repository = GetIt.I<MsiRepository>();
                            await repository.setAiLanPriority(value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Download',
                          _networkStats['downloadSpeed'] ?? '0 Mbps',
                          Icons.download,
                          colors.performance,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Upload',
                          _networkStats['uploadSpeed'] ?? '0 Mbps',
                          Icons.upload,
                          colors.tempCool,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Ping',
                          _networkStats['ping'] ?? '0 ms',
                          Icons.timer,
                          colors.tempWarm,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            MsiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MsiSectionHeader(title: 'Network Information'),
                  const SizedBox(height: 16),
                  _buildInfoRow('Connection Type', _networkStats['connectionType'] ?? 'Unknown'),
                  _buildDivider(colors),
                  _buildInfoRow('IP Address', _networkStats['ipAddress'] ?? 'Not available'),
                  _buildDivider(colors),
                  _buildInfoRow('Gateway', _networkStats['gateway'] ?? 'Not available'),
                  _buildDivider(colors),
                  _buildInfoRow('DNS Servers', _networkStats['dns'] ?? 'Not available'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            MsiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MsiSectionHeader(title: 'Traffic Statistics'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTrafficCard(
                          'Packets Sent',
                          _networkStats['packetsSent']?.toString() ?? '0',
                          Icons.send,
                          colors.performance,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTrafficCard(
                          'Packets Received',
                          _networkStats['packetsReceived']?.toString() ?? '0',
                          Icons.inbox,
                          colors.superBattery,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            MsiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MsiSectionHeader(title: 'Network Tools'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildToolButton('Ping Test', Icons.network_ping, () {
                          GetIt.instance<ToastService>().showInfo('Running ping test...');
                        }, colors),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildToolButton('Speed Test', Icons.speed, () {
                          GetIt.instance<ToastService>().showInfo('Running speed test...');
                        }, colors),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFCBD5E1),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(AppColors colors) {
    return Divider(height: 1, color: colors.border);
  }

  Widget _buildTrafficCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(String label, IconData icon, VoidCallback onPressed, AppColors colors) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: colors.performance.withValues(alpha: 0.1),
        foregroundColor: colors.performance,
        elevation: 0,
      ),
    );
  }
}
