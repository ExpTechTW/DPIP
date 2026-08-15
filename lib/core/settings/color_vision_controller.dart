/// The app's colour-vision correction setting.
library;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/foundation.dart';

/// Holds the chosen [ColorVision], persisted across launches, and publishes it
/// to [AppColorVision] so the colours that have no `BuildContext` — map layer
/// paint, intensity tables — can read it too.
///
/// [ColorVision.none] is stored as absence, so the default is a missing key
/// rather than a magic string.
class ColorVisionController extends ChangeNotifier {
  ColorVisionController(this._settings) {
    // Install before the first frame so nothing paints in the wrong colours and
    // then corrects itself.
    AppColorVision.install(vision);
  }

  final SettingsStore _settings;

  ColorVision get vision =>
      ColorVision.fromToken(_settings.getString(SettingKeys.colorVision));

  Future<void> set(ColorVision next) async {
    if (next == vision) return;
    AppColorVision.install(next);
    if (next == ColorVision.none) {
      await _settings.remove(SettingKeys.colorVision);
    } else {
      await _settings.setString(SettingKeys.colorVision, next.token);
    }
    notifyListeners();
  }
}
