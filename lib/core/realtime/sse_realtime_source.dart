import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:flutter/foundation.dart' show protected;

/// How a source decides an SSE feed is currently "alive", given that a poll
/// channel measures freshness from the last successful [RealtimeSource.fetch].
enum SseLivenessMode {
  /// The connection being **open** is the liveness signal, independent of event
  /// recency. For a **bursty** feed that is silent between events (EEW sends
  /// nothing between earthquakes), so a quiet-but-connected feed is correctly
  /// `live` (connected, no alert) rather than aging to offline on silence.
  connectionOpen,

  /// A **recent event** is the liveness signal: `fetch` returns `Err` once no
  /// event has arrived within the window, so the channel can age a frozen feed.
  /// For a **continuous** feed (RTS streams ~1 Hz) whose silence means trouble.
  eventRecency,
}

/// Liveness policy for [SseRealtimeSource]: a [SseLivenessMode] plus the window
/// used by [SseLivenessMode.eventRecency].
class SseLiveness {
  const SseLiveness.connectionOpen()
    : mode = SseLivenessMode.connectionOpen,
      window = null;

  const SseLiveness.eventRecency(Duration this.window)
    : mode = SseLivenessMode.eventRecency;

  final SseLivenessMode mode;

  /// The recency window for [SseLivenessMode.eventRecency]; null otherwise.
  final Duration? window;
}

/// A [RealtimeSource] whose transport is a Server-Sent Events connection,
/// adapting a **push** stream to the spine's **poll** seam so the channel,
/// state model, staleness classifier, and lifecycle are all reused unchanged.
///
/// How it bridges push → poll: the source holds one long-lived SSE connection
/// and buffers the latest decoded payload. [fetch] (called by the channel each
/// tick) returns that buffer while the feed is [_alive], or an [Err] while
/// disconnected/reconnecting — so the channel ages the feed live→stale→offline
/// with exactly the same monotonic logic it uses for failed HTTP polls. The
/// connection opens lazily on the first [fetch] and reconnects on drop with a
/// bounded backoff (capped at the server's `retry:` hint); the data format is
/// whatever [decode] parses from each event's `data:`, i.e. the same JSON the
/// one-shot GET returns.
///
/// Subclasses supply the feed specifics ([decode] plus
/// [RealtimeSource.timestampOf]/[RealtimeSource.sameData]); the connection
/// factory, liveness policy and payload event name come through the
/// constructor. A continuous feed (RTS) uses [SseLiveness.eventRecency].
abstract class SseRealtimeSource<T> extends RealtimeSource<T> {
  SseRealtimeSource({
    required this._connect,
    this._liveness = const SseLiveness.connectionOpen(),
    Elapsed? elapsed,
    Future<void> Function(Duration delay)? delay,
    this._label = 'sse',
    this._payloadEvent = 'g',
  }) : _elapsed = elapsed ?? SystemElapsed(),
       _delay = delay ?? _defaultDelay;

  static Future<void> _defaultDelay(Duration d) => Future<void>.delayed(d);

  /// Opens a fresh SSE connection; called once lazily and again per reconnect.
  final Stream<SseEvent> Function() _connect;
  final SseLiveness _liveness;
  final Elapsed _elapsed;
  final Future<void> Function(Duration delay) _delay;
  final String _label;

  /// The event name whose `data:` is a base64-gzipped payload: `g` under the
  /// LB feeds' `compress=1`, the topic itself (`trem.rts.v1`) on the TREM
  /// stream, which compresses every topic frame and names each for its topic.
  final String _payloadEvent;

  /// The default server reconnect hint, refined by any `retry:` frame.
  Duration _serverRetry = const Duration(seconds: 3);

  StreamSubscription<SseEvent>? _subscription;

  /// The connection [renew] opened, until it speaks and takes over.
  StreamSubscription<SseEvent>? _pending;
  bool _started = false;
  bool _connected = false;
  bool _hasSnapshot = false;
  bool _disposed = false;
  bool _paused = false;

  /// Bumped whenever the connection lifecycle is torn down, so a reconnect that
  /// belongs to an older lifecycle cannot open a socket for the new one.
  ///
  /// A backoff is an un-cancellable pending future, and [pause] does not
  /// outlive it: background and foreground can both happen inside one backoff
  /// window, leaving the stale timer *and* the re-armed lazy open both live.
  /// Both would then call [_openConnection], which assigns [_subscription]
  /// unconditionally — so the first connection would be orphaned, still
  /// subscribed, still receiving, with nothing left holding a reference to
  /// cancel it. That is a leaked socket per background cycle.
  int _generation = 0;
  int _attempt = 0;
  T? _latest;
  Duration? _lastEventMark;

  /// Decodes a default-event `data:` payload into `T`. The payload is the same
  /// JSON the one-shot GET returns, so this mirrors the repository's mapping.
  T decode(String data);

  /// Decodes an inflated `compress=1` payload — the same JSON as [decode]'s
  /// argument, still as UTF-8 bytes.
  ///
  /// Default: materialise the string and hand it to [decode], which is what
  /// every source did before this hook existed. A source whose payload is
  /// large and continuous (RTS, ~1000 stations at 1 Hz) overrides it to parse
  /// the bytes directly with `Utf8Decoder.fuse(JsonDecoder)`: `dart:convert`
  /// then walks the UTF-8 once, instead of decoding it into a 60 KB `String`
  /// only to tokenise that string a second time. Same object graph out, one
  /// full copy of every frame fewer — on the UI isolate, every second.
  T decodeBytes(Uint8List utf8Json) => decode(utf8.decode(utf8Json));

  /// What a connected feed with nothing fresh to report stands for — or null
  /// (the default), when that silence is itself the fault the liveness policy
  /// exists to catch.
  ///
  /// A feed the server only speaks on when something happens (the TREM
  /// stream's sleep mode sends an RTS frame only while a station is alerting)
  /// returns its calm value here: its silence *is* the answer, and reading it
  /// as a dead feed would age a healthy connection to offline between events.
  T? get quiet => null;

  @override
  Future<Result<T>> fetch() async {
    if (_disposed) {
      return const Err(NetworkFailure('SSE source disposed'));
    }
    _ensureStarted();
    if (!_connected) return Err(NetworkFailure('$_label SSE not connected'));
    if (_hasSnapshot && _isFresh) return Ok(_latest as T);
    final quiet = this.quiet;
    if (quiet != null) return Ok(quiet);
    return Err(NetworkFailure('$_label SSE has nothing fresh'));
  }

  /// Whether the buffered payload counts as fresh under the liveness policy.
  bool get _isFresh {
    final window = _liveness.window;
    if (window == null) return true; // connection-open liveness
    final mark = _lastEventMark;
    return mark != null && (_elapsed.elapsed - mark) <= window;
  }

  /// Drops the connection for the duration of a background stint.
  ///
  /// Cancelling the subscription does not run [_onClosed] (a cancel raises no
  /// `onDone`), so this cannot start a reconnect of its own. A reconnect already
  /// in flight when this lands is harmless: its timer still fires, but
  /// [_openConnection] refuses while paused.
  @override
  void pause() {
    if (_disposed || _paused) return;
    _paused = true;
    _generation++; // orphan any backoff still counting down
    _pending?.cancel();
    _pending = null;
    _subscription?.cancel();
    _subscription = null;
    _connected = false;
    _hasSnapshot = false;
  }

  /// Re-arms the lazy open, so the channel's first post-resume `fetch` builds a
  /// fresh connection exactly the way the first one was built. The backoff is
  /// reset with it: a new foreground deserves the fast first retry, not whatever
  /// the connection had climbed to before the app was put away.
  @override
  void resume() {
    if (_disposed || !_paused) return;
    _paused = false;
    _started = false;
    _attempt = 0;
  }

  void _ensureStarted() {
    if (_started || _disposed || _paused) return;
    _started = true;
    _openConnection();
  }

  void _openConnection() {
    if (_disposed || _paused) return;
    _connected = false;
    _hasSnapshot = false;
    // A fresh connection reads the current parameters anyway, so a handover
    // still in flight has nothing left to deliver.
    _pending?.cancel();
    _pending = null;
    // Belt and braces: the generation guard should mean there is never a live
    // subscription here, but the assignment below would orphan one silently
    // rather than fail, and an orphaned SSE socket is exactly the kind of leak
    // this class exists to avoid.
    _subscription?.cancel();
    _subscription = _connect().listen(
      _onEvent,
      onError: _onError,
      onDone: _onClosed,
      cancelOnError: true,
    );
  }

  /// Swaps the connection for a fresh one without a gap — for a subclass whose
  /// connection parameters just changed (the RTS stream's mode).
  ///
  /// The new connection opens *alongside* the current one and takes over on
  /// its first frame (the server's greeting), so the feed never drops to
  /// nothing while the swap is in flight. If it fails before then, the swap
  /// falls back to an ordinary reconnect: the old connection still carries the
  /// old parameters, and keeping it would leave the change quietly unapplied.
  ///
  /// Before the first [fetch], or while paused, there is nothing to swap —
  /// the next open reads the new parameters on its own.
  @protected
  void renew() {
    if (_disposed || _paused || !_started) return;
    _pending?.cancel();
    final pending = _connect().listen(null, cancelOnError: true);
    _pending = pending;
    pending
      ..onData((event) {
        _pending = null;
        // A reconnect the old connection's loss had queued would only replace
        // this one.
        _generation++;
        _subscription?.cancel();
        _subscription = pending;
        pending
          ..onData(_onEvent)
          ..onError(_onError)
          ..onDone(_onClosed);
        _onEvent(event);
      })
      ..onError((Object error, StackTrace _) {
        Log.warning('[$_label] SSE handover failed: $error');
        _abandonHandover(pending);
      })
      ..onDone(() => _abandonHandover(pending));
  }

  void _abandonHandover(StreamSubscription<SseEvent> pending) {
    if (!identical(_pending, pending)) return;
    _pending = null;
    _generation++; // the reconnect below supersedes any already queued
    _subscription?.cancel();
    _onClosed();
  }

  void _onError(Object error, StackTrace _) {
    Log.warning('[$_label] SSE connection error: $error');
    _onClosed();
  }

  void _onEvent(SseEvent event) {
    if (_disposed) return;
    _connected = true;
    _attempt = 0; // the connection is delivering — reset the backoff
    final retry = event.retry;
    if (retry != null) _serverRetry = retry;
    // A payload arrives either as the default event (plain JSON) or as the
    // payload event, whose data is base64-gzipped JSON — decompressed here at
    // the application layer.
    if (event.name == _payloadEvent || event.isDefault) {
      try {
        // Metadata-only frames carry no payload: skipped before decoding on
        // either path, exactly as the empty-string check did.
        if (event.name == _payloadEvent) {
          final bytes = gzip.decode(base64.decode(event.data.trim()));
          if (bytes.isEmpty) return;
          _latest = decodeBytes(
            bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
          );
        } else {
          if (event.data.isEmpty) return;
          _latest = decode(event.data);
        }
        _hasSnapshot = true;
        _lastEventMark = _elapsed.elapsed;
      } catch (error, stackTrace) {
        // One bad frame must not kill the connection; keep the last good data.
        Log.handle(error, stackTrace, '[$_label] SSE decode');
      }
    } else if (event.name == 'info') {
      // The TREM stream's greeting lists what it would not grant under
      // `denied` — a topic this source is waiting on that will never arrive.
      if (event.data.contains('"denied"')) {
        Log.warning('[$_label] SSE refused a topic: ${event.data}');
      } else {
        Log.debug('[$_label] SSE served by ${event.data}');
      }
    } else if (event.name == 'unsubscribed' || event.name == 'close') {
      // The server says why it dropped a topic, or the stream, only here.
      Log.warning('[$_label] SSE ${event.name}: ${event.data}');
    }
  }

  void _onClosed() {
    _subscription = null;
    _connected = false;
    _hasSnapshot = false;
    if (_disposed) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    final delay = _backoffDelay();
    final generation = _generation;
    _attempt++;
    _delay(delay).then((_) {
      if (_disposed || generation != _generation) return;
      _openConnection();
    });
  }

  /// 1s, 2s, then capped at the server's `retry:` hint (default 3s). Reset to 1s
  /// whenever a connection delivers an event, so a transient blip recovers fast
  /// while a sustained outage does not hammer the server.
  Duration _backoffDelay() {
    final base = Duration(seconds: 1 << _attempt.clamp(0, 2));
    return base < _serverRetry ? base : _serverRetry;
  }

  @override
  void dispose() {
    _disposed = true;
    _pending?.cancel();
    _pending = null;
    _subscription?.cancel();
    _subscription = null;
  }
}
