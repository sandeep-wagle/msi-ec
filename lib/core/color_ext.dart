import 'package:flutter/material.dart';

/// Small extension to keep compatibility with the codebase's
/// `.withValues(alpha: x)` usage. `alpha` is 0.0 - 1.0 and maps
/// to Color.fromARGB to preserve precision.
extension ColorValues on Color {
  Color withValues({required double alpha}) {
    final a = (alpha.clamp(0.0, 1.0) * 255).round();
    return Color.fromARGB(a, red, green, blue);
  }
}
