import 'package:flutter/material.dart';
import 'package:msi_controller/screens/sound_tune/sound_tune_theme.dart';

const _kSoundTunePanelBorder = Color(0xFF1C222D);

class SoundTuneHeader extends StatelessWidget {
  final String title;
  final List<Widget>? leading;

  const SoundTuneHeader({
    super.key,
    required this.title,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kSoundTunePanelBorder)),
      ),
      child: Row(
        children: [
          ...?leading,
          if (leading != null) ...[const SizedBox(width: 16), const Spacer()],
          Text(title, style: SoundTuneTheme.h1),
          const Spacer(),
        ],
      ),
    );
  }
}
