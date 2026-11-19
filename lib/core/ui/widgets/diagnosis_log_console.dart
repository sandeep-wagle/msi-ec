import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class DiagnosisLogConsole extends StatelessWidget {
  final AppColors colors;
  final List<String> logs;

  const DiagnosisLogConsole({
    super.key,
    required this.colors,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: logs
            .map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  log,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}