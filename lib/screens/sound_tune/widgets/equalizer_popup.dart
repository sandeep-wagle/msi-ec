import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../sound_tune_theme.dart';
import 'shared_widgets.dart';
import '../../../logic/blocs/sound/sound_bloc.dart';
import '../../../logic/blocs/sound/sound_event.dart';

class EqualizerPopup extends StatelessWidget {
  const EqualizerPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.select((SoundBloc b) => b.state.profile);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 800,
          height: 500,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: kPanel,
            border: Border.all(color: kPanelBorder, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('EQUALIZER', style: SoundTuneTheme.h1),
                  Row(
                    children: [
                      Text(
                        profile.toUpperCase(),
                        style: const TextStyle(color: kAccent, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, color: kAccent, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(10, (i) {
                    final labels = ['32Hz', '64Hz', '125Hz', '250Hz', '500Hz', '1kHz', '2kHz', '4kHz', '8kHz', '16kHz'];
                    return EqBand(index: i, label: labels[i]);
                  }),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LOWEST NOTES (BASS)',
                    style: TextStyle(color: kTextSub.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  Text(
                    'HIGHEST NOTES (TREBLE)',
                    style: TextStyle(color: kTextSub.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EqBand extends StatelessWidget {
  final int index;
  final String label;
  const EqBand({required this.index, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    final gain = context.select((SoundBloc b) => b.state.eqGains[index]);

    return SizedBox(
      width: 44,
      child: Column(
        children: [
          Text(
            gain.toStringAsFixed(0),
            style: const TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: NahimicSlider(
              value: gain,
              min: -15,
              max: 15,
              isVertical: true,
              onChanged: (v) {
                final bloc = context.read<SoundBloc>();
                final newGains = List<double>.from(bloc.state.eqGains);
                newGains[index] = v;
                bloc.add(UpdateEQGains(newGains));
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(color: kTextSub.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
