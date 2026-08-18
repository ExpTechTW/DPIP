import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/foundation.dart';

/// Whether the EEW (Earthquake Early Warning) feeds are filtered down to
/// 中央氣象署 (CWA) alerts only, persisted via [SettingsStore]. **On** by
/// default, matching the legacy app's default — every other agency is opt-in
/// (the "所有來源" row on `EewSourcePage`), not the other way around.
///
/// Read by the EEW data sources ([EewRealtimeSource], [EewReplaySource],
/// [EewRepositoryImpl]) as a plain closure (`() => settings.enabled`), not by
/// holding this object directly — they live in `data/`, and a closure keeps
/// them from depending on the settings layer's full API.
class EewCwaOnlySettings extends ChangeNotifier {
  EewCwaOnlySettings(this._settings);

  final SettingsStore _settings;

  /// Whether only CWA-published alerts should reach the app's EEW feeds.
  bool get enabled => _settings.getBool(SettingKeys.eewCwaOnly) ?? true;

  Future<void> setEnabled(bool value) async {
    await _settings.setBool(SettingKeys.eewCwaOnly, value);
    notifyListeners();
  }
}
