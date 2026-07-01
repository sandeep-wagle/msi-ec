import 'package:flutter/material.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/widgets/sdk/procedural_radar.dart';
import 'package:msi_controller/widgets/sdk/info_panel.dart';
import 'package:msi_controller/widgets/sdk/system_logs.dart';

class SdkInitializationLoader extends StatefulWidget {
  final double progress;
  final String message;
  final String version;

  const SdkInitializationLoader({
    super.key,
    this.progress = 0.4,
    this.message = 'Synchronizing hardware protocols...',
    this.version = 'v2.0.34.0',
  });

  @override
  State<SdkInitializationLoader> createState() =>
      _SdkInitializationLoaderState();
}

class _SdkInitializationLoaderState extends State<SdkInitializationLoader>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scanAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_scanController);
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      decoration: BoxDecoration(
        color: const Color(0xFF050510).withValues(alpha: 0.95),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ProceduralRadar(
                progress: widget.progress,
                rotateController: _rotateController,
                scanAnimation: _scanAnimation,
              ),
              const SizedBox(width: AppSpacing.xxxl),
              Expanded(
                child: InfoPanel(
                  message: widget.message,
                  version: widget.version,
                  progress: widget.progress,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          SystemLogs(progress: widget.progress),
        ],
      ),
    );
  }
}
