import 'package:flutter/material.dart';
import 'sound_tune/widgets/shared_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msi_controller/logic/blocs/sound/sound_bloc.dart';
import 'package:msi_controller/logic/blocs/sound/sound_event.dart';
import 'package:msi_controller/services/toast_service.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/widgets/glass_container.dart';

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
    final theme = Theme.of(context);
    final colors = theme.extension<AppColors>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Sound Tune',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          const _AudioHeader(),
          const _ModeTabs(),
          Expanded(
            child: Row(
              children: [
                const _LeftSidebar(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colors.surfaceElevated.withValues(alpha: 0.3),
                          colors.cardBackground.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: const _ContentLayout(),
                  ),
                ),
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final effectsOn = context.select((SoundBloc b) => b.state.effectsEnabled);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: effectsOn
                  ? colors.performance.withValues(alpha: 0.1)
                  : colors.textTertiary.withValues(alpha: 0.05),
            ),
            child: Icon(
              Icons.power_settings_new_rounded,
              color: effectsOn ? colors.performance : colors.textTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            effectsOn ? 'AUDIO ENGINE ACTIVE' : 'AUDIO ENGINE DISABLED',
            style: TextStyle(
              color: effectsOn ? colors.textPrimary : colors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 32),
          const _NightModeToggle(),
          const Spacer(),
          Text(
            'NAHIMIC AUDIO',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 6.0,
            ),
          ),
          const Spacer(),
          _HeaderAction(
            onPressed: () =>
                getIt<ToastService>().showInfo('▶ Playing test tone...'),
            icon: Icons.play_circle_outline_rounded,
            label: 'TRY',
            color: colors.performance,
          ),
          const SizedBox(width: 16),
          _HeaderAction(
            onPressed: () =>
                context.read<SoundBloc>().add(ResetSoundSettings()),
            icon: Icons.refresh_rounded,
            label: 'RESET',
            color: colors.textSecondary,
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
        borderRadius: AppRadius.smAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final profile = context.select((SoundBloc b) => b.state.profile);

    const tabs = [
      (
        'MUSIC',
        'Music',
        Icons.music_note_rounded,
        'Optimized for critical listening',
      ),
      (
        'GAMING',
        'Gaming',
        Icons.sports_esports_rounded,
        'Enhanced spatial awareness',
      ),
      (
        'MOVIE',
        'Movie',
        Icons.movie_filter_rounded,
        'Cinematic dialogue and bass',
      ),
      (
        'COMMUNICATION',
        'Voice',
        Icons.headset_mic_rounded,
        'Perfect clarity for chat',
      ),
      ('SMART', 'Custom', Icons.auto_awesome_rounded, 'Adaptive intelligence'),
    ];

    return Container(
      height: 80,
      color: colors.cardBackground.withValues(alpha: 0.3),
      child: Row(
        children: tabs.map((t) {
          final (label, profileKey, icon, tooltip) = t;
          final isSelected = profile == profileKey;

          return Expanded(
            child: Tooltip(
              message: tooltip,
              child: GestureDetector(
                onTap: () =>
                    context.read<SoundBloc>().add(SetSoundProfile(profileKey)),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: AppDurations.medium,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? colors.performance
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                colors.performance.withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: isSelected
                              ? colors.performance
                              : colors.textTertiary,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? colors.textPrimary
                                : colors.textTertiary,
                            fontSize: 10,
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
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      constraints: const BoxConstraints(minWidth: 70, maxWidth: 90),
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.4),
        border: Border(
          right: BorderSide(
            color: colors.border.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _VerticalTabText(
            label: 'EQUALIZER',
            tooltip: 'Fine-tune audio frequencies',
            onTap: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: 'EQ',
                barrierColor: Colors.black.withValues(alpha: 0.85),
                pageBuilder: (c, a, s) => const _EqualizerPopup(),
              );
            },
          ),
          const Spacer(),
          const _VerticalVolumeBar(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _VerticalTabText extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  const _VerticalTabText({
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smAll,
        child: RotatedBox(
          quarterTurns: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, color: colors.performance, size: 18),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final boost = context.select((SoundBloc b) => b.state.volumeBoost);

    return Column(
      children: [
        Icon(Icons.headphones_rounded, color: colors.textPrimary, size: 22),
        const SizedBox(height: 6),
        Text(
          'OUTPUT',
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: NahimicSlider(
            value: boost,
            min: 0.2,
            max: 1.3,
            isVertical: true,
            labelTransformer: (v) => '${(v * 100).round()}%',
            onChanged: (v) {
              context.read<SoundBloc>().add(ChangeVolumeBoostPreview(v));
            },
            onChangedEnd: (v) {
              context.read<SoundBloc>().add(ChangeVolumeBoost(v));
            },
          ),
        ),
        const SizedBox(height: 20),
        IconButton(
          onPressed: () =>
              context.read<SoundBloc>().add(const ChangeVolumeBoost(0.0)),
          icon: Icon(
            Icons.volume_off_rounded,
            color: colors.textTertiary,
            size: 20,
          ),
        ),
        Text(
          'MUTE',
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
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
                  desc:
                      'Make them faraway or present\n(dialogs, choirs, chat, etc.)',
                ),
              ),
              Expanded(
                child: _EffectBox(
                  title: 'BASS',
                  field: 'bass',
                  enableField: 'bassBoost',
                  desc:
                      'Make them punchy or lighter\n(explosions, beats, bass guitars)',
                ),
              ),
              Expanded(
                child: _EffectBox(
                  title: 'TREBLE',
                  field: 'treble',
                  enableField: 'trebleEnhancer',
                  desc:
                      'Make them faded or clearer\n(footsteps, whistles, cymbals)',
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
    final colors = Theme.of(context).extension<AppColors>()!;
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
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active
                            ? colors.performance.withValues(alpha: 0.5)
                            : colors.textTertiary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: colors.performance.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ]
                          : null,
                      gradient: active
                          ? RadialGradient(
                              colors: [
                                colors.performance.withValues(alpha: 0.3),
                                colors.performance.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            )
                          : null,
                    ),
                  ),
                  Icon(
                    Icons.person_rounded,
                    color: active
                        ? colors.textPrimary
                        : colors.textTertiary.withValues(alpha: 0.4),
                    size: 60,
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
              padding: const EdgeInsets.only(right: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SURROUND SOUND',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Experience 7.1 virtual surround for total immersion in your games and movies.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'SURROUND STRENGTH',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  NahimicSlider(
                    value: context.select((SoundBloc b) => b.state.stereoWidth),
                    min: 0.0,
                    max: 4.0,
                    onChanged: (v) => context.read<SoundBloc>().add(
                      ChangeStereoWidthPreview(v),
                    ),
                    onChangedEnd: (v) =>
                        context.read<SoundBloc>().add(ChangeStereoWidth(v)),
                    labelTransformer: (v) => '${(v * 100).round()}%',
                  ),
                  const SizedBox(height: 16),
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final active = context.select((SoundBloc b) => b.state.smartVolume);

    return _PanelBox(
      enableField: 'smartVolume',
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VOLUME\nSTABILIZER',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            if (active) ...[
              Text(
                'COMPRESSION RATIO',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              NahimicSlider(
                value: context.select((SoundBloc b) => b.state.compressorRatio),
                min: 1.0,
                max: 10.0,
                onChanged: (v) => context.read<SoundBloc>().add(
                  ChangeCompressorRatioPreview(v),
                ),
                onChangedEnd: (v) =>
                    context.read<SoundBloc>().add(ChangeCompressorRatio(v)),
                labelTransformer: (v) => '${v.toStringAsFixed(1)}:1',
              ),
            ],
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: 36,
                    color: active
                        ? colors.performance
                        : colors.textTertiary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    active
                        ? 'DYNAMIC COMPRESSION ACTIVE'
                        : 'STABILIZER STANDBY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active ? colors.textPrimary : colors.textTertiary,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              'Maintains consistent volume levels across all content.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10,
                height: 1.4,
              ),
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
    final colors = Theme.of(context).extension<AppColors>()!;
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 54,
                    child: Text(
                      '${gain.toInt()} dB',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: NahimicSlider(
                      value: gain,
                      isVertical: false,
                      min: -12,
                      max: 12,
                      onChanged: isFullyActive
                          ? (v) => context.read<SoundBloc>().add(
                              ChangeEffectGainPreview(field, v),
                            )
                          : null,
                      onChangedEnd: isFullyActive
                          ? (v) => context.read<SoundBloc>().add(
                              ChangeEffectGain(field, v),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Flexible(
                    child: Text(
                      desc,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
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

  const _PanelBox({
    required this.child,
    required this.enableField,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.glassBg,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: colors.glassHighlight.withValues(alpha: 0.1),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            child,
            Positioned(
              top: 16,
              right: 16,
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
    final colors = Theme.of(context).extension<AppColors>()!;
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
      onTap: () =>
          context.read<SoundBloc>().add(ToggleEnhancement(field, !active)),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? colors.performance : Colors.transparent,
          border: Border.all(
            color: active
                ? colors.performance
                : colors.textTertiary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: colors.performance.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.power_settings_new_rounded,
          size: 16,
          color: active ? Colors.white : colors.textTertiary,
        ),
      ),
    );
  }
}

class _NightModeToggle extends StatelessWidget {
  const _NightModeToggle();
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final nightMode = context.select((SoundBloc b) => b.state.nightMode);
    return InkWell(
      onTap: () => context.read<SoundBloc>().add(
        ToggleEnhancement('nightMode', !nightMode),
      ),
      borderRadius: AppRadius.smAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.nightlight_round,
              size: 14,
              color: nightMode ? colors.performance : colors.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              'NIGHT MODE',
              style: TextStyle(
                color: nightMode ? colors.performance : colors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurroundVariationSelector extends StatelessWidget {
  const _SurroundVariationSelector();
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final current = context.select((SoundBloc b) => b.state.surroundVariation);
    const variations = ['Surround', '3D', 'Wide'];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: variations.map((v) {
        final isSelected = v == current;
        return InkWell(
          onTap: () =>
              context.read<SoundBloc>().add(ChangeSurroundVariation(v)),
          borderRadius: AppRadius.xsAll,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? colors.performance : Colors.transparent,
              borderRadius: AppRadius.xsAll,
              border: Border.all(
                color: isSelected
                    ? colors.performance
                    : colors.border.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              v.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final profile = context.select((SoundBloc b) => b.state.profile);
    final size = MediaQuery.sizeOf(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(40),
          height: size.height < 550 ? size.height * 0.9 : 500,
          child: SizedBox(
            width: size.width < 700 ? size.width * 0.95 : 650,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AUDIO EQUALIZER',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.performance.withValues(alpha: 0.1),
                            borderRadius: AppRadius.smAll,
                            border: Border.all(
                              color: colors.performance.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            profile.toUpperCase(),
                            style: TextStyle(
                              color: colors.performance,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(10, (i) {
                      final labels = [
                        '32',
                        '64',
                        '125',
                        '250',
                        '500',
                        '1K',
                        '2K',
                        '4K',
                        '8K',
                        '16K',
                      ];
                      return _EqBand(index: i, label: labels[i]);
                    }),
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

class _EqBand extends StatelessWidget {
  final int index;
  final String label;
  const _EqBand({required this.index, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final gain = context.select((SoundBloc b) => b.state.eqGains[index]);

    return Column(
      children: [
        Text(
          gain.toStringAsFixed(0),
          style: TextStyle(
            color: colors.performance,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _NahimicSliderEq(
            value: gain,
            onChanged: (v) {
              final bloc = context.read<SoundBloc>();
              final newGains = List<double>.from(bloc.state.eqGains);
              newGains[index] = v;
              bloc.add(UpdateEQGainsPreview(newGains));
            },
            onChangedEnd: (v) {
              final bloc = context.read<SoundBloc>();
              final newGains = List<double>.from(bloc.state.eqGains);
              newGains[index] = v;
              bloc.add(UpdateEQGains(newGains));
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
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

class _SurroundWaveState extends State<_SurroundWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
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
    final colors = Theme.of(context).extension<AppColors>()!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 120 + (_controller.value * 140),
          height: 120 + (_controller.value * 140),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.performance.withValues(
                alpha: (1.0 - _controller.value) * 0.4,
              ),
              width: 2.0 - (_controller.value * 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.performance.withValues(
                  alpha: (1.0 - _controller.value) * 0.1,
                ),
                blurRadius: 15,
                spreadRadius: 2,
              ),
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
    final colors = Theme.of(context).extension<AppColors>()!;
    final active = context.select((SoundBloc b) => b.state.micEnabled);
    final noiseSuppression = context.select(
      (SoundBloc b) => b.state.micNoiseSuppression,
    );
    final echoCancellation = context.select(
      (SoundBloc b) => b.state.echoCancellation,
    );
    final gain = context.select((SoundBloc b) => b.state.microphoneGain);

    return _PanelBox(
      enableField: 'micEnabled',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MICROPHONE\nENHANCEMENT',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            if (active) ...[
              _MicSettingsItem(
                label: 'NOISE SUPPRESSION',
                field: 'micNoiseSuppression',
                isActive: noiseSuppression,
                desc: 'Eliminate ambient noise for pure voice capture.',
              ),
              const SizedBox(height: 16),
              _MicSettingsItem(
                label: 'ECHO CANCELLATION',
                field: 'echoCancellation',
                isActive: echoCancellation,
                desc: 'Filter speaker output from being re-captured.',
              ),
              const Spacer(),
              Text(
                'MICROPHONE GAIN',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              NahimicSlider(
                value: gain,
                min: 0.0,
                max: 1.5,
                labelTransformer: (v) => '${(v * 100).round()}%',
                onChanged: (v) =>
                    context.read<SoundBloc>().add(ChangeMicrophoneGain(v)),
                onChangedEnd: (v) =>
                    context.read<SoundBloc>().add(ChangeMicrophoneGain(v)),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text(
                    'MICROPHONE IS OFF',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
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
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      children: [
        _SmallPowerToggle(field: field),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? colors.textPrimary : colors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 9,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
