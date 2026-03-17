import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../../domain/repositories/msi_repository.dart';
import 'sound_event.dart';
import 'sound_state.dart';

class SoundBloc extends Bloc<SoundEvent, SoundState> {
  final MsiRepository _repository;
  static const String _prefKey = 'sound_settings';


  static final Map<String, Map<String, dynamic>> _profilePresets = {
    'Music': {
      'eqGains': [2.0, 1.5, 0.5, 0.0, 0.0, -1.0, -1.5, -2.0, -2.5, -3.0],
      'bassGain': 8.0,
      'trebleGain': 2.0,
      'voiceGain': 4.0,
    },
    'Gaming': {
      'eqGains': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      'bassGain': 4.0,
      'trebleGain': 4.0,
      'voiceGain': 6.0,
    },
    'Movie': {
      'eqGains': [3.0, 2.0, 1.0, 0.5, 0.0, -0.5, -1.0, -1.5, -2.0, -2.5],
      'bassGain': 6.0,
      'trebleGain': 3.0,
      'voiceGain': 8.0,
    },
    'Voice': {
      'eqGains': [-2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 2.0, 1.0, 0.0, -1.0],
      'bassGain': 2.0,
      'trebleGain': 6.0,
      'voiceGain': 10.0,
    },
    'Custom': {
      'eqGains': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      'bassGain': 0.0,
      'trebleGain': 0.0,
      'voiceGain': 0.0,
    },
  };

  SoundBloc(this._repository) : super(SoundState.initial()) {
    on<LoadSoundSettings>(_onLoadSoundSettings);
    on<SetSoundProfile>(_onSetSoundProfile, transformer: restartable());
    on<UpdateEQGains>(_onUpdateEQGains, transformer: restartable());
    on<ToggleEnhancement>(_onToggleEnhancement, transformer: restartable());
    on<ChangeSampleRate>(_onChangeSampleRate, transformer: restartable());
    on<ChangeStereoWidth>(_onChangeStereoWidth, transformer: restartable());
    on<ChangeVolumeBoost>(_onChangeVolumeBoost, transformer: restartable());
    on<ChangeVolumeBoostPreview>(_onChangeVolumeBoostPreview, transformer: restartable());
    on<ChangeEffectGain>(_onChangeEffectGain, transformer: restartable());
    on<ChangeEffectGainPreview>(_onChangeEffectGainPreview, transformer: restartable());
    on<UpdateEQGainsPreview>(_onUpdateEQGainsPreview, transformer: restartable());
    on<ChangeNoiseLevel>(_onChangeNoiseLevel, transformer: restartable());
    on<ToggleLimiter>(_onToggleLimiter, transformer: restartable());
    on<ChangeCompressorRatio>(_onChangeCompressorRatio, transformer: restartable());
    on<ChangeSurroundVariation>(_onChangeSurroundVariation, transformer: restartable());
    on<ChangeMicrophoneGain>(_onChangeMicrophoneGain, transformer: restartable());
    on<ResetSoundSettings>(_onResetSoundSettings);
    on<SyncVolume>(_onSyncVolume);

    _repository.volumeStream.listen((vol) {
      add(SyncVolume(vol));
    });
  }

  Future<void> _onSyncVolume(SyncVolume event, Emitter<SoundState> emit) async {
    emit(state.copyWith(volumeBoost: event.volume));
  }

  Future<void> _onLoadSoundSettings(
    LoadSoundSettings event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final systemVol = _repository.currentVolume;

      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null) {
        final map = json.decode(jsonStr);
        final newState = SoundState(
          profile: map['profile'] ?? 'Gaming',
          eqGains: List<double>.from(
            map['eqGains'] ?? List.generate(10, (_) => 0.0),
          ),
          virtualSurround: map['virtualSurround'] ?? true,
          bassBoost: map['bassBoost'] ?? false,
          voiceClarity: map['voiceClarity'] ?? true,
          trebleEnhancer: map['trebleEnhancer'] ?? false,
          smartVolume: map['smartVolume'] ?? false,
          stereoWidth: (map['stereoWidth'] ?? 1.2).toDouble(), // Increased default for better effect
          volumeBoost: systemVol > 0
              ? systemVol
              : (map['volumeBoost'] ?? 1.0).toDouble(),
          sampleRate: map['sampleRate'] ?? 48000,
          bassGain: (map['bassGain'] ?? 0.0).toDouble(),
          trebleGain: (map['trebleGain'] ?? 0.0).toDouble(),
          voiceGain: (map['voiceGain'] ?? 0.0).toDouble(),
          noiseLevel: (map['noiseLevel'] ?? 2.0).toDouble(),
          limiterEnabled: map['limiterEnabled'] ?? false,
          compressorRatio: (map['compressorRatio'] ?? 5.0).toDouble(),
          trackerEnabled: map['trackerEnabled'] ?? false,
          sharingEnabled: map['sharingEnabled'] ?? false,
          microphoneGain: (map['microphoneGain'] ?? 1.0).toDouble(),
          surroundVariation: map['surroundVariation'] ?? 'Surround',
          nightMode: map['nightMode'] ?? false,
          effectsEnabled: map['effectsEnabled'] ?? true,
          micEnabled: map['micEnabled'] ?? true,
          micNoiseSuppression: map['micNoiseSuppression'] ?? false,
          echoCancellation: map['echoCancellation'] ?? false,
        );
        emit(newState);

        // Set profile name in repo FIRST so UPDATE commands use the right name.
        _repository.setActiveProfileName(newState.profile);

        const timeout = Duration(seconds: 1);
        unawaited(_repository.setSoundProfile(newState.profile));
        
        try {
          await _repository.setSoundEQ(newState.eqGains).timeout(timeout);
          await _repository.setSoundSampleRate(newState.sampleRate).timeout(timeout);
          await _repository.setSoundEnhancement('virtualSurround', newState.virtualSurround).timeout(timeout);
          await _repository.setSoundEnhancement('bassBoost', newState.bassBoost).timeout(timeout);
          await _repository.setSoundEnhancement('voiceClarity', newState.voiceClarity).timeout(timeout);
          await _repository.setSoundEnhancement('trebleEnhancer', newState.trebleEnhancer).timeout(timeout);
          await _repository.setSoundEnhancement('smartVolume', newState.smartVolume).timeout(timeout);
          await _repository.setSoundStereoWidth(newState.stereoWidth).timeout(timeout);
          await _repository.setSoundVolumeBoost(newState.volumeBoost).timeout(timeout);
          await _repository.setSoundEffectGain('bass', newState.bassGain).timeout(timeout);
          await _repository.setSoundEffectGain('treble', newState.trebleGain).timeout(timeout);
          await _repository.setSoundEffectGain('voice', newState.voiceGain).timeout(timeout);
          await _repository.setSoundNoiseLevel(newState.noiseLevel).timeout(timeout);
          await _repository.setSoundLimiterEnabled(newState.limiterEnabled).timeout(timeout);
          await _repository.setSoundCompressorRatio(newState.compressorRatio).timeout(timeout);
          await _repository.setSoundSurroundVariation(newState.surroundVariation).timeout(timeout);
          await _repository.setSoundNightMode(newState.nightMode).timeout(timeout);
          await _repository.setSoundEffectsEnabled(newState.effectsEnabled).timeout(timeout);
          await _repository.setSoundMicEnabled(newState.micEnabled).timeout(timeout);
          await _repository.setSoundMicGain(newState.microphoneGain).timeout(timeout);
          await _repository.setSoundMicNoiseSuppression(newState.micNoiseSuppression).timeout(timeout);
          await _repository.setSoundEchoCancellation(newState.echoCancellation).timeout(timeout);
        } catch (e) {
          debugPrint('SoundBloc: Timeout or error during initial hardware sync: $e');
        }
      }
    } catch (e) {
      // Fallback to initial if error
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onSetSoundProfile(
    SetSoundProfile event,
    Emitter<SoundState> emit,
  ) async {
    debugPrint('SoundBloc: Setting sound profile to ${event.profile}');

    // FIX 1: Update profile name in the repository FIRST.
    // setSoundEffectGain calls _updateDspRealtime which builds
    // UPDATE:{name:_soundProfileName, ...}. Without this, the UPDATE would
    // carry the OLD profile name every time and save gains to the wrong file.
    _repository.setActiveProfileName(event.profile);

    // Build initial state from hardcoded presets.
    final preset = _profilePresets[event.profile];
    SoundState newState;
    if (preset != null && event.profile != 'Custom') {
      newState = state.copyWith(
        profile: event.profile,
        eqGains: List<double>.from(preset['eqGains']),
        bassGain: preset['bassGain'],
        trebleGain: preset['trebleGain'],
        voiceGain: preset['voiceGain'],
      );
    } else {
      newState = state.copyWith(profile: event.profile);
    }

    // Override with any previously-saved per-profile customisations.
    final profilePrefs = await SharedPreferences.getInstance();
    final profileBass = profilePrefs.getString('${event.profile}_bassGain');
    final profileTreble = profilePrefs.getString('${event.profile}_trebleGain');
    final profileVoice = profilePrefs.getString('${event.profile}_voiceGain');
    final profileEqGains = profilePrefs.getString('${event.profile}_eqGains');

    if (profileBass != null) {
      newState = newState.copyWith(
        bassGain: double.tryParse(profileBass) ?? newState.bassGain,
      );
    }
    if (profileTreble != null) {
      newState = newState.copyWith(
        trebleGain: double.tryParse(profileTreble) ?? newState.trebleGain,
      );
    }
    if (profileVoice != null) {
      newState = newState.copyWith(
        voiceGain: double.tryParse(profileVoice) ?? newState.voiceGain,
      );
    }
    if (profileEqGains != null) {
      try {
        newState = newState.copyWith(
          eqGains: List<double>.from(json.decode(profileEqGains)),
        );
      } catch (_) {
        // Keep resolved preset values if persisted EQ data is malformed.
      }
    }

    emit(newState);
    debugPrint('SoundBloc: Emitted new state for profile ${event.profile}');

    // Push all resolved values to the DSP engine with the CORRECT profile name.
    await _repository.setSoundEQ(newState.eqGains);
    await _repository.setSoundEffectGain('bass', newState.bassGain);
    await _repository.setSoundEffectGain('treble', newState.trebleGain);
    await _repository.setSoundEffectGain('voice', newState.voiceGain);

    // FIX 2: setSoundProfile is fire-and-forget here — we only call it so the
    // DSP service updates its internal bookkeeping / LOAD response cache.
    // We no longer read back its response values (which previously overwrote
    // Flutter's saved customisations with DSP defaults).
    unawaited(_repository.setSoundProfile(event.profile));

    await _saveSettings();
    debugPrint('SoundBloc: Profile ${event.profile} setup complete');
  }

  Future<void> _onUpdateEQGains(
    UpdateEQGains event,
    Emitter<SoundState> emit,
  ) async {
    // FIX 3 & Safety: Ensure we don't spam if nothing actually changed
    bool changed = false;
    for (int i = 0; i < event.gains.length; i++) {
       if ((event.gains[i] - state.eqGains[i]).abs() > 0.01) {
         changed = true;
         break;
       }
    }
    if (!changed) return;

    final roundedGains = event.gains.map((g) => g.roundToDouble()).toList();
    emit(state.copyWith(eqGains: roundedGains));
    await _repository.setSoundEQ(roundedGains);
    await _saveSettings();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${state.profile}_eqGains',
      json.encode(state.eqGains),
    );
  }

  Future<void> _onUpdateEQGainsPreview(
    UpdateEQGainsPreview event,
    Emitter<SoundState> emit,
  ) async {
    final roundedGains = event.gains.map((g) => g.roundToDouble()).toList();
    emit(state.copyWith(eqGains: roundedGains));
  }

  Future<void> _onToggleEnhancement(
    ToggleEnhancement event,
    Emitter<SoundState> emit,
  ) async {
    SoundState newState;
    switch (event.enhancement) {
      case 'virtualSurround':
        newState = state.copyWith(virtualSurround: event.value);
        break;
      case 'bassBoost':
        newState = state.copyWith(bassBoost: event.value);
        break;
      case 'voiceClarity':
        newState = state.copyWith(voiceClarity: event.value);
        break;
      case 'trebleEnhancer':
        newState = state.copyWith(trebleEnhancer: event.value);
        break;
      case 'smartVolume':
        newState = state.copyWith(smartVolume: event.value);
        break;
      case 'trackerEnabled':
        newState = state.copyWith(trackerEnabled: event.value);
        break;
      case 'sharingEnabled':
        newState = state.copyWith(sharingEnabled: event.value);
        break;
      case 'limiterEnabled':
        newState = state.copyWith(limiterEnabled: event.value);
        await _repository.setSoundLimiterEnabled(event.value);
        break;
      case 'nightMode':
        newState = state.copyWith(nightMode: event.value);
        await _repository.setSoundNightMode(event.value);
        break;
      case 'effectsEnabled':
        newState = state.copyWith(effectsEnabled: event.value);
        await _repository.setSoundEffectsEnabled(event.value);
        break;
      case 'micEnabled':
        newState = state.copyWith(micEnabled: event.value);
        await _repository.setSoundMicEnabled(event.value);
        break;
      case 'micNoiseSuppression':
        newState = state.copyWith(micNoiseSuppression: event.value);
        await _repository.setSoundMicNoiseSuppression(event.value);
        break;
      case 'echoCancellation':
        newState = state.copyWith(echoCancellation: event.value);
        await _repository.setSoundEchoCancellation(event.value);
        break;
      default:
        return;
    }
    emit(newState);
    if (event.enhancement != 'limiterEnabled' && 
        event.enhancement != 'nightMode' && 
        event.enhancement != 'effectsEnabled' && 
        event.enhancement != 'micEnabled' && 
        event.enhancement != 'micNoiseSuppression' &&
        event.enhancement != 'echoCancellation') {
      await _repository.setSoundEnhancement(event.enhancement, event.value);
    }
    await _saveSettings();
  }

  Future<void> _onChangeSampleRate(
    ChangeSampleRate event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(sampleRate: event.hertz));
    await _repository.setSoundSampleRate(event.hertz);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'profile': state.profile,
      'eqGains': state.eqGains,
      'virtualSurround': state.virtualSurround,
      'bassBoost': state.bassBoost,
      'voiceClarity': state.voiceClarity,
      'trebleEnhancer': state.trebleEnhancer,
      'smartVolume': state.smartVolume,
      'stereoWidth': state.stereoWidth,
      'volumeBoost': state.volumeBoost,
      'sampleRate': state.sampleRate,
      'bassGain': state.bassGain,
      'trebleGain': state.trebleGain,
      'voiceGain': state.voiceGain,
      'noiseLevel': state.noiseLevel,
      'limiterEnabled': state.limiterEnabled,
      'compressorRatio': state.compressorRatio,
      'trackerEnabled': state.trackerEnabled,
      'sharingEnabled': state.sharingEnabled,
      'microphoneGain': state.microphoneGain,
      'surroundVariation': state.surroundVariation,
      'nightMode': state.nightMode,
      'effectsEnabled': state.effectsEnabled,
      'micEnabled': state.micEnabled,
      'micNoiseSuppression': state.micNoiseSuppression,
      'echoCancellation': state.echoCancellation,
    };
    await prefs.setString(_prefKey, json.encode(map));
  }

  Future<void> _onChangeEffectGain(
    ChangeEffectGain event,
    Emitter<SoundState> emit,
  ) async {
    // FIX 3: Guard against duplicate values
    double currentGain = 0.0;
    if (event.effect == 'bass') currentGain = state.bassGain;
    if (event.effect == 'treble') currentGain = state.trebleGain;
    if (event.effect == 'voice') currentGain = state.voiceGain;

    final roundedGain = event.gain.roundToDouble();

    if ((roundedGain - currentGain).abs() < 0.1) {
      debugPrint('SoundBloc: Effect ${event.effect} gain unchanged after rounding, skipping DSP commit');
      return;
    }

    debugPrint('SoundBloc: COMMITTING effect gain change - ${event.effect}: $roundedGain');

    switch (event.effect) {
      case 'bass':
        emit(state.copyWith(bassGain: roundedGain));
        break;
      case 'treble':
        emit(state.copyWith(trebleGain: roundedGain));
        break;
      case 'voice':
        emit(state.copyWith(voiceGain: roundedGain));
        break;
    }

    try {
      await _repository.setSoundEffectGain(event.effect, roundedGain);
      await _saveSettings();
      // Persist per-profile gains
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${state.profile}_bassGain', state.bassGain.toString());
      await prefs.setString('${state.profile}_trebleGain', state.trebleGain.toString());
      await prefs.setString('${state.profile}_voiceGain', state.voiceGain.toString());
    } catch (e) {
      debugPrint('SoundBloc: Error applying DSP update: $e');
    }
  }

  Future<void> _onChangeEffectGainPreview(
    ChangeEffectGainPreview event,
    Emitter<SoundState> emit,
  ) async {
    final roundedGain = event.gain.roundToDouble();
    switch (event.effect) {
      case 'bass':
        emit(state.copyWith(bassGain: roundedGain));
        break;
      case 'treble':
        emit(state.copyWith(trebleGain: roundedGain));
        break;
      case 'voice':
        emit(state.copyWith(voiceGain: roundedGain));
        break;
    }
  }

  Future<void> _onChangeStereoWidth(
    ChangeStereoWidth event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(stereoWidth: event.width));
    await _repository.setSoundStereoWidth(event.width);
    await _saveSettings();
  }

  Future<void> _onChangeVolumeBoost(
    ChangeVolumeBoost event,
    Emitter<SoundState> emit,
  ) async {
    // FIX 2: Clamp volume to 1.0 safely
    final clampedBoost = event.boost.clamp(0.0, 1.0);
    
    if ((clampedBoost - state.volumeBoost).abs() < 0.01) return;

    emit(state.copyWith(volumeBoost: clampedBoost));
    await _repository.setSoundVolumeBoost(clampedBoost);
    await _saveSettings();
  }

  Future<void> _onChangeVolumeBoostPreview(
    ChangeVolumeBoostPreview event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(volumeBoost: event.boost.clamp(0.0, 1.0)));
  }

  Future<void> _onChangeNoiseLevel(
    ChangeNoiseLevel event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(noiseLevel: event.level));
    await _repository.setSoundNoiseLevel(event.level);
    await _saveSettings();
  }

  Future<void> _onToggleLimiter(
    ToggleLimiter event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(limiterEnabled: event.enabled));
    await _repository.setSoundLimiterEnabled(event.enabled);
    await _saveSettings();
  }

  Future<void> _onChangeCompressorRatio(
    ChangeCompressorRatio event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(compressorRatio: event.ratio));
    await _repository.setSoundCompressorRatio(event.ratio);
    await _saveSettings();
  }

  Future<void> _onChangeSurroundVariation(
    ChangeSurroundVariation event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(surroundVariation: event.variation));
    await _repository.setSoundSurroundVariation(event.variation);
    await _saveSettings();
  }

  Future<void> _onChangeMicrophoneGain(
    ChangeMicrophoneGain event,
    Emitter<SoundState> emit,
  ) async {
    emit(state.copyWith(microphoneGain: event.gain));
    await _repository.setSoundMicGain(event.gain);
    await _saveSettings();
  }

  Future<void> _onResetSoundSettings(
    ResetSoundSettings event,
    Emitter<SoundState> emit,
  ) async {
    final newState = SoundState.initial();
    emit(newState);
    await _repository.setSoundProfile(newState.profile);
    await _repository.setSoundEQ(newState.eqGains);
    await _repository.setSoundEnhancement('virtualSurround', newState.virtualSurround);
    await _repository.setSoundEnhancement('bassBoost', newState.bassBoost);
    await _repository.setSoundEnhancement('voiceClarity', newState.voiceClarity);
    await _repository.setSoundEnhancement('trebleEnhancer', newState.trebleEnhancer);
    await _repository.setSoundEnhancement('smartVolume', newState.smartVolume);
    await _repository.setSoundStereoWidth(newState.stereoWidth);
    await _repository.setSoundVolumeBoost(newState.volumeBoost);
    await _repository.setSoundEffectGain('bass', newState.bassGain);
    await _repository.setSoundEffectGain('treble', newState.trebleGain);
    await _repository.setSoundEffectGain('voice', newState.voiceGain);
    await _repository.setSoundNoiseLevel(newState.noiseLevel);
    await _repository.setSoundLimiterEnabled(newState.limiterEnabled);
    await _repository.setSoundCompressorRatio(newState.compressorRatio);
    await _repository.setSoundSurroundVariation(newState.surroundVariation);
    await _repository.setSoundNightMode(newState.nightMode);
    await _repository.setSoundEffectsEnabled(newState.effectsEnabled);
    await _repository.setSoundMicEnabled(newState.micEnabled);
    await _repository.setSoundMicGain(newState.microphoneGain);
    await _repository.setSoundMicNoiseSuppression(newState.micNoiseSuppression);
    await _repository.setSoundEchoCancellation(newState.echoCancellation);
    await _saveSettings();
  }
}
