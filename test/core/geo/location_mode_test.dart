import 'package:dpip/core/geo/location_mode.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

TownDirectory _dir() => TownDirectory.fromJson({
  '100': {
    'city': '臺北',
    'town': '中正',
    'lat': 25.03,
    'lng': 121.52,
    'cityLevel': '市',
    'townLevel': '區',
  },
  '970': {
    'city': '花蓮',
    'town': '花蓮',
    'lat': 23.99,
    'lng': 121.60,
    'cityLevel': '縣',
    'townLevel': '市',
  },
});

/// The location source survives a relaunch: a township set by hand is the one
/// every alert follows, so it must not quietly fall back to the GPS — nor stay
/// pinned once the user switched back.
void main() {
  test(
    'starts automatic, pins a township, and keeps it across launches',
    () async {
      final settings = SettingsStore.inMemory({});
      final mode = LocationMode(settings, _dir());
      expect(mode.isManual, isFalse);
      var notified = 0;
      mode.addListener(() => notified++);

      await mode.setManual(_dir().byCode('970')!);
      expect(mode.manualTown?.code, '970');
      expect(notified, 1);

      // The same township again is no change.
      await mode.setManual(_dir().byCode('970')!);
      expect(notified, 1);
      expect(LocationMode(settings, _dir()).manualTown?.code, '970');

      await mode.setAuto();
      expect(mode.isManual, isFalse);
      expect(notified, 2);
      expect(LocationMode(settings, _dir()).isManual, isFalse);
    },
  );

  test('a pinned township the directory no longer knows falls back to GPS', () {
    final settings = SettingsStore.inMemory({
      SettingKeys.manualLocationTown.name: '999',
    });
    expect(LocationMode(settings, _dir()).isManual, isFalse);
  });

  group('the More page warning', () {
    late DateTime now;
    late SettingsStore settings;
    LocationMode mode() => LocationMode(settings, _dir(), now: () => now);

    setUp(() {
      now = DateTime.utc(2026, 11, 28, 12);
      settings = SettingsStore.inMemory({});
    });

    test('shows only while the location is set by hand', () async {
      final m = mode();
      expect(m.showsWarning, isFalse);
      await m.setManual(_dir().byCode('970')!);
      expect(m.showsWarning, isTrue);
    });

    test('a dismissal hides it for seven days, then it comes back', () async {
      final m = mode();
      await m.setManual(_dir().byCode('970')!);
      var notified = 0;
      m.addListener(() => notified++);

      await m.dismissWarning();
      expect(m.showsWarning, isFalse);
      expect(notified, 1);

      now = now.add(const Duration(days: 6, hours: 23));
      expect(m.showsWarning, isFalse);
      now = now.add(const Duration(hours: 1));
      expect(m.showsWarning, isTrue, reason: 'seven days have passed');
      // And across a relaunch.
      expect(mode().showsWarning, isTrue);
    });

    test('a dismissal survives a relaunch inside the seven days', () async {
      final m = mode();
      await m.setManual(_dir().byCode('970')!);
      await m.dismissWarning();
      now = now.add(const Duration(days: 1));
      expect(mode().showsWarning, isFalse);
    });

    test('a dismissal stamped ahead of the clock is ignored', () async {
      final m = mode();
      await m.setManual(_dir().byCode('970')!);
      await m.dismissWarning();
      // The clock was set back after the dismissal.
      now = now.subtract(const Duration(days: 1));
      expect(m.showsWarning, isTrue);
    });

    test('setting it by hand again after automatic shows it again', () async {
      final m = mode();
      await m.setManual(_dir().byCode('970')!);
      await m.dismissWarning();
      await m.setAuto();
      await m.setManual(_dir().byCode('970')!);
      expect(m.showsWarning, isTrue);
    });

    test('changing the township while manual keeps the dismissal', () async {
      final m = mode();
      await m.setManual(_dir().byCode('970')!);
      await m.dismissWarning();
      await m.setManual(_dir().byCode('100')!);
      expect(m.showsWarning, isFalse);
    });
  });
}
