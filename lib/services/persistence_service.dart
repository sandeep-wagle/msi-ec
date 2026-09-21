import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class PersistenceService {
  SharedPreferences? _prefs;

  Future<void> ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    if (_prefs == null) {
      throw StateError(
        'PersistenceService not initialized. Call ensureInitialized() first.',
      );
    }
    return _prefs!;
  }

  // Theme
  static const _themeKey = 'theme_mode';

  Future<void> saveThemeMode(String mode) async {
    await _p.setString(_themeKey, mode);
  }

  String loadThemeMode() {
    return _p.getString(_themeKey) ?? 'dark';
  }

  // Notification read state
  static const _readIdsKey = 'notification_read_ids';

  Future<void> saveReadIds(Set<String> ids) async {
    await _p.setStringList(_readIdsKey, ids.toList());
  }

  Set<String> loadReadIds() {
    return _p.getStringList(_readIdsKey)?.toSet() ?? {};
  }

  // Smart Priority
  static const _smartPriorityModeKey = 'smart_priority_mode';
  static const _smartPriorityEnabledKey = 'smart_priority_enabled';
  static const _smartPriorityListKey = 'smart_priority_list';

  Future<void> saveSmartPriority({
    required String mode,
    required bool enabled,
    required List<String> priorityAppNames,
  }) async {
    await _p.setString(_smartPriorityModeKey, mode);
    await _p.setBool(_smartPriorityEnabledKey, enabled);
    await _p.setStringList(_smartPriorityListKey, priorityAppNames);
  }

  String loadSmartPriorityMode() {
    return _p.getString(_smartPriorityModeKey) ?? 'smartPriority';
  }

  bool loadSmartPriorityEnabled() {
    return _p.getBool(_smartPriorityEnabledKey) ?? true;
  }

  List<String> loadSmartPriorityList() {
    return _p.getStringList(_smartPriorityListKey) ?? [];
  }

  // Mystic Light
  static const _mysticEffectKey = 'mystic_effect';
  static const _mysticColorKey = 'mystic_color';
  static const _mysticBrightnessKey = 'mystic_brightness';
  static const _mysticZoneKey = 'mystic_zone';

  Future<void> saveMysticLight({
    required String effect,
    required int color,
    required double brightness,
    required int zone,
  }) async {
    await _p.setString(_mysticEffectKey, effect);
    await _p.setInt(_mysticColorKey, color);
    await _p.setDouble(_mysticBrightnessKey, brightness);
    await _p.setInt(_mysticZoneKey, zone);
  }

  String loadMysticEffect() => _p.getString(_mysticEffectKey) ?? 'static';
  int loadMysticColor() => _p.getInt(_mysticColorKey) ?? 0xFFEB1D24;
  double loadMysticBrightness() => _p.getDouble(_mysticBrightnessKey) ?? 1.0;
  int loadMysticZone() => _p.getInt(_mysticZoneKey) ?? 0;

  // LAN Manager
  static const _lanAiPriorityKey = 'lan_ai_priority';

  Future<void> saveLanAiPriority(bool enabled) async {
    await _p.setBool(_lanAiPriorityKey, enabled);
  }

  bool loadLanAiPriority() {
    return _p.getBool(_lanAiPriorityKey) ?? false;
  }

  // Keyboard backlight
  static const _kbBrightnessKey = 'keyboard_brightness';
  static const _kbModeKey = 'keyboard_mode';

  Future<void> saveKeyboardBacklight({
    required int brightness,
    required int mode,
  }) async {
    await _p.setInt(_kbBrightnessKey, brightness);
    await _p.setInt(_kbModeKey, mode);
  }

  int loadKeyboardBrightness() => _p.getInt(_kbBrightnessKey) ?? 3;
  int loadKeyboardMode() => _p.getInt(_kbModeKey) ?? 0;

  // Personal Space (Unified Vault)
  static const _vaultItemsKey = 'vault_items_v1';

  Future<void> saveVaultItems(List<String> itemsJson) async {
    await _p.setStringList(_vaultItemsKey, itemsJson);
  }

  List<String> loadVaultItems() {
    return _p.getStringList(_vaultItemsKey) ?? [];
  }

  // Controls tab: Hyprland pointer / touchpad preferences.
  // Live values are applied via hyprctl and persisted to
  // ~/.config/hypr/input.lua; these prefs act as the UI restore cache so
  // the tab renders instantly (and sanely on non-Hyprland machines).
  static const _sensitivityKey = 'controls_sensitivity';
  static const _naturalScrollKey = 'controls_natural_scroll';
  static const _accelProfileKey = 'controls_accel_profile';

  Future<void> saveControlsInput({
    double? sensitivity,
    bool? naturalScroll,
    String? accelProfile,
  }) async {
    if (sensitivity != null) await _p.setDouble(_sensitivityKey, sensitivity);
    if (naturalScroll != null) await _p.setBool(_naturalScrollKey, naturalScroll);
    if (accelProfile != null) await _p.setString(_accelProfileKey, accelProfile);
  }

  double loadSensitivity() => _p.getDouble(_sensitivityKey) ?? 0.0;
  bool loadNaturalScroll() => _p.getBool(_naturalScrollKey) ?? false;
  String loadAccelProfile() => _p.getString(_accelProfileKey) ?? 'adaptive';

  // Controls tab: battery charge threshold (display 0-100 matching the
  // slider). Live sysfs is authoritative; this is the fallback shown
  // before the first successful read (or on hardware without the node).
  static const _batteryThresholdKey = 'controls_battery_threshold';

  Future<void> saveBatteryThreshold(int limit) async {
    await _p.setInt(_batteryThresholdKey, limit);
  }

  int loadBatteryThreshold() => _p.getInt(_batteryThresholdKey) ?? 80;
}
