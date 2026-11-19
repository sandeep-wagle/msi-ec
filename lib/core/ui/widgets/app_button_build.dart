import 'package:flutter/material.dart';
import 'package:msi_controller/core/ui/widgets/app_button_content.dart';

class AppButtonBuild extends StatelessWidget {
  final BorderRadius borderRadius;
  final bool isOutline;
  final bool isFilled;
  final bool isElevated;
  final bool isPrimary;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final String? text;
  final Widget? child;
  final bool isLoading;
  final IconData? icon;
  final double? fontSize;

  const AppButtonBuild({
    super.key,
    required this.borderRadius,
    required this.isOutline,
    required this.isFilled,
    required this.isElevated,
    required this.isPrimary,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.text,
    this.child,
    this.isLoading = false,
    this.icon,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutline) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color:
                backgroundColor ??
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          foregroundColor: foregroundColor,
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: AppButtonContent(
          text: text,
          isLoading: isLoading,
          icon: icon,
          fontSize: fontSize,
          child: child,
        ),
      );
    }

    if (isFilled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor:
              backgroundColor ?? Theme.of(context).colorScheme.primary,
          foregroundColor:
              foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: AppButtonContent(
          text: text,
          isLoading: isLoading,
          icon: icon,
          fontSize: fontSize,
          child: child,
        ),
      );
    }

    if (!isElevated && !isPrimary) {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: AppButtonContent(
          text: text,
          isLoading: isLoading,
          icon: icon,
          fontSize: fontSize,
          child: child,
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor:
            foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: isElevated ? 2 : 0,
      ),
      child: AppButtonContent(
        text: text,
        isLoading: isLoading,
        icon: icon,
        fontSize: fontSize,
        child: child,
      ),
    );
  }
}