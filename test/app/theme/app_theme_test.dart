/// Text weight is applied on the theme, and contrast on the scheme. A theme
/// that ignores either setting looks the same after the user changes it.
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_theme.dart';
import 'package:dpip/core/build/demo_flags.dart';
import 'package:dpip/core/settings/display_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light and dark themes follow brightness and weight', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.light.useMaterial3, isTrue);

    final plain = AppTheme.of(Brightness.light);
    final heavy = AppTheme.of(
      Brightness.light,
      weight: TextWeightStep.bold,
      contrast: ContrastStep.high,
    );
    expect(plain.textTheme.bodyMedium?.fontWeight, isNull);
    expect(heavy.textTheme.bodyMedium?.fontWeight, isNotNull);
    expect(
      AppTheme.scheme(
        Brightness.dark,
        contrast: ContrastStep.medium,
      ).brightness,
      Brightness.dark,
    );
  });

  test('radius and motion tokens are the shared scale', () {
    expect(AppRadius.sm, 8);
    expect(AppRadius.md, 16);
    expect(AppRadius.lg, 20);
    expect(AppRadius.small.topLeft.x, AppRadius.sm);
    expect(AppRadius.medium.topLeft.x, AppRadius.md);
    expect(AppRadius.large.topLeft.x, AppRadius.lg);
    expect(AppRadius.topSheet.topLeft.y, AppRadius.lg);
    expect(AppRadius.topSheet.bottomLeft.y, 0);
    expect(AppMotion.fast, const Duration(milliseconds: 150));
    expect(AppMotion.medium, const Duration(milliseconds: 220));
    expect(AppMotion.slow, const Duration(milliseconds: 400));
  });

  test('demo flags are off unless a debug define turns them on', () {
    expect(kMonitorDemoEnabled, isFalse);
    expect(kStartupEewDemoEnabled, isFalse);
    expect(kMonitorDemoSevereEnabled, isFalse);
    expect(kMonitorDemoSoundEnabled, isFalse);
  });
}
