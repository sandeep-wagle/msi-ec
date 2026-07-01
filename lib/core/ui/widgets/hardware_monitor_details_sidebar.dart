import 'package:flutter/material.dart';
import 'package:msi_controller/core/ui/widgets/sidebar_row_widget.dart';
import 'package:msi_controller/domain/entities/system_info.dart';

class HardwareMonitorDetailsSidebar extends StatelessWidget {
  final SystemInfo? systemInfo;
  final List<FanInfo> fans;

  const HardwareMonitorDetailsSidebar({
    super.key,
    required this.systemInfo,
    required this.fans,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalGb = ((systemInfo?.ramTotal ?? 0) / 1024).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          systemInfo?.cpuModel ?? 'Intel Core i7-11800H @ 2.30GHz',
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          child: Text(
            systemInfo?.gpuModel ?? 'NVIDIA GeForce RTX 3080',
            style: const TextStyle(fontSize: 13),
          ),
        ),
        SidebarRowWidget(label: 'RAM', value: '$totalGb GB'),
        SidebarRowWidget(
          label: 'VRAM',
          value: '${systemInfo?.vramUsage ?? 0} / ${systemInfo?.vramTotal ?? 8192} MB',
          isAlt: true,
        ),
        SidebarRowWidget(
          label: 'Fan 1',
          value: '${fans.isNotEmpty ? fans[0].currentRpm : 0} RPM',
        ),
        SidebarRowWidget(
          label: 'Fan 2',
          value: '${fans.length > 1 ? fans[1].currentRpm : 0} RPM',
          isAlt: true,
        ),
        SidebarRowWidget(label: 'GPU Clock', value: '${systemInfo?.gpuCoreClock ?? 0} MHz'),
        SidebarRowWidget(
          label: 'CPU Temp',
          value: '${systemInfo?.cpuTemperature ?? 0} °C',
          isAlt: true,
        ),
        SidebarRowWidget(label: 'GPU Temp', value: '${systemInfo?.gpuTemperature ?? 0} °C'),
        SsdRowWidget(diskUsage: systemInfo?.diskUsage ?? 0.16),
        SidebarRowWidget(
          label: 'Power Plan',
          value: systemInfo?.powerPlan ?? 'Balance',
          isAlt: true,
        ),
      ],
    );
  }
}