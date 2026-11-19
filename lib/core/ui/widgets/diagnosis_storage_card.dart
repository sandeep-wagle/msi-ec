import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/screens/system_diagnosis/widgets/status_badge_widget.dart';
import 'package:msi_controller/core/ui/widgets/diagnosis_pro_gauge.dart';
import 'package:msi_controller/core/ui/widgets/diagnosis_temp_toggle.dart';

class DiagnosisStorageCard extends StatefulWidget {
  final int ssdTemp;
  final double diskUsage;
  final AppColors colors;

  const DiagnosisStorageCard({
    super.key,
    required this.ssdTemp,
    required this.diskUsage,
    required this.colors,
  });

  @override
  State<DiagnosisStorageCard> createState() => _DiagnosisStorageCardState();
}

class _DiagnosisStorageCardState extends State<DiagnosisStorageCard> {
  bool _isCelsius = true;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NVMe SSD MASTER',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: colors.textPrimary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '/DEV/NVME0N1P2',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 9,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              StatusBadgeWidget(label: 'HEALTHY', color: colors.success, colors: colors),
            ],
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Row(
            children: [
              Expanded(
                child: DiagnosisProGauge(
                  label: 'STORAGE',
                  percent: widget.diskUsage,
                  color: colors.balanced,
                  colors: colors,
                  suffix: '%',
                ),
              ),
              Container(
                height: 80,
                width: 1,
                color: colors.border.withValues(alpha: 0.1),
              ),
              Expanded(
                child: DiagnosisProGauge(
                  label: 'THERMAL',
                  percent: _isCelsius
                      ? widget.ssdTemp / 100
                      : ((widget.ssdTemp * 9 / 5 + 32) / 212),
                  color: colors.performance,
                  colors: colors,
                  customValue:
                      '${_isCelsius ? widget.ssdTemp.toInt() : (widget.ssdTemp * 9 / 5 + 32).toInt()}°',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DiagnosisTempToggle(
                label: 'CELSIUS',
                active: _isCelsius,
                onTap: () => setState(() => _isCelsius = true),
                colors: colors,
              ),
              const SizedBox(width: AppSpacing.xl),
              DiagnosisTempToggle(
                label: 'FAHRENHEIT',
                active: !_isCelsius,
                onTap: () => setState(() => _isCelsius = false),
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}