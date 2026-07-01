import 'package:flutter/material.dart';

class TactileButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color? borderColor;

  const TactileButton({
    super.key,
    this.onPressed,
    required this.child,
    required this.color,
    this.borderColor,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isPressed = true),
      onExit: (_) => setState(() => _isPressed = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.color.withValues(alpha: 0.8)
                : widget.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.borderColor ?? Colors.transparent),
            boxShadow: [
              if (_isPressed)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 15,
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class PulseIconWidget extends StatefulWidget {
  final IconData icon;
  final Color color;

  const PulseIconWidget({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  State<PulseIconWidget> createState() => _PulseIconWidgetState();
}

class _PulseIconWidgetState extends State<PulseIconWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Container(
            width: 80 + (_controller.value * 80),
            height: 80 + (_controller.value * 80),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withValues(
                  alpha: (1.0 - _controller.value) * 0.4,
                ),
                width: 2,
              ),
            ),
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(widget.icon, color: widget.color, size: 40),
        ),
      ],
    );
  }
}