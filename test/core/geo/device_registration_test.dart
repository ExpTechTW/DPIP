import 'dart:async';

import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/device_registration.dart';
import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:dpip/core/network/notify_request_lane.dart';
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
  late ReportOutcome? pendingOutcome;
  late int resent;
  late NotifyRequestLane lane;
  late DeviceRegistration registration;

  setUp(() {
    settings = SettingsStore.inMemory();
    token = 'token-a';
    fix = (lat: 25.03, lng: 121.56);
    reported = [];
    outcomes = [];
    now = DateTime.utc(2026, 10, 16, 12);
    nativeSuccess = null;
    pendingOutcome = null;
    resent = 0;
    lane = NotifyRequestLane(spacing: Duration.zero);
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
      // Plays the reporter's pending fix: null is "nothing pending".
      resend: () async {
        final outcome = pendingOutcome;
        if (outcome == null) return null;
        resent++;
        pendingOutcome = null;
        if (outcome == ReportOutcome.sent) await registration.recordSuccess();
        return outcome;
      },
      lane: lane,
      nativeLastSuccess: () async => nativeSuccess,
      now: () => now,
    );
  });

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

  test('a pending location report goes first, and its 2xx registers', () async {
    pendingOutcome = ReportOutcome.sent;
    await registration.ensure('resume');
    expect(resent, 1);
    // The token is now registered: no second report.
    expect(reported, isEmpty);
    expect(settings.getString(SettingKeys.registeredTokenHash), isNotNull);
  });

  test('a pending report still waiting is left to the reporter', () async {
    for (final waiting in [
      ReportOutcome.throttled,
      ReportOutcome.failed,
      ReportOutcome.noToken,
    ]) {
      pendingOutcome = waiting;
      await registration.ensure('resume');
      expect(reported, isEmpty, reason: waiting.name);
    }
  });

  test('a failed report schedules nothing of its own', () {
    // Retrying is the reporter's: the fix stays pending there.
    fakeAsync((async) {
      outcomes = [ReportOutcome.failed, ReportOutcome.throttled];
      registration.ensure('launch');
      async.flushMicrotasks();
      expect(reported, hasLength(1));

      async.elapse(const Duration(hours: 1));
      expect(reported, hasLength(1));
      expect(settings.getString(SettingKeys.registeredTokenHash), isNull);
    });
  });

  test(
    'registered: only for the token stored now, and only after a 2xx',
    () async {
      expect(registration.registered, isFalse);
      outcomes = [ReportOutcome.failed];
      await registration.ensure('launch');
      expect(registration.registered, isFalse);

      await registration.ensure('resume');
      expect(registration.registered, isTrue);
      token = 'token-b';
      expect(registration.registered, isFalse);
      token = null;
      expect(registration.registered, isFalse);
    },
  );

  test('deferred requests wait until the check is done', () async {
    final fixReady = Completer<GpsFix?>();
    final order = <String>[];
    final slow = DeviceRegistration(
      settings: settings,
      token: () => token,
      fix: () => fixReady.future,
      report: (f) => lane.run(() async {
        order.add('location');
        return ReportOutcome.sent;
      }),
      resend: () async => null,
      lane: lane,
      now: () => now,
    );

    final check = slow.ensure('resume');
    // Queued while the check still waits for its fix, on an idle lane.
    final liveActivity = lane.run(
      () async => order.add('live activity'),
      priority: NotifyRequestPriority.deferred,
    );
    await pumpEventQueue();
    expect(order, isEmpty);

    fixReady.complete((lat: 25.03, lng: 121.56));
    await check;
    await liveActivity;
    expect(order, ['location', 'live activity']);
  });
}
