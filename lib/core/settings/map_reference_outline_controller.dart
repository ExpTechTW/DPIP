/// Persisted, shared state for a raster layer's reference chrome — the
/// admin-border outlines (國界 / 縣市 / 鄉鎮) and the scan-range coverage
/// outline every weather raster can redraw over itself.
library;

import 'dart:async';

import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/foundation.dart';

/// One shared preference per toggle, used by every raster layer that offers
/// it (radar, QPESUMS, satellite, wind forecast) — see `AdminOutlineChrome`
/// and `ScanRangeOverlayChrome`. A layer instance is rebuilt per map surface,
/// so without one shared, persisted source of truth each rebuild forgot the
/// choice and every layer kept its own copy, out of sync with the others.
///
/// All four ship on: a blank area reads as "not observed", not "no weather",
/// and an unidentified county is one a reader cannot act on.
class MapReferenceOutlineController extends ChangeNotifier {
  MapReferenceOutlineController(this._settings)
    : _global = _settings.getBool(SettingKeys.mapShowGlobalOutline) ?? true,
      _county = _settings.getBool(SettingKeys.mapShowCountyOutline) ?? true,
      _town = _settings.getBool(SettingKeys.mapShowTownOutline) ?? true,
      _scanRange = _settings.getBool(SettingKeys.mapShowScanRange) ?? true;

  final SettingsStore _settings;

  bool _global;
  bool _county;
  bool _town;
  bool _scanRange;

  bool get showGlobalOutline => _global;
  bool get showCountyOutline => _county;
  bool get showTownOutline => _town;
  bool get showScanRange => _scanRange;

  void setShowGlobalOutline(bool value) {
    if (!_changed(_global, value)) return;
    _global = value;
    _persist(SettingKeys.mapShowGlobalOutline, value);
  }

  void setShowCountyOutline(bool value) {
    if (!_changed(_county, value)) return;
    _county = value;
    _persist(SettingKeys.mapShowCountyOutline, value);
  }

  void setShowTownOutline(bool value) {
    if (!_changed(_town, value)) return;
    _town = value;
    _persist(SettingKeys.mapShowTownOutline, value);
  }

  void setShowScanRange(bool value) {
    if (!_changed(_scanRange, value)) return;
    _scanRange = value;
    _persist(SettingKeys.mapShowScanRange, value);
  }

  bool _changed(bool current, bool next) => current != next;

  void _persist(SettingKey<bool> key, bool value) {
    unawaited(_settings.setBool(key, value));
    notifyListeners();
  }
}
