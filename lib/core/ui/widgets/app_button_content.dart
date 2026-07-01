import 'package:flutter/material.dart';

class AppButtonContent extends StatelessWidget {
  final String? text;
  final Widget? child;
  final bool isLoading;
  final IconData? icon;
  final double? fontSize;

  const AppButtonContent({
    super.key,
    this.text,
    this.child,
    this.isLoading = false,
    this.icon,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    }

    final label = text != null
        ? Text(
            text!,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: fontSize ?? 11,
              letterSpacing: 1.5,
            ),
          )
        : child;

    if (icon != null && label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 8), label],
      );
    }

    return label ?? const SizedBox.shrink();
  }
}