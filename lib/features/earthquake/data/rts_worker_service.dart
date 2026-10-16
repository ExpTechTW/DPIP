/// The lifecycle around [RtsWorker]: started the first time the feed has a
/// frame for it, and stepped away from for good if it cannot start or stops.
library;

import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/earthquake/data/rts_worker.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';

/// Starts an RTS worker — [RtsWorker.spawn], replaceable in tests.
typedef RtsWorkerSpawner = Future<RtsWorker> Function();

/// Hands the live RTS feed's frames to an [RtsWorker].
///
/// The worker starts on the first frame rather than at launch: the stream
/// sleeps until the monitor opens or a station alerts, and an isolate nobody
/// uses is memory a cheap phone would rather keep. One that fails to start, or
/// stops, is not replaced — [decode] answers null from then on and the feed
/// decodes on the UI isolate, exactly as it did before the worker existed.
/// A replacement would buy back a little speed at the cost of a retry loop on
/// the one path the monitor cannot do without.
class RtsWorkerService {
  RtsWorkerService({this._spawn = RtsWorker.spawn});

  final RtsWorkerSpawner _spawn;
  RtsWorker? _worker;
  Future<RtsWorker?>? _starting;

  /// The worker could not start, or has stopped.
  bool _failed = false;
  bool _disposed = false;

  /// Decodes a payload-event frame on the worker, [payload] exactly as it
  /// arrived; null for a frame with no payload. See
  /// `SseRealtimeSource.decodeElsewhere`.
  ///
  /// Returns null instead of a future once the worker cannot be used, so the
  /// caller decodes the frame itself. A frame already on its way when the
  /// worker turns out to be unusable is decoded here instead — none is lost.
  Future<Rts?>? decode(String payload) {
    if (_failed || _disposed) return null;
    return _decode(payload);
  }

  Future<Rts?> _decode(String payload) async {
    final worker = _worker ?? await _start();
    if (worker == null) return decodeRtsPayload(payload);
    try {
      return (await worker.decode(payload))?.frame;
    } on RtsWorkerGone {
      return decodeRtsPayload(payload);
    }
  }

  Future<RtsWorker?> _start() => _starting ??= _spawnWorker();

  Future<RtsWorker?> _spawnWorker() async {
    final RtsWorker worker;
    try {
      worker = await _spawn();
    } catch (error, stackTrace) {
      _failed = true;
      Log.handle(error, stackTrace, 'rts: worker failed to start');
      return null;
    }
    if (_disposed) {
      worker.dispose();
      return null;
    }
    unawaited(
      worker.stopped.then((_) {
        _failed = true;
        _worker = null;
        if (!_disposed) {
          Log.warning('rts: worker stopped, decoding on the UI isolate');
        }
      }),
    );
    return _worker = worker;
  }

  void dispose() {
    _disposed = true;
    _worker?.dispose();
    _worker = null;
  }
}
