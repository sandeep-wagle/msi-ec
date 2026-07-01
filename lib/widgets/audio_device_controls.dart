import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msi_controller/logic/blocs/audio/audio_bloc.dart';
import 'package:msi_controller/logic/blocs/audio/audio_event.dart';
import 'package:msi_controller/logic/blocs/audio/audio_state.dart';
import 'package:msi_controller/core/ui/widgets/effect_control.dart';

class AudioDeviceControls extends StatelessWidget {
  const AudioDeviceControls({super.key});

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType) {
      case 'headphones':
        return Icons.headphones;
      case 'earphones':
        return Icons.earbuds;
      case 'speakers':
        return Icons.speaker;
      default:
        return Icons.volume_up;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioBloc, AudioState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!state.hasActiveDevice) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No audio device detected'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getDeviceIcon(state.activeDevice!.type), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.activeDevice!.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Profile: ${state.activeProfile?.profileName ?? 'Loading...'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('DSP Effects'),
                const SizedBox(height: 8),

                EffectControl(
                  label: 'Surround Sound',
                  isEnabled: state.activeProfile?.powerSurround ?? false,
                  value: state.activeProfile?.surroundLevel ?? 0.5,
                  onToggle: (enabled) => context.read<AudioBloc>().add(
                    ToggleDeviceEffectPower(
                      state.activeDevice!.id,
                      'surround',
                      enabled,
                    ),
                  ),
                  onSliderChanged: (state.activeProfile?.powerSurround ?? false)
                      ? (value) => context.read<AudioBloc>().add(
                          UpdateDeviceEffectLevel(
                            state.activeDevice!.id,
                            'surround',
                            value,
                          ),
                        )
                      : null,
                  min: 0.0,
                  max: 1.0,
                ),

                EffectControl(
                  label: 'Noise Reduction',
                  isEnabled: state.activeProfile?.powerNoiseReduction ?? false,
                  value: state.activeProfile?.noiseLevel ?? 0.3,
                  onToggle: (enabled) => context.read<AudioBloc>().add(
                    ToggleDeviceEffectPower(
                      state.activeDevice!.id,
                      'noise',
                      enabled,
                    ),
                  ),
                  onSliderChanged: (state.activeProfile?.powerNoiseReduction ?? false)
                      ? (value) => context.read<AudioBloc>().add(
                          UpdateDeviceEffectLevel(
                            state.activeDevice!.id,
                            'noise',
                            value,
                          ),
                        )
                      : null,
                  min: 0.0,
                  max: 5.0,
                ),

                EffectControl(
                  label: 'Stereo Enhancement',
                  isEnabled: state.activeProfile?.powerStereoEnhancement ?? false,
                  value: state.activeProfile?.stereoWidth ?? 0.8,
                  onToggle: (enabled) => context.read<AudioBloc>().add(
                    ToggleDeviceEffectPower(
                      state.activeDevice!.id,
                      'stereo',
                      enabled,
                    ),
                  ),
                  onSliderChanged: (state.activeProfile?.powerStereoEnhancement ?? false)
                      ? (value) => context.read<AudioBloc>().add(
                          UpdateDeviceEffectLevel(
                            state.activeDevice!.id,
                            'stereo',
                            value,
                          ),
                        )
                      : null,
                  min: 0.0,
                  max: 2.0,
                ),

                EffectControl(
                  label: 'Voice Clarity',
                  isEnabled: state.activeProfile?.powerVoiceClarity ?? false,
                  value: state.activeProfile?.voiceGain ?? 3.0,
                  onToggle: (enabled) => context.read<AudioBloc>().add(
                    ToggleDeviceEffectPower(
                      state.activeDevice!.id,
                      'voice',
                      enabled,
                    ),
                  ),
                  onSliderChanged: (state.activeProfile?.powerVoiceClarity ?? false)
                      ? (value) => context.read<AudioBloc>().add(
                          UpdateDeviceEffectLevel(
                            state.activeDevice!.id,
                            'voice',
                            value,
                          ),
                        )
                      : null,
                  min: -20.0,
                  max: 20.0,
                ),

                EffectControl(
                  label: 'Bass Boost',
                  isEnabled: state.activeProfile?.powerBassBoost ?? false,
                  value: state.activeProfile?.bassGain ?? 2.0,
                  onToggle: (enabled) => context.read<AudioBloc>().add(
                    ToggleDeviceEffectPower(
                      state.activeDevice!.id,
                      'bass',
                      enabled,
                    ),
                  ),
                  onSliderChanged: (state.activeProfile?.powerBassBoost ?? false)
                      ? (value) => context.read<AudioBloc>().add(
                          UpdateDeviceEffectLevel(
                            state.activeDevice!.id,
                            'bass',
                            value,
                          ),
                        )
                      : null,
                  min: -20.0,
                  max: 20.0,
                ),

                EffectControl(
                  label: 'Treble Enhancer',
                  isEnabled: state.activeProfile?.powerTrebleEnhancer ?? false,
                  value: state.activeProfile?.trebleGain ?? 1.0,
                  onToggle: (enabled) => context.read<AudioBloc>().add(
                    ToggleDeviceEffectPower(
                      state.activeDevice!.id,
                      'treble',
                      enabled,
                    ),
                  ),
                  onSliderChanged: (state.activeProfile?.powerTrebleEnhancer ?? false)
                      ? (value) => context.read<AudioBloc>().add(
                          UpdateDeviceEffectLevel(
                            state.activeDevice!.id,
                            'treble',
                            value,
                          ),
                        )
                      : null,
                  min: -20.0,
                  max: 20.0,
                ),

                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}