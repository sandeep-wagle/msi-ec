import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../sound_tune_theme.dart';
import '../../../logic/blocs/sound/sound_bloc.dart';
import '../../../logic/blocs/sound/sound_event.dart';

class NahimicPanel extends StatefulWidget {
  final Widget child;
  const NahimicPanel({required this.child, super.key});

  @override
  State<NahimicPanel> createState() => _NahimicPanelState();
}

class _NahimicPanelState extends State<NahimicPanel> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(1),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF10141C) : kPanel,
          border: Border.all(
            color: _isHovered ? kAccent.withOpacity(0.5) : kPanelBorder, 
            width: 0.5
          ),
          boxShadow: _isHovered ? [
            BoxShadow(
              color: kAccent.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ] : null,
        ),
        child: widget.child,
      ),
    );
  }
}

class PowerToggle extends StatelessWidget {
  final String field;
  const PowerToggle({required this.field, super.key});

  @override
  Widget build(BuildContext context) {
    final isActive = context.select((SoundBloc b) {
      if (field == 'bassBoost') return b.state.bassBoost;
      if (field == 'trebleEnhancer') return b.state.trebleEnhancer;
      if (field == 'voiceClarity') return b.state.voiceClarity;
      if (field == 'virtualSurround') return b.state.virtualSurround;
      if (field == 'smartVolume') return b.state.smartVolume;
      if (field == 'limiterEnabled') return b.state.limiterEnabled;
      if (field == 'trackerEnabled') return b.state.trackerEnabled;
      if (field == 'sharingEnabled') return b.state.sharingEnabled;
      return false;
    });

    return Tooltip(
      message: 'Toggle ${field.replaceAll(RegExp(r"(?=[A-Z])"), " ").toLowerCase()}',
      child: GestureDetector(
        onTap: () =>
            context.read<SoundBloc>().add(ToggleEnhancement(field, !isActive)),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? kAccent.withOpacity(0.15) : Colors.transparent,
            border: Border.all(color: isActive ? kAccent : kTextSub.withOpacity(0.5), width: 1.5),
            boxShadow: isActive
                ? [BoxShadow(color: kAccentGlow.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)]
                : null,
          ),
          child: Icon(
            Icons.power_settings_new,
            size: 16,
            color: isActive ? kAccent : kTextSub.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

class SmallPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const SmallPill({required this.label, required this.active, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? kAccent.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: active ? kAccent : kTextSub.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? kAccent : kTextSub,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class NahimicSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final bool isVertical;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangedEnd;
  final String Function(double)? labelTransformer;

  const NahimicSlider({
    required this.value,
    this.min = 0,
    this.max = 12,
    this.isVertical = false,
    required this.onChanged,
    this.onChangedEnd,
    this.labelTransformer,
    super.key,
  });

  @override
  State<NahimicSlider> createState() => _NahimicSliderState();
}

class _NahimicSliderState extends State<NahimicSlider> {
  bool _isInteracting = false;

  @override
  Widget build(BuildContext context) {
    // Using constants from sound_tune_theme.dart via imports
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalRange = widget.max - widget.min;
        final progress = ((widget.value - widget.min) / totalRange).clamp(0.0, 1.0);
        final isActive = widget.onChanged != null;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => setState(() => _isInteracting = true),
          onPanEnd: (_) {
            setState(() => _isInteracting = false);
            widget.onChangedEnd?.call(widget.value);
          },
          onPanUpdate: (details) {
            if (!isActive) return;
            final box = context.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(details.globalPosition);
            
            double newValue;
            if (widget.isVertical) {
              newValue = widget.max - (localPos.dy / constraints.maxHeight) * totalRange;
            } else {
              newValue = widget.min + (localPos.dx / constraints.maxWidth) * totalRange;
            }
            widget.onChanged!(newValue.clamp(widget.min, widget.max));
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _isInteracting = true),
            onExit: (_) => setState(() => _isInteracting = false),
            cursor: isActive ? SystemMouseCursors.grab : SystemMouseCursors.basic,
            child: Container(
              width: widget.isVertical ? 40 : double.infinity,
              height: widget.isVertical ? double.infinity : 40,
              color: Colors.transparent, 
              child: Center(
                child: Container(
                  width: widget.isVertical ? 6 : double.infinity,
                  height: widget.isVertical ? double.infinity : 6,
                  decoration: BoxDecoration(
                    color: kPanelBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Stack(
                    alignment: widget.isVertical ? Alignment.bottomCenter : Alignment.centerLeft,
                    clipBehavior: Clip.none,
                    children: [
                      if (widget.isVertical)
                        FractionallySizedBox(
                          heightFactor: progress,
                          child: Container(
                            width: 6,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [kAccent, Color(0xBB00F0FF)],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        )
                      else
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [kAccent, Color(0xBB00F0FF)],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: widget.isVertical ? (progress * constraints.maxHeight) - 8 : -5,
                        left: widget.isVertical ? -5 : (progress * constraints.maxWidth) - 8,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : kTextSub,
                            shape: BoxShape.circle,
                            border: Border.all(color: isActive ? kAccent : kTextSub, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2)),
                              if (isActive && _isInteracting)
                                BoxShadow(color: kAccent.withOpacity(0.6), blurRadius: 12, spreadRadius: 4),
                            ],
                          ),
                        ),
                      ),
                      if (isActive && _isInteracting)
                        Positioned(
                          bottom: widget.isVertical ? (progress * constraints.maxHeight) + 24 : 28,
                          left: widget.isVertical ? -38 : (progress * constraints.maxWidth) - 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: kPanel.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: kAccent.withValues(alpha: 0.6), width: 1.5),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 12),
                                BoxShadow(color: kAccent.withValues(alpha: 0.2), blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              widget.labelTransformer?.call(widget.value) ??
                              (widget.max <= 1.5 
                                ? '${(widget.value * 100).toInt()}%'
                                : '${widget.value.toInt()} dB'),
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 11, 
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const HeaderActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
