import 'dart:io';

import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/domain/repositories/msi_repository.dart';

/// MSI hardware & keyboard accessories with graceful cross-device fallbacks.
///
/// Policy (all Linux devices):
/// - NEVER spawn `sudo`/`pkexec` from Dart. Writes go directly to the
///   udev-permissioned sysfs paths (see packaging/99-msi-ec.rules); when the
///   native layer is available it applies its own direct-write-first +
///   `sudo -n` fallback, which also never prompts.
/// - On non-MSI hardware (no `/sys/devices/platform/msi-ec`) every probe
///   reports `supported == false` and setters return false, so the UI can
///   render an "unavailable on this device" state instead of erroring.
class AccessoriesService {
  static const String msiEcDir = '/sys/devices/platform/msi-ec';
  static const String coolerBoostPath = '$msiEcDir/cooler_boost';
  static const String fnKeyPath = '$msiEcDir/fn_key';

  static const List<String> batteryThresholdPaths = [
    '/sys/class/power_supply/BAT1/charge_control_end_threshold',
    '/sys/class/power_supply/BAT0/charge_control_end_threshold',
  ];

  MsiRepository get _repository => getIt<MsiRepository>();

  // ------------------------------------------------------------------
  // Capability probes (synchronous — cheap file-exists checks).
  // ------------------------------------------------------------------
  bool get hasMsiEc => Directory(msiEcDir).existsSync();
  bool get supportsCoolerBoost => File(coolerBoostPath).existsSync();
  bool get supportsFnKeySwap => File(fnKeyPath).existsSync();

  String? get batteryThresholdPath {
    for (final p in batteryThresholdPaths) {
      if (File(p).existsSync()) return p;
    }
    return null;
  }

  bool get supportsBatteryThreshold => batteryThresholdPath != null;

  // ------------------------------------------------------------------
  // Cooler Boost: fan full blast.
  // ------------------------------------------------------------------
  Future<bool?> readCoolerBoost() async {
    final direct = _readSysfs(coolerBoostPath);
    if (direct != null) return _isOn(direct);
    try {
      final settings = await _repository.getDeviceSettings();
      if (!hasMsiEc && !supportsCoolerBoost) return null;
      return settings.coolerBoost;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setCoolerBoost(bool enable) async {
    final value = enable ? 'on' : 'off';
    if (supportsCoolerBoost && await _writeSysfs(coolerBoostPath, value)) {
      return true;
    }
    try {
      return await _repository.setCoolerBoost(enable);
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------------
  // Battery charge threshold (60/80/100).
  // ------------------------------------------------------------------
  Future<int?> readBatteryThreshold() async {
    final path = batteryThresholdPath;
    if (path != null) {
      final raw = _readSysfs(path)?.trim();
      final parsed = int.tryParse(raw ?? '');
      if (parsed != null) return parsed;
    }
    try {
      final info = _repository.lastSystemInfo;
      if (info != null) return info.batteryLimit;
    } catch (_) {}
    return null;
  }

  Future<bool> setBatteryThreshold(int limit) async {
    assert(limit >= 30 && limit <= 100);
    // Write, then READ BACK: sysfs writes can fail silently (perms,
    // driver clamps). Only report success when the file holds the value.
    if (!await _writeThreshold(limit)) return false;
    await Future.delayed(const Duration(milliseconds: 150));
    return await readBatteryThreshold() == limit;
  }

  Future<bool> _writeThreshold(int limit) async {
    final path = batteryThresholdPath;
    if (path != null && await _writeSysfs(path, limit.toString())) {
      return true;
    }
    try {
      return await _repository.setBatteryLimit(limit);
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------------
  // Win/Fn key swap. Firmware encodings vary ("on"/"off" vs "1"/"0"),
  // so reads normalize to bool and writes preserve the existing encoding.
  // ------------------------------------------------------------------
  Future<bool?> readFnKeySwap() async {
    final raw = _readSysfs(fnKeyPath)?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    // Upstream msi-ec encodes the swap as left/right; older maps use on/off
    // or 1/0. Normalize everything to a bool for the toggle.
    if (raw == 'left') return false;
    if (raw == 'right') return true;
    return _isOn(raw);
  }

  Future<bool> setFnKeySwap(bool swapped) async {
    if (!supportsFnKeySwap) {
      // Native fallback (also handles encoding normalization in C++).
      try {
        return await _repository.setDeviceSetting('fn_key', swapped);
      } catch (_) {
        return false;
      }
    }
    final current = _readSysfs(fnKeyPath)?.trim().toLowerCase() ?? 'off';
    final String out;
    if (current == 'left' || current == 'right') {
      // Preserve the firmware encoding: flipping left<->right IS the swap.
      out = swapped ? 'right' : 'left';
    } else if (current == '1' || current == '0') {
      out = swapped ? '1' : '0';
    } else {
      out = swapped ? 'on' : 'off';
    }
    if (await _writeSysfs(fnKeyPath, out)) return true;
    try {
      return await _repository.setDeviceSetting('fn_key', swapped);
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------------
  // Low-level helpers: direct user-space I/O only. No processes, no sudo.
  // ------------------------------------------------------------------
  String? _readSysfs(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      return file.readAsStringSync().trim();
    } catch (_) {
      return null;
    }
  }

  Future<bool> _writeSysfs(String path, String value) async {
    try {
      await File(path).writeAsString(value, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isOn(String raw) {
    final v = raw.trim().toLowerCase();
    return v == 'on' || v == '1' || v == 'swapped' || v == 'left_win';
  }
}
