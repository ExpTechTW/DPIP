import 'dart:async';

import 'package:dpip/core/geo/device_location_reporter.dart';
import 'package:dpip/core/geo/location_service.dart' show GpsFix;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports each distance-triggered move; skips identical fixes', () async {
    final positions = StreamController<GpsFix>();
    final reported = <GpsFix>[];
    DeviceLocationReporter(
      positions: () => positions.stream,
      onMoved: (fix) async => reported.add(fix),
    ).start();

    positions
      ..add((lat: 25.0, lng: 121.0))
      ..add((lat: 25.0, lng: 121.0)) // identical → skipped
      ..add((lat: 25.1, lng: 121.1));
    await pumpEventQueue();

    expect(reported, [(lat: 25.0, lng: 121.0), (lat: 25.1, lng: 121.1)]);
    await positions.close();
  });

  test('stop() ends reporting', () async {
    final positions = StreamController<GpsFix>();
    final reported = <GpsFix>[];
    final reporter = DeviceLocationReporter(
      positions: () => positions.stream,
      onMoved: (fix) async => reported.add(fix),
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
    DeviceLocationReporter(
      positions: () => positions.stream,
      onMoved: (fix) async {
        calls++;
        throw Exception('network down');
      },
    ).start();

    positions
      ..add((lat: 25.0, lng: 121.0))
      ..add((lat: 25.1, lng: 121.1));
    await pumpEventQueue();

    expect(calls, 2); // kept going after the first failure
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
      onMoved: (fix) async => reported.add(fix),
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
}
