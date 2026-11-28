import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dpip/core/notifications/live_activity_registration.dart';
import 'package:dpip/core/platform/live_activity_tokens.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Sent = ({String token, String pushToStart, bool enabled});

DioException _status(int code) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response<void>(
    requestOptions: RequestOptions(path: '/'),
    statusCode: code,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsStore settings;
  late String? token;
  late bool registered;
  late StreamController<LiveActivityState> states;
  late List<_Sent> sent;
  late List<Object> failures;
  late DateTime now;
  late LiveActivityRegistration registration;

  setUp(() {
    settings = SettingsStore.inMemory();
    token = 'push-token-a';
    registered = true;
    states = StreamController<LiveActivityState>();
    sent = [];
    failures = [];
    now = DateTime.utc(2026, 11, 28, 12);
    registration = LiveActivityRegistration(
      settings: settings,
      token: () => token,
      registered: () => registered,
      states: states.stream,
      report: (t, p, e) async {
        sent.add((token: t, pushToStart: p, enabled: e));
        if (failures.isNotEmpty) throw failures.removeAt(0);
      },
      now: () => now,
    );
  });

  tearDown(() {
    registration.dispose();
    // Not awaited: a single-subscription controller nobody listened to never
    // completes its close.
    unawaited(states.close());
  });

  /// Emits a platform state and lets the report it triggers finish.
  Future<void> emit(String? pushToStart, {bool enabled = true}) async {
    states.add((token: pushToStart, enabled: enabled));
    await pumpEventQueue();
  }

  test('nothing is reported before start', () async {
    await registration.ensure('launch');
    expect(sent, isEmpty);
  });

  test('the first state with a token is reported once', () async {
    registration.start();
    await emit('aa');
    expect(sent, [(token: 'push-token-a', pushToStart: 'aa', enabled: true)]);

    await registration.ensure('resume');
    await emit('aa');
    expect(sent, hasLength(1));
  });

  test(
    'no push-to-start token yet, or no push token, reports nothing',
    () async {
      registration.start();
      await emit(null);
      expect(sent, isEmpty);

      token = null;
      await emit('aa');
      expect(sent, isEmpty);

      token = 'push-token-a';
      await registration.ensure('push token changed');
      expect(sent, hasLength(1));
    },
  );

  test('a change of any part is reported at once', () async {
    registration.start();
    await emit('aa');
    await emit('aa', enabled: false);
    await emit('bb', enabled: false);
    token = 'push-token-b';
    await registration.ensure('push token changed');
    expect(sent, [
      (token: 'push-token-a', pushToStart: 'aa', enabled: true),
      (token: 'push-token-a', pushToStart: 'aa', enabled: false),
      (token: 'push-token-a', pushToStart: 'bb', enabled: false),
      (token: 'push-token-b', pushToStart: 'bb', enabled: false),
    ]);
  });

  test('an unchanged report is repeated after maxAge, not before', () async {
    registration.start();
    await emit('aa');
    now = now.add(const Duration(hours: 5, minutes: 59));
    await registration.ensure('resume');
    expect(sent, hasLength(1));

    now = now.add(const Duration(minutes: 1));
    await registration.ensure('resume');
    expect(sent, hasLength(2));
  });

  test('neither token is stored, only a hash', () async {
    registration.start();
    await emit('aa');
    final stored = settings.getString(SettingKeys.liveActivityReportedHash);
    expect(stored, isNotNull);
    expect(stored, isNot(contains('aa')));
    expect(stored, isNot(contains('push-token-a')));
  });

  test('401 is not remembered: the next trigger reports again', () async {
    failures.add(_status(401));
    registration.start();
    await emit('aa');
    expect(sent, hasLength(1));

    await registration.ensure('device registered');
    expect(sent, hasLength(2));
    await registration.ensure('resume');
    expect(sent, hasLength(2));
  });

  test(
    'a final 4xx is remembered and not re-sent until something changes',
    () async {
      failures.add(_status(400));
      registration.start();
      await emit('aa');
      await registration.ensure('resume');
      expect(sent, hasLength(1));

      await emit('bb');
      expect(sent, hasLength(2));
    },
  );

  test('a failure stays pending: retried with backoff until a 2xx', () {
    fakeAsync((async) {
      failures.addAll([_status(503), _status(429)]);
      registration.start();
      states.add((token: 'aa', enabled: true));
      async.flushMicrotasks();
      expect(sent, hasLength(1));
      expect(settings.getString(SettingKeys.liveActivityReportedHash), isNull);

      async.elapse(const Duration(minutes: 4, seconds: 59));
      expect(sent, hasLength(1));
      async.elapse(const Duration(seconds: 1));
      expect(sent, hasLength(2));

      // The second failure in a row doubles the wait.
      async.elapse(const Duration(minutes: 9, seconds: 59));
      expect(sent, hasLength(2));
      async.elapse(const Duration(seconds: 1));
      expect(sent, hasLength(3));
      expect(
        settings.getString(SettingKeys.liveActivityReportedHash),
        isNotNull,
      );

      // Answered: nothing more until something changes.
      async.elapse(const Duration(hours: 1));
      expect(sent, hasLength(3));
    });
  });

  test('a failure stays pending for the next trigger too', () async {
    failures.add(_status(503));
    registration.start();
    await emit('aa');
    expect(sent, hasLength(1));

    await registration.ensure('resume');
    expect(sent, hasLength(2));
    await registration.ensure('resume');
    expect(sent, hasLength(2));
  });

  test('the retry goes through ensure: a trigger during it is folded in', () {
    // The retry used to call the pass directly, beside one a trigger had
    // started, and both sent.
    fakeAsync((async) {
      final gate = Completer<void>();
      var calls = 0;
      final slow = LiveActivityRegistration(
        settings: SettingsStore.inMemory(),
        token: () => 'push-token-a',
        registered: () => true,
        states: states.stream,
        report: (t, p, e) async {
          calls++;
          if (calls == 1) throw _status(503);
          if (calls == 2) await gate.future;
        },
        now: () => now,
      )..start();
      states.add((token: 'aa', enabled: true));
      async.flushMicrotasks();
      expect(calls, 1);

      async.elapse(const Duration(minutes: 5));
      expect(calls, 2);
      slow.ensure('resume');
      async.flushMicrotasks();
      gate.complete();
      async.flushMicrotasks();
      async.elapse(const Duration(hours: 1));
      expect(calls, 2);
      slow.dispose();
    });
  });

  test('nothing is sent before the device is registered', () async {
    registered = false;
    registration.start();
    await emit('aa');
    await registration.ensure('resume');
    expect(sent, isEmpty);

    // The location report that registers it triggers another pass.
    registered = true;
    await registration.ensure('device registered');
    expect(sent, [(token: 'push-token-a', pushToStart: 'aa', enabled: true)]);
  });

  test('pending after a change or six hours; only a 2xx clears it', () async {
    registration.start();
    await emit('aa');
    expect(sent, hasLength(1));

    // A changed switch is pending; a failure leaves it so.
    failures.add(_status(500));
    await emit('aa', enabled: false);
    await registration.ensure('resume');
    expect(sent, hasLength(3));
    await registration.ensure('resume');
    expect(sent, hasLength(3));

    // Six hours after the last 2xx, the same triple is pending again.
    now = now.add(const Duration(hours: 6));
    await registration.ensure('resume');
    expect(sent, hasLength(4));
    expect(sent.last.enabled, isFalse);
  });

  test('a state that arrives mid-report is reported right after it', () async {
    final gate = Completer<void>();
    final calls = <String>[];
    final slow = LiveActivityRegistration(
      settings: SettingsStore.inMemory(),
      token: () => 'push-token-a',
      registered: () => true,
      states: states.stream,
      report: (t, p, e) async {
        calls.add(p);
        if (calls.length == 1) await gate.future;
      },
      now: () => now,
    )..start();
    states.add((token: 'aa', enabled: true));
    await pumpEventQueue();
    states.add((token: 'bb', enabled: true));
    await pumpEventQueue();
    expect(calls, ['aa']);

    gate.complete();
    await pumpEventQueue();
    expect(calls, ['aa', 'bb']);
    slow.dispose();
  });
}
