import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msi_controller/core/tokens/tokens.dart';

void main() {
  group('AppSpacing', () {
    test('spacing values are consistent multiples of base unit', () {
      expect(AppSpacing.xxxxs, 4.0);
      expect(AppSpacing.xxs, 8.0);
      expect(AppSpacing.xs, 12.0);
      expect(AppSpacing.sm, 16.0);
      expect(AppSpacing.md, 20.0);
      expect(AppSpacing.lg, 24.0);
      expect(AppSpacing.xl, 32.0);
      expect(AppSpacing.xxl, 40.0);
      expect(AppSpacing.xxxl, 48.0);
    });

    test('page padding is horizontal only', () {
      expect(AppSpacing.pagePaddingH.horizontal, AppSpacing.xl * 2);
      expect(AppSpacing.pagePaddingH.vertical, 0);
    });
  });

  group('AppRadius', () {
    test('radius values are in ascending order', () {
      expect(AppRadius.xs, lessThan(AppRadius.sm));
      expect(AppRadius.sm, lessThan(AppRadius.md));
      expect(AppRadius.md, lessThan(AppRadius.lg));
      expect(AppRadius.lg, lessThan(AppRadius.xl));
    });

    test('BorderRadius helpers return correct values', () {
      expect(AppRadius.smAll, isNotNull);
      expect(AppRadius.mdAll, isNotNull);
      expect(AppRadius.pillAll, isNotNull);
    });
  });

  group('AppDurations', () {
    test('durations are in ascending order', () {
      expect(AppDurations.instant.inMilliseconds,
          lessThan(AppDurations.fast.inMilliseconds));
      expect(AppDurations.fast.inMilliseconds,
          lessThan(AppDurations.normal.inMilliseconds));
      expect(AppDurations.normal.inMilliseconds,
          lessThan(AppDurations.medium.inMilliseconds));
      expect(AppDurations.medium.inMilliseconds,
          lessThan(AppDurations.slow.inMilliseconds));
      expect(AppDurations.slow.inMilliseconds,
          lessThan(AppDurations.verySlow.inMilliseconds));
    });

    test('polling durations are reasonable', () {
      expect(AppDurations.pollingSystem.inSeconds, 2);
      expect(AppDurations.pollingFan.inSeconds, 1);
      expect(AppDurations.streamThrottle.inMilliseconds, 500);
    });
  });

  group('AppTypography', () {
    test('font sizes are in ascending order', () {
      expect(AppTypography.labelSmall.fontSize,
          lessThan(AppTypography.labelMedium.fontSize!));
      expect(AppTypography.labelMedium.fontSize,
          lessThan(AppTypography.bodySmall.fontSize!));
      expect(AppTypography.bodySmall.fontSize,
          lessThan(AppTypography.bodyMedium.fontSize!));
      expect(AppTypography.bodyMedium.fontSize,
          lessThan(AppTypography.bodyLarge.fontSize!));
      expect(AppTypography.bodyLarge.fontSize,
          lessThan(AppTypography.titleMedium.fontSize!));
      expect(AppTypography.titleMedium.fontSize,
          lessThan(AppTypography.titleLarge.fontSize!));
      expect(AppTypography.titleLarge.fontSize,
          lessThan(AppTypography.headlineMedium.fontSize!));
      expect(AppTypography.headlineMedium.fontSize,
          lessThan(AppTypography.displayMedium.fontSize!));
      expect(AppTypography.displayMedium.fontSize,
          lessThan(AppTypography.displayLarge.fontSize!));
    });
  });

  group('AppBreakpoints', () {
    test('compact detection works', () {
      expect(AppBreakpoints.isCompact(400), isTrue);
      expect(AppBreakpoints.isCompact(700), isFalse);
    });

    test('medium detection works', () {
      expect(AppBreakpoints.isMedium(700), isTrue);
      expect(AppBreakpoints.isMedium(400), isFalse);
      expect(AppBreakpoints.isMedium(1300), isFalse);
    });

    test('large detection works', () {
      expect(AppBreakpoints.isLarge(1300), isTrue);
      expect(AppBreakpoints.isLarge(800), isFalse);
    });

    test('grid columns adapt to width', () {
      expect(AppBreakpoints.gridColumns(500), 2);
      expect(AppBreakpoints.gridColumns(700), 2);
      expect(AppBreakpoints.gridColumns(1000), 3);
      expect(AppBreakpoints.gridColumns(1300), 4);
      expect(AppBreakpoints.gridColumns(1700), 5);
    });
  });

  group('AppShadows', () {
    test('glow shadow creates correct color', () {
      final shadow = AppShadows.glow(const Color(0xFFEB1D24));
      expect(shadow.color, isNotNull);
      expect(shadow.blurRadius, 16);
    });

    test('card shadows are non-empty', () {
      expect(AppShadows.cardLight, isNotEmpty);
      expect(AppShadows.cardDark, isNotEmpty);
    });
  });
}
