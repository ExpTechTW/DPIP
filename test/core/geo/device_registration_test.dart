import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/device_registration.dart';
import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsStore settings;
  late String? token;
  late GpsFix? fix;
  late List<GpsFix> reported;
  late List<ReportOutcome> outcomes;
  late DateTime now;
  late DateTime? nativeSuccess;
  late DeviceRegistration registration;

  setUp(() {
    settings = SettingsStore.inMemory();
    token = 'token-a';
    fix = (lat: 25.03, lng: 121.56);
    reported = [];
    outcomes = [];
    now = DateTime.utc(2026, 10, 16, 12);
    nativeSuccess = null;
    registration = DeviceRegistration(
      settings: settings,
      token: () => token,
      fix: () async => fix,
      // Plays the reporter: a `sent` is a 2xx, which calls the success hook.
      report: (f) async {
        reported.add(f);
        final outcome = outcomes.isEmpty
            ? ReportOutcome.sent
            : outcomes.removeAt(0);
        if (outcome == ReportOutcome.sent) await registration.recordSuccess();
        return outcome;
      },
      nativeLastSuccess: () async => nativeSuccess,
      now: () => now,
    );
  });

  tearDown(() => registration.dispose());

  test('an unregistered token is reported once', () async {
    await registration.ensure('launch');
    expect(reported, [(lat: 25.03, lng: 121.56)]);

    await registration.ensure('resume');
    expect(reported, hasLength(1));
  });

  test('a changed token is reported even when nothing moved', () async {
    await registration.ensure('launch');
    token = 'token-b';
    await registration.ensure('push token changed');
    expect(reported, hasLength(2));
  });

  test('the token itself is never stored, only its hash', () async {
    await registration.ensure('launch');
    final stored = settings.getString(SettingKeys.registeredTokenHash);
    expect(stored, isNotNull);
    expect(stored, isNot(contains('token-a')));
  });

  test('a day without a successful report is reported again', () async {
    await registration.ensure('launch');
    now = now.add(const Duration(hours: 23));
    await registration.ensure('resume');
    expect(reported, hasLength(1));

    now = now.add(const Duration(hours: 2));
    await registration.ensure('resume');
    expect(reported, hasLength(2));
  });

  test('a recent native background report counts', () async {
    await registration.ensure('launch');
    now = now.add(const Duration(hours: 30));
    nativeSuccess = now.subtract(const Duration(hours: 1));
    await registration.ensure('resume');
    expect(reported, hasLength(1));
  });

  test('a report stamped in the future does not hold forever', () async {
    await registration.ensure('launch');
    now = now.subtract(const Duration(hours: 5));
    await registration.ensure('resume');
    expect(reported, hasLength(2));
  });

  test('nothing is sent without a token or a position', () async {
    token = null;
    await registration.ensure('launch');
    token = 'token-a';
    fix = null;
    await registration.ensure('launch');
    expect(reported, isEmpty);
    expect(settings.getString(SettingKeys.registeredTokenHash), isNull);
  });

  test('a failed report is not recorded as registered', () async {
    outcomes = [ReportOutcome.rejected];
    await registration.ensure('launch');
    expect(settings.getString(SettingKeys.registeredTokenHash), isNull);

    await registration.ensure('resume');
    expect(reported, hasLength(2));
  });

  test('concurrent triggers share one report', () async {
    await Future.wait([
      registration.ensure('launch'),
      registration.ensure('push token changed'),
    ]);
    expect(reported, hasLength(1));
  });

  test('a throttled report is retried once, after the window', () {
    fakeAsync((async) {
      outcomes = [ReportOutcome.throttled, ReportOutcome.throttled];
      registration.ensure('launch');
      async.flushMicrotasks();
      expect(reported, hasLength(1));

      async.elapse(const Duration(seconds: 61));
      expect(reported, hasLength(2));

      // The retry does not schedule another: the next launch or resume will.
      async.elapse(const Duration(minutes: 10));
      expect(reported, hasLength(2));
    });
  });

  test('a failed report is retried later, and then registers', () {
    fakeAsync((async) {
      outcomes = [ReportOutcome.failed];
      registration.ensure('launch');
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 4));
      expect(reported, hasLength(1));

      async.elapse(const Duration(minutes: 1));
      expect(reported, hasLength(2));
      expect(settings.getString(SettingKeys.registeredTokenHash), isNotNull);
    });
  });

  test('a new trigger replaces a scheduled retry', () {
    fakeAsync((async) {
      outcomes = [ReportOutcome.failed];
      registration.ensure('launch');
      async.flushMicrotasks();
      registration.ensure('resume');
      async.flushMicrotasks();
      expect(reported, hasLength(2));

      async.elapse(const Duration(minutes: 10));
      expect(reported, hasLength(2));
    });
  });
}
