/// Where the app takes the user's location from: the device (GPS), or one
/// township the user pinned by hand.
library;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/foundation.dart';

/// The location source the user chose: automatic (the device's GPS, the
/// default) or manual (one township, fixed).
///
/// Manual is an escape hatch, not a preference. The server targets every alert
/// at this device — earthquake early warnings included — by the location the
/// app reports, so a pinned township that is not where the user is means
/// missing the alerts meant for where they are. The settings page warns
/// accordingly; this class only holds the choice.
///
/// While manual, nothing in the app reads the GPS: `LocationService` answers
/// with the pinned township, background reporting is stopped, and maps draw no
/// device location.
class LocationMode extends ChangeNotifier {
  /// [now] reads the clock the warning's dismissal is stamped and aged by;
  /// tests pass their own.
  LocationMode(this._settings, this._directory, {DateTime Function()? now})
    : _now = now ?? _deviceNow {
    final stored = _settings.getString(SettingKeys.manualLocationTown);
    _manual = _directory.byCode(stored);
    // A code this directory no longer knows (a township merged away) cannot be
    // reported; falling back to the device is the safe reading of it.
    if (stored != null && _manual == null) {
      Log.warning('location mode: unknown pinned township $stored — using GPS');
    }
  }

  final SettingsStore _settings;
  final TownDirectory _directory;
  final DateTime Function() _now;
  Town? _manual;

  // wall-clock: the dismissal is stamped and aged by this same clock and never
  // compared with a server or radio time, so the device's offset cancels out.
  static DateTime _deviceNow() => DateTime.now();

  /// How long a dismissed warning stays hidden before it is shown again.
  static const Duration warningSnooze = Duration(days: 7);

  /// The pinned township; null while the location comes from the device.
  Town? get manualTown => _manual;

  /// Whether the location is pinned by hand.
  bool get isManual => _manual != null;

  /// Whether the More page shows its warning that the location is set by
  /// hand: while manual, unless dismissed less than [warningSnooze] ago.
  ///
  /// A township set by hand silently decides every alert this device gets, so
  /// a dismissal only quiets the reminder for a while rather than for good. A
  /// dismissal stamped in the future (the clock was set back) is ignored.
  bool get showsWarning {
    if (_manual == null) return false;
    final dismissed = _settings.getInt(
      SettingKeys.manualLocationWarningDismissedAtMs,
    );
    if (dismissed == null) return true;
    final age = _now().difference(
      DateTime.fromMillisecondsSinceEpoch(dismissed),
    );
    return age.isNegative || age >= warningSnooze;
  }

  /// Hides the More page's warning for [warningSnooze].
  Future<void> dismissWarning() async {
    await _settings.setInt(
      SettingKeys.manualLocationWarningDismissedAtMs,
      _now().millisecondsSinceEpoch,
    );
    Log.info('location mode: warning dismissed for ${warningSnooze.inDays} d');
    notifyListeners();
  }

  /// Pins [town] as the user's location, replacing any earlier one.
  ///
  /// Coming from automatic, the More page's warning shows again even if it was
  /// dismissed during an earlier stretch of manual.
  Future<void> setManual(Town town) async {
    if (_manual?.code == town.code) return;
    if (_manual == null) {
      await _settings.remove(SettingKeys.manualLocationWarningDismissedAtMs);
    }
    _manual = _directory.byCode(town.code) ?? town;
    await _settings.setString(SettingKeys.manualLocationTown, town.code);
    Log.info('location mode: manual (${town.code} ${town.fullName})');
    notifyListeners();
  }

  /// Returns to the device's location (GPS).
  Future<void> setAuto() async {
    if (_manual == null) return;
    _manual = null;
    await _settings.remove(SettingKeys.manualLocationTown);
    Log.info('location mode: automatic (GPS)');
    notifyListeners();
  }
}
