import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/blocs/audio/audio_bloc.dart';
import '../logic/blocs/audio/audio_event.dart';
import '../logic/blocs/audio/audio_state.dart';

class AudioDeviceControls extends StatelessWidget {
  const AudioDeviceControls({super.key});

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
                    Icon(
                      _getDeviceIcon(state.activeDevice!.type),
                      size: 24,
                    ),
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

                // Surround Sound
                _buildEffectControl(
                  context,
                  'Surround Sound',
                  state.powerSurround,
                  state.surroundLevel,
                  (enabled) => context.read<AudioBloc>().add(
                        ToggleDeviceEffectPower(
                          state.activeDevice!.id,
                          'surround',
                          enabled,
                        ),
                      ),
                  state.powerSurround
                      ? (value) => context.read<AudioBloc>().add(
                            UpdateDeviceEffectLevel(
                              state.activeDevice!.id,
                              'surround',
                              value,
                            ),
                          )
                      : null,
                  0.0,
                  1.0,
                ),

                // Noise Reduction
                _buildEffectControl(
                  context,
                  'Noise Reduction',
                  state.powerNoiseReduction,
                  state.noiseLevel,
                  (enabled) => context.read<AudioBloc>().add(
                        ToggleDeviceEffectPower(
                          state.activeDevice!.id,
                          'noise',
                          enabled,
                        ),
                      ),
                  state.powerNoiseReduction
                      ? (value) => context.read<AudioBloc>().add(
                            UpdateDeviceEffectLevel(
                              state.activeDevice!.id,
                              'noise',
                              value,
                            ),
                          )
                      : null,
                  0.0,
                  5.0,
                ),

                // Stereo Enhancement
                _buildEffectControl(
                  context,
                  'Stereo Enhancement',
                  state.powerStereoEnhancement,
                  state.stereoWidth,
                  (enabled) => context.read<AudioBloc>().add(
                        ToggleDeviceEffectPower(
                          state.activeDevice!.id,
                          'stereo',
                          enabled,
                        ),
                      ),
                  state.powerStereoEnhancement
                      ? (value) => context.read<AudioBloc>().add(
                            UpdateDeviceEffectLevel(
                              state.activeDevice!.id,
                              'stereo',
                              value,
                            ),
                          )
                      : null,
                  0.0,
                  2.0,
                ),

                // Voice Clarity
                _buildEffectControl(
                  context,
                  'Voice Clarity',
                  state.powerVoiceClarity,
                  state.voiceGain,
                  (enabled) => context.read<AudioBloc>().add(
                        ToggleDeviceEffectPower(
                          state.activeDevice!.id,
                          'voice',
                          enabled,
                        ),
                      ),
                  state.powerVoiceClarity
                      ? (value) => context.read<AudioBloc>().add(
                            UpdateDeviceEffectLevel(
                              state.activeDevice!.id,
                              'voice',
                              value,
                            ),
                          )
                      : null,
                  -20.0,
                  20.0,
                ),

                // Bass Boost
                _buildEffectControl(
                  context,
                  'Bass Boost',
                  state.powerBassBoost,
                  state.bassGain,
                  (enabled) => context.read<AudioBloc>().add(
                        ToggleDeviceEffectPower(
                          state.activeDevice!.id,
                          'bass',
                          enabled,
                        ),
                      ),
                  state.powerBassBoost
                      ? (value) => context.read<AudioBloc>().add(
                            UpdateDeviceEffectLevel(
                              state.activeDevice!.id,
                              'bass',
                              value,
                            ),
                          )
                      : null,
                  -20.0,
                  20.0,
                ),

                // Treble Enhancer
                _buildEffectControl(
                  context,
                  'Treble Enhancer',
                  state.powerTrebleEnhancer,
                  state.trebleGain,
                  (enabled) => context.read<AudioBloc>().add(
                        ToggleDeviceEffectPower(
                          state.activeDevice!.id,
                          'treble',
                          enabled,
                        ),
                      ),
                  state.powerTrebleEnhancer
                      ? (value) => context.read<AudioBloc>().add(
                            UpdateDeviceEffectLevel(
                              state.activeDevice!.id,
                              'treble',
                              value,
                            ),
                          )
                      : null,
                  -20.0,
                  20.0,
                ),

                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      state.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

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

  Widget _buildEffectControl(
    BuildContext context,
    String label,
    bool isEnabled,
    double value,
    ValueChanged<bool> onToggle,
    ValueChanged<double>? onSliderChanged,
    double min,
    double max,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: onToggle,
            ),
          ],
        ),
        if (isEnabled && onSliderChanged != null)
          Slider(
            value: value.isNaN ? min : value.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min) >= 10 ? 10 : null,
            label: value.isNaN ? min.toStringAsFixed(1) : value.toStringAsFixed(1),
            onChanged: onSliderChanged,
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}