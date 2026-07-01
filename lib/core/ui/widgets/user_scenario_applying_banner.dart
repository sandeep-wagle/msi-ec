import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

enum LoadingType { performance, gpu, fan }

class UserScenarioApplyingBanner extends StatelessWidget {
  final LoadingType loadingType;

  const UserScenarioApplyingBanner({
    super.key,
    required this.loadingType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    String loadingText = 'SYNCING PROTOCOLS...';
    switch (loadingType) {
      case LoadingType.performance:
        loadingText = 'PUSHING PERFORMANCE CLOCK...';
        break;
      case LoadingType.gpu:
        loadingText = 'SWITCHING GRAPHICS BUS...';
        break;
      case LoadingType.fan:
        loadingText = 'ADJUSTING THERMAL CURVE...';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.performance.withValues(alpha: 0.1),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: colors.performance.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            loadingText,
            style: TextStyle(
              color: colors.performance,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}