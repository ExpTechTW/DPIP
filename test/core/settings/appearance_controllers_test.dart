import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/settings/color_vision_controller.dart';
import 'package:dpip/core/settings/default_map_layer.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('theme follows the system until light or dark is chosen', () async {
    final settings = SettingsStore.inMemory();
    final theme = ThemeController(settings);
    expect(theme.mode, ThemeMode.system);

    var notified = 0;
    theme.addListener(() => notified++);
    await theme.setMode(ThemeMode.light);
    expect(theme.mode, ThemeMode.light);
    await theme.setMode(ThemeMode.dark);
    expect(settings.getString(SettingKeys.themeMode), 'dark');
    await theme.setMode(ThemeMode.system);
    expect(settings.getString(SettingKeys.themeMode), isNull);
    expect(notified, 3);

    await theme.setMode(ThemeMode.system);
    expect(notified, 3);
  });

  test('colour vision clears the key when set back to none', () async {
    final settings = SettingsStore.inMemory();
    final vision = ColorVisionController(settings);
    expect(vision.vision, ColorVision.none);

    await vision.set(ColorVision.deutan);
    expect(settings.getString(SettingKeys.colorVision), 'deutan');
    await vision.set(ColorVision.none);
    expect(settings.getString(SettingKeys.colorVision), isNull);
    await vision.set(ColorVision.none);
  });

  test('the default map layer notifies only when it changes', () {
    final map = DefaultMapLayerController(SettingsStore.inMemory());
    expect(map.layer, DefaultMapLayer.radar);
    var notified = 0;
    map.addListener(() => notified++);
    map.setLayer(DefaultMapLayer.monitor);
    map.setLayer(DefaultMapLayer.monitor);
    expect(map.layer, DefaultMapLayer.monitor);
    expect(notified, 1);
  });
}
