import 'package:flutter/material.dart';

const double _kBaseUnit = 4.0;

class AppSpacing {
  AppSpacing._();

  static const double xxxxs = _kBaseUnit * 1; // 4
  static const double xxxs = _kBaseUnit * 1.5; // 6
  static const double xxs = _kBaseUnit * 2; // 8
  static const double xs = _kBaseUnit * 3; // 12
  static const double sm = _kBaseUnit * 4; // 16
  static const double md = _kBaseUnit * 5; // 20
  static const double lg = _kBaseUnit * 6; // 24
  static const double xl = _kBaseUnit * 8; // 32
  static const double xxl = _kBaseUnit * 10; // 40
  static const double xxxl = _kBaseUnit * 12; // 48

  static const EdgeInsets pagePaddingH = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets sectionPaddingH = EdgeInsets.symmetric(
    horizontal: lg,
  );
}

class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double pill = 100.0;

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get pillAll => BorderRadius.circular(pill);
}

class AppDurations {
  AppDurations._();

  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration streamThrottle = Duration(milliseconds: 500);
  static const Duration pollingSystem = Duration(seconds: 2);
  static const Duration pollingFan = Duration(seconds: 1);
}

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    height: 1.2,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w600,
  );
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> cardLight = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> cardDark = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> bottomNavLight = [
    BoxShadow(color: Color(0x14000000), blurRadius: 32, offset: Offset(0, -6)),
  ];

  static const List<BoxShadow> bottomNavDark = [
    BoxShadow(color: Color(0x99000000), blurRadius: 32, offset: Offset(0, -6)),
  ];

  static BoxShadow glow(
    Color color, {
    double radius = 16,
    double opacity = 0.06,
  }) {
    return BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: radius,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    );
  }
}

class AppBreakpoints {
  AppBreakpoints._();

  static const double compact = 600;
  static const double medium = 900;
  static const double large = 1200;
  static const double extraLarge = 1600;

  static bool isCompact(double width) => width < compact;
  static bool isMedium(double width) => width >= compact && width < large;
  static bool isLarge(double width) => width >= large;

  static int gridColumns(double width) {
    if (width < medium) return 2;
    if (width < large) return 3;
    if (width < extraLarge) return 4;
    return 5;
  }
}
