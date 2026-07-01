import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:msi_controller/domain/repositories/msi_repository.dart';
import 'package:msi_controller/domain/entities/system_info.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final MsiRepository _repository;
  static const String _prefKey = 'msi_settings';
  static const _kTimeout = Duration(seconds: 2);

  SettingsBloc(this._repository, SettingsState initialState)
    : super(initialState) {
    on<SetGpuModeEvent>(_onSetGpuMode);
    on<SetBatteryLimitEvent>(_onSetBatteryLimit);
    on<SetPerformanceModeEvent>(_onSetPerformanceMode);
    on<SetFanModeEvent>(_onSetFanMode);
    on<SetWebcamEnabledEvent>(_onSetWebcamEnabled);
    on<SetSuperBatteryEvent>(_onSetSuperBattery);
    on<SetPerformanceLevelEvent>(_onSetPerformanceLevel);
  }

  /// Wraps a hardware call with a timeout.
  /// Returns `false` if the call times out or throws.
  Future<bool> _safeCall(Future<bool> Function() call) async {
    try {
      return await call().timeout(_kTimeout);
    } catch (e) {
      debugPrint('[BLOC] Hardware call timed out or failed: $e');
      return false;
    }
  }

  GpuMode? _autoGpuForMode(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.silent:
      case PerformanceMode.superBattery:
        return GpuMode.integrated;
      case PerformanceMode.balanced:
        return GpuMode.dynamic;
      case PerformanceMode.extreme:
        return GpuMode.discrete;
      default:
        return null;
    }
  }

  FanMode _autoFanForMode(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.extreme:
        return FanMode.coolerBoost;
      default:
        return FanMode.auto;
    }
  }

  void applyInitialSettings() {
    _applyAllSettings(state);
  }

  void _applyAllSettings(SettingsState settings) {
    unawaited(_safeCall(() => _repository.setGpuMode(settings.gpuMode)));
    unawaited(
      _safeCall(() => _repository.setBatteryLimit(settings.batteryLimit)),
    );
    unawaited(
      _safeCall(() => _repository.setPerformanceMode(settings.performanceMode)),
    );
    unawaited(_safeCall(() => _repository.setFanMode(settings.fanMode)));
    unawaited(
      _safeCall(
        () => _repository.setDeviceSetting('webcam', settings.webcamEnabled),
      ),
    );
    unawaited(
      _safeCall(
        () => _repository.setSuperBattery(settings.superBatteryEnabled),
      ),
    );
  }

  Future<void> _onSetGpuMode(
    SetGpuModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(gpuMode: event.mode, isGpuLoading: true));
    await _yieldForUiFrame();

    await _safeCall(() => _repository.setGpuMode(event.mode));

    // Always clear loading — never get stuck
    emit(state.copyWith(isGpuLoading: false));
    unawaited(_saveSettings());
  }

  Future<void> _onSetBatteryLimit(
    SetBatteryLimitEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(batteryLimit: event.limit));
    final success = await _safeCall(
      () => _repository.setBatteryLimit(event.limit),
    );
    if (success) {
      unawaited(_saveSettings());
    }
  }

  Future<void> _onSetPerformanceMode(
    SetPerformanceModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    debugPrint('[BLOC] _onSetPerformanceMode called with: ${event.mode}');

    // 1. OPTIMISTIC UPDATE — Change selection state IMMEDIATELY
    // This triggers the highlight animation and UI transition before any hardware lag.
    final autoGpu = _autoGpuForMode(event.mode);
    final autoFan = _autoFanForMode(event.mode);
    final wasSuperBattery = state.superBatteryEnabled;

    emit(
      state.copyWith(
        performanceMode: event.mode,
        gpuMode: autoGpu ?? state.gpuMode,
        fanMode: autoFan,
        // Note: We don't set loading flags yet to keep UI interaction fluid
      ),
    );

    // 2. UI BREATHE — Allow the framework to paint the selection highlight
    await Future.delayed(const Duration(milliseconds: 100));

    // 3. APPLY LOADING STATE
    emit(
      state.copyWith(
        isPerformanceLoading: true,
        isGpuLoading: autoGpu != null,
        isFanLoading: true,
      ),
    );

    // 4. BACKGROUND HARDWARE SYNC
    // Fire all hardware calls. We use individual try/catches via _safeCall
    // to ensure one failing hardware piece doesn't block others or the UI.
    final List<Future> hardwareTasks = [
      _safeCall(() => _repository.setPerformanceMode(event.mode)),
      _safeCall(() => _repository.setFanMode(autoFan)),
    ];

    if (autoGpu != null) {
      hardwareTasks.add(_safeCall(() => _repository.setGpuMode(autoGpu)));
    }

    if (event.mode == PerformanceMode.superBattery) {
      hardwareTasks.add(_safeCall(() => _repository.setSuperBattery(true)));
    } else if (wasSuperBattery) {
      hardwareTasks.add(_safeCall(() => _repository.setSuperBattery(false)));
    }

    // Await all tasks in parallel — total lag is only as slow as the single slowest call
    await Future.wait(hardwareTasks);

    // 5. FINALIZE STATE
    emit(
      state.copyWith(
        isPerformanceLoading: false,
        isGpuLoading: false,
        isFanLoading: false,
        superBatteryEnabled: event.mode == PerformanceMode.superBattery,
      ),
    );

    unawaited(_saveSettings());
  }

  Future<void> _onSetFanMode(
    SetFanModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    // 1. Optimistic selection update
    emit(state.copyWith(fanMode: event.mode));

    // 2. UI paint breathing room
    await Future.delayed(const Duration(milliseconds: 100));

    // 3. Start hardware sync
    emit(state.copyWith(isFanLoading: true));

    await _safeCall(() => _repository.setFanMode(event.mode));

    // Remember fan mode for Customize mode
    if (state.performanceMode == PerformanceMode.user) {
      emit(state.copyWith(userFanMode: event.mode));
    }

    emit(state.copyWith(isFanLoading: false));
    unawaited(_saveSettings());
  }

  Future<void> _onSetWebcamEnabled(
    SetWebcamEnabledEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(webcamEnabled: event.enabled));
    final success = await _safeCall(
      () => _repository.setDeviceSetting('webcam', event.enabled),
    );
    if (success) {
      unawaited(_saveSettings());
    }
  }

  Future<void> _onSetSuperBattery(
    SetSuperBatteryEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(superBatteryEnabled: event.enabled));
    if (event.enabled) {
      // Super Battery implies silent mode
      emit(
        state.copyWith(
          performanceMode: PerformanceMode.superBattery,
          fanMode: FanMode.auto,
        ),
      );
    }
    await _safeCall(() => _repository.setSuperBattery(event.enabled));
    unawaited(_saveSettings());
  }

  Future<void> _onSetPerformanceLevel(
    SetPerformanceLevelEvent event,
    Emitter<SettingsState> emit,
  ) async {
    // 1. Optimistic update
    emit(state.copyWith(performanceLevel: event.level));

    // 2. UI paint room
    await Future.delayed(const Duration(milliseconds: 100));

    // 3. Start hardware sync
    emit(state.copyWith(isPerformanceLoading: true));

    // Auto-switch GPU based on performance level
    final targetGpu = event.level == PerformanceLevel.low
        ? GpuMode.integrated
        : GpuMode.discrete;

    final List<Future> tasks = [
      _safeCall(() => _repository.setPerformanceLevel(event.level.name)),
    ];

    if (state.gpuMode != targetGpu) {
      emit(
        state.copyWith(
          gpuMode: targetGpu,
          isGpuLoading: true,
          isGpuSwitching: true,
        ),
      );
      tasks.add(_safeCall(() => _repository.setGpuMode(targetGpu)));
    }

    await Future.wait(tasks);

    emit(
      state.copyWith(
        isPerformanceLoading: false,
        isGpuLoading: false,
        isGpuSwitching: false,
      ),
    );
    unawaited(_saveSettings());
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'gpuMode': state.gpuMode.name,
        'batteryLimit': state.batteryLimit,
        'performanceMode': state.performanceMode.name,
        'webcamEnabled': state.webcamEnabled,
        'superBatteryEnabled': state.superBatteryEnabled,
        'fanMode': state.fanMode.name,
        'performanceLevel': state.performanceLevel.name,
        'userFanMode': state.userFanMode?.name,
      };
      await prefs.setString(_prefKey, json.encode(map));
    } catch (e) {
      debugPrint('[BLOC] Failed to save settings: $e');
    }
  }

  Future<void> _yieldForUiFrame() async {
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
}
