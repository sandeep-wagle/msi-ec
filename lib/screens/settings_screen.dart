import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/domain/entities/system_info.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'package:msi_controller/services/toast_service.dart';
import 'package:msi_controller/services/persistence_service.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/screens/settings/widgets/settings_section_header.dart';
import 'package:msi_controller/screens/settings/widgets/settings_mode_option.dart';
import 'package:msi_controller/screens/settings/widgets/settings_horizontal_divider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _modeLabels = [
    'STATIC_NORMAL',
    'GAMING_DYNAMIC',
    'THERMAL_BREATHING',
    'WAVE_INTERFERENCE',
    'PROTOCOL_OFF',
  ];
  final MsiRepository _repository = getIt<MsiRepository>();
  bool _webcamEnabled = false;
  bool _micEnabled = false;
  bool _usbPowerShare = false;
  bool _coolerBoost = false;
  bool _isLoading = false;
  int _keyboardBrightness = 3;
  int _keyboardMode = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );
    _animController.forward();
    _loadSettings();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _repository.getDeviceSettings();
    if (mounted) {
      setState(() {
        _webcamEnabled = settings.webcamEnabled;
        _micEnabled = settings.micEnabled;
        _usbPowerShare = settings.usbPowerShare;
        _coolerBoost = settings.coolerBoost;
      });
    }
    final kbBrightness = await _repository.getKeyboardBacklight();
    final storage = getIt<PersistenceService>();
    if (mounted) {
      setState(() {
        _keyboardBrightness = kbBrightness >= 0
            ? kbBrightness
            : storage.loadKeyboardBrightness();
        _keyboardMode = storage.loadKeyboardMode();
      });
    }
  }

  Future<void> _toggleSetting(String key, bool value) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final success = await _repository.setDeviceSetting(key, value);
    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        getIt<ToastService>().showError('FAILED TO SYNCHRONIZE HARDWARE');
      }
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
          'System Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: FadeTransition(
        opacity: _animController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSectionHeader(title: 'HARDWARE SWITCHES', colors: colors),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _PremiumToggleTile(
                      icon: Icons.videocam_outlined,
                      title: 'WEBCAM_PROTOCOL',
                      value: _webcamEnabled,
                      color: colors.balanced,
                      onChanged: (value) {
                        setState(() => _webcamEnabled = value);
                        _toggleSetting('webcam', value);
                      },
                    ),
                    SettingsHorizontalDivider(colors: colors),
                    _PremiumToggleTile(
                      icon: Icons.mic_none_rounded,
                      title: 'MIC_INPUT_BRIDGE',
                      value: _micEnabled,
                      color: colors.balanced,
                      onChanged: (value) {
                        setState(() => _micEnabled = value);
                        _toggleSetting('mic', value);
                      },
                    ),
                    SettingsHorizontalDivider(colors: colors),
                    _PremiumToggleTile(
                      icon: Icons.usb_rounded,
                      title: 'USB_POWER_SHARE',
                      value: _usbPowerShare,
                      color: colors.warning,
                      onChanged: (value) {
                        setState(() => _usbPowerShare = value);
                        _toggleSetting('usb_power_share', value);
                      },
                    ),
                    SettingsHorizontalDivider(colors: colors),
                    _PremiumToggleTile(
                      icon: Icons.ac_unit_rounded,
                      title: 'COOLER_BOOST_FORCE',
                      value: _coolerBoost,
                      color: colors.performance,
                      onChanged: (value) {
                        setState(() => _coolerBoost = value);
                        _toggleSetting('cooler_boost', value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),
              SettingsSectionHeader(
                title: 'ILLUMINATION ARCHITECTURE',
                colors: colors,
              ),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'KEYBOARD_LUMINANCE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'LVL_0$_keyboardBrightness',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: colors.performance,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        activeTrackColor: colors.performance,
                        thumbColor: colors.performance,
                        overlayColor: colors.performance.withValues(alpha: 0.1),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                      ),
                      child: Slider(
                        value: _keyboardBrightness.toDouble(),
                        min: 0,
                        max: 3,
                        divisions: 3,
                        onChanged: (value) =>
                            setState(() => _keyboardBrightness = value.round()),
                        onChangeEnd: (value) async {
                          final brightness = value.round();
                          await _repository.setKeyboardBacklight(
                            KeyboardBacklightInfo(
                              brightness: brightness,
                              mode: _keyboardMode,
                            ),
                          );
                          getIt<PersistenceService>().saveKeyboardBacklight(
                            brightness: brightness,
                            mode: _keyboardMode,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              SettingsSectionHeader(
                title: 'BACKLIGHT_PROTOCOL',
                colors: colors,
              ),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    for (int mode = 0; mode < 5; mode++) ...[
                      SettingsModeOption(
                        label: _modeLabels[mode],
                        isSelected: _keyboardMode == mode,
                        accentColor: colors.performance,
                        onTap: () {
                          setState(() => _keyboardMode = mode);
                          getIt<PersistenceService>().saveKeyboardBacklight(
                            brightness: _keyboardBrightness,
                            mode: mode,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),
              SettingsSectionHeader(title: 'SYSTEM_MANIFEST', colors: colors),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.performance.withValues(alpha: 0.1),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Icon(
                        Icons.terminal_rounded,
                        color: colors.performance,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MSI CENTER LINUX',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'VERSION 2.0.4.ALPHA (STITCH_CORE)',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _PremiumToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
