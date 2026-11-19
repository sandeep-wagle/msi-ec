import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:msi_controller/screens/sound_tune/sound_tune_theme.dart';
import 'shared_widgets.dart';
import 'content_panels.dart';
import 'smart_profile_view.dart';
import 'package:msi_controller/logic/blocs/sound/sound_bloc.dart';
import 'package:msi_controller/logic/blocs/sound/sound_event.dart';
import 'package:msi_controller/services/toast_service.dart';
import 'package:msi_controller/core/di/injection.dart';
import 'package:msi_controller/screens/sound_tune/widgets/sound_tune_header.dart';

class AudioView extends StatelessWidget {
  const AudioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AudioHeader(),
        const ModeTabs(),
        const Expanded(child: ContentLayout()),
      ],
    );
  }
}

class AudioHeader extends StatelessWidget {
  const AudioHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final effectsEnabled = context.select(
      (SoundBloc b) => b.state.effectsEnabled,
    );

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: kPanel,
        border: Border(bottom: BorderSide(color: kPanelBorder, width: 1.5)),
      ),
      child: Row(
        children: [
          PowerToggle(field: 'effectsEnabled'),
          const SizedBox(width: 12),
          Text(
            effectsEnabled ? 'Effects ON' : 'Effects OFF',
            style: TextStyle(
              color: effectsEnabled ? kAccent : kTextSub,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          const Text('AUDIO', style: SoundTuneTheme.h1),
          const Spacer(),
          HeaderActionButton(
            icon: Icons.play_arrow,
            label: 'Try',
            color: kAccent,
            onPressed: () =>
                getIt<ToastService>().showInfo('▶ Playing test tone...'),
          ),
          const SizedBox(width: 16),
          HeaderActionButton(
            icon: Icons.refresh,
            label: 'Reset',
            color: kTextSub,
            onPressed: () {
              context.read<SoundBloc>().add(ResetSoundSettings());
              getIt<ToastService>().showInfo(
                'All sound settings have been reset.',
              );
            },
          ),
        ],
      ),
    );
  }
}

class ModeTabs extends StatelessWidget {
  const ModeTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.select((SoundBloc b) => b.state.profile);
    const tabs = [
      ('MUSIC', 'Music', Icons.music_note),
      ('MOVIE', 'Movie', Icons.movie_creation_outlined),
      ('COMMUNICATION', 'Voice', Icons.headset_mic_outlined),
      ('GAMING', 'Gaming', Icons.sports_esports),
      ('SMART', 'Custom', Icons.auto_awesome_outlined),
    ];

    return Container(
      height: 80,
      color: kPanel,
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
                      color: isSelected ? kAccent : Colors.transparent,
                      width: 4,
                    ),
                  ),
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            kAccent.withValues(alpha: 0.05),
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
                      size: 24,
                      color: isSelected ? kAccent : kTextSub,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? kTextPrimary : kTextSub,
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.bold,
                        letterSpacing: 2.0,
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

class ContentLayout extends StatelessWidget {
  const ContentLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.select((SoundBloc b) => b.state.profile);

    return Column(
      children: [
        Expanded(
          flex: profile == 'Custom' ? 6 : 5,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: NahimicPanel(
                  child: profile == 'Custom'
                      ? const SmartProfileView()
                      : const SurroundPanel(),
                ),
              ),
              const Expanded(
                flex: 2,
                child: NahimicPanel(child: VolumeStabilizerPanel()),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Row(
            children: [
              const Expanded(
                child: NahimicPanel(
                  child: EffectSliderPanel(
                    title: 'VOICES',
                    field: 'voice',
                    enableField: 'voiceClarity',
                    desc:
                        'Make them faraway or present\n(dialogs, choirs, chat, etc.)',
                  ),
                ),
              ),
              const Expanded(
                child: NahimicPanel(
                  child: EffectSliderPanel(
                    title: 'BASS',
                    field: 'bass',
                    enableField: 'bassBoost',
                    desc:
                        'Make them punchy or lighter\n(explosions, engines, beats, bass guitars, etc.)',
                  ),
                ),
              ),
              const Expanded(
                child: NahimicPanel(
                  child: EffectSliderPanel(
                    title: 'TREBLE',
                    field: 'treble',
                    enableField: 'trebleEnhancer',
                    desc:
                        'Make them faded or clearer\n(footsteps, whistles, cymbals, etc.)',
                  ),
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: NahimicPanel(
                  child: AdvancedEffectPanel(
                    title: 'NOISE SUPPRESSION',
                    field: 'noiseLevel',
                    min: 0,
                    max: 10,
                    desc: 'Reduce background noise',
                  ),
                ),
              ),
              Expanded(
                child: NahimicPanel(
                  child: AdvancedEffectPanel(
                    title: 'STEREO WIDTH',
                    field: 'stereoWidth',
                    min: 0,
                    max: 2,
                    desc: 'Expand audio soundstage',
                  ),
                ),
              ),
              Expanded(
                child: NahimicPanel(
                  child: LimiterPanel(
                    title: 'LIMITER',
                    desc: 'Prevent audio clipping',
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

class EasySurroundView extends StatelessWidget {
  const EasySurroundView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SoundTuneHeader(
          title: 'EASY SURROUND',
          leading: const [
            PowerToggle(field: 'virtualSurround'),
            StatusText(field: 'virtualSurround'),
          ],
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.gps_fixed,
                  color: kAccent.withValues(alpha: 0.3),
                  size: 120,
                ),
                const SizedBox(height: 24),
                const Text('OPTIMIZE YOUR HEADSET', style: SoundTuneTheme.h1),
                const SizedBox(height: 12),
                const Text(
                  'Connect your Bluetooth headset and enjoy the surround sound',
                  style: SoundTuneTheme.subText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class StatusText extends StatelessWidget {
  final String field;
  const StatusText({required this.field, super.key});

  @override
  Widget build(BuildContext context) {
    final isActive = context.select((SoundBloc b) {
      if (field == 'virtualSurround') return b.state.virtualSurround;
      if (field == 'trackerEnabled') return b.state.trackerEnabled;
      if (field == 'sharingEnabled') return b.state.sharingEnabled;
      if (field == 'micEnabled') return b.state.micEnabled;
      return false;
    });

    return Text(
      isActive ? 'ON' : 'OFF',
      style: TextStyle(
        color: isActive ? kAccent : kTextSub,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }
}

class SoundSharingView extends StatelessWidget {
  const SoundSharingView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SoundBloc>().state;

    return Column(
      children: [
        SoundTuneHeader(
          title: 'SOUND SHARING',
          leading: const [
            PowerToggle(field: 'sharingEnabled'),
            StatusText(field: 'sharingEnabled'),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: NahimicPanel(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.headset,
                          color: state.sharingEnabled ? kAccent : kTextSub,
                          size: 60,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.wifi,
                          color: state.sharingEnabled
                              ? kAccent.withValues(alpha: 0.5)
                              : kTextSub.withValues(alpha: 0.2),
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.headset,
                          color: state.sharingEnabled ? kAccent : kTextSub,
                          size: 60,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('MULTICAST AUDIO', style: SoundTuneTheme.h1),
                    const SizedBox(height: 12),
                    const Text(
                      'Share your audio with multiple Bluetooth devices simultaneously.',
                      style: SoundTuneTheme.subText,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kBg.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kPanelBorder),
                      ),
                      child: const Column(
                        children: [
                          _SharingDeviceItem(
                            name: 'Sony WH-1000XM4',
                            connected: true,
                          ),
                          Divider(color: kPanelBorder),
                          _SharingDeviceItem(
                            name: 'MSI IMMERSE GH50',
                            connected: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SharingDeviceItem extends StatelessWidget {
  final String name;
  final bool connected;
  const _SharingDeviceItem({required this.name, required this.connected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.bluetooth,
            color: connected ? kAccent : kTextSub,
            size: 16,
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: TextStyle(
              color: connected ? kTextPrimary : kTextSub,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            connected ? 'CONNECTED' : 'NOT CONNECTED',
            style: TextStyle(
              color: connected ? kAccent : kTextSub,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SoundTuneHeader(title: 'SETTINGS'),
        const Expanded(
          child: Center(
            child: Text(
              'Application Settings...',
              style: TextStyle(color: kTextSub),
            ),
          ),
        ),
      ],
    );
  }
}

class MicrophoneView extends StatelessWidget {
  const MicrophoneView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SoundBloc>().state;

    return Column(
      children: [
        SoundTuneHeader(
          title: 'MICROPHONE',
          leading: const [
            PowerToggle(field: 'micEnabled'),
            StatusText(field: 'micEnabled'),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: NahimicPanel(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic,
                            color: state.micEnabled ? kAccent : kTextSub,
                            size: 80,
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'MICROPHONE GAIN',
                            style: SoundTuneTheme.h2,
                          ),
                          const SizedBox(height: 16),
                          NahimicSlider(
                            value: state.microphoneGain,
                            min: 0.0,
                            max: 2.0,
                            onChanged: (v) => context.read<SoundBloc>().add(
                              ChangeMicrophoneGainPreview(v),
                            ),
                            onChangedEnd: (v) => context.read<SoundBloc>().add(
                              ChangeMicrophoneGain(v),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(state.microphoneGain * 100).round()}%',
                            style: const TextStyle(
                              color: kAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: NahimicPanel(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'NOISE SUPPRESSION',
                                      style: SoundTuneTheme.h2,
                                    ),
                                    PowerToggle(field: 'micNoiseSuppression'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Remove background noise from your microphone for clear communication.',
                                  style: SoundTuneTheme.subText,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: NahimicPanel(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'ECHO CANCELLATION',
                                      style: SoundTuneTheme.h2,
                                    ),
                                    PowerToggle(field: 'echoCancellation'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Prevent your microphone from picking up sound from your speakers.',
                                  style: SoundTuneTheme.subText,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SoundTrackerView extends StatelessWidget {
  const SoundTrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SoundBloc>().state;

    return Column(
      children: [
        SoundTuneHeader(
          title: 'SOUND TRACKER',
          leading: const [
            PowerToggle(field: 'trackerEnabled'),
            StatusText(field: 'trackerEnabled'),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: NahimicPanel(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          color: state.trackerEnabled
                              ? kAccent.withValues(alpha: 0.2)
                              : kTextSub.withValues(alpha: 0.1),
                          size: 200,
                        ),
                        if (state.trackerEnabled)
                          const Icon(
                            Icons.navigation,
                            color: kAccent,
                            size: 60,
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'VISUAL SOUND COMPASS',
                      style: SoundTuneTheme.h1,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The Sound Tracker is a visual indicator that points out the directions of sounds.',
                      style: SoundTuneTheme.subText,
                    ),
                    const SizedBox(height: 24),
                    const SmallPill(label: 'CALIBRATE', active: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
