import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import '../domain/entities/system_info.dart';
import '../domain/repositories/msi_repository.dart';
import '../services/toast_service.dart';

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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Webcam'),
                    subtitle: const Text('Enable or disable the webcam'),
                    secondary: const Icon(Icons.videocam),
                    value: _webcamEnabled,
                    onChanged: (value) {
                      setState(() => _webcamEnabled = value);
                      _toggleSetting('webcam', value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Microphone'),
                    subtitle: const Text('Enable or disable the microphone'),
                    secondary: const Icon(Icons.mic),
                    value: _micEnabled,
                    onChanged: (value) {
                      setState(() => _micEnabled = value);
                      _toggleSetting('mic', value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('USB Power Share'),
                    subtitle: const Text(
                      'Charge devices via USB when laptop is off',
                    ),
                    secondary: const Icon(Icons.usb),
                    value: _usbPowerShare,
                    onChanged: (value) {
                      setState(() => _usbPowerShare = value);
                      _toggleSetting('usb_power_share', value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Cooler Boost'),
                    subtitle: const Text(
                      'Maximum fan speed for optimal cooling',
                    ),
                    secondary: const Icon(Icons.ac_unit),
                    value: _coolerBoost,
                    onChanged: (value) {
                      setState(() => _coolerBoost = value);
                      _toggleSetting('cooler_boost', value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Keyboard Backlight',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Customize keyboard backlight settings',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.keyboard),
                        const SizedBox(width: 12),
                        const Text(
                          'Brightness',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Text(
                            '$_keyboardBrightness',
                            key: ValueKey(_keyboardBrightness),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.palette),
                        SizedBox(width: 12),
                        Text(
                          'Backlight Mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
            ),
            const SizedBox(height: 24),
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.laptop,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MSI Center Linux',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Version 2.0.0 (Clean Architecture)',
                              style: TextStyle(color: Colors.grey),
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
                      style: TextStyle(color: Colors.grey, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(int mode, String title, String description) {
    final isSelected = _keyboardMode == mode;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        setState(() => _keyboardMode = mode);
      },
    );
  }
}
