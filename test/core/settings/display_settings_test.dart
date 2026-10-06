/// Text size, weight, and contrast have to persist as absence when they are
/// the default, and a weight step has to move every style rather than flatten
/// them. Writing the default token would make "normal" look like a choice the
/// user made, and a scaler that does not compare equal re-lays-out the tree
/// on every frame.
library;

import 'package:dpip/core/settings/display_settings.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'defaults are stored as absence and a repeat write does nothing',
    () async {
      final settings = SettingsStore.inMemory();
      final display = DisplaySettings(settings);
      var notices = 0;
      display.addListener(() => notices++);

      expect(display.textScale, TextScaleStep.normal);
      expect(display.textWeight, TextWeightStep.normal);
      expect(display.contrast, ContrastStep.standard);

      await display.setTextScale(TextScaleStep.large);
      await display.setTextWeight(TextWeightStep.bold);
      await display.setContrast(ContrastStep.high);
      expect(settings.getString(SettingKeys.textScale), 'large');
      expect(settings.getString(SettingKeys.textWeight), 'bold');
      expect(settings.getString(SettingKeys.contrast), 'high');
      expect(display.textScale.factor, 1.2);
      expect(display.textWeight.steps, 2);
      expect(display.contrast.level, 1);

      final after = notices;
      await display.setTextScale(TextScaleStep.large);
      expect(notices, after);

      await display.setTextScale(TextScaleStep.normal);
      await display.setTextWeight(TextWeightStep.normal);
      await display.setContrast(ContrastStep.standard);
      expect(settings.getString(SettingKeys.textScale), isNull);
      expect(settings.getString(SettingKeys.textWeight), isNull);
      expect(settings.getString(SettingKeys.contrast), isNull);
    },
  );

  test(
    'weight climbs the ladder and the composed scaler compares by value',
    () {
      expect(TextScaleStep.fromToken('nope'), TextScaleStep.normal);
      expect(TextWeightStep.fromToken('medium').token, 'medium');
      expect(ContrastStep.fromToken(null), ContrastStep.standard);

      final themed = applyTextWeight(
        const TextTheme(
          bodyMedium: TextStyle(fontWeight: FontWeight.w400),
          titleLarge: TextStyle(),
        ),
        TextWeightStep.medium,
      );
      expect(themed.bodyMedium!.fontWeight, FontWeight.w500);
      expect(themed.titleLarge!.fontWeight, isNot(FontWeight.w400));
      expect(
        applyTextWeight(const TextTheme(), TextWeightStep.normal),
        const TextTheme(),
      );

      const base = TextScaler.linear(2);
      const scaler = ComposedTextScaler(base, 1.2);
      expect(scaler.scale(10), 24);
      expect(scaler.textScaleFactor, closeTo(2.4, 0.001));
      expect(scaler, const ComposedTextScaler(TextScaler.linear(2), 1.2));
      expect(scaler.hashCode, const ComposedTextScaler(base, 1.2).hashCode);
      expect(scaler == base, isFalse);
    },
  );
}
