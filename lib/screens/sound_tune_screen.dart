import 'package:flutter/material.dart';
import 'sound_tune/widgets/shared_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/blocs/sound/sound_bloc.dart';
import '../logic/blocs/sound/sound_event.dart';
import '../services/toast_service.dart';
import '../core/di/injection.dart';

// Nahimic Premium Palette
const _bg = Color(0xFF0A0C10);
const _panel = Color(0xFF14171C);
const _panelBorder = Color(0xFF1F2228);
const _accent = Color(0xFFE53935); // Nahimic Red
const _textPrimary = Color(0xFFF0F0F0);
const _textSub = Color(0xFF8E9196);


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
          const _AudioHeader(),
          const _ModeTabs(),
          Expanded(
            child: Row(
              children: [
                const _LeftSidebar(),
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
    final effectsOn = context.select((SoundBloc b) => b.state.effectsEnabled);

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(bottom: BorderSide(color: _panelBorder, width: 1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.power_settings_new_rounded,
            color: effectsOn ? _accent : _textSub,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            effectsOn ? 'EFFECTS ON' : 'EFFECTS OFF',
            style: TextStyle(
              color: effectsOn ? _accent : _textSub,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 32),
          const _NightModeToggle(),
          const Spacer(),
          const Text(
            'AUDIO',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 8.0,
            ),
          ),
          const Spacer(),
          _HeaderAction(
            onPressed: () => getIt<ToastService>().showInfo('▶ Playing test tone...'),
            icon: Icons.play_circle_outline_rounded,
            label: 'Try',
            color: _accent,
          ),
          const SizedBox(width: 16),
          _HeaderAction(
            onPressed: () => context.read<SoundBloc>().add(ResetSoundSettings()),
            icon: Icons.refresh_rounded,
            label: 'Reset',
            color: _textSub,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderAction({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tap to $label',
      preferBelow: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs();

  @override
  Widget build(BuildContext context) {
    final profile = context.select((SoundBloc b) => b.state.profile);

    const tabs = [
      ('MUSIC', 'Music', Icons.music_note_rounded, 'Optimized for critical listening'),
      ('GAMING', 'Gaming', Icons.sports_esports_rounded, 'Enhanced spatial awareness'),
      ('MOVIE', 'Movie', Icons.movie_filter_rounded, 'Cinematic dialogue and bass'),
      ('COMMUNICATION', 'Voice', Icons.headset_mic_rounded, 'Perfect clarity for chat'),
      ('SMART', 'Custom', Icons.auto_awesome_rounded, 'Adaptive intelligence'),
    ];

    return Container(
      height: 76,
      color: _panel,
      child: Row(
        children: tabs.map((t) {
          final (label, profileKey, icon, tooltip) = t;
          final isSelected = profile == profileKey;

          return Expanded(
            child: Tooltip(
              message: tooltip,
              child: GestureDetector(
                onTap: () => context.read<SoundBloc>().add(SetSoundProfile(profileKey)),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? _accent : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      gradient: isSelected ? LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [_accent.withOpacity(0.05), Colors.transparent],
                      ) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: isSelected ? _accent : _textSub, size: 22),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? _textPrimary : _textSub,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LeftSidebar extends StatelessWidget {
  const _LeftSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(right: BorderSide(color: _panelBorder, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _VerticalTabText(
            label: 'EQUALIZER',
            tooltip: 'Fine-tune audio frequencies',
            onTap: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'EQ',
                barrierColor: Colors.black.withOpacity(0.8),
                pageBuilder: (c, a, s) => const _EqualizerPopup(),
              );
            },
          ),
          const Spacer(),
          const _VerticalVolumeBar(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _VerticalTabText extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  const _VerticalTabText({required this.label, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: RotatedBox(
          quarterTurns: 3,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tune_rounded, color: _accent, size: 18),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: _textSub,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalVolumeBar extends StatelessWidget {
  const _VerticalVolumeBar();

  @override
  Widget build(BuildContext context) {
    final boost = context.select((SoundBloc b) => b.state.volumeBoost);

    return Column(
      children: [
        const Icon(Icons.headphones_rounded, color: _textPrimary, size: 22),
        const SizedBox(height: 4),
        const Text(
          'OUTPUT',
          style: TextStyle(color: _textSub, fontSize: 8, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: NahimicSlider(
            value: boost,
            min: 0.2,
            max: 1.3,
            isVertical: true,
            labelTransformer: (v) => '${(v * 100).round()}%',
            onChanged: (v) {
              context.read<SoundBloc>().add(ChangeVolumeBoost(v));
            },
          ),
        ),
        const SizedBox(height: 16),
        IconButton(
          onPressed: () => context.read<SoundBloc>().add(const ChangeVolumeBoost(0.0)),
          icon: const Icon(Icons.volume_off_rounded, color: _textSub, size: 20),
        ),
        const Text(
          'MUTE',
          style: TextStyle(color: _textSub, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ContentLayout extends StatelessWidget {
  const _ContentLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Row(
            children: [
              const Expanded(flex: 3, child: _SurroundPanel()),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    const Expanded(child: _StabilizerPanel()),
                    const Expanded(child: _MicrophonePanel()),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                child: _EffectBox(
                  title: 'VOICES',
                  field: 'voice',
                  enableField: 'voiceClarity',
                  desc: 'Make them faraway or present\n(dialogs, choirs, chat, etc.)',
                ),
              ),
              Expanded(
                child: _EffectBox(
                  title: 'BASS',
                  field: 'bass',
                  enableField: 'bassBoost',
                  desc: 'Make them punchy or lighter\n(explosions, beats, bass guitars)',
                ),
              ),
              Expanded(
                child: _EffectBox(
                  title: 'TREBLE',
                  field: 'treble',
                  enableField: 'trebleEnhancer',
                  desc: 'Make them faded or clearer\n(footsteps, whistles, cymbals)',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SurroundPanel extends StatelessWidget {
  const _SurroundPanel();

  @override
  Widget build(BuildContext context) {
    final active = context.select((SoundBloc b) => b.state.virtualSurround);

    return _PanelBox(
      enableField: 'virtualSurround',
      tooltip: 'Create a virtual 7.1 listening experience',
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: active ? _accent.withOpacity(0.5) : _textSub.withOpacity(0.3), width: 1),
                      boxShadow: active ? [
                        BoxShadow(color: _accent.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)
                      ] : null,
                      gradient: active
                          ? RadialGradient(
                              colors: [
                                _accent.withOpacity(0.3),
                                _accent.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            )
                          : null,
                    ),
                  ),
                  Icon(
                    Icons.person_rounded,
                    color: active ? _textPrimary : _textSub.withOpacity(0.5),
                    size: 54,
                  ),
                  if (active) ...[
                    _SurroundWave(delay: 0),
                    _SurroundWave(delay: 1),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'SURROUND SOUND',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Make Sound come from all around you for a better immersion.',
                    style: TextStyle(color: _textSub, fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SURROUND STRENGTH (WIDTH)',
                    style: TextStyle(color: _textSub, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  NahimicSlider(
                    value: context.select((SoundBloc b) => b.state.stereoWidth),
                    min: 0.0,
                    max: 4.0,
                    onChanged: (v) => context.read<SoundBloc>().add(ChangeStereoWidth(v)),
                    onChangedEnd: (v) => context.read<SoundBloc>().add(ChangeStereoWidth(v)),
                    labelTransformer: (v) => '${(v * 100).round()}%',
                  ),
                  const SizedBox(height: 12),
                  const _SurroundVariationSelector(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StabilizerPanel extends StatelessWidget {
  const _StabilizerPanel();

  @override
  Widget build(BuildContext context) {
    final active = context.select((SoundBloc b) => b.state.smartVolume);

    return _PanelBox(
      enableField: 'smartVolume',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VOLUME\nSTABILIZER',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            if (active) ...[
              const Text(
                'COMPRESSION RATIO',
                style: TextStyle(color: _textSub, fontSize: 8, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              NahimicSlider(
                value: context.select((SoundBloc b) => b.state.compressorRatio),
                min: 1.0,
                max: 10.0,
                onChanged: (v) => context.read<SoundBloc>().add(ChangeCompressorRatio(v)),
                onChangedEnd: (v) => context.read<SoundBloc>().add(ChangeCompressorRatio(v)),
                labelTransformer: (v) => '${v.toStringAsFixed(1)}:1',
              ),
            ],
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: 32,
                    color: active ? _accent : _textSub.withOpacity(0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    active ? 'STABILIZER ON' : 'STABILIZER OFF',
                    style: TextStyle(
                      color: active ? _textPrimary : _textSub,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Text(
              'Volume is never inaudible or too loud.',
              style: TextStyle(color: _textSub, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _EffectBox extends StatelessWidget {
  final String title;
  final String field;
  final String enableField;
  final String desc;

  const _EffectBox({
    required this.title,
    required this.field,
    required this.enableField,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final active = context.select((SoundBloc b) => b.state.effectsEnabled);
    final innerActive = context.select((SoundBloc b) {
      if (field == 'bass') return b.state.bassBoost;
      if (field == 'treble') return b.state.trebleEnhancer;
      return b.state.voiceClarity;
    });
    final gain = context.select((SoundBloc b) {
      if (field == 'bass') return b.state.bassGain;
      if (field == 'treble') return b.state.trebleGain;
      return b.state.voiceGain;
    });

    final isFullyActive = active && innerActive;

    return _PanelBox(
      enableField: enableField,
      child: Opacity(
        opacity: isFullyActive ? 1.0 : 0.4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const Expanded(child: SizedBox()),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${gain.toInt()} dB',
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NahimicSlider(
                      value: gain,
                      isVertical: false,
                      min: -12,
                      max: 12,
                      onChanged: isFullyActive
                          ? (v) => context.read<SoundBloc>().add(ChangeEffectGain(field, v))
                          : null,
                      onChangedEnd: isFullyActive
                          ? (v) => context.read<SoundBloc>().add(ChangeEffectGain(field, v))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 140,
                    child: Text(
                      desc,
                      style: const TextStyle(
                        color: _textSub,
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelBox extends StatelessWidget {
  final Widget child;
  final String enableField;
  final String? tooltip;

  const _PanelBox({required this.child, required this.enableField, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _panelBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(4, 4),
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_panel, _panel.withOpacity(0.8)],
          ),
        ),
        child: Stack(
          children: [
            child,
            Positioned(
              top: 12,
              right: 12,
              child: _SmallPowerToggle(field: enableField),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallPowerToggle extends StatelessWidget {
  final String field;
  const _SmallPowerToggle({required this.field});

  @override
  Widget build(BuildContext context) {
    final active = context.select((SoundBloc b) {
      if (field == 'virtualSurround') return b.state.virtualSurround;
      if (field == 'smartVolume') return b.state.smartVolume;
      if (field == 'bassBoost') return b.state.bassBoost;
      if (field == 'trebleEnhancer') return b.state.trebleEnhancer;
      if (field == 'voiceClarity') return b.state.voiceClarity;
      if (field == 'micNoiseSuppression') return b.state.micNoiseSuppression;
      if (field == 'echoCancellation') return b.state.echoCancellation;
      if (field == 'micEnabled') return b.state.micEnabled;
      return false;
    });

    return GestureDetector(
      onTap: () => context.read<SoundBloc>().add(ToggleEnhancement(field, !active)),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? _accent : Colors.transparent,
          border: Border.all(color: active ? _accent : _textSub, width: 1.5),
        ),
        child: Icon(
          Icons.power_settings_new_rounded,
          size: 14,
          color: active ? Colors.white : _textSub,
        ),
      ),
    );
  }
}


class _NightModeToggle extends StatelessWidget {
  const _NightModeToggle();
  @override
  Widget build(BuildContext context) {
    final nightMode = context.select((SoundBloc b) => b.state.nightMode);
    return InkWell(
      onTap: () => context.read<SoundBloc>().add(ToggleEnhancement('nightMode', !nightMode)),
      child: Row(
        children: [
          Icon(Icons.nightlight_round, size: 14, color: nightMode ? _accent : _textSub),
          const SizedBox(width: 6),
          Text(
            'NIGHT MODE',
            style: TextStyle(color: nightMode ? _accent : _textSub, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SurroundVariationSelector extends StatelessWidget {
  const _SurroundVariationSelector();
  @override
  Widget build(BuildContext context) {
    final current = context.select((SoundBloc b) => b.state.surroundVariation);
    const variations = ['Surround', '3D', 'Wide'];

    return Row(
      children: variations.map((v) {
        final isSelected = v == current;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: () => context.read<SoundBloc>().add(ChangeSurroundVariation(v)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? _accent : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: isSelected ? _accent : _panelBorder),
              ),
              child: Text(
                v.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : _textSub,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
          width: 600,
          height: 480,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _panelBorder, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 40),
              if (profile != 'Custom') 
                BoxShadow(color: _accent.withOpacity(0.1), blurRadius: 20, spreadRadius: -5),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EQUALIZER',
                    style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 4.0),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _accent.withOpacity(0.4)),
                        ),
                        child: Text(
                          profile.toUpperCase(),
                          style: const TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: _textSub),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(10, (i) {
                    final labels = ['32', '64', '125', '250', '500', '1K', '2K', '4K', '8K', '16K'];
                    return _EqBand(index: i, label: labels[i]);
                  }),
                ),
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

    return Column(
      children: [
        Text(
          gain.toStringAsFixed(0),
          style: const TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _NahimicSliderEq(
            value: gain,
            onChanged: (v) {
              final bloc = context.read<SoundBloc>();
              final newGains = List<double>.from(bloc.state.eqGains);
              newGains[index] = v;
              bloc.add(UpdateEQGains(newGains));
            },
            onChangedEnd: (v) {
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
          style: const TextStyle(color: _textSub, fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _NahimicSliderEq extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangedEnd;

  const _NahimicSliderEq({
    required this.value, 
    required this.onChanged,
    required this.onChangedEnd,
  });

  @override
  Widget build(BuildContext context) {
    return NahimicSlider(
      value: value,
      min: -12,
      max: 12,
      isVertical: true,
      onChanged: onChanged,
      onChangedEnd: onChangedEnd,
    );
  }
}

class _SurroundWave extends StatefulWidget {
  final int delay;
  const _SurroundWave({required this.delay});

  @override
  State<_SurroundWave> createState() => _SurroundWaveState();
}

class _SurroundWaveState extends State<_SurroundWave> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    Future.delayed(Duration(milliseconds: widget.delay * 1000), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 100 + (_controller.value * 120),
          height: 100 + (_controller.value * 120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _accent.withOpacity((1.0 - _controller.value) * 0.5),
              width: 1.5 - (_controller.value * 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity((1.0 - _controller.value) * 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
        );
      },
    );
  }
}

class _MicrophonePanel extends StatelessWidget {
  const _MicrophonePanel();

  @override
  Widget build(BuildContext context) {
    final active = context.select((SoundBloc b) => b.state.micEnabled);
    final noiseSuppression = context.select((SoundBloc b) => b.state.micNoiseSuppression);
    final echoCancellation = context.select((SoundBloc b) => b.state.echoCancellation);
    final gain = context.select((SoundBloc b) => b.state.microphoneGain);

    return _PanelBox(
      enableField: 'micEnabled',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MICROPHONE\nENHANCEMENT',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            if (active) ...[
              _MicSettingsItem(
                label: 'NOISE SUPPRESSION',
                field: 'micNoiseSuppression',
                isActive: noiseSuppression,
                desc: 'Remove static background noises',
              ),
              const SizedBox(height: 12),
              _MicSettingsItem(
                label: 'ECHO CANCELLATION',
                field: 'echoCancellation',
                isActive: echoCancellation,
                desc: 'Prevents voice being captured twice',
              ),
              const Spacer(),
              const Text(
                'MICROPHONE GAIN',
                style: TextStyle(color: _textSub, fontSize: 8, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              NahimicSlider(
                value: gain,
                min: 0.0,
                max: 1.5,
                labelTransformer: (v) => '${(v * 100).round()}%',
                onChanged: (v) => context.read<SoundBloc>().add(ChangeMicrophoneGain(v)),
                onChangedEnd: (v) => context.read<SoundBloc>().add(ChangeMicrophoneGain(v)),
              ),
            ] else 
              const Expanded(
                child: Center(
                  child: Text(
                    'MICROPHONE IS OFF',
                    style: TextStyle(color: _textSub, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MicSettingsItem extends StatelessWidget {
  final String label;
  final String field;
  final bool isActive;
  final String desc;

  const _MicSettingsItem({
    required this.label,
    required this.field,
    required this.isActive,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SmallPowerToggle(field: field),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? _textPrimary : _textSub,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(color: _textSub, fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
