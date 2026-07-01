import 'package:flutter/material.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class SystemLogs extends StatelessWidget {
  final double progress;
  const SystemLogs({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LogLine(text: 'Checking PCIe lanes...', active: true),
          _LogLine(text: 'Mapping thermal sensors...', active: progress > 0.3),
          _LogLine(
            text: 'Handshaking with DSP engine...',
            active: progress > 0.6,
          ),
          _LogLine(
            text: 'Authenticating biometric bridge...',
            active: progress > 0.8,
          ),
        ],
      ),
    );
  }
}

class _LogLine extends StatelessWidget {
  final String text;
  final bool active;
  const _LogLine({required this.text, required this.active});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: active ? 1.0 : 0.2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(
              '>',
              style: TextStyle(
                color: active ? Colors.greenAccent : Colors.white24,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
