import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/services/accessories_service.dart';
import 'package:msi_controller/services/hyprland_service.dart';
import 'package:msi_controller/services/persistence_service.dart';
import 'package:msi_controller/services/toast_service.dart';
import 'package:msi_controller/widgets/glass_container.dart';
import 'package:msi_controller/core/ui/widgets/screen_header.dart';
import 'package:msi_controller/logic/blocs/settings/settings_bloc.dart';
import 'package:msi_controller/logic/blocs/settings/settings_event.dart';
import 'package:msi_controller/logic/blocs/settings/settings_state.dart';

/// Accessories / Controls tab: the Hardware and System Settings Center.
///
/// Section A — Mouse & pointer (Hyprland input engine, current user only,
/// never elevated). Section B — MSI hardware & keyboard accessories
/// (direct udev-permissioned writes, never a password prompt).
///
/// Every control degrades gracefully: on non-Hyprland desktops the pointer
/// section reports unavailable, and on non-MSI hardware each accessory row
/// shows "Not available on this device" instead of failing.
class ControlsScreen extends StatefulWidget {
  const ControlsScreen({super.key});

  @override
  State<ControlsScreen> createState() => _ControlsScreenState();
}

class _ControlsScreenState extends State<ControlsScreen>
    with AutomaticKeepAliveClientMixin {
  final HyprlandService _hyprland = HyprlandService();
  final AccessoriesService _accessories = AccessoriesService();

  bool _hyprlandAvailable = false;
  bool _loading = true;

  double _sensitivity = 0.0;
  bool _naturalScroll = false;
  String _accelProfile = 'adaptive';

  bool _coolerBoost = false;
  bool _fnKeySwap = false;

  bool _supportsCoolerBoost = false;
  bool _supportsBatteryThreshold = false;
  bool _supportsFnKeySwap = false;

  Timer? _sensitivityDebounce;
  Timer? _refreshTimer;
  bool _sliderActive = false;
  DateTime _lastUserEdit = DateTime.fromMillisecondsSinceEpoch(0);

  /// Marks a user-driven change. The periodic refresh ignores everything
  /// newer than this window, so slow hardware writes (sudo sysfs round
  /// trips) can land without the UI snapping back mid-write.
  void _markUserEdit() {
    _lastUserEdit = DateTime.now();
    _sliderActive = true;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAll();
    // Silent live refresh: values changed outside the tab (hyprctl CLI,
    // fn-key presses, EC writes from other tools, driver state) must flow
    // back in, or the UI and the system permanently disagree after any
    // tab switch or external tweak. Skipped while the user drags and for
    // a grace window after any edit (slow writes landing late must win).
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _loading || _sliderActive) return;
      if (DateTime.now().difference(_lastUserEdit).inSeconds < 3) return;
      _refreshLive();
    });
  }

  @override
  void dispose() {
    _sensitivityDebounce?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Re-reads every live source without touching user interaction state.
  /// Only applies values that actually changed, so sliders never jump.
  Future<void> _refreshLive() async {
    final results = await Future.wait([
      _hyprland.getSensitivity(),
      _hyprland.getNaturalScroll(),
      _hyprland.getAccelProfile(),
      _accessories.readCoolerBoost(),
      _accessories.readFnKeySwap(),
    ]);
    if (!mounted || _sliderActive) return;
    setState(() {
      final sensitivity = results[0] as double?;
      final natural = results[1] as bool?;
      final accel = results[2] as String?;
      final cooler = results[3] as bool?;
      final fnSwap = results[4] as bool?;
      if (sensitivity != null &&
          (sensitivity - _sensitivity).abs() > 0.005) {
        _sensitivity = sensitivity;
      }
      if (natural != null && natural != _naturalScroll) {
        _naturalScroll = natural;
      }
      if (accel != null && accel != _accelProfile) {
        _accelProfile = accel;
      }
      if (cooler != null && cooler != _coolerBoost) _coolerBoost = cooler;
      if (fnSwap != null && fnSwap != _fnKeySwap) _fnKeySwap = fnSwap;
    });
  }

  Future<void> _loadAll() async {
    final storage = getIt<PersistenceService>();
    setState(() {
      // Instant restore from cache so the tab never flashes empty.
      _sensitivity = storage.loadSensitivity();
      _naturalScroll = storage.loadNaturalScroll();
      _accelProfile = storage.loadAccelProfile();
      _supportsCoolerBoost = _accessories.supportsCoolerBoost;
      _supportsBatteryThreshold = _accessories.supportsBatteryThreshold;
      _supportsFnKeySwap = _accessories.supportsFnKeySwap;
    });

    final available = await _hyprland.isAvailable();
    double? liveSensitivity;
    bool? liveNatural;
    String? liveAccel;
    if (available) {
      liveSensitivity = await _hyprland.getSensitivity();
      liveNatural = await _hyprland.getNaturalScroll();
      liveAccel = await _hyprland.getAccelProfile();
    }
    final cooler = await _accessories.readCoolerBoost();
    final fnSwap = await _accessories.readFnKeySwap();

    if (!mounted) return;
    setState(() {
      _hyprlandAvailable = available;
      if (liveSensitivity != null) _sensitivity = liveSensitivity;
      if (liveNatural != null) _naturalScroll = liveNatural;
      if (liveAccel != null) _accelProfile = liveAccel;
      if (cooler != null) _coolerBoost = cooler;
      if (fnSwap != null) _fnKeySwap = fnSwap;
      _loading = false;
    });
  }

  void _fail(String message) {
    getIt<ToastService>().showError(message);
  }

  // ------------------------------------------------------------------
  // Section A handlers (Hyprland — unprivileged live apply + persistence).
  // ------------------------------------------------------------------
  void _onSensitivityChanged(double value) {
    setState(() => _sensitivity = value);
    _sensitivityDebounce?.cancel();
    _markUserEdit();
    _sensitivityDebounce = Timer(const Duration(milliseconds: 120), () async {
      final ok = await _hyprland.setSensitivity(_sensitivity);
      if (!mounted) return;
      _sliderActive = false;
      if (ok) {
        await getIt<PersistenceService>().saveControlsInput(
          sensitivity: _sensitivity,
        );
      } else {
        _fail('FAILED TO APPLY POINTER SPEED');
      }
    });
  }

  Future<void> _onNaturalScrollChanged(bool value) async {
    _markUserEdit();
    setState(() => _naturalScroll = value);
    final ok = await _hyprland.setNaturalScroll(value);
    if (!mounted) return;
    if (ok) {
      await getIt<PersistenceService>().saveControlsInput(naturalScroll: value);
    } else {
      setState(() => _naturalScroll = !value);
      _fail('FAILED TO APPLY SCROLL DIRECTION');
    }
  }

  Future<void> _onAccelProfileChanged(String profile) async {
    final previous = _accelProfile;
    _markUserEdit();
    setState(() => _accelProfile = profile);
    final ok = await _hyprland.setAccelProfile(profile);
    if (!mounted) return;
    if (ok) {
      await getIt<PersistenceService>().saveControlsInput(accelProfile: profile);
    } else {
      setState(() => _accelProfile = previous);
      _fail('FAILED TO APPLY ACCEL PROFILE');
    }
  }

  // ------------------------------------------------------------------
  // Section B handlers (MSI hardware — passwordless sysfs writes).
  // ------------------------------------------------------------------
  Future<void> _onCoolerBoostChanged(bool value) async {
    _markUserEdit();
    setState(() => _coolerBoost = value);
    final ok = await _accessories.setCoolerBoost(value);
    if (!mounted) return;
    if (!ok) {
      setState(() => _coolerBoost = !value);
      _fail('FAILED TO SYNCHRONIZE COOLER BOOST');
    }
  }

  Future<void> _onFnKeySwapChanged(bool value) async {
    _markUserEdit();
    setState(() => _fnKeySwap = value);
    final ok = await _accessories.setFnKeySwap(value);
    if (!mounted) return;
    if (!ok) {
      setState(() => _fnKeySwap = !value);
      _fail('FAILED TO SWAP WIN/FN KEYS');
    }
  }

  // ------------------------------------------------------------------
  // UI.
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final horizontalPadding = isWide ? AppSpacing.xxxl : AppSpacing.xl;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.xxxl,
              horizontalPadding,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Controls',
                  subtitle:
                      'Pointer, touchpad and MSI hardware accessories — instant apply, reboot-safe.',
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(
                  title: 'MOUSE & POINTER',
                  subtitle: 'Hyprland input engine — live, no sudo',
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.md),
                if (!_hyprlandAvailable && !_loading)
                  _UnavailableBanner(
                    colors: colors,
                    message:
                        'HYPRLAND NOT DETECTED — POINTER CONTROLS ARE UNAVAILABLE ON THIS DESKTOP',
                  ),
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _IconBadge(
                            icon: Icons.mouse_rounded,
                            color: colors.balanced,
                          ),
                          const SizedBox(width: AppSpacing.xl),
                          Expanded(
                            child: Text(
                              'POINTER SPEED',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.5,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            _sensitivity.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              color: colors.balanced,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          activeTrackColor: colors.balanced,
                          thumbColor: colors.balanced,
                          overlayColor:
                              colors.balanced.withValues(alpha: 0.15),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                          ),
                        ),
                        child: Slider(
                          value: _sensitivity,
                          min: -1.0,
                          max: 1.0,
                          divisions: 40,
                          onChanged: _hyprlandAvailable || _loading
                              ? _onSensitivityChanged
                              : null,
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            _ScaleLabel(
                              text: '-1.0 SLOW',
                              colors: colors,
                            ),
                            _ScaleLabel(
                              text: '0.0 DEFAULT',
                              colors: colors,
                              highlight: true,
                            ),
                            _ScaleLabel(
                              text: '+1.0 FAST',
                              colors: colors,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ControlToggleTile(
                        icon: Icons.touch_app_rounded,
                        title: 'NATURAL SCROLL',
                        subtitle: 'Touchpad content tracks fingers',
                        value: _naturalScroll,
                        color: colors.success,
                        enabled: _hyprlandAvailable || _loading,
                        onChanged: _onNaturalScrollChanged,
                      ),
                      Divider(
                        height: 1,
                        color: colors.border.withValues(alpha: 0.4),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.superBattery.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: AppRadius.smAll,
                              ),
                              child: Icon(
                                Icons.speed_rounded,
                                color: colors.superBattery,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ACCEL PROFILE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Mouse acceleration curve',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'flat',
                              label: Text('FLAT'),
                              icon: Icon(Icons.show_chart_rounded, size: 16),
                            ),
                            ButtonSegment(
                              value: 'adaptive',
                              label: Text('ADAPTIVE'),
                              icon:
                                  Icon(Icons.auto_graph_rounded, size: 16),
                            ),
                          ],
                          selected: {_accelProfile},
                          showSelectedIcon: false,
                          onSelectionChanged:
                              (_hyprlandAvailable || _loading)
                                  ? (selected) =>
                                      _onAccelProfileChanged(selected.first)
                                  : null,
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: colors.superBattery
                                .withValues(alpha: 0.2),
                            selectedForegroundColor: colors.superBattery,
                            foregroundColor: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                _SectionTitle(
                  title: 'HARDWARE ACCESSORIES',
                  subtitle: 'MSI EC — passwordless, instant apply',
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.md),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ControlToggleTile(
                        icon: Icons.ac_unit_rounded,
                        title: 'COOLER BOOST',
                        subtitle: _supportsCoolerBoost
                            ? 'Fans to full blast for builds & gaming'
                            : 'Not available on this device',
                        value: _coolerBoost,
                        color: colors.performance,
                        enabled: _supportsCoolerBoost,
                        onChanged: _onCoolerBoostChanged,
                      ),
                      Divider(
                        height: 1,
                        color: colors.border.withValues(alpha: 0.4),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    colors.success.withValues(alpha: 0.12),
                                borderRadius: AppRadius.smAll,
                              ),
                              child: Icon(
                                Icons.battery_charging_full_rounded,
                                color: colors.success,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CHARGE THRESHOLD',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _supportsBatteryThreshold
                                        ? 'Cap charge to extend battery health'
                                        : 'Not available on this device',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      BlocBuilder<SettingsBloc, SettingsState>(
                        builder: (context, settings) {
                          final batteryLimit = settings.batteryLimit;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$batteryLimit%',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'monospace',
                                          color: colors.success,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _supportsBatteryThreshold
                                          ? 'STOPS CHARGING HERE'
                                          : 'READ-ONLY PRESET',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: colors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 4,
                                    activeTrackColor: colors.success,
                                    thumbColor: colors.success,
                                    overlayColor:
                                        colors.success.withValues(alpha: 0.15),
                                    thumbShape:
                                        const RoundSliderThumbShape(
                                      enabledThumbRadius: 10,
                                    ),
                                  ),
                                  child: Slider(
                                    value: batteryLimit.toDouble(),
                                    min: 30,
                                    max: 100,
                                    divisions: 14,
                                    label: '$batteryLimit%',
                                    onChanged: _supportsBatteryThreshold
                                        ? (v) {
                                            _markUserEdit();
                                            // Optimistic UI update via BLoC
                                            context
                                                .read<SettingsBloc>()
                                                .add(SetBatteryLimitEvent(
                                                    v.round()));
                                          }
                                        : null,
                                    onChangeEnd: (v) {
                                      _sliderActive = false;
                                      // Final confirm already sent onChanged
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            _ScaleLabel(
                              text: '30% MAX-SAVER',
                              colors: colors,
                            ),
                            _ScaleLabel(
                              text: '80% BALANCED',
                              colors: colors,
                              highlight: true,
                            ),
                            _ScaleLabel(
                              text: '100% FULL',
                              colors: colors,
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: colors.border.withValues(alpha: 0.4),
                      ),
                      _ControlToggleTile(
                        icon: Icons.keyboard_alt_rounded,
                        title: 'WIN / FN SWAP',
                        subtitle: _supportsFnKeySwap
                            ? 'Swap Windows and Fn keys (MSI laptops)'
                            : 'Not available on this device',
                        value: _fnKeySwap,
                        color: colors.warning,
                        enabled: _supportsFnKeySwap,
                        onChanged: _onFnKeySwapChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Pointer changes apply instantly via hyprctl and persist to ~/.config/hypr/input.lua. '
                  'Hardware toggles write directly — no password prompt, on any Linux device with the control present.',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textTertiary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final AppColors colors;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: colors.textTertiary),
        ),
      ],
    );
  }
}

class _UnavailableBanner extends StatelessWidget {
  final AppColors colors;
  final String message;

  const _UnavailableBanner({required this.colors, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.1),
        borderRadius: AppRadius.smAll,
        border: Border.all(
          color: colors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: colors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _ScaleLabel extends StatelessWidget {
  final String text;
  final AppColors colors;
  final bool highlight;

  const _ScaleLabel({
    required this.text,
    required this.colors,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: highlight ? colors.balanced : colors.textTertiary,
        fontSize: 10,
        fontWeight: highlight ? FontWeight.w900 : FontWeight.bold,
      ),
    );
  }
}

class _ControlToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ControlToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: color,
              activeTrackColor: color.withValues(alpha: 0.25),
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}
