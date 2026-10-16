/// The isolate the live RTS feed is decoded and drawn in.
///
/// At live speed the TREM stream sends a frame about twice a second: every
/// station's reading, as base64 over gzip over JSON. Undoing all three and
/// building the [Rts], then building the monitor's station GeoJSON from it
/// and encoding that, all ran on the UI isolate, on every frame, for as long
/// as the monitor was open — on a cheap phone that is a frame the screen
/// misses, twice a second. Here a frame crosses over as the string it arrived
/// as and comes back decoded; the worker keeps its own copy, and the station
/// layer is built from that copy and comes back as the string MapLibre takes.
/// The UI isolate never walks the stations.
///
/// Isolates spawned from this one share its heap, and a message between them
/// is copied by the side that sends it: the decoded frame is copied out on
/// the worker, and the UI isolate takes it as it stands.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_station_geojson.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// A request sent to, or still waiting on, a worker that has stopped.
class RtsWorkerGone implements Exception {
  const RtsWorkerGone();

  @override
  String toString() => 'RtsWorkerGone: the RTS worker has stopped';
}

/// A frame the worker decoded, and the number it gave the frame.
typedef RtsWorkerFrame = ({int seq, Rts frame});

/// A running RTS worker.
class RtsWorker {
  RtsWorker._(this._isolate, this._requests, this._replies);

  final Isolate _isolate;
  final SendPort _requests;
  final ReceivePort _replies;
  final Map<int, Completer<Object?>> _pending = {};
  final Completer<void> _stopped = Completer<void>();
  int _nextId = 0;

  /// Starts a worker. Throws if the isolate does not come up.
  static Future<RtsWorker> spawn() async {
    final replies = ReceivePort();
    final ready = Completer<SendPort>();
    RtsWorker? worker;
    replies.listen((message) {
      switch (message) {
        case SendPort port when !ready.isCompleted:
          ready.complete(port);
        // The isolate's exit message, whatever ended it.
        case null:
          if (!ready.isCompleted) {
            ready.completeError(StateError('rts worker exited at start'));
          }
          worker?._stop();
        case (id: final int id, reply: final Object? reply):
          worker?._pending.remove(id)?.complete(reply);
        case (
          id: final int id,
          error: final String error,
          stack: final String stack,
        ):
          worker?._pending
              .remove(id)
              ?.completeError(
                RemoteError(error, stack),
                StackTrace.fromString(stack),
              );
      }
    });
    final Isolate isolate;
    try {
      isolate = await Isolate.spawn(
        _main,
        replies.sendPort,
        debugName: 'rts',
        errorsAreFatal: false,
        onExit: replies.sendPort,
      );
    } catch (_) {
      replies.close();
      rethrow;
    }
    try {
      return worker = RtsWorker._(isolate, await ready.future, replies);
    } catch (_) {
      replies.close();
      isolate.kill(priority: Isolate.immediate);
      rethrow;
    }
  }

  /// The isolate itself, so a test can end it the way a crash would.
  @visibleForTesting
  Isolate get isolate => _isolate;

  /// Completes once the worker has stopped — disposed, or ended by anything
  /// else. Every request still waiting has failed with [RtsWorkerGone] by
  /// then, and every later one fails with it at once.
  Future<void> get stopped => _stopped.future;

  /// Decodes one payload-event frame, [payload] exactly as it arrived.
  /// Completes with null for a frame with no payload, and fails for one that
  /// does not decode.
  Future<RtsWorkerFrame?> decode(String payload) async =>
      await _request((id) => (id: id, payload: payload)) as RtsWorkerFrame?;

  /// The station layer for the frame numbered [seq], placed against the
  /// directory last given to [placeStations] — exactly
  /// [encodeRtsStationGeoJson]'s output. Null once the worker no longer holds
  /// that frame (see [_HeldFrames]).
  Future<String?> encode(
    int seq, {
    required bool eventLit,
    required bool eewActive,
    required List<String> badgeIcons,
  }) async => await _request(
    (id) => (
      id: id,
      seq: seq,
      eventLit: eventLit,
      eewActive: eewActive,
      badgeIcons: badgeIcons,
    ),
  ) as String?;

  /// Sets the station directory every later [encode] places frames against.
  /// Requests are handled in the order they are sent, so an [encode] sent
  /// after this sees this directory.
  void placeStations(Map<String, SeismicStation> stations) {
    if (!_stopped.isCompleted) _requests.send((stations: stations));
  }

  Future<Object?> _request(Object Function(int id) message) {
    if (_stopped.isCompleted) return Future.error(const RtsWorkerGone());
    final id = _nextId++;
    final reply = Completer<Object?>();
    _pending[id] = reply;
    _requests.send(message(id));
    return reply.future;
  }

  void _stop() {
    if (_stopped.isCompleted) return;
    _replies.close();
    final pending = _pending.values.toList();
    _pending.clear();
    for (final reply in pending) {
      reply.completeError(const RtsWorkerGone());
    }
    _stopped.complete();
  }

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
    _stop();
  }
}

/// Decodes one payload-event frame as the TREM stream sends it — base64 over
/// gzip over UTF-8 JSON — or null for a frame with no payload. The same steps
/// the stream source takes when it decodes on the UI isolate.
Rts? decodeRtsPayload(String payload) {
  final bytes = gzip.decode(base64.decode(payload.trim()));
  if (bytes.isEmpty) return null;
  return decodeRtsJson(bytes);
}

/// Parses an inflated frame straight from its UTF-8 bytes. The fused decoder
/// is the pair `jsonDecode` itself uses on a byte input, so the map handed to
/// [Rts.fromJson] is shape-for-shape what `jsonDecode` builds from a string;
/// it just never builds the string.
Rts decodeRtsJson(List<int> utf8Json) =>
    Rts.fromJson(_utf8Json.convert(utf8Json) as Map<String, dynamic>);

/// Fused once; `fuse` builds a new converter object per call.
final Converter<List<int>, Object?> _utf8Json = const Utf8Decoder().fuse(
  const JsonDecoder(),
);

void _main(SendPort replies) {
  final requests = ReceivePort();
  final frames = _HeldFrames();
  var stations = const <String, SeismicStation>{};
  var nextSeq = 0;
  requests.listen((message) {
    switch (message) {
      case (stations: final Map<String, SeismicStation> directory):
        stations = directory;
      case (id: final int id, payload: final String payload):
        _answer(replies, id, () {
          final frame = decodeRtsPayload(payload);
          if (frame == null) return null;
          final seq = nextSeq++;
          frames.add(seq, frame);
          return (seq: seq, frame: frame);
        });
      case (
        id: final int id,
        seq: final int seq,
        eventLit: final bool eventLit,
        eewActive: final bool eewActive,
        badgeIcons: final List<String> badgeIcons,
      ):
        _answer(replies, id, () {
          final frame = frames.take(seq);
          if (frame == null) return null;
          return encodeRtsStationGeoJson(
            frame.stations,
            stations,
            eventLit: eventLit,
            eewActive: eewActive,
            badgeIcons: badgeIcons,
          );
        });
    }
  });
  replies.send(requests.sendPort);
}

/// The frames the worker keeps to build the station layer from: the newest
/// few it decoded, and the one it last built.
///
/// The monitor asks for the frame its feed last published, which the feed
/// polls once a second from frames arriving twice a second — one or two
/// behind the newest at most, so a few cover it. The last-built frame is kept
/// apart because a repaint without new data (an alert arriving, the map
/// coming back into view) asks for it again however long the feed has been
/// quiet or busy since. Anything older answers null and the monitor builds
/// that one itself.
final class _HeldFrames {
  static const int _recent = 4;

  final Map<int, Rts> _frames = {};
  int? _builtSeq;
  Rts? _built;

  void add(int seq, Rts frame) {
    _frames[seq] = frame;
    if (_frames.length > _recent) _frames.remove(_frames.keys.first);
  }

  Rts? take(int seq) {
    final frame = _frames[seq] ?? (seq == _builtSeq ? _built : null);
    if (frame != null) {
      _builtSeq = seq;
      _built = frame;
    }
    return frame;
  }
}

/// Sends what [work] returns as the reply to request [id], or what it threw.
void _answer(SendPort replies, int id, Object? Function() work) {
  final Object? reply;
  try {
    reply = work();
  } catch (error, stackTrace) {
    replies.send((id: id, error: '$error', stack: '$stackTrace'));
    return;
  }
  replies.send((id: id, reply: reply));
}
