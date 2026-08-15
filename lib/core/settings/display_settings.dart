/// How the app's interface is drawn: text size, text weight, contrast.
library;

import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/material.dart';

/// UI text size, as a multiplier on whatever the OS accessibility setting
/// already gives.
enum TextScaleStep {
  small(0.85),
  normal(1),
  large(1.2),
  huge(1.45);

  const TextScaleStep(this.factor);

  /// Multiplied with the platform's own scale, never substituted for it — a
  /// user who has already enlarged text system-wide has said something, and
  /// replacing that would shrink the app for exactly the people who need it
  /// biggest.
  final double factor;

  String get token => name;

  static TextScaleStep fromToken(String? token) => switch (token) {
    'small' => TextScaleStep.small,
    'large' => TextScaleStep.large,
    'huge' => TextScaleStep.huge,
    _ => TextScaleStep.normal,
  };
}

/// UI text weight.
enum TextWeightStep {
  normal(0),
  medium(1),
  bold(2);

  const TextWeightStep(this.steps);

  /// How many places to move every text style up the weight ladder.
  final int steps;

  String get token => name;

  static TextWeightStep fromToken(String? token) => switch (token) {
    'medium' => TextWeightStep.medium,
    'bold' => TextWeightStep.bold,
    _ => TextWeightStep.normal,
  };
}

/// Colour-scheme contrast, passed straight to `ColorScheme.fromSeed`.
enum ContrastStep {
  standard(0),
  medium(0.5),
  high(1);

  const ContrastStep(this.level);

  /// Material's own contrast level, 0–1.
  final double level;

  String get token => name;

  static ContrastStep fromToken(String? token) => switch (token) {
    'medium' => ContrastStep.medium,
    'high' => ContrastStep.high,
    _ => ContrastStep.standard,
  };
}

/// The display-accessibility settings, persisted and published to the app root.
///
/// Each default is stored as absence, so an untouched install has no keys at
/// all rather than three magic strings.
///
/// Text size is deliberately **not** applied through `textTheme.apply(
/// fontSizeFactor:)`. This app's [ThemeData] declares only a `colorScheme`, so
/// its text theme is Material's colour-only default, and `apply` asserts on it.
/// The size travels as a `TextScaler` on `MediaQuery` instead, which is also
/// what lets it compose with the platform's own accessibility scale rather than
/// overwrite it.
class DisplaySettings extends ChangeNotifier {
  DisplaySettings(this._settings);

  final SettingsStore _settings;

  TextScaleStep get textScale =>
      TextScaleStep.fromToken(_settings.getString(SettingKeys.textScale));

  TextWeightStep get textWeight =>
      TextWeightStep.fromToken(_settings.getString(SettingKeys.textWeight));

  ContrastStep get contrast =>
      ContrastStep.fromToken(_settings.getString(SettingKeys.contrast));

  Future<void> setTextScale(TextScaleStep next) =>
      _write(SettingKeys.textScale, next.token, next == TextScaleStep.normal);

  Future<void> setTextWeight(TextWeightStep next) =>
      _write(SettingKeys.textWeight, next.token, next == TextWeightStep.normal);

  Future<void> setContrast(ContrastStep next) =>
      _write(SettingKeys.contrast, next.token, next == ContrastStep.standard);

  Future<void> _write(
    SettingKey<String> key,
    String token,
    bool isDefault,
  ) async {
    if (_settings.getString(key) == (isDefault ? null : token)) return;
    if (isDefault) {
      await _settings.remove(key);
    } else {
      await _settings.setString(key, token);
    }
    notifyListeners();
  }
}

/// [weight] applied to every style in [base].
///
/// Moves each style up the ladder rather than setting one absolute weight, so
/// the type hierarchy survives: a heading that was already heavier than its
/// body text stays heavier. The app's 123 explicit `fontWeight:` overrides beat
/// this wherever they appear, which is why it moves rather than flattens —
/// flattening would collapse the hierarchy at the top of the range.
TextTheme applyTextWeight(TextTheme base, TextWeightStep weight) {
  if (weight == TextWeightStep.normal) return base;
  TextStyle? bump(TextStyle? style) {
    if (style == null) return null;
    final index = FontWeight.values.indexOf(
      style.fontWeight ?? FontWeight.w400,
    );
    final next = (index + weight.steps).clamp(0, FontWeight.values.length - 1);
    return style.copyWith(fontWeight: FontWeight.values[next]);
  }

  return base.copyWith(
    displayLarge: bump(base.displayLarge),
    displayMedium: bump(base.displayMedium),
    displaySmall: bump(base.displaySmall),
    headlineLarge: bump(base.headlineLarge),
    headlineMedium: bump(base.headlineMedium),
    headlineSmall: bump(base.headlineSmall),
    titleLarge: bump(base.titleLarge),
    titleMedium: bump(base.titleMedium),
    titleSmall: bump(base.titleSmall),
    bodyLarge: bump(base.bodyLarge),
    bodyMedium: bump(base.bodyMedium),
    bodySmall: bump(base.bodySmall),
    labelLarge: bump(base.labelLarge),
    labelMedium: bump(base.labelMedium),
    labelSmall: bump(base.labelSmall),
  );
}

/// [base] with the user's step applied on top.
///
/// A composed scaler rather than a replacement, so the OS accessibility size
/// still counts. It overrides `==` because the framework uses it to decide
/// whether text widgets rebuild when the scaler changes — without it every
/// rebuild of the app root would re-lay-out every piece of text in the tree.
@immutable
class ComposedTextScaler extends TextScaler {
  const ComposedTextScaler(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  /// Derived from [scale] rather than from `base.textScaleFactor`, which is
  /// deprecated — and which the framework's own docs call only an estimate
  /// once a scaler is non-linear. 14 is Material's reference body size.
  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComposedTextScaler &&
          other.base == base &&
          other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}
