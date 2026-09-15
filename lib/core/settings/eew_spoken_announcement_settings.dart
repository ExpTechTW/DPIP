import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/foundation.dart';

/// Whether the seismic monitor speaks the estimated intensity before the EEW
/// warning sound plays, persisted via [SettingsStore]. **Off** by default:
/// speech is an accessibility aid, and one that delays the warning sound by as
/// long as the phrase takes — nobody should be given that trade without asking
/// for it.
///
/// Turning it off never delays a warning. The monitor drops its announcement
/// controller to inactive, which releases anything the foreground gate is
/// holding, so the channel's own sound plays exactly as it did before this
/// feature existed.
class EewSpokenAnnouncementSettings extends ChangeNotifier {
  EewSpokenAnnouncementSettings(this._settings);

  final SettingsStore _settings;

  /// Whether the monitor — live or replay — may speak.
  bool get enabled =>
      _settings.getBool(SettingKeys.eewSpokenAnnouncement) ?? false;

  Future<void> setEnabled(bool value) async {
    await _settings.setBool(SettingKeys.eewSpokenAnnouncement, value);
    notifyListeners();
  }
}
