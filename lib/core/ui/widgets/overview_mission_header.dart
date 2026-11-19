import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/screens/overview/widgets/overview_pulse_badge.dart';

class OverviewMissionHeader extends StatelessWidget {
  final SystemInfo? info;

  const OverviewMissionHeader({super.key, this.info});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: colors.performance,
                borderRadius: AppRadius.xsAll,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text(
              'Mission Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
            const Spacer(),
            OverviewPulseBadge(colors: colors),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          info?.cpuModel?.toUpperCase() ?? 'INITIALIZING SYSTEM PROTOCOLS...',
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}