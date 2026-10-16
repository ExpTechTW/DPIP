/// The lifecycle around [RtsWorker]: started the first time the feed has a
/// frame for it, and stepped away from for good if it cannot start or stops.
library;

import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/earthquake/data/rts_worker.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_station_encoder.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';

/// Starts an RTS worker — [RtsWorker.spawn], replaceable in tests.
typedef RtsWorkerSpawner = Future<RtsWorker> Function();

/// Hands the live RTS feed's frames to an [RtsWorker], and the monitor's
/// station layer back from it.
///
/// Each frame the worker decodes is remembered by the number the worker gave
/// it, so the monitor can ask for the layer of the frame it is showing by the
/// frame alone; a frame that did not come from the worker answers null, and
/// the monitor builds that one itself.
///
/// The worker starts on the first frame rather than at launch: the stream
/// sleeps until the monitor opens or a station alerts, and an isolate nobody
/// uses is memory a cheap phone would rather keep. One that fails to start, or
/// stops, is not replaced — [decode] answers null from then on and the feed
/// decodes on the UI isolate, exactly as it did before the worker existed.
/// A replacement would buy back a little speed at the cost of a retry loop on
/// the one path the monitor cannot do without.
class RtsWorkerService implements RtsStationEncoder {
  RtsWorkerService({this._spawn = RtsWorker.spawn});

  final RtsWorkerSpawner _spawn;
  RtsWorker? _worker;
  Future<RtsWorker?>? _starting;

  /// The number the worker gave each frame it decoded. Never reused: a
  /// stopped worker is not replaced, so a number always means its own frame.
  final Expando<int> _seqs = Expando('rts worker frame');

  /// The directory the worker places frames against, kept for a worker that
  /// has yet to start.
  Map<String, SeismicStation> _stations = const {};

  /// How long [encode] waits on the worker before leaving the layer to the
  /// caller. The worker answers in milliseconds; this only keeps one that has
  /// stopped answering without stopping from holding up what the monitor
  /// writes after its station layer — the EEW overlay among it.
  static const Duration encodeTimeout = Duration(milliseconds: 500);

  /// The worker could not start, or has stopped.
  bool _failed = false;
  bool _encodeFailureLogged = false;
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
    final RtsWorkerFrame? decoded;
    try {
      decoded = await worker.decode(payload);
    } on RtsWorkerGone {
      return decodeRtsPayload(payload);
    }
    if (decoded == null) return null;
    _seqs[decoded.frame] = decoded.seq;
    return decoded.frame;
  }

  @override
  void placeStations(Map<String, SeismicStation> stations) {
    if (identical(stations, _stations)) return;
    _stations = stations;
    _worker?.placeStations(stations);
  }

  @override
  Future<String?> encode(
    Rts frame, {
    required bool eventLit,
    required bool eewActive,
    required List<String> badgeIcons,
  }) async {
    final worker = _worker;
    final seq = _seqs[frame];
    if (worker == null || seq == null) return null;
    try {
      return await worker
          .encode(
            seq,
            eventLit: eventLit,
            eewActive: eewActive,
            badgeIcons: badgeIcons,
          )
          .timeout(encodeTimeout, onTimeout: () => null);
    } on RtsWorkerGone {
      return null;
    } catch (error, stackTrace) {
      // A frame the builder cannot write: the caller builds it itself and
      // meets the same fault the way it always has. Said once, not at the
      // feed's two frames a second, into a log that is kept for a day.
      if (!_encodeFailureLogged) {
        _encodeFailureLogged = true;
        Log.handle(error, stackTrace, 'rts: worker station layer');
      }
      return null;
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
    // Before any frame is sent, so the first layer asked for is placed.
    worker.placeStations(_stations);
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
