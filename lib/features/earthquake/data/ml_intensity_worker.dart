/// The isolate the ML v1 intensity model lives in.
///
/// Loading the model means inflating 14.7 MB and reading four million protobuf
/// fields; scoring a quake means 368 townships through 2,800 trees. Neither may
/// run on the UI isolate — the alert that triggers them is the moment the
/// monitor can least afford a dropped frame. So the model is built once in a
/// long-lived worker and stays there; a quake crosses over as four numbers and
/// comes back as 368 bytes.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dpip/features/earthquake/domain/ml/ml_intensity_model.dart';

/// A running worker holding a built model.
class MlIntensityWorker {
  MlIntensityWorker._(this._isolate, this._requests, this._replies);

  final Isolate _isolate;
  final SendPort _requests;
  final ReceivePort _replies;
  final Map<int, Completer<Uint8List>> _pending = {};
  int _nextId = 0;

  /// Starts a worker and builds the model in it from [model] — the ONNX file,
  /// gzip-compressed when [gzipped] — scored at the points whose coordinates
  /// are [latitudes] and [longitudes]. Throws if the model does not build.
  static Future<MlIntensityWorker> spawn({
    required Uint8List model,
    required bool gzipped,
    required Float64List latitudes,
    required Float64List longitudes,
  }) async {
    final replies = ReceivePort();
    final isolate = await Isolate.spawn(
      _main,
      (
        replies.sendPort,
        TransferableTypedData.fromList([model]),
        gzipped,
        latitudes,
        longitudes,
      ),
      debugName: 'ml-intensity',
      errorsAreFatal: false,
    );
    final ready = Completer<SendPort>();
    late final MlIntensityWorker worker;
    replies.listen((message) {
      switch (message) {
        case SendPort port when !ready.isCompleted:
          ready.complete(port);
        case String error when !ready.isCompleted:
          ready.completeError(StateError(error));
        case (int id, Uint8List levels):
          worker._pending.remove(id)?.complete(levels);
        case (int id, String error):
          worker._pending.remove(id)?.completeError(StateError(error));
      }
    });
    try {
      worker = MlIntensityWorker._(isolate, await ready.future, replies);
      return worker;
    } catch (_) {
      replies.close();
      isolate.kill();
      rethrow;
    }
  }

  /// Each point's level for a quake, in point order.
  Future<Uint8List> levels({
    required double magnitude,
    required double depth,
    required double latitude,
    required double longitude,
  }) {
    final id = _nextId++;
    final reply = Completer<Uint8List>();
    _pending[id] = reply;
    _requests.send((id, magnitude, depth, latitude, longitude));
    return reply.future;
  }

  void dispose() {
    for (final reply in _pending.values) {
      reply.completeError(StateError('ml worker disposed'));
    }
    _pending.clear();
    _replies.close();
    _isolate.kill();
  }
}

Future<void> _main(
  (SendPort, TransferableTypedData, bool, Float64List, Float64List) args,
) async {
  final (replies, transferred, gzipped, latitudes, longitudes) = args;
  final MlPointPredictor predictor;
  try {
    final bytes = transferred.materialize().asUint8List();
    final onnx = gzipped ? Uint8List.fromList(gzip.decode(bytes)) : bytes;
    predictor = MlPointPredictor(
      MlIntensityModel.parse(onnx),
      latitudes,
      longitudes,
    );
  } catch (error) {
    replies.send('$error');
    return;
  }
  final requests = ReceivePort();
  replies.send(requests.sendPort);
  await for (final message in requests) {
    final (id, magnitude, depth, latitude, longitude) =
        message as (int, double, double, double, double);
    try {
      replies.send((
        id,
        predictor.levels(
          magnitude: magnitude,
          depth: depth,
          latitude: latitude,
          longitude: longitude,
        ),
      ));
    } catch (error) {
      replies.send((id, '$error'));
    }
  }
}
