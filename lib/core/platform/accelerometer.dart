import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

/// One accelerometer reading.
///
/// [x], [y] and [z] are gal (1 gal = 0.01 m/s²). [timestampNanos] is
/// nanoseconds since boot, on the clock the platform sensor already uses.
///
/// The frame is the device's, not the current interface orientation: +x to
/// the right, +y toward the top of the device, +z out of the screen. A phone
/// at rest, flat, screen up, has z ≈ +980.
final class AccelerometerSample {
  const AccelerometerSample({
    required this.timestampNanos,
    required this.x,
    required this.y,
    required this.z,
  });

  final int timestampNanos;
  final double x;
  final double y;
  final double z;
}

const _channel = EventChannel('com.exptech.dpip/accelerometer');

/// Batches from the accelerometer event channel.
///
/// The platform samples at about 50 Hz and sends one batch about every
/// 100 ms. Each batch is a [Float64List] of `timestampNanos, x, y, z`
/// groups, in gal. An interval with no samples sends nothing.
///
/// A platform failure arrives as an error on this stream. That is either the
/// `listen` call failing — iOS returns `FlutterError` code `unavailable`
/// from `onListen` when the sensor is missing — or a later error event,
/// which is how Android reports the same condition.
///
/// Single-subscription. Cancelling releases the platform listener at once,
/// without waiting for another sample.
Stream<List<AccelerometerSample>> accelerometerBatches() =>
    accelerometerBatchesOf(_accelerometerEvents(_channel));

/// The batch decoder over any stream of raw platform batches.
///
/// [batches] carries what the event channel delivers: a [Float64List], or a
/// [List] of numbers for a test that does not go through the codec. A value
/// that is not a batch, or whose length is not a multiple of four, is a
/// [FormatException] on the returned stream. Errors already on [batches] are
/// forwarded unchanged.
@visibleForTesting
Stream<List<AccelerometerSample>> accelerometerBatchesOf(
  Stream<Object?> batches,
) => Stream<List<AccelerometerSample>>.multi((out) {
  final subscription = batches.listen(
    (batch) {
      try {
        out.add(_samplesFrom(batch));
      } catch (error, stackTrace) {
        out.addError(error, stackTrace);
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      out.addError(error, stackTrace);
    },
    onDone: out.close,
  );
  out
    ..onPause = subscription.pause
    ..onResume = subscription.resume
    ..onCancel = subscription.cancel;
});

/// Events from [channel].
///
/// A failed `listen` and a later error envelope are both errors on the
/// returned stream. A `null` message from the platform ends it.
Stream<Object?> _accelerometerEvents(EventChannel channel) {
  final messenger = channel.binaryMessenger;
  final codec = channel.codec;
  final methods = MethodChannel(channel.name, codec, messenger);
  late StreamController<Object?> controller;
  controller = StreamController<Object?>(
    onListen: () async {
      messenger.setMessageHandler(channel.name, (ByteData? message) async {
        if (controller.isClosed || !controller.hasListener) return null;
        if (message == null) {
          await controller.close();
          return null;
        }
        try {
          controller.add(codec.decodeEnvelope(message) as Object?);
        } catch (error, stackTrace) {
          if (!controller.isClosed && controller.hasListener) {
            controller.addError(error, stackTrace);
          }
        }
        return null;
      });
      try {
        await methods.invokeMethod<void>('listen');
      } catch (error, stackTrace) {
        if (!controller.isClosed && controller.hasListener) {
          controller.addError(error, stackTrace);
        }
      }
    },
    onCancel: () async {
      messenger.setMessageHandler(channel.name, null);
      try {
        await methods.invokeMethod<void>('cancel');
      } catch (_) {
        // The listener is already gone. A platform that rejects cancel
        // because listen never started has nothing left to deliver.
      }
    },
  );
  return controller.stream;
}

List<AccelerometerSample> _samplesFrom(Object? raw) {
  final Float64List values;
  if (raw is Float64List) {
    values = raw;
  } else if (raw is List<Object?>) {
    values = Float64List(raw.length);
    for (var i = 0; i < raw.length; i++) {
      final entry = raw[i];
      if (entry is! num) {
        throw FormatException(
          'accelerometer batch entry $i is ${entry.runtimeType}',
        );
      }
      values[i] = entry.toDouble();
    }
  } else {
    throw FormatException('accelerometer batch is ${raw.runtimeType}');
  }
  if (values.length % 4 != 0) {
    throw FormatException(
      'accelerometer batch length ${values.length} is not a multiple of 4',
    );
  }
  final samples = <AccelerometerSample>[];
  for (var i = 0; i < values.length; i += 4) {
    samples.add(
      AccelerometerSample(
        timestampNanos: values[i].round(),
        x: values[i + 1],
        y: values[i + 2],
        z: values[i + 3],
      ),
    );
  }
  return samples;
}
