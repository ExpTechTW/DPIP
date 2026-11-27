/// What a device is known to have decides what the app offers on it. Unknown
/// must read as absent, so nothing appears and then vanishes; a failure must
/// read as absent, so nothing is offered that cannot run; and the platform is
/// asked once, because the answer cannot change while the app runs.
library;

import 'dart:async';

import 'package:dpip/core/platform/device_sensors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nothing is present until the answer is in', () async {
    final answer = Completer<bool>();
    final sensors = DeviceSensors(
      probes: {DeviceSensor.accelerometer: () => answer.future},
    );
    addTearDown(sensors.dispose);
    var notified = 0;
    sensors.addListener(() => notified++);

    final resolving = sensors.resolve();
    await pumpEventQueue();
    expect(sensors.has(DeviceSensor.accelerometer), isFalse);
    expect(sensors.present, isEmpty);
    expect(notified, 0);

    answer.complete(true);
    await resolving;
    expect(sensors.has(DeviceSensor.accelerometer), isTrue);
    expect(sensors.present, {DeviceSensor.accelerometer});
    expect(notified, 1);
  });

  test('an absent sensor stays absent and notifies nobody', () async {
    final sensors = DeviceSensors(
      probes: {DeviceSensor.accelerometer: () async => false},
    );
    addTearDown(sensors.dispose);
    var notified = 0;
    sensors.addListener(() => notified++);

    await sensors.resolve();
    expect(sensors.has(DeviceSensor.accelerometer), isFalse);
    expect(notified, 0);
  });

  test('a probe that throws counts as absent', () async {
    final sensors = DeviceSensors(
      probes: {
        DeviceSensor.accelerometer: () async =>
            throw StateError('no sensor service'),
      },
    );
    addTearDown(sensors.dispose);

    await sensors.resolve();
    expect(sensors.has(DeviceSensor.accelerometer), isFalse);
  });

  test('the platform is asked once', () async {
    var asked = 0;
    final sensors = DeviceSensors(
      probes: {
        DeviceSensor.accelerometer: () async {
          asked++;
          return true;
        },
      },
    );
    addTearDown(sensors.dispose);

    await Future.wait([sensors.resolve(), sensors.resolve()]);
    await sensors.resolve();
    expect(asked, 1);
    expect(sensors.has(DeviceSensor.accelerometer), isTrue);
  });

  test('an answer that lands after dispose is dropped quietly', () async {
    final answer = Completer<bool>();
    final sensors = DeviceSensors(
      probes: {DeviceSensor.accelerometer: () => answer.future},
    );
    final resolving = sensors.resolve();
    sensors.dispose();

    answer.complete(true);
    // Notifying a disposed notifier throws; resolving must not.
    await expectLater(resolving, completes);
  });

  test('a known device answers at once and asks nothing', () async {
    final sensors = DeviceSensors.known(const {DeviceSensor.accelerometer});
    addTearDown(sensors.dispose);
    expect(sensors.has(DeviceSensor.accelerometer), isTrue);
    await expectLater(sensors.resolve(), completes);

    final none = DeviceSensors.known(const {});
    addTearDown(none.dispose);
    expect(none.has(DeviceSensor.accelerometer), isFalse);
  });
}
