import 'dart:async';

import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:dpip/core/settings/preference_keys.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Prefs> prefs([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    return Prefs(await SharedPreferences.getInstance());
  }

  test('reports each distance-triggered move; skips identical fixes', () async {
    final positions = StreamController<GpsFix>();
    final reported = <GpsFix>[];
    var t = DateTime.utc(2024, 1, 1);
    DeviceLocationReporter(
      positions: () => positions.stream,
      prefs: await prefs(),
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
      prefs: await prefs(),
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
      prefs: await prefs(),
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
    final p = await prefs({
      PreferenceKeys.deviceLocationUpdatedAtMs.name: stamped,
    });
    final positions = StreamController<GpsFix>();
    var calls = 0;
    DeviceLocationReporter(
      positions: () => positions.stream,
      prefs: p,
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
      prefs: await prefs(),
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

  test('shares accepted fixes on [fixes] for the township tracker', () async {
    final positions = StreamController<GpsFix>();
    final reporter = DeviceLocationReporter(
      positions: () => positions.stream,
      prefs: await prefs(),
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
      prefs: await prefs(),
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
      prefs: await prefs({
        PreferenceKeys.deviceLocationUpdatedAtMs.name: stamped,
      }),
      now: () => DateTime.utc(2024, 1, 1, 0, 0, 10),
      onMoved: (fix) async {
        fail('should not upload');
        return true;
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
}
