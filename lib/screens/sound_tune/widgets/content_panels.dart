import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msi_controller/screens/sound_tune/sound_tune_theme.dart';
import 'shared_widgets.dart';
import 'painters.dart';
import 'equalizer_popup.dart';
import 'package:msi_controller/logic/blocs/sound/sound_bloc.dart';
import 'package:msi_controller/logic/blocs/sound/sound_event.dart';
import 'package:msi_controller/logic/blocs/sound/sound_state.dart';

class SurroundPanel extends StatelessWidget {
  const SurroundPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final variation = context.select(
      (SoundBloc b) => b.state.surroundVariation,
    );

    return Row(
      children: [
        Container(
          width: 70,
          decoration: BoxDecoration(
            color: kBg.withValues(alpha: 0.5),
            border: const Border(right: BorderSide(color: kPanelBorder)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: kAccent, size: 28),
                onPressed: () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: 'EQ',
                    barrierColor: Colors.black.withValues(alpha: 0.7),
                    pageBuilder: (c, a, s) => const EqualizerPopup(),
                  );
                },
              ),
              const Text(
                'Equalizer',
                style: TextStyle(
                  color: kTextSub,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(painter: NeuralHeadPainter()),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'SURROUND\nSOUND',
                        style: SoundTuneTheme.h2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PowerToggle(field: 'virtualSurround'),
                  ],
                ),
                const SizedBox(height: 8),
                const Flexible(
                  child: Text(
                    'Make Sound come from all around you for a better immersion.',
                    style: SoundTuneTheme.subText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    SmallPill(
                      label: 'VIRTUAL SURROUND',
                      active: variation == 'Surround',
                      onTap: () => context.read<SoundBloc>().add(
                        const ChangeSurroundVariation('Surround'),
                      ),
                    ),
                    SmallPill(
                      label: 'VIRTUAL HEADSET',
                      active: variation == 'Headset',
                      onTap: () => context.read<SoundBloc>().add(
                        const ChangeSurroundVariation('Headset'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class VolumeStabilizerPanel extends StatelessWidget {
  const VolumeStabilizerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final nightMode = context.select((SoundBloc b) => b.state.nightMode);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'VOLUME\nSTABILIZER',
                  style: SoundTuneTheme.h2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PowerToggle(field: 'smartVolume'),
            ],
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 140,
              height: 60,
              child: CustomPaint(painter: WaveformPainter(color: kAccent)),
            ),
          ),
          const Spacer(),
          Center(
            child: SmallPill(
              label: nightMode ? 'NIGHT ON' : 'NIGHT OFF',
              active: nightMode,
              onTap: () => context.read<SoundBloc>().add(
                ToggleEnhancement('nightMode', !nightMode),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Volume is never inaudible or too loud. Night mode won\'t disturb people around you.',
            style: TextStyle(color: kTextSub, fontSize: 10, height: 1.2),
            textAlign: TextAlign.start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class EffectSliderPanel extends StatelessWidget {
  final String title;
  final String field;
  final String enableField;
  final String desc;

  const EffectSliderPanel({
    required this.title,
    required this.field,
    required this.enableField,
    required this.desc,
    super.key,
  });

  double _getGain(SoundState s) {
    if (field == 'bass') return s.bassGain;
    if (field == 'treble') return s.trebleGain;
    return s.voiceGain;
  }

  @override
  Widget build(BuildContext context) {
    final gain = context.select((SoundBloc b) => _getGain(b.state));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: SoundTuneTheme.h2.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PowerToggle(field: enableField),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                gain.toStringAsFixed(0),
                style: const TextStyle(
                  color: kAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'dB',
                style: TextStyle(
                  color: kTextSub,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          NahimicSlider(
            value: gain,
            min: -12,
            max: 12,
            onChanged: (v) => context.read<SoundBloc>().add(
              ChangeEffectGainPreview(field, v),
            ),
            onChangedEnd: (v) =>
                context.read<SoundBloc>().add(ChangeEffectGain(field, v)),
          ),
          const Spacer(),
          Text(
            desc,
            style: const TextStyle(color: kTextSub, fontSize: 10, height: 1.2),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class AdvancedEffectPanel extends StatelessWidget {
  final String title;
  final String field;
  final double min;
  final double max;
  final String desc;

  const AdvancedEffectPanel({
    required this.title,
    required this.field,
    required this.min,
    required this.max,
    required this.desc,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final value = context.select((SoundBloc b) {
      if (field == 'noiseLevel') return b.state.noiseLevel;
      if (field == 'stereoWidth') return b.state.stereoWidth;
      return 0.0;
    });

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            title,
            style: SoundTuneTheme.h2.copyWith(fontSize: 10, letterSpacing: 1.5),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              color: kAccent,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          NahimicSlider(
            value: value,
            min: min,
            max: max,
            onChanged: (v) {
              if (field == 'noiseLevel') {
                context.read<SoundBloc>().add(ChangeNoiseLevelPreview(v));
              }
              if (field == 'stereoWidth') {
                context.read<SoundBloc>().add(ChangeStereoWidthPreview(v));
              }
            },
            onChangedEnd: (v) {
              if (field == 'noiseLevel') {
                context.read<SoundBloc>().add(ChangeNoiseLevel(v));
              }
              if (field == 'stereoWidth') {
                context.read<SoundBloc>().add(ChangeStereoWidth(v));
              }
            },
          ),
          const Spacer(),
          Text(
            desc,
            style: const TextStyle(color: kTextSub, fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class LimiterPanel extends StatelessWidget {
  final String title;
  final String desc;

  const LimiterPanel({required this.title, required this.desc, super.key});

  @override
  Widget build(BuildContext context) {
    final isEnabled = context.select((SoundBloc b) => b.state.limiterEnabled);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            title,
            style: SoundTuneTheme.h2.copyWith(fontSize: 10, letterSpacing: 1.5),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          const PowerToggle(field: 'limiterEnabled'),
          const SizedBox(height: 8),
          Text(
            isEnabled ? 'ON' : 'OFF',
            style: TextStyle(
              color: isEnabled ? kAccent : kTextSub,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            desc,
            style: const TextStyle(color: kTextSub, fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
