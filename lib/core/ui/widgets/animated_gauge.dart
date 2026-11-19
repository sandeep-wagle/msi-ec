import 'package:flutter/material.dart';
import 'package:msi_controller/core/app_colors.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

class AnimatedGauge extends StatefulWidget {
  final double value;
  final Color color;

  const AnimatedGauge({super.key, required this.value, required this.color});

  @override
  State<AnimatedGauge> createState() => AnimatedGaugeState();
}

class AnimatedGaugeState extends State<AnimatedGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _controller.forward(from: 0);
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
      animation: _anim,
      builder: (context, _) => ClipRRect(
        borderRadius: AppRadius.xsAll,
        child: LinearProgressIndicator(
          value: (_anim.value * widget.value).clamp(0.0, 1.0),
          minHeight: 4,
          backgroundColor: colors.gaugeTrack,
          valueColor: AlwaysStoppedAnimation<Color>(widget.color),
        ),
      ),
    );
  }
}