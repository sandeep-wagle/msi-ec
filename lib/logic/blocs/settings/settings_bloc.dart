import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../domain/repositories/msi_repository.dart';
import '../../../domain/entities/system_info.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final MsiRepository _repository;
  static const String _prefKey = 'msi_settings';

  SettingsBloc(this._repository) : super(SettingsState.initial()) {
    on<LoadSettings>(_onLoadSettings);
    on<SetGpuModeEvent>(_onSetGpuMode);
    on<SetBatteryLimitEvent>(_onSetBatteryLimit);
    on<SetPerformanceModeEvent>(_onSetPerformanceMode);
    on<SetFanModeEvent>(_onSetFanMode);
    on<SetWebcamEnabledEvent>(_onSetWebcamEnabled);
    on<SetSuperBatteryEvent>(_onSetSuperBattery);
    on<SetPerformanceLevelEvent>(_onSetPerformanceLevel);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null) {
        final map = json.decode(jsonStr);
        final parsedPerformanceMode = PerformanceMode.fromString(
          map['performanceMode'] ?? 'balanced',
        );
        final newState = SettingsState(
          gpuMode: GpuMode.fromString(map['gpuMode'] ?? 'hybrid'),
          batteryLimit: map['batteryLimit'] ?? 100,
          performanceMode: parsedPerformanceMode == PerformanceMode.unknown
              ? PerformanceMode.balanced
              : parsedPerformanceMode,
          webcamEnabled: map['webcamEnabled'] ?? false,
          superBatteryEnabled: map['superBatteryEnabled'] ?? false,
          fanMode: FanMode.fromString(map['fanMode'] ?? 'auto'),
          performanceLevel: PerformanceLevel.fromString(
            map['performanceLevel'] ?? 'medium',
          ),
          userFanMode: map['userFanMode'] != null
              ? FanMode.fromString(map['userFanMode'])
              : null,
        );
        emit(newState);

        // Apply restored settings to hardware
        await _applyAllSettings(newState);
      }
    } catch (e) {
      // Fallback
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _applyAllSettings(SettingsState settings) async {
    await _repository.setGpuMode(settings.gpuMode);
    await _repository.setBatteryLimit(settings.batteryLimit);
    await _repository.setPerformanceMode(settings.performanceMode);
    await _repository.setFanMode(settings.fanMode);
    await _repository.setDeviceSetting('webcam', settings.webcamEnabled);
    await _repository.setSuperBattery(settings.superBatteryEnabled);
  }

  Future<void> _onSetGpuMode(
    SetGpuModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final previousMode = state.gpuMode;
    emit(state.copyWith(gpuMode: event.mode, isGpuLoading: true));
    await _yieldForUiFrame();
    final success = await _repository.setGpuMode(event.mode);
    if (success) {
      await _saveSettings();
    }
    emit(
      state.copyWith(
        isGpuLoading: false,
        gpuMode: success ? event.mode : previousMode,
      ),
    );
  }

  Future<void> _onSetBatteryLimit(
    SetBatteryLimitEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final previousLimit = state.batteryLimit;
    emit(state.copyWith(batteryLimit: event.limit));
    final success = await _repository.setBatteryLimit(event.limit);
    if (success) {
      await _saveSettings();
    } else {
      emit(state.copyWith(batteryLimit: previousLimit));
    }
  }

  Future<void> _onSetPerformanceMode(
    SetPerformanceModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final previousMode = state.performanceMode;
    final previousGpuMode = state.gpuMode;
    final previousFanMode = state.fanMode;

    debugPrint('[BLOC] _onSetPerformanceMode called with: ${event.mode}');

    // Handle User/Customize mode - set hardware to high performance but keep custom GPU/fan
    if (event.mode == PerformanceMode.user) {
      emit(
        state.copyWith(
          performanceMode: event.mode,
          fanMode: state.userFanMode ?? FanMode.auto,
          isPerformanceLoading: true,
        ),
      );
      await _yieldForUiFrame();
      // Set performance to high (same as extreme mode)
      final success = await _repository.setPerformanceMode(
        PerformanceMode.extreme,
      );
      if (success) {
        await _saveSettings();
        debugPrint(
          '[BLOC] User mode set to high performance, restored fan mode: ${state.userFanMode ?? FanMode.auto}',
        );
      } else {
        debugPrint('[BLOC] Failed to set high performance for user mode');
      }
      emit(state.copyWith(isPerformanceLoading: false));
      return;
    }

    emit(
      state.copyWith(performanceMode: event.mode, isPerformanceLoading: true),
    );
    await _yieldForUiFrame();
    final success = await _repository.setPerformanceMode(event.mode);

    if (!success) {
      debugPrint('[BLOC] Failed to set performance mode, reverting');
      emit(
        state.copyWith(
          performanceMode: previousMode,
          isPerformanceLoading: false,
        ),
      );
      return;
    }

    // Auto-link GPU mode based on performance scenario
    GpuMode? autoGpuMode;
    if (event.mode == PerformanceMode.silent) {
      autoGpuMode = GpuMode.integrated;
    } else if (event.mode == PerformanceMode.balanced) {
      autoGpuMode = GpuMode.dynamic;
    } else if (event.mode == PerformanceMode.extreme) {
      autoGpuMode = GpuMode.discrete;
    } else if (event.mode == PerformanceMode.superBattery) {
      autoGpuMode = GpuMode.integrated;
    }

    if (autoGpuMode != null) {
      emit(state.copyWith(gpuMode: autoGpuMode, isGpuLoading: true));
      final gpuSuccess = await _repository.setGpuMode(autoGpuMode);
      emit(
        state.copyWith(
          isGpuLoading: false,
          gpuMode: gpuSuccess ? autoGpuMode : previousGpuMode,
        ),
      );
    }

    // Auto-link fan mode based on performance scenario
    FanMode autoFanMode;
    if (event.mode == PerformanceMode.silent) {
      autoFanMode = FanMode.auto;
    } else if (event.mode == PerformanceMode.balanced) {
      autoFanMode = FanMode.auto;
    } else if (event.mode == PerformanceMode.extreme) {
      autoFanMode = FanMode.coolerBoost;
    } else if (event.mode == PerformanceMode.superBattery) {
      autoFanMode = FanMode.auto;
    } else {
      autoFanMode = FanMode.auto; // Default for any other modes
    }

    emit(state.copyWith(fanMode: autoFanMode, isFanLoading: true));
    final fanSuccess = await _repository.setFanMode(autoFanMode);
    if (fanSuccess) {
      await _saveSettings();
    }
    emit(
      state.copyWith(
        isFanLoading: false,
        fanMode: fanSuccess ? autoFanMode : previousFanMode,
      ),
    );

    if (event.mode == PerformanceMode.superBattery) {
      emit(
        state.copyWith(superBatteryEnabled: true, isPerformanceLoading: false),
      );
      final batterySuccess = await _repository.setSuperBattery(true);
      if (!batterySuccess) {
        emit(state.copyWith(superBatteryEnabled: false));
      }
    } else {
      emit(state.copyWith(isPerformanceLoading: false));
    }

    await _saveSettings();
  }

  Future<void> _onSetFanMode(
    SetFanModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final previousFanMode = state.fanMode;
    emit(state.copyWith(fanMode: event.mode, isFanLoading: true));
    await _yieldForUiFrame();
    final success = await _repository.setFanMode(event.mode);
    if (success) {
      await _saveSettings();
      // If in Customize mode, remember the fan mode
      if (state.performanceMode == PerformanceMode.user) {
        emit(state.copyWith(userFanMode: event.mode));
      }
    }
    emit(
      state.copyWith(
        isFanLoading: false,
        fanMode: success ? event.mode : previousFanMode,
      ),
    );
  }

  Future<void> _onSetWebcamEnabled(
    SetWebcamEnabledEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final previous = state.webcamEnabled;
    emit(state.copyWith(webcamEnabled: event.enabled));
    final success = await _repository.setDeviceSetting('webcam', event.enabled);
    if (success) {
      await _saveSettings();
    } else {
      emit(state.copyWith(webcamEnabled: previous));
    }
    emit(state.copyWith(isLoading: false));
  }

  Future<void> _onSetSuperBattery(
    SetSuperBatteryEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final previous = state.superBatteryEnabled;
    emit(state.copyWith(superBatteryEnabled: event.enabled));
    final success = await _repository.setSuperBattery(event.enabled);
    if (success) {
      await _saveSettings();
    } else {
      emit(state.copyWith(superBatteryEnabled: previous));
    }
    emit(state.copyWith(isLoading: false));
  }

  Future<void> _onSetPerformanceLevel(
    SetPerformanceLevelEvent event,
    Emitter<SettingsState> emit,
  ) async {
    debugPrint('[BLOC] _onSetPerformanceLevel called with: ${event.level}');
    debugPrint('[BLOC] Current gpuMode: ${state.gpuMode}');

    emit(
      state.copyWith(isPerformanceLoading: true, performanceLevel: event.level),
    );
    await _yieldForUiFrame();
    debugPrint(
      '[BLOC] Emitted new state with performanceLevel: ${event.level}',
    );

    // Auto-switch GPU based on performance level
    // Low = Integrated GPU, Medium/High/Turbo = Discrete GPU
    GpuMode targetGpu;
    if (event.level == PerformanceLevel.low) {
      targetGpu = GpuMode.integrated;
      debugPrint('[BLOC] Setting GPU to Integrated (low mode)');
    } else {
      targetGpu = GpuMode.discrete;
      debugPrint('[BLOC] Setting GPU to Discrete (high mode)');
    }

    // Only switch GPU if different from current
    if (state.gpuMode != targetGpu) {
      debugPrint('[BLOC] GPU mode changed, showing switching indicator');
      emit(
        state.copyWith(
          isGpuLoading: true,
          gpuMode: targetGpu,
          isGpuSwitching: true,
        ),
      );
      debugPrint('[BLOC] Calling repository.setGpuMode');
      final gpuResult = await _repository.setGpuMode(targetGpu);
      debugPrint('[BLOC] GPU switch result: $gpuResult');
      emit(state.copyWith(isGpuLoading: false, isGpuSwitching: false));
    } else {
      debugPrint('[BLOC] GPU mode unchanged, skipping');
    }

    await _saveSettings();
    debugPrint('[BLOC] Settings saved');
    emit(state.copyWith(isPerformanceLoading: false));
    debugPrint('[BLOC] isPerformanceLoading set to false');
  }

  Future<void> _saveSettings() async {
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
  }

  Future<void> _yieldForUiFrame() async {
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
}
