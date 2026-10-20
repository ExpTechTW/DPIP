import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:dpip/core/logging/crash_sink.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
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
    // Second distinct fix is inside 60s → API skipped, but first uploaded.
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

  test('skips API inside 60s using persisted stamp (silent)', () async {
    final stamped = DateTime.utc(2024, 1, 1).millisecondsSinceEpoch;
    final p = await settings({
      SettingKeys.deviceLocationUpdatedAtMs.name: stamped,
    });
    final positions = StreamController<GpsFix>();
    var calls = 0;
    DeviceLocationReporter(
      positions: () => positions.stream,
      settings: p,
      now: () => DateTime.utc(2024, 1, 1, 0, 0, 30), // +30s
      onMoved: (fix) async {
        calls++;
        return true;
      },
    ).start();

    positions.add((lat: 25.0, lng: 121.0));
    await pumpEventQueue();
    expect(calls, 0);
    await positions.close();
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
      var reported = 0;
      final reporter = DeviceLocationReporter(
        positions: () => const Stream.empty(),
        settings: await settings(),
        now: () => t,
        onReported: () async => reported++,
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
      expect(reported, 1);
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
      expect(reported, 1);
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

      expect(await registration, ReportOutcome.throttled);
      expect(calls, 1);
      await positions.close();
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
