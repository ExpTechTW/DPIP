/// The wire format is the whole contract of the accelerometer pipe: four
/// float64s per sample, an `unavailable` platform error on the stream, and a
/// cancel that reaches the platform without waiting for another sample.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:dpip/core/platform/accelerometer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = 'com.exptech.dpip/accelerometer';
  const eventChannel = EventChannel(channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockStreamHandler(eventChannel, null);
    messenger.setMockMethodCallHandler(const MethodChannel(channelName), null);
  });

  test('a float64 batch becomes samples', () async {
    MockStreamHandlerEventSink? sink;
    messenger.setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (_, events) {
          sink = events;
        },
      ),
    );

    final seen = <List<AccelerometerSample>>[];
    final subscription = accelerometerBatches().listen(seen.add);
    await pumpEventQueue();
    expect(sink, isNotNull);
    sink!.success(
      Float64List.fromList(const <double>[
        123456789,
        12.5,
        -3.25,
        980.665,
        143456789,
        -1,
        0,
        4.5,
      ]),
    );
    await pumpEventQueue();

    expect(seen, hasLength(1));
    final batch = seen.single;
    expect(batch, hasLength(2));
    expect(batch[0].timestampNanos, 123456789);
    expect(batch[0].x, 12.5);
    expect(batch[0].y, -3.25);
    expect(batch[0].z, 980.665);
    expect(batch[1].timestampNanos, 143456789);
    expect(batch[1].x, -1);
    expect(batch[1].y, 0);
    expect(batch[1].z, 4.5);

    await subscription.cancel();
  });

  test('an unavailable error event is a stream error', () async {
    MockStreamHandlerEventSink? sink;
    messenger.setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (_, events) {
          sink = events;
        },
      ),
    );
    final errors = <Object>[];
    final subscription = accelerometerBatches().listen(
      (_) {},
      onError: errors.add,
    );
    await pumpEventQueue();
    sink!.error(code: 'unavailable', message: 'Accelerometer not available');
    await pumpEventQueue();

    expect(errors, hasLength(1));
    expect(errors.single, isA<PlatformException>());
    expect((errors.single as PlatformException).code, 'unavailable');
    await subscription.cancel();
  });

  test('a listen failure with code unavailable is a stream error', () async {
    // iOS reports a missing accelerometer by failing the listen call.
    messenger.setMockMethodCallHandler(const MethodChannel(channelName), (
      call,
    ) async {
      if (call.method == 'listen') {
        throw PlatformException(
          code: 'unavailable',
          message: 'Accelerometer not available',
        );
      }
      return null;
    });
    final errors = <Object>[];
    final subscription = accelerometerBatches().listen(
      (_) {},
      onError: errors.add,
    );
    await pumpEventQueue();

    expect(errors, hasLength(1));
    expect((errors.single as PlatformException).code, 'unavailable');
    await subscription.cancel();
  });

  test('cancelling the subscription cancels the platform stream', () async {
    var cancelled = false;
    messenger.setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (_, _) {},
        onCancel: (_) => cancelled = true,
      ),
    );
    final subscription = accelerometerBatches().listen((_) {});
    await pumpEventQueue();
    expect(cancelled, isFalse);
    await subscription.cancel();
    await pumpEventQueue();
    expect(cancelled, isTrue);
  });

  test('a list fed straight to the decoder is the same samples', () async {
    final batch = await accelerometerBatchesOf(
      Stream<Object?>.value(const <double>[10, 1, 2, 3]),
    ).first;
    expect(batch, hasLength(1));
    expect(batch.single.timestampNanos, 10);
    expect(batch.single.x, 1);
    expect(batch.single.y, 2);
    expect(batch.single.z, 3);
  });

  test('a batch whose length is not a multiple of 4 is an error', () async {
    await expectLater(
      accelerometerBatchesOf(Stream<Object?>.value(const <double>[1, 2, 3]))
          .first,
      throwsFormatException,
    );
  });
}
