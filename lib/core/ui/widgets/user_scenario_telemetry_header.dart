import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/screens/user_scenario/widgets/user_scenario_telemetry_item.dart';

class UserScenarioTelemetryHeader extends StatelessWidget {
  final int? cpuTemperature;
  final int? cpuUsage;
  final int? batteryLevel;

  const UserScenarioTelemetryHeader({
    super.key,
    this.cpuTemperature,
    this.cpuUsage,
    this.batteryLevel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserScenarioTelemetryItem(
          icon: Icons.thermostat,
          value: '${cpuTemperature ?? "--"}°C',
          color: colors.performance,
        ),
        const SizedBox(width: AppSpacing.xl),
        UserScenarioTelemetryItem(
          icon: Icons.bolt,
          value: '${cpuUsage ?? "--"}%',
          color: colors.balanced,
        ),
        const SizedBox(width: AppSpacing.xl),
        UserScenarioTelemetryItem(
          icon: Icons.battery_charging_full,
          value: '${batteryLevel ?? "--"}%',
          color: colors.success,
        ),
      ],
    );
  }
}