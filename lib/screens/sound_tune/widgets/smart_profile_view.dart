import 'package:flutter/material.dart';
import '../sound_tune_theme.dart';
import 'painters.dart';

class SmartProfileView extends StatelessWidget {
  const SmartProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBg,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(painter: AtomicPainter()),
          ),
          const SizedBox(width: 32),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'SMART PROFILE IS ON',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 12),
                Flexible(
                  child: Text(
                    'Nahimic identifies the content you play and performs automatic audio adjustments.',
                    style: TextStyle(
                      color: kTextSub,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 8),
                Flexible(
                  child: Text(
                    'Various game-specific presets have been created by our audio experts to highlight the sounds you really want to hear.',
                    style: TextStyle(
                      color: kTextSub,
                      fontSize: 11,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Relax and let yourself be immersed!',
                  style: TextStyle(
                    color: kTextSub,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
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
