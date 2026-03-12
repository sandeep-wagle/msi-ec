import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/blocs/sound/sound_bloc.dart';
import '../logic/blocs/sound/sound_event.dart';
import '../logic/blocs/sound/sound_state.dart';
import '../services/toast_service.dart';
import '../core/di/injection.dart';

// MSI Nahimic Color Palette
const _bg = Color(0xFF0F1115); // MSI Dark Black
const _panel = Color(0xFF181B21); // MSI Dark Panel
const _panelBorder = Color(0xFF252932); // Subtle border
const _accent = Color(0xFFD32F2F); // MSI Red (standardized)
const _accentGlow = Color(0x33D32F2F);
const _textPrimary = Color(0xFFFFFFFF);
const _textSub = Color(0xFF9E9E9E);

class SoundTuneScreen extends StatefulWidget {
  const SoundTuneScreen({super.key});

  @override
  State<SoundTuneScreen> createState() => _SoundTuneScreenState();
}

class _SoundTuneScreenState extends State<SoundTuneScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Header
          const _AudioHeader(),
          // Mode Tabs
          const _ModeTabs(),
          // Main Grid
          Expanded(
            child: Row(
              children: [
                // Left volume bar
                const _LeftVolumeBar(),
                const SizedBox(width: 1),
                // Content panels
                const Expanded(child: _ContentLayout()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioHeader extends StatelessWidget {
  const _AudioHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _panel,
        border: Border(bottom: BorderSide(color: _panelBorder)),
      ),
      child: Row(
        children: [
          const Icon(Icons.power_settings_new, color: _accent, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Effects ON',
            style: TextStyle(color: _accent, fontSize: 12, letterSpacing: 1.2),
          ),
          const Spacer(),
          const Text(
            'AUDIO',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          // Try button
          TextButton.icon(
            onPressed: () async {
              // Open a short test tone with paplay
              _showSnackbar(context, '▶ Playing test tone...');
            },
            icon: const Icon(
              Icons.play_circle_outline,
              color: _accent,
              size: 20,
            ),
            label: const Text('Try', style: TextStyle(color: _accent)),
          ),
          // Reset button
          TextButton.icon(
            onPressed: () {
              context.read<SoundBloc>().add(
                UpdateEQGains(List.generate(10, (_) => 0.0)),
              );
              context.read<SoundBloc>().add(
                const ChangeEffectGain('bass', 0.0),
              );
              context.read<SoundBloc>().add(
                const ChangeEffectGain('treble', 0.0),
              );
              context.read<SoundBloc>().add(
                const ChangeEffectGain('voice', 0.0),
              );
              _showSnackbar(context, 'Audio settings reset to flat.');
            },
            icon: const Icon(Icons.refresh, color: _textSub, size: 18),
            label: const Text('Reset', style: TextStyle(color: _textSub)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String msg) {
    getIt<ToastService>().showInfo(msg);
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs();

  @override
  Widget build(BuildContext context) {
    final profile = context.select((SoundBloc b) => b.state.profile);

    const tabs = [
      ('MUSIC', 'Music', Icons.music_note),
      ('GAMING', 'Gaming', Icons.sports_esports),
      ('MOVIE', 'Movie', Icons.movie_creation_outlined),
      ('COMMUNICATION', 'Voice', Icons.headset_mic_outlined),
      ('SMART', 'Custom', Icons.auto_awesome_outlined),
    ];

    return Container(
      height: 72,
      color: _panel,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: tabs.map((t) {
          final (label, profileKey, icon) = t;
          final isSelected = profile == profileKey;

          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  context.read<SoundBloc>().add(SetSoundProfile(profileKey)),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? _accent : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected ? _accent : _textSub,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? _textPrimary : _textSub,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LeftVolumeBar extends StatelessWidget {
  const _LeftVolumeBar();

  @override
  Widget build(BuildContext context) {
    final boost = context.select((SoundBloc b) => b.state.volumeBoost);
    final pct = ((boost) * 100).round();

    return Container(
      width: 72,
      color: _panel,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.headphones, color: _textPrimary, size: 24),
          const SizedBox(height: 4),
          const Text(
            'Headphones',
            style: TextStyle(color: _textSub, fontSize: 9),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            boost >= 1.0 ? '+$pct%' : '$pct%',
            style: const TextStyle(
              color: _accent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _accent,
                    inactiveTrackColor: Colors.white10,
                    thumbColor: Colors.white,
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                  ),
                  child: Slider(
                    value: boost,
                    min: 0.0,
                    max: 1.2,
                    onChanged: (v) =>
                        context.read<SoundBloc>().add(ChangeVolumeBoost(v)),
                  ),
                ),
              ),
            ),
          ),
          const Icon(Icons.volume_off, color: _textSub, size: 18),
          const Text('Mute', style: TextStyle(color: _textSub, fontSize: 9)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ContentLayout extends StatelessWidget {
  const _ContentLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top row: Surround Sound + Volume Stabilizer
        Expanded(
          flex: 5,
          child: Row(
            children: [
              // Surround Sound panel
              Expanded(
                flex: 3,
                child: _Panel(
                  child: Row(
                    children: [
                      // Equalizer sidebar button
                      Container(
                        width: 70,
                        color: _bg.withOpacity(0.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.tune,
                                color: _accent,
                                size: 28,
                              ),
                              onPressed: () {
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: 'EQ',
                                  barrierColor: Colors.black.withOpacity(0.7),
                                  pageBuilder: (c, a, s) =>
                                      const _EqualizerPopup(),
                                );
                              },
                            ),
                            const Text(
                              'Equalizer',
                              style: TextStyle(color: _textSub, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      // 3D head illustration
                      Expanded(
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _accent, width: 1),
                                  gradient: RadialGradient(
                                    colors: [
                                      _accent.withOpacity(0.12),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.person_outline,
                                color: _textSub,
                                size: 60,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Text panel
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'SURROUND SOUND',
                                    style: TextStyle(
                                      color: _textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  _PowerToggle(field: 'virtualSurround'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Make Sound come from all around you for a better immersion.',
                                style: TextStyle(
                                  color: _textSub,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Volume Stabilizer panel
              Expanded(
                flex: 2,
                child: _Panel(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'VOLUME\nSTABILIZER',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            _PowerToggle(field: 'smartVolume'),
                          ],
                        ),
                        const Spacer(),
                        // Waveform animation placeholder
                        const Center(
                          child: Icon(
                            Icons.graphic_eq,
                            size: 52,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'QUIET OFF',
                          style: TextStyle(
                            color: _textSub,
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                        const Text(
                          'Volume is never inaudible or too loud.',
                          style: TextStyle(color: _textSub, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom row: Voices, Bass, Treble
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                child: _Panel(
                  child: _EffectSliderPanel(
                    title: 'VOICES',
                    field: 'voice',
                    enableField: 'voiceClarity',
                    desc:
                        'Make them faraway or present\n(dialogs, choirs, chat, etc.)',
                  ),
                ),
              ),
              Expanded(
                child: _Panel(
                  child: _EffectSliderPanel(
                    title: 'BASS',
                    field: 'bass',
                    enableField: 'bassBoost',
                    desc:
                        'Make them punchy or lighter\n(explosions, beats, bass guitars)',
                  ),
                ),
              ),
              Expanded(
                child: _Panel(
                  child: _EffectSliderPanel(
                    title: 'TREBLE',
                    field: 'treble',
                    enableField: 'trebleEnhancer',
                    desc:
                        'Make them faded or clearer\n(footsteps, whistles, cymbals)',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _panelBorder, width: 0.5),
      ),
      child: child,
    );
  }
}

/// A vertical dB slider panel for Voices/Bass/Treble
class _EffectSliderPanel extends StatelessWidget {
  final String title;
  final String field; // 'bass' | 'treble' | 'voice'
  final String enableField;
  final String desc;

  const _EffectSliderPanel({
    required this.title,
    required this.field,
    required this.enableField,
    required this.desc,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              _PowerToggle(field: enableField),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${gain.toStringAsFixed(1)} dB',
            style: const TextStyle(
              color: _accent,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Vertical slider container
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _accent,
                  inactiveTrackColor: Colors.white10,
                  thumbColor: Colors.white,
                  trackHeight: 14,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: gain,
                  min: 0.0,
                  max: 12.0,
                  divisions: 24,
                  onChanged: (v) =>
                      context.read<SoundBloc>().add(ChangeEffectGain(field, v)),
                ),
              ),
            ),
          ),
          Text(
            desc,
            style: const TextStyle(color: _textSub, fontSize: 10, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PowerToggle extends StatelessWidget {
  final String field;
  const _PowerToggle({required this.field});

  @override
  Widget build(BuildContext context) {
    final isActive = context.select((SoundBloc b) {
      if (field == 'bassBoost') return b.state.bassBoost;
      if (field == 'trebleEnhancer') return b.state.trebleEnhancer;
      if (field == 'voiceClarity') return b.state.voiceClarity;
      if (field == 'virtualSurround') return b.state.virtualSurround;
      if (field == 'smartVolume') return b.state.smartVolume;
      return false;
    });

    return GestureDetector(
      onTap: () =>
          context.read<SoundBloc>().add(ToggleEnhancement(field, !isActive)),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? _accent.withOpacity(0.15) : Colors.transparent,
          border: Border.all(color: isActive ? _accent : _textSub, width: 1.5),
          boxShadow: isActive
              ? [BoxShadow(color: _accentGlow, blurRadius: 8, spreadRadius: 1)]
              : null,
        ),
        child: Icon(
          Icons.power_settings_new,
          size: 14,
          color: isActive ? _accent : _textSub,
        ),
      ),
    );
  }
}

class _EqualizerPopup extends StatelessWidget {
  const _EqualizerPopup();

  @override
  Widget build(BuildContext context) {
    final profile = context.select((SoundBloc b) => b.state.profile);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 520,
          height: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _panelBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EQUALIZER',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        profile.toUpperCase(),
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, color: _textSub),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(10, (i) {
                    final labels = [
                      '32Hz',
                      '64Hz',
                      '125Hz',
                      '250Hz',
                      '500Hz',
                      '1kHz',
                      '2kHz',
                      '4kHz',
                      '8kHz',
                      '16kHz',
                    ];
                    return _EqBand(index: i, label: labels[i]);
                  }),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'From lowest notes (basses)',
                    style: TextStyle(color: _textSub, fontSize: 10),
                  ),
                  Text(
                    'To highest notes (trebles)',
                    style: TextStyle(color: _textSub, fontSize: 10),
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

class _EqBand extends StatelessWidget {
  final int index;
  final String label;
  const _EqBand({required this.index, required this.label});

  @override
  Widget build(BuildContext context) {
    final gain = context.select((SoundBloc b) => b.state.eqGains[index]);

    return SizedBox(
      width: 40,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: _textSub, fontSize: 9),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _accent,
                  inactiveTrackColor: Colors.white10,
                  thumbColor: Colors.white,
                  trackHeight: 16,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 0,
                  ),
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: gain,
                  min: -12,
                  max: 12,
                  onChanged: (v) {
                    final bloc = context.read<SoundBloc>();
                    final newGains = List<double>.from(bloc.state.eqGains);
                    newGains[index] = v;
                    bloc.add(UpdateEQGains(newGains));
                  },
                ),
              ),
            ),
          ),
          Text(
            gain.toStringAsFixed(0),
            style: const TextStyle(color: _accent, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
