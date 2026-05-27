import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import '../core/app_colors.dart';
import '../domain/entities/system_info.dart';
import '../domain/repositories/msi_repository.dart';
import '../services/toast_service.dart';
import '../widgets/msi_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final MsiRepository _repository = getIt<MsiRepository>();
  bool _webcamEnabled = false;
  bool _micEnabled = false;
  bool _usbPowerShare = false;
  bool _coolerBoost = false;
  bool _isLoading = false;
  int _keyboardBrightness = 3;
  int _keyboardMode = 0;
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
    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
  }

  Future<void> _toggleSetting(String key, bool value) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final success = await _repository.setDeviceSetting(key, value);
    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        getIt<ToastService>().showError('Failed to update setting');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            MsiCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Webcam',
                    'Enable or disable the webcam',
                    Icons.videocam,
                    _webcamEnabled,
                    (v) {
                      setState(() => _webcamEnabled = v);
                      _toggleSetting('webcam', v);
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    'Microphone',
                    'Enable or disable the microphone',
                    Icons.mic,
                    _micEnabled,
                    (v) {
                      setState(() => _micEnabled = v);
                      _toggleSetting('mic', v);
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    'USB Power Share',
                    'Charge devices via USB when laptop is off',
                    Icons.usb,
                    _usbPowerShare,
                    (v) {
                      setState(() => _usbPowerShare = v);
                      _toggleSetting('usb_power_share', v);
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    'Cooler Boost',
                    'Maximum fan speed for optimal cooling',
                    Icons.ac_unit,
                    _coolerBoost,
                    (v) {
                      setState(() => _coolerBoost = v);
                      _toggleSetting('cooler_boost', v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildKeyboardSection(colors),
            const SizedBox(height: 24),
            _buildAboutSection(colors, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEB1D24).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFFEB1D24)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: const Color(0xFFEB1D24).withValues(alpha: 0.08),
    );
  }

  Widget _buildKeyboardSection(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MsiSectionHeader(title: 'Keyboard Backlight'),
        const SizedBox(height: 16),
        MsiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.keyboard, size: 20, color: Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  const Text(
                    'Brightness',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Text(
                      '$_keyboardBrightness',
                      key: ValueKey(_keyboardBrightness),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEB1D24),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _keyboardBrightness.toDouble(),
                min: 0,
                max: 3,
                divisions: 3,
                label: _keyboardBrightness.toString(),
                onChanged: (value) {
                  setState(() => _keyboardBrightness = value.round());
                },
                onChangeEnd: (value) async {
                  final brightness = value.round();
                  await _repository.setKeyboardBacklight(
                    KeyboardBacklightInfo(
                      brightness: brightness,
                      mode: _keyboardMode,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MsiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette, size: 20, color: Color(0xFF64748B)),
                  SizedBox(width: 10),
                  Text(
                    'Backlight Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildModeOption(0, 'Normal', 'Single color, static'),
              _buildModeOption(1, 'Gaming', 'Dynamic gaming effects'),
              _buildModeOption(2, 'Breathing', 'Fade in and out'),
              _buildModeOption(3, 'Wave', 'Color wave animation'),
              _buildModeOption(4, 'Off', 'Backlight disabled'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeOption(int mode, String title, String description) {
    final isSelected = _keyboardMode == mode;
    return InkWell(
      onTap: () => setState(() => _keyboardMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFEB1D24)
                      : const Color(0xFF475569),
                  width: isSelected ? 2 : 1.5,
                ),
                color: isSelected ? const Color(0xFFEB1D24) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFFEB1D24)
                          : const Color(0xFFCBD5E1),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(AppColors colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MsiSectionHeader(title: 'About'),
        const SizedBox(height: 12),
        MsiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.performance.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.laptop,
                      size: 22,
                      color: Color(0xFFEB1D24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MSI Center Linux',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Version 2.0.0 (Clean Architecture)',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'An open-source Linux alternative to the MSI Center software. '
                'Control performance profiles, fan speeds, and hardware settings on supported MSI laptops. '
                'Based on msi-ec, MControlCenter, and MSI Center UI standards.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
