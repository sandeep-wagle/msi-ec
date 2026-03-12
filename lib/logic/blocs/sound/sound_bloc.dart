import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import '../../../domain/repositories/msi_repository.dart';
import 'sound_event.dart';
import 'sound_state.dart';

class SoundBloc extends Bloc<SoundEvent, SoundState> {
  final MsiRepository _repository;
  static const String _prefKey = 'sound_settings';

  // Preset values for each audio profile
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
    on<ChangeEffectGain>(_onChangeEffectGain, transformer: restartable());
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
          stereoWidth: (map['stereoWidth'] ?? 0.5).toDouble(),
          volumeBoost: systemVol > 0
              ? systemVol
              : (map['volumeBoost'] ?? 1.0).toDouble(),
          sampleRate: map['sampleRate'] ?? 48000,
          bassGain: (map['bassGain'] ?? 0.0).toDouble(),
          trebleGain: (map['trebleGain'] ?? 0.0).toDouble(),
          voiceGain: (map['voiceGain'] ?? 0.0).toDouble(),
        );
        emit(newState);

        // Apply restored settings to hardware/audio engine
        await _repository.setSoundProfile(newState.profile);
        await _repository.setSoundEQ(newState.eqGains);
        await _repository.setSoundSampleRate(newState.sampleRate);
        await _repository.setSoundEnhancement(
          'virtualSurround',
          newState.virtualSurround,
        );
        await _repository.setSoundEnhancement('bassBoost', newState.bassBoost);
        await _repository.setSoundEnhancement(
          'voiceClarity',
          newState.voiceClarity,
        );
        await _repository.setSoundEnhancement(
          'trebleEnhancer',
          newState.trebleEnhancer,
        );
        await _repository.setSoundEnhancement(
          'smartVolume',
          newState.smartVolume,
        );
        await _repository.setSoundStereoWidth(newState.stereoWidth);
        await _repository.setSoundVolumeBoost(newState.volumeBoost);
        await _repository.setSoundEffectGain('bass', newState.bassGain);
        await _repository.setSoundEffectGain('treble', newState.trebleGain);
        await _repository.setSoundEffectGain('voice', newState.voiceGain);
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
    emit(newState);

    // Load per-profile settings if available
    final profilePrefs = await SharedPreferences.getInstance();
    final profileBass = profilePrefs.getString('${event.profile}_bassGain');
    final profileTreble = profilePrefs.getString('${event.profile}_trebleGain');
    final profileVoice = profilePrefs.getString('${event.profile}_voiceGain');
    final profileEqGains = profilePrefs.getString('${event.profile}_eqGains');

    if (profileBass != null &&
        profileTreble != null &&
        profileVoice != null &&
        profileEqGains != null) {
      final loadedState = newState.copyWith(
        bassGain: double.tryParse(profileBass) ?? newState.bassGain,
        trebleGain: double.tryParse(profileTreble) ?? newState.trebleGain,
        voiceGain: double.tryParse(profileVoice) ?? newState.voiceGain,
        eqGains: List<double>.from(json.decode(profileEqGains)),
      );
      emit(loadedState);
      await _repository.setSoundEQ(loadedState.eqGains);
      await _repository.setSoundEffectGain('bass', loadedState.bassGain);
      await _repository.setSoundEffectGain('treble', loadedState.trebleGain);
      await _repository.setSoundEffectGain('voice', loadedState.voiceGain);
    }

    await _repository.setSoundProfile(event.profile);
    await _saveSettings();
  }

  Future<void> _onUpdateEQGains(
    UpdateEQGains event,
    Emitter<SoundState> emit,
  ) async {
    // Debounce: wait 250ms then apply
    emit(state.copyWith(eqGains: event.gains));
    await Future.delayed(const Duration(milliseconds: 250));
    await _repository.setSoundEQ(event.gains);
    await _saveSettings();
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
      default:
        return;
    }
    emit(newState);
    await _repository.setSoundEnhancement(event.enhancement, event.value);
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
    };
    await prefs.setString(_prefKey, json.encode(map));
  }

  Future<void> _onChangeEffectGain(
    ChangeEffectGain event,
    Emitter<SoundState> emit,
  ) async {
    switch (event.effect) {
      case 'bass':
        emit(state.copyWith(bassGain: event.gain));
        break;
      case 'treble':
        emit(state.copyWith(trebleGain: event.gain));
        break;
      case 'voice':
        emit(state.copyWith(voiceGain: event.gain));
        break;
    }
    // Debounce 200ms before applying to PipeWire
    await Future.delayed(const Duration(milliseconds: 200));
    await _repository.setSoundEffectGain(event.effect, event.gain);
    await _saveSettings();
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
    emit(state.copyWith(volumeBoost: event.boost));
    await _repository.setSoundVolumeBoost(event.boost);
    await _saveSettings();
  }
}
