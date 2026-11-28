import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:dpip/core/logging/crash_sink.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsStore> settings([
    Map<String, Object> initial = const {},
  ]) async {
    return SettingsStore.inMemory(initial);
  }

  test('reports each distance-triggered move; skips identical fixes', () async {
    final positions = StreamController<GpsFix>();
    final reported = <GpsFix>[];
    var t = DateTime.utc(2024, 1, 1);
    DeviceLocationReporter(
      positions: () => positions.stream,
      settings: await settings(),
      now: () => t,
      onMoved: (fix) async {
        reported.add(fix);
        return true;
      },
    ).start();

    positions
      ..add((lat: 25.0, lng: 121.0))
      ..add((lat: 25.0, lng: 121.0)) // identical → skipped
      ..add((lat: 25.1, lng: 121.1));
    await pumpEventQueue();
    // The second distinct fix is inside 60 s: it waits, the first went out.
    expect(reported, [(lat: 25.0, lng: 121.0)]);

    t = t.add(const Duration(seconds: 61));
    positions.add((lat: 25.2, lng: 121.2));
    await pumpEventQueue();
    expect(reported, [(lat: 25.0, lng: 121.0), (lat: 25.2, lng: 121.2)]);
    await positions.close();
  });

  test('stop() ends reporting', () async {
    final positions = StreamController<GpsFix>();
    final reported = <GpsFix>[];
    final reporter = DeviceLocationReporter(
      positions: () => positions.stream,
      settings: await settings(),
      onMoved: (fix) async {
        reported.add(fix);
        return true;
      },
    )..start();

    positions.add((lat: 25.0, lng: 121.0));
    await pumpEventQueue();
    reporter.stop();
    positions.add((lat: 26.0, lng: 122.0));
    await pumpEventQueue();

    expect(reported, hasLength(1));
    await positions.close();
  });

  test('a report failure is swallowed and does not stop the stream', () async {
    final positions = StreamController<GpsFix>();
    var calls = 0;
    var t = DateTime.utc(2024, 1, 1);
    DeviceLocationReporter(
      positions: () => positions.stream,
      settings: await settings(),
      now: () => t,
      onMoved: (fix) async {
        calls++;
        throw Exception('network down');
      },
    ).start();

    positions.add((lat: 25.0, lng: 121.0));
    await pumpEventQueue();
    t = t.add(const Duration(seconds: 61));
    positions.add((lat: 25.1, lng: 121.1));
    await pumpEventQueue();

    expect(calls, 2); // kept going after the first failure
    await positions.close();
  });

  test('a move inside the 60 s window waits for its end', () {
    fakeAsync((async) {
      final stamped = DateTime.utc(2024, 1, 1).millisecondsSinceEpoch;
      final p = SettingsStore.inMemory({
        SettingKeys.deviceLocationUpdatedAtMs.name: stamped,
      });
      final positions = StreamController<GpsFix>();
      final reported = <GpsFix>[];
      final reporter = DeviceLocationReporter(
        positions: () => positions.stream,
        settings: p,
        // 30 s into the window the stamp opened.
        now: () => DateTime.utc(2024, 1, 1, 0, 0, 30).add(async.elapsed),
        onMoved: (fix) async {
          reported.add(fix);
          return true;
        },
      )..start();

      positions.add((lat: 25.0, lng: 121.0));
      async.flushMicrotasks();
      expect(reported, isEmpty);

      async.elapse(const Duration(seconds: 29));
      expect(reported, isEmpty);
      async.elapse(const Duration(seconds: 1));
      expect(reported, [(lat: 25.0, lng: 121.0)]);
      reporter.dispose();
    });
  });

  test('recovers via restart() after the position stream errors', () async {
    // A fresh controller per subscription — the factory models geolocator
    // handing back a new stream when services come back.
    final controllers = <StreamController<GpsFix>>[];
    final reported = <GpsFix>[];
    final reporter = DeviceLocationReporter(
      positions: () {
        final controller = StreamController<GpsFix>();
        controllers.add(controller);
        return controller.stream;
      },
      settings: await settings(),
      onMoved: (fix) async {
        reported.add(fix);
        return true;
      },
    )..start();

    // Services off → the stream errors and the subscription is dropped.
    controllers[0].addError(Exception('LocationServiceDisabled'));
    await pumpEventQueue();

    // Services back → restart re-subscribes with a fresh stream and reporting
    // resumes (the old code held a dead subscription and stayed dead).
    reporter.restart();
    controllers[1].add((lat: 25.0, lng: 121.0));
    await pumpEventQueue();

    expect(reported, [(lat: 25.0, lng: 121.0)]);
    reporter.stop();
    for (final c in controllers) {
      await c.close();
    }
  });

  test('a location refusal ends the stream without a crash report', () async {
    final sink = _Sink();
    Log.crashSink = sink;
    addTearDown(() => Log.crashSink = null);
    final controllers = <StreamController<GpsFix>>[];
    final reporter = DeviceLocationReporter(
      positions: () {
        final controller = StreamController<GpsFix>();
        controllers.add(controller);
        return controller.stream;
      },
      settings: await settings(),
      onMoved: (fix) async => true,
    )..start();

    controllers[0].addError(const LocationServiceDisabledException());
    await pumpEventQueue();
    expect(sink.handled, isEmpty);

    reporter.restart();
    controllers[1].addError(StateError('gps'));
    await pumpEventQueue();
    expect(sink.handled.single, isA<StateError>());

    reporter.stop();
    for (final c in controllers) {
      await c.close();
    }
  });

  test('shares accepted fixes on [fixes] for the township tracker', () async {
    final positions = StreamController<GpsFix>();
    final reporter = DeviceLocationReporter(
      positions: () => positions.stream,
      settings: await settings(),
      onMoved: (fix) async => true,
    );
    final seen = <GpsFix>[];
    reporter.fixes.listen(seen.add);
    reporter.start();

    positions
      ..add((lat: 25.0, lng: 121.0))
      ..add((lat: 25.0, lng: 121.0)) // identical → skipped, as for reporting
      ..add((lat: 24.1, lng: 120.6));
    await pumpEventQueue();

    // Throttle skips second API but both distinct fixes still publish.
    expect(seen, [(lat: 25.0, lng: 121.0), (lat: 24.1, lng: 120.6)]);
    await positions.close();
  });

  test('a fix is shared even when the server report throws', () async {
    // The current township must still follow the user when the upload fails or
    // is skipped (e.g. no push token yet).
    final positions = StreamController<GpsFix>();
    final reporter = DeviceLocationReporter(
      positions: () => positions.stream,
      settings: await settings(),
      onMoved: (fix) async => throw StateError('no token'),
    );
    final seen = <GpsFix>[];
    reporter.fixes.listen(seen.add);
    reporter.start();

    positions.add((lat: 23.5, lng: 120.4));
    await pumpEventQueue();

    expect(seen, [(lat: 23.5, lng: 120.4)]);
    await positions.close();
  });

  test('a fix is shared even when upload is throttled', () async {
    final stamped = DateTime.utc(2024, 1, 1).millisecondsSinceEpoch;
    final positions = StreamController<GpsFix>();
    final reporter = DeviceLocationReporter(
      positions: () => positions.stream,
      settings: await settings({
        SettingKeys.deviceLocationUpdatedAtMs.name: stamped,
      }),
      now: () => DateTime.utc(2024, 1, 1, 0, 0, 10),
      onMoved: (fix) async {
        fail('should not upload');
      },
    );
    final seen = <GpsFix>[];
    reporter.fixes.listen(seen.add);
    reporter.start();

    positions.add((lat: 23.5, lng: 120.4));
    await pumpEventQueue();

    expect(seen, [(lat: 23.5, lng: 120.4)]);
    await positions.close();
  });

  group('reportNow', () {
    DioException http(int status) => DioException(
      requestOptions: RequestOptions(path: '/v2/location'),
      response: Response<void>(
        requestOptions: RequestOptions(path: '/v2/location'),
        statusCode: status,
      ),
      type: DioExceptionType.badResponse,
    );

    test('says what happened, and only a 2xx counts as reported', () async {
      var t = DateTime.utc(2024, 1, 1);
      Object? failure;
      var token = true;
      // Every 2xx is handed on with the fix it sent — the native report
      // heartbeat resends exactly that point.
      final reported = <GpsFix>[];
      final reporter = DeviceLocationReporter(
        positions: () => const Stream.empty(),
        settings: await settings(),
        now: () => t,
        onReported: (sent) async => reported.add(sent),
        onMoved: (fix) async {
          final error = failure;
          if (error != null) throw error;
          return token;
        },
      );
      const fix = (lat: 25.0, lng: 121.0);
      Future<ReportOutcome> next() {
        t = t.add(const Duration(minutes: 2));
        return reporter.reportNow(fix);
      }

      expect(await reporter.reportNow(fix), ReportOutcome.sent);
      expect(reported, [fix]);
      expect(await reporter.reportNow(fix), ReportOutcome.throttled);

      token = false;
      expect(await next(), ReportOutcome.noToken);
      token = true;

      for (final (status, outcome) in [
        (400, ReportOutcome.rejected),
        (404, ReportOutcome.rejected),
        (408, ReportOutcome.failed),
        (429, ReportOutcome.failed),
        (500, ReportOutcome.failed),
      ]) {
        failure = http(status);
        expect(await next(), outcome, reason: '$status');
      }
      failure = DioException(
        requestOptions: RequestOptions(path: '/v2/location'),
        type: DioExceptionType.connectionError,
      );
      expect(await next(), ReportOutcome.failed);
      failure = StateError('boom');
      expect(await next(), ReportOutcome.failed);
      expect(reported, [fix]);
    });

    test('a report and a move arriving together send one request', () async {
      final positions = StreamController<GpsFix>();
      final gate = Completer<void>();
      var calls = 0;
      final reporter = DeviceLocationReporter(
        positions: () => positions.stream,
        settings: await settings(),
        now: () => DateTime.utc(2024, 1, 1),
        onMoved: (fix) async {
          calls++;
          await gate.future;
          return true;
        },
      )..start();

      positions.add((lat: 25.0, lng: 121.0));
      await pumpEventQueue();
      final registration = reporter.reportNow((lat: 25.0, lng: 121.0));
      gate.complete();

      // The move's 2xx carried the registration's place too, so nothing is
      // left pending to go again when the window ends.
      expect(await registration, ReportOutcome.sent);
      expect(calls, 1);
      expect(
        reporter.retryPending(),
        completion(isNull),
        reason: 'nothing is pending',
      );
      reporter.dispose();
      await positions.close();
    });
  });

  group('reportWhenAllowed', () {
    final start = DateTime.utc(2024, 1, 1);
    const pinned = (lat: 22.6, lng: 120.6);

    DeviceLocationReporter reporterAt(
      FakeAsync async,
      List<GpsFix> reported, {
      DateTime? lastReport,
    }) => DeviceLocationReporter(
      positions: () => const Stream<GpsFix>.empty(),
      settings: SettingsStore.inMemory({
        if (lastReport != null)
          SettingKeys.deviceLocationUpdatedAtMs.name:
              lastReport.millisecondsSinceEpoch,
      }),
      now: () => start.add(async.elapsed),
      onMoved: (fix) async {
        reported.add(fix);
        return true;
      },
    );

    test('reports at once when the window is open', () {
      fakeAsync((async) {
        final reported = <GpsFix>[];
        ReportOutcome? outcome;
        reporterAt(
          async,
          reported,
        ).reportWhenAllowed(pinned).then((o) => outcome = o);
        async.flushMicrotasks();
        expect(reported, [pinned]);
        expect(outcome, ReportOutcome.sent);
      });
    });

    test('waits out a window a report just took, then reports', () {
      // A township pinned a moment after a move was reported must still reach
      // the server, or it keeps alerting for where the move put the device.
      fakeAsync((async) {
        final reported = <GpsFix>[];
        ReportOutcome? outcome;
        reporterAt(
          async,
          reported,
          lastReport: start.subtract(const Duration(seconds: 20)),
        ).reportWhenAllowed(pinned).then((o) => outcome = o);

        async.elapse(const Duration(seconds: 39));
        expect(reported, isEmpty);
        // Answered at once: pending, and sent by the timer when the window
        // ends.
        expect(outcome, ReportOutcome.throttled);
        async.elapse(const Duration(seconds: 2));
        expect(reported, [pinned]);
      });
    });

    test('a later placement supersedes one still waiting', () {
      fakeAsync((async) {
        final reported = <GpsFix>[];
        final reporter = reporterAt(
          async,
          reported,
          lastReport: start.subtract(const Duration(seconds: 20)),
        );
        ReportOutcome? first;
        ReportOutcome? second;
        reporter
            .reportWhenAllowed((lat: 25.0, lng: 121.5))
            .then((o) => first = o);
        reporter.reportWhenAllowed(pinned).then((o) => second = o);

        async.elapse(const Duration(seconds: 41));
        expect(reported, [pinned]);
        // Both answered at once — pending, inside the window — and the one
        // pending slot held only the later placement when the window ended.
        expect(first, ReportOutcome.throttled);
        expect(second, ReportOutcome.throttled);
        async.elapse(const Duration(minutes: 5));
        expect(reported, [pinned]);
      });
    });

    test('a fix the server already has is not sent again', () {
      fakeAsync((async) {
        final reported = <GpsFix>[];
        final reporter = reporterAt(async, reported);
        reporter.reportNow(pinned);
        async.flushMicrotasks();

        ReportOutcome? outcome;
        reporter.reportWhenAllowed(pinned).then((o) => outcome = o);
        async.flushMicrotasks();
        expect(reported, [pinned]);
        expect(outcome, ReportOutcome.sent);
      });
    });

    test('a placement the server failed is kept and sent again', () {
      fakeAsync((async) {
        final store = SettingsStore.inMemory();
        final answers = <Object?>[
          DioException(
            requestOptions: RequestOptions(path: '/v2/location'),
            response: Response<void>(
              requestOptions: RequestOptions(path: '/v2/location'),
              statusCode: 503,
            ),
            type: DioExceptionType.badResponse,
          ),
          null,
        ];
        final sent = <GpsFix>[];
        final reporter = DeviceLocationReporter(
          positions: () => const Stream<GpsFix>.empty(),
          settings: store,
          now: () => start.add(async.elapsed),
          onMoved: (fix) async {
            sent.add(fix);
            final answer = answers.removeAt(0);
            if (answer != null) throw answer;
            return true;
          },
        );
        ReportOutcome? outcome;
        reporter.reportWhenAllowed(pinned).then((o) => outcome = o);
        async.flushMicrotasks();
        expect(outcome, ReportOutcome.failed);
        expect(store.getString(SettingKeys.pendingLocationReport), isNotNull);

        async.elapse(const Duration(minutes: 5));
        expect(sent, [pinned, pinned]);
        expect(store.getString(SettingKeys.pendingLocationReport), isNull);
        reporter.dispose();
      });
    });

    test('a placement of the place a move is sending goes once', () {
      // The position stream reports a newly pinned township itself, and the
      // placement for it can arrive while that request is still out.
      fakeAsync((async) {
        final positions = StreamController<GpsFix>();
        final gate = Completer<void>();
        final sent = <GpsFix>[];
        final reporter = DeviceLocationReporter(
          positions: () => positions.stream,
          settings: SettingsStore.inMemory(),
          now: () => start.add(async.elapsed),
          onMoved: (fix) async {
            sent.add(fix);
            await gate.future;
            return true;
          },
        )..start();
        positions.add(pinned);
        async.flushMicrotasks();
        expect(sent, [pinned]);

        ReportOutcome? outcome;
        reporter.reportWhenAllowed(pinned).then((o) => outcome = o);
        async.flushMicrotasks();
        gate.complete();
        async.flushMicrotasks();
        expect(outcome, ReportOutcome.sent);

        async.elapse(const Duration(hours: 1));
        expect(sent, [pinned]);
        reporter.dispose();
        positions.close();
      });
    });
  });

  group('pinned township', () {
    const gps = (lat: 25.03, lng: 121.56);
    const township = (lat: 22.6, lng: 120.6);

    String? pending(SettingsStore store) =>
        store.getString(SettingKeys.pendingLocationReport);

    test('a GPS fix pending when the township is pinned goes as the '
        "township's point", () {
      fakeAsync((async) {
        final store = SettingsStore.inMemory();
        GpsFix? pinned;
        var fail = true;
        final sent = <GpsFix>[];
        final reported = <GpsFix>[];
        final reporter = DeviceLocationReporter(
          positions: () => const Stream<GpsFix>.empty(),
          settings: store,
          now: () => DateTime.utc(2026, 11, 29).add(async.elapsed),
          pinned: () async => pinned,
          onReported: (fix) async => reported.add(fix),
          onMoved: (fix) async {
            sent.add(fix);
            if (fail) {
              throw DioException(
                requestOptions: RequestOptions(path: '/v2/location'),
                type: DioExceptionType.connectionError,
              );
            }
            return true;
          },
        );
        reporter.reportNow(gps);
        async.flushMicrotasks();
        expect(sent, [gps]);
        expect(pending(store), contains('${gps.lat}'));

        // Pinned before the retry: the retry is the township, never the GPS.
        pinned = township;
        fail = false;
        async.elapse(const Duration(minutes: 5));
        expect(sent, [gps, township]);
        expect(reported, [township]);
        expect(pending(store), isNull);

        // A GPS fix offered while pinned is the township's point too.
        async.elapse(const Duration(minutes: 2));
        reporter.reportNow(gps);
        async.flushMicrotasks();
        expect(sent, [gps, township, township]);
        reporter.dispose();
      });
    });

    test('a GPS fix a run left pending goes as the township after a '
        'restart', () async {
      final store = SettingsStore.inMemory({
        SettingKeys.pendingLocationReport.name:
            '{"lat":${gps.lat},"lng":${gps.lng},"takenAt":0}',
      });
      final sent = <GpsFix>[];
      final reporter = DeviceLocationReporter(
        positions: () => const Stream<GpsFix>.empty(),
        settings: store,
        now: () => DateTime.utc(2026, 11, 29),
        pinned: () async => township,
        onMoved: (fix) async {
          sent.add(fix);
          return true;
        },
      )..start();
      await pumpEventQueue();

      expect(sent, [township]);
      expect(pending(store), isNull);
      reporter.dispose();
    });

    test('a GPS fix chosen while pinned is stored as the township', () {
      fakeAsync((async) {
        final store = SettingsStore.inMemory();
        final gate = Completer<void>();
        final sent = <GpsFix>[];
        final reporter = DeviceLocationReporter(
          positions: () => const Stream<GpsFix>.empty(),
          settings: store,
          now: () => DateTime.utc(2026, 11, 29).add(async.elapsed),
          pinned: () async => township,
          onMoved: (fix) async {
            sent.add(fix);
            await gate.future;
            return true;
          },
        );
        reporter.reportNow(township);
        async.flushMicrotasks();
        expect(sent, [township]);

        // Stored while that request is still out, before any attempt has
        // looked at it: what survives a restart now is the township already.
        reporter.reportNow(gps);
        async.flushMicrotasks();
        expect(pending(store), contains('${township.lat}'));
        expect(pending(store), isNot(contains('${gps.lat}')));

        gate.complete();
        async.elapse(const Duration(hours: 1));
        expect(sent, [township]);
        reporter.dispose();
      });
    });
  });

  group('pending report', () {
    const a = (lat: 25.0, lng: 121.0);
    const b = (lat: 24.1, lng: 120.6);

    DioException http(int status) => DioException(
      requestOptions: RequestOptions(path: '/v2/location'),
      response: Response<void>(
        requestOptions: RequestOptions(path: '/v2/location'),
        statusCode: status,
      ),
      type: DioExceptionType.badResponse,
    );

    String? pending(SettingsStore store) =>
        store.getString(SettingKeys.pendingLocationReport);

    test('a 429 keeps it pending, retried after the cool-down; only a 2xx '
        'clears it', () {
      fakeAsync((async) {
        final store = SettingsStore.inMemory();
        final answers = <Object?>[http(429), http(429), null];
        final sent = <GpsFix>[];
        var reported = 0;
        final reporter = DeviceLocationReporter(
          positions: () => const Stream.empty(),
          settings: store,
          now: () => DateTime.utc(2026, 11, 29).add(async.elapsed),
          onReported: (_) async => reported++,
          onMoved: (fix) async {
            sent.add(fix);
            final answer = answers.removeAt(0);
            if (answer != null) throw answer;
            return true;
          },
        );

        reporter.reportNow(a);
        async.flushMicrotasks();
        expect(sent, [a]);
        expect(pending(store), isNotNull);
        expect(reported, 0);

        // Not inside the minute the server is still counting.
        async.elapse(const Duration(seconds: 60));
        expect(sent, hasLength(1));
        async.elapse(const Duration(seconds: 1));
        expect(sent, [a, a]);
        expect(pending(store), isNotNull);
        expect(reported, 0);

        // A second 429 in a row doubles the wait.
        async.elapse(const Duration(seconds: 121));
        expect(sent, hasLength(2));
        async.elapse(const Duration(seconds: 1));
        expect(sent, [a, a, a]);
        expect(pending(store), isNull);
        expect(reported, 1);

        // Nothing left to send.
        async.elapse(const Duration(hours: 1));
        expect(sent, hasLength(3));
        reporter.dispose();
      });
    });

    test('a 5xx, a timeout or no network is retried after failedRetry', () {
      fakeAsync((async) {
        final answers = <Object?>[
          http(503),
          DioException(
            requestOptions: RequestOptions(path: '/v2/location'),
            type: DioExceptionType.connectionError,
          ),
          null,
        ];
        final sent = <GpsFix>[];
        final reporter = DeviceLocationReporter(
          positions: () => const Stream.empty(),
          settings: SettingsStore.inMemory(),
          now: () => DateTime.utc(2026, 11, 29).add(async.elapsed),
          onMoved: (fix) async {
            sent.add(fix);
            final answer = answers.removeAt(0);
            if (answer != null) throw answer;
            return true;
          },
        );

        reporter.reportNow(a);
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 4, seconds: 59));
        expect(sent, hasLength(1));
        async.elapse(const Duration(seconds: 1));
        expect(sent, hasLength(2));
        async.elapse(const Duration(minutes: 10));
        expect(sent, hasLength(3));
        reporter.dispose();
      });
    });

    test('it survives a restart and is sent on start', () async {
      final store = SettingsStore.inMemory();
      var t = DateTime.utc(2026, 11, 29);
      final first = DeviceLocationReporter(
        positions: () => const Stream.empty(),
        settings: store,
        now: () => t,
        onMoved: (fix) async => throw http(503),
      );
      expect(await first.reportNow(a), ReportOutcome.failed);
      first.dispose();
      expect(pending(store), isNotNull);

      // A new process: only the persisted state is left.
      t = t.add(const Duration(minutes: 2));
      final sent = <GpsFix>[];
      var reported = 0;
      final second = DeviceLocationReporter(
        positions: () => const Stream.empty(),
        settings: store,
        now: () => t,
        onReported: (_) async => reported++,
        onMoved: (fix) async {
          sent.add(fix);
          return true;
        },
      )..start();
      await pumpEventQueue();

      expect(sent, [a]);
      expect(reported, 1);
      expect(pending(store), isNull);
      second.dispose();
    });

    test('a newer fix replaces a pending one', () {
      fakeAsync((async) {
        final positions = StreamController<GpsFix>();
        final answers = <Object?>[http(503), null];
        final sent = <GpsFix>[];
        final reporter = DeviceLocationReporter(
          positions: () => positions.stream,
          settings: SettingsStore.inMemory(),
          now: () => DateTime.utc(2026, 11, 29).add(async.elapsed),
          onMoved: (fix) async {
            sent.add(fix);
            final answer = answers.removeAt(0);
            if (answer != null) throw answer;
            return true;
          },
        )..start();

        positions.add(a);
        async.flushMicrotasks();
        expect(sent, [a]);

        // Inside the cool-down: b replaces a, and goes when the window ends.
        async.elapse(const Duration(seconds: 10));
        positions.add(b);
        async.flushMicrotasks();
        expect(sent, [a]);
        async.elapse(const Duration(seconds: 50));
        expect(sent, [a, b]);

        // a is not sent again.
        async.elapse(const Duration(hours: 1));
        expect(sent, [a, b]);
        reporter.dispose();
        positions.close();
      });
    });

    test('a newer fix that arrives mid-request is not cleared by its 2xx', () {
      fakeAsync((async) {
        final positions = StreamController<GpsFix>();
        final gate = Completer<void>();
        final sent = <GpsFix>[];
        final reporter = DeviceLocationReporter(
          positions: () => positions.stream,
          settings: SettingsStore.inMemory(),
          now: () => DateTime.utc(2026, 11, 29).add(async.elapsed),
          onMoved: (fix) async {
            sent.add(fix);
            if (sent.length == 1) await gate.future;
            return true;
          },
        )..start();

        positions.add(a);
        async.flushMicrotasks();
        positions.add(b);
        async.flushMicrotasks();
        gate.complete();
        async.flushMicrotasks();
        expect(sent, [a]);

        async.elapse(const Duration(seconds: 60));
        expect(sent, [a, b]);
        reporter.dispose();
        positions.close();
      });
    });

    test('a refusal for good drops it', () {
      fakeAsync((async) {
        final store = SettingsStore.inMemory();
        var calls = 0;
        final reporter = DeviceLocationReporter(
          positions: () => const Stream.empty(),
          settings: store,
          now: () => DateTime.utc(2026, 11, 29).add(async.elapsed),
          onMoved: (fix) async {
            calls++;
            throw http(400);
          },
        );

        reporter.reportNow(a);
        async.flushMicrotasks();
        expect(pending(store), isNull);
        async.elapse(const Duration(hours: 2));
        expect(calls, 1);
        reporter.dispose();
      });
    });

    test('without a push token it waits, and goes on retryPending', () async {
      final store = SettingsStore.inMemory();
      var token = false;
      final sent = <GpsFix>[];
      final reporter = DeviceLocationReporter(
        positions: () => const Stream.empty(),
        settings: store,
        now: () => DateTime.utc(2026, 11, 29),
        onMoved: (fix) async {
          if (!token) return false;
          sent.add(fix);
          return true;
        },
      );

      expect(await reporter.reportNow(a), ReportOutcome.noToken);
      expect(pending(store), isNotNull);

      token = true;
      expect(await reporter.retryPending(), ReportOutcome.sent);
      expect(sent, [a]);
      expect(await reporter.retryPending(), isNull);
      reporter.dispose();
    });

    test('a background report since it was taken drops it unsent', () async {
      final store = SettingsStore.inMemory();
      final taken = DateTime.utc(2026, 11, 29, 8);
      final failing = DeviceLocationReporter(
        positions: () => const Stream.empty(),
        settings: store,
        now: () => taken,
        calibratedNow: () => taken,
        onMoved: (fix) async => throw http(503),
      );
      await failing.reportNow(a);
      failing.dispose();

      var calls = 0;
      DateTime? native = taken.subtract(const Duration(minutes: 1));
      final reporter = DeviceLocationReporter(
        positions: () => const Stream.empty(),
        settings: store,
        now: () => taken.add(const Duration(hours: 1)),
        calibratedNow: () => taken.add(const Duration(hours: 1)),
        nativeLastSuccess: () async => native,
        onMoved: (fix) async {
          calls++;
          throw http(503);
        },
      );
      // An older background report changes nothing.
      expect(await reporter.retryPending(), ReportOutcome.failed);
      expect(calls, 1);

      native = taken.add(const Duration(minutes: 30));
      expect(await reporter.retryPending(), ReportOutcome.superseded);
      expect(calls, 1);
      expect(pending(store), isNull);
      reporter.dispose();
    });

    test('a fix taken within the minute is not weighed against the '
        'background reporter', () async {
      final taken = DateTime.utc(2026, 11, 29, 8);
      var asked = 0;
      var calls = 0;
      final reporter = DeviceLocationReporter(
        positions: () => const Stream.empty(),
        settings: SettingsStore.inMemory(),
        now: () => taken,
        calibratedNow: () => taken,
        nativeLastSuccess: () async {
          asked++;
          return taken.add(const Duration(hours: 1));
        },
        onMoved: (fix) async {
          calls++;
          return true;
        },
      );
      expect(await reporter.reportNow(a), ReportOutcome.sent);
      expect(asked, 0);
      expect(calls, 1);
      reporter.dispose();
    });
  });
}

class _Sink implements CrashSink {
  final handled = <Object>[];

  @override
  void report(
    Object error,
    StackTrace stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    handled.add(error);
  }
}
