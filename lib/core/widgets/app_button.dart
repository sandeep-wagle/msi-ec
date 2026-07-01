import 'package:flutter/material.dart';
import 'package:msi_controller/core/tokens/tokens.dart';
import 'package:msi_controller/core/ui/widgets/app_button_build.dart';

class AppButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double? height;
  final String? semanticLabel;
  final bool isElevated;
  final bool isFilled;
  final bool isOutline;
  final bool isPrimary;
  final bool isOval;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.icon,
    this.width,
    this.height,
    this.semanticLabel,
    this.isElevated = true,
    this.isFilled = false,
    this.isOutline = false,
    this.isPrimary = true,
    this.isOval = true,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
    this.isLoading = false,
    this.padding,
  }) : assert(text != null || child != null);

  @override
  Widget build(BuildContext context) {
    final borderRadius = isOval ? AppRadius.pillAll : AppRadius.smAll;
    final button = AppButtonBuild(
      borderRadius: borderRadius,
      isOutline: isOutline,
      isFilled: isFilled,
      isElevated: isElevated,
      isPrimary: isPrimary,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding,
      text: text,
      isLoading: isLoading,
      icon: icon,
      fontSize: fontSize,
      child: child,
    );
    if (width != null || height != null) {
      return SizedBox(width: width, height: height ?? 48, child: button);
    }
    return button;
  }
}