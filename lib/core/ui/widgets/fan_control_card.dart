import 'package:flutter/material.dart';
import 'package:msi_controller/core/tokens/app_tokens.dart';
import 'package:msi_controller/core/app_colors.dart';
// Removed as AppRadius is in app_tokens.dart
import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/screens/fan/widgets/fan_mode_toggle.dart';
import 'package:msi_controller/screens/fan/widgets/fan_rpm_display.dart';

class FanControlCard extends StatelessWidget {
  final FanInfo fan;
  final int index;
  final AppColors colors;
  final bool autoMode;
  final int targetRpm;
  final Function(bool) onAutoModeToggle;
  final Function(int) onSpeedChanged;

  const FanControlCard({
    super.key,
    required this.fan,
    required this.index,
    required this.colors,
    required this.autoMode,
    required this.targetRpm,
    required this.onAutoModeToggle,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxRpm = fan.maxRpm ?? 6000;
    final percent = maxRpm > 0
        ? (fan.currentRpm / maxRpm).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.air_rounded,
                    color: colors.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FAN ENGINE #${fan.fanIndex + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        autoMode
                            ? 'PROTOCOL: AI-CONTROLLED'
                            : 'PROTOCOL: MANUAL OVERRIDE',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                FanModeToggle(
                  autoMode: autoMode,
                  fanIndex: fan.fanIndex,
                  colors: colors,
                  onToggle: onAutoModeToggle,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FanRpmDisplay(
                  label: 'CURRENT VELOCITY',
                  value: fan.currentRpm,
                  color: colors.textPrimary,
                ),
                FanRpmDisplay(
                  label: 'TARGET VELOCITY',
                  value: autoMode ? fan.currentRpm : targetRpm,
                  color: colors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent),
              duration: const Duration(seconds: 1),
              curve: Curves.easeOutCubic,
              builder: (context, val, _) => Column(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.xsAll,
                    child: LinearProgressIndicator(
                      value: val,
                      minHeight: 6,
                      backgroundColor: colors.gaugeTrack,
                      color: _getFanColor(val * 100, colors),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0 RPM',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        '${(val * 100).toInt()}% LOAD',
                        style: TextStyle(
                          color: _getFanColor(val * 100, colors),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '$maxRpm RPM',
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!autoMode) ...[
              const SizedBox(height: AppSpacing.xxl),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  activeTrackColor: colors.warning,
                  thumbColor: colors.warning,
                ),
                child: Slider(
                  value: targetRpm.toDouble(),
                  min: 0,
                  max: maxRpm.toDouble(),
                  onChanged: (v) => onSpeedChanged(v.round()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getFanColor(double load, AppColors colors) {
    if (load < 30) return colors.success;
    if (load < 60) return colors.balanced;
    if (load < 85) return colors.warning;
    return colors.performance;
  }
}
