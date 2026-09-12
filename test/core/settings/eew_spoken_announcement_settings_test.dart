/// The monitor's spoken-announcement switch.
///
/// The default is the whole point of these tests: speech delays the warning
/// sound by however long the phrase takes, so it has to be something the user
/// asked for. A default that silently drifted to on would push that trade onto
/// everyone.
library;

import 'package:dpip/core/settings/eew_spoken_announcement_settings.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to off when nothing was ever saved', () {
    final settings = EewSpokenAnnouncementSettings(SettingsStore.inMemory());
    expect(settings.enabled, isFalse);
  });

  test('reads back what was saved, in both directions', () async {
    final store = SettingsStore.inMemory();
    final settings = EewSpokenAnnouncementSettings(store);

    await settings.setEnabled(true);
    expect(settings.enabled, isTrue);
    expect(store.getBool(SettingKeys.eewSpokenAnnouncement), isTrue);

    await settings.setEnabled(false);
    expect(settings.enabled, isFalse);
  });

  test('a saved value survives a new instance over the same store', () async {
    final store = SettingsStore.inMemory();
    await EewSpokenAnnouncementSettings(store).setEnabled(true);
    expect(EewSpokenAnnouncementSettings(store).enabled, isTrue);
  });

  test('notifies listeners so the monitor re-reads it mid-alert', () async {
    final settings = EewSpokenAnnouncementSettings(SettingsStore.inMemory());
    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.setEnabled(false);
    await settings.setEnabled(true);

    expect(notifications, 2);
  });
}
