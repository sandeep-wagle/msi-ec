import 'dart:io';

/// User-space Hyprland input controls.
///
/// CRITICAL: every command here runs as the normal login user via
/// `hyprctl` with NO `sudo`/`pkexec` prefix. Hyprland's IPC socket lives in
/// `$XDG_RUNTIME_DIR/hypr/...` and is only reachable by the user that owns
/// the compositor session — elevating to root would both pop up a password
/// prompt AND break the socket connection.
///
/// Works on ALL Linux devices:
/// - On Hyprland: commands apply live.
/// - Anywhere else (GNOME/KDE/TTY, hyprctl missing): [isAvailable] is false
///   and every setter is a harmless no-op returning false, so callers can
///   render an "unavailable" state instead of crashing.
class HyprlandService {
  static const String keywordSensitivity = 'input:sensitivity';
  static const String keywordNaturalScroll = 'input:touchpad:natural_scroll';
  static const String keywordAccelProfile = 'input:accel_profile';

  bool? _cachedAvailable;
  String? _instanceSig;
  String? _runtimeDir;

  /// Resolve the Hyprland instance signature, preferring the environment
  /// and falling back to scanning the runtime dir for live instances
  /// (hyprland.lock marker). Null when no compositor is reachable — this
  /// is what makes the tab work no matter how the app was launched
  /// (desktop terminal, autostart without env, IDE debugger, ...).
  Future<String?> _resolveInstance() async {
    if (_instanceSig != null) return _instanceSig;
    final envSig = Platform.environment['HYPRLAND_INSTANCE_SIGNATURE'];
    if (envSig != null && envSig.isNotEmpty) {
      _instanceSig = envSig;
      return _instanceSig;
    }
    final runtime = await _runtimeDirPath();
    if (runtime == null) return null;
    try {
      await for (final ent in Directory('$runtime/hypr').list()) {
        if (ent is Directory &&
            await File('${ent.path}/hyprland.lock').exists()) {
          final sig = ent.uri.pathSegments
              .where((s) => s.isNotEmpty)
              .last;
          // Verify it answers before trusting it.
          final probe = await Process.run(
              'hyprctl', ['-i', sig, 'version'],
              runInShell: false);
          if (probe.exitCode == 0) {
            _instanceSig = sig;
            return _instanceSig;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _runtimeDirPath() async {
    if (_runtimeDir != null) return _runtimeDir;
    final env = Platform.environment['XDG_RUNTIME_DIR'];
    if (env != null && env.isNotEmpty) {
      _runtimeDir = env;
      return _runtimeDir;
    }
    try {
      final id = await Process.run('id', ['-u'], runInShell: false);
      if (id.exitCode == 0) {
        final uid = id.stdout.toString().trim();
        final dir = Directory('/run/user/$uid');
        if (await dir.exists()) {
          _runtimeDir = dir.path;
          return _runtimeDir;
        }
      }
    } catch (_) {}
    if (await Directory('/run/user/1000').exists()) {
      _runtimeDir = '/run/user/1000';
      return _runtimeDir;
    }
    return null;
  }

  /// True when a Hyprland instance actually answers (not merely when the
  /// binary exists — the old `hyprctl version` probe lied without a
  /// reachable socket).
  Future<bool> isAvailable() async {
    if (_cachedAvailable != null) return _cachedAvailable!;
    try {
      final which = await Process.run('which', ['hyprctl']);
      if (which.exitCode != 0) {
        _cachedAvailable = false;
        return false;
      }
      _cachedAvailable = await _resolveInstance() != null;
      return _cachedAvailable!;
    } catch (_) {
      _cachedAvailable = false;
      return false;
    }
  }

  void invalidateCache() {
    _cachedAvailable = null;
    _instanceSig = null;
  }

  /// Runs `hyprctl` as the current user against the resolved instance.
  /// Never elevated, never a shell.
  Future<ProcessResult> _hyprctl(List<String> args) async {
    final sig = await _resolveInstance();
    final full = sig == null ? args : ['-i', sig, ...args];
    // Assigned (not returned directly) so the future always completes inside
    // this try block and failures surface as false from the callers.
    final result = await Process.run('hyprctl', full, runInShell: false);
    return result;
  }

  Future<bool> _keyword(String key, String value) async {
    try {
      final result = await _hyprctl(['keyword', key, value]);
      final output =
          '${result.stdout} ${result.stderr}'.toLowerCase();
      if (result.exitCode == 0 &&
          !output.contains('non-legacy') &&
          !output.contains("can't work")) {
        return true;
      }
      // Omarchy / Lua-configured Hyprland rejects `keyword`: apply the same
      // option live through the Lua runtime instead (still unprivileged).
      final applied = await _evalOption(key, value);
      return applied;
    } catch (_) {
      return false;
    }
  }

  /// Applies a `scope:sub:key` option via `hyprctl eval 'hl.config({...})'`
  /// for compositors whose legacy `keyword` parser is disabled (Omarchy).
  Future<bool> _evalOption(String key, String value) async {
    final luaValue = _luaLiteral(key, value);
    if (luaValue == null) return false;
    try {
      final snippet = _luaFor(key, luaValue);
      final result = await _hyprctl(['eval', snippet]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Renders the CLI string value as a Lua literal of the correct type.
  String? _luaLiteral(String key, String value) {
    if (key == keywordNaturalScroll) {
      if (value == 'true') return 'true';
      if (value == 'false') return 'false';
      return null;
    }
    if (key == keywordSensitivity) {
      return double.tryParse(value)?.toStringAsFixed(2);
    }
    if (key == keywordAccelProfile) {
      if (value == 'flat' || value == 'adaptive') return '"$value"';
      return null;
    }
    return null;
  }

  String _luaFor(String key, String luaValue) {
    switch (key) {
      case keywordSensitivity:
        return 'hl.config({ input = { sensitivity = $luaValue } })';
      case keywordNaturalScroll:
        return 'hl.config({ input = { touchpad = { natural_scroll = $luaValue } } })';
      case keywordAccelProfile:
        return 'hl.config({ input = { accel_profile = $luaValue } })';
      default:
        return 'hl.config({})';
    }
  }

  // ------------------------------------------------------------------
  // Pointer sensitivity: -1.0 (slow) .. 1.0 (fast), default 0.0.
  // ------------------------------------------------------------------
  Future<double?> getSensitivity() async {
    try {
      final result = await _hyprctl(['getoption', keywordSensitivity]);
      if (result.exitCode != 0) return null;
      final match =
          RegExp(r'float:\s*(-?\d+(?:\.\d+)?)').firstMatch(result.stdout.toString());
      return match == null ? null : double.tryParse(match.group(1)!);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setSensitivity(double value) async {
    final clamped = value.clamp(-1.0, 1.0);
    final ok = await _keyword(
        keywordSensitivity, clamped.toStringAsFixed(2));
    if (ok) await persistSensitivity(clamped);
    return ok;
  }

  // ------------------------------------------------------------------
  // Touchpad natural scrolling.
  // ------------------------------------------------------------------
  Future<bool?> getNaturalScroll() async {
    try {
      final result = await _hyprctl(['getoption', keywordNaturalScroll]);
      if (result.exitCode != 0) return null;
      final out = result.stdout.toString();
      if (RegExp(r'int:\s*1|true').hasMatch(out)) return true;
      if (RegExp(r'int:\s*0|false').hasMatch(out)) return false;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setNaturalScroll(bool enabled) async {
    final ok =
        await _keyword(keywordNaturalScroll, enabled ? 'true' : 'false');
    if (ok) await persistNaturalScroll(enabled);
    return ok;
  }

  // ------------------------------------------------------------------
  // Mouse acceleration profile: `flat` vs `adaptive`.
  // ------------------------------------------------------------------
  Future<String?> getAccelProfile() async {
    try {
      final result = await _hyprctl(['getoption', keywordAccelProfile]);
      if (result.exitCode != 0) return null;
      final out = result.stdout.toString().toLowerCase();
      if (out.contains('flat')) return 'flat';
      if (out.contains('adaptive')) return 'adaptive';
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setAccelProfile(String profile) async {
    assert(profile == 'flat' || profile == 'adaptive');
    final ok = await _keyword(keywordAccelProfile, profile);
    if (ok) await persistAccelProfile(profile);
    return ok;
  }

  // ------------------------------------------------------------------
  // Persistence: merge into ~/.config/hypr/input.lua (Omarchy/Lua config).
  //
  // The user's file is hand-crafted, so we NEVER overwrite it wholesale:
  // existing `sensitivity = ...` / `natural_scroll = ...` /
  // `accel_profile = ...` lines are updated in place, and missing keys are
  // appended in a clearly-marked managed block. Everything else is kept
  // byte-for-byte, so this is safe on any distro / dotfiles setup.
  // ------------------------------------------------------------------
  static String get inputLuaPath {
    final home =
        Platform.environment['HOME'] ?? '/home/${Platform.environment['USER'] ?? 'user'}';
    return '$home/.config/hypr/input.lua';
  }

  Future<void> persistSensitivity(double value) =>
      _upsertInputLua('sensitivity', value.toStringAsFixed(2));

  Future<void> persistNaturalScroll(bool enabled) =>
      _upsertInputLua('natural_scroll', enabled ? 'true' : 'false');

  Future<void> persistAccelProfile(String profile) =>
      _upsertInputLua('accel_profile', '"$profile"');

  Future<void> _upsertInputLua(String key, String luaValue) async {
    try {
      final file = File(inputLuaPath);
      if (!await file.exists()) {
        await file.parent.create(recursive: true);
        await file.writeAsString(
          '-- Created by MSI Center (Controls tab).\n'
          'hl.config({\n'
          '  input = {\n'
          '    $key = $luaValue,\n'
          '  },\n'
          '})\n',
        );
        return;
      }
      var content = await file.readAsString();
      final pattern = RegExp(
          '(^|\\n)(\\s*)${RegExp.escape(key)}\\s*=\\s*[^,\\n]+');
      if (pattern.hasMatch(content)) {
        content = content.replaceAllMapped(
          pattern,
          (m) => '${m.group(1)}${m.group(2)}$key = $luaValue',
        );
      } else {
        content =
            '${content.trimRight()}\n\n-- Managed by MSI Center (Controls tab): persists reboot-safe input defaults.\n'
            'hl.config({\n'
            '  input = {\n'
            '    $key = $luaValue,\n'
            '  },\n'
            '})\n';
      }
      await file.writeAsString(content);
    } catch (_) {
      // Persistence is best-effort; the live hyprctl call already applied.
    }
  }
}
