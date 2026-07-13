import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_source.dart';

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
/// factory and liveness policy come through the constructor. A future
/// continuous feed (RTS) reuses this with [SseLiveness.eventRecency].
abstract class SseRealtimeSource<T> extends RealtimeSource<T> {
  SseRealtimeSource({
    required this._connect,
    this._liveness = const SseLiveness.connectionOpen(),
    Elapsed? elapsed,
    Future<void> Function(Duration delay)? delay,
    this._label = 'sse',
  }) : _elapsed = elapsed ?? SystemElapsed(),
       _delay = delay ?? _defaultDelay;

  static Future<void> _defaultDelay(Duration d) => Future<void>.delayed(d);

  /// Opens a fresh SSE connection; called once lazily and again per reconnect.
  final Stream<SseEvent> Function() _connect;
  final SseLiveness _liveness;
  final Elapsed _elapsed;
  final Future<void> Function(Duration delay) _delay;
  final String _label;

  /// The default server reconnect hint, refined by any `retry:` frame.
  Duration _serverRetry = const Duration(seconds: 3);

  StreamSubscription<SseEvent>? _subscription;
  bool _started = false;
  bool _connected = false;
  bool _hasSnapshot = false;
  bool _disposed = false;
  int _attempt = 0;
  T? _latest;
  Duration? _lastEventMark;

  /// Decodes a default-event `data:` payload into `T`. The payload is the same
  /// JSON the one-shot GET returns, so this mirrors the repository's mapping.
  T decode(String data);

  @override
  Future<Result<T>> fetch() async {
    if (_disposed) {
      return const Err(NetworkFailure('SSE source disposed'));
    }
    _ensureStarted();
    if (_connected && _hasSnapshot && _isFresh) {
      return Ok(_latest as T);
    }
    return Err(NetworkFailure('$_label SSE not connected'));
  }

  /// Whether the buffered payload counts as fresh under the liveness policy.
  bool get _isFresh {
    final window = _liveness.window;
    if (window == null) return true; // connection-open liveness
    final mark = _lastEventMark;
    return mark != null && (_elapsed.elapsed - mark) <= window;
  }

  void _ensureStarted() {
    if (_started || _disposed) return;
    _started = true;
    _openConnection();
  }

  void _openConnection() {
    if (_disposed) return;
    _connected = false;
    _hasSnapshot = false;
    _subscription = _connect().listen(
      _onEvent,
      onError: (Object error, StackTrace stackTrace) {
        Log.warning('[$_label] SSE connection error: $error');
        _onClosed();
      },
      onDone: _onClosed,
      cancelOnError: true,
    );
  }

  void _onEvent(SseEvent event) {
    if (_disposed) return;
    _connected = true;
    _attempt = 0; // the connection is delivering — reset the backoff
    final retry = event.retry;
    if (retry != null) _serverRetry = retry;
    // A payload arrives either as the default event (plain JSON) or, under the
    // `compress=1` flag, as `event: g` whose data is base64-gzipped JSON —
    // decompressed here at the application layer.
    if (event.name == _compressedEvent || event.isDefault) {
      try {
        final json = event.name == _compressedEvent
            ? utf8.decode(gzip.decode(base64.decode(event.data.trim())))
            : event.data;
        if (json.isEmpty) return; // metadata-only frame, not a payload
        _latest = decode(json);
        _hasSnapshot = true;
        _lastEventMark = _elapsed.elapsed;
      } catch (error, stackTrace) {
        // One bad frame must not kill the connection; keep the last good data.
        Log.handle(error, stackTrace, '[$_label] SSE decode');
      }
    } else if (event.name == 'info') {
      Log.debug('[$_label] SSE served by ${event.data}');
    }
  }

  /// ExpTech's `compress=1` streams the payload as `event: g` (base64 gzip).
  static const String _compressedEvent = 'g';

  void _onClosed() {
    _subscription = null;
    _connected = false;
    _hasSnapshot = false;
    if (_disposed) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    final delay = _backoffDelay();
    _attempt++;
    _delay(delay).then((_) {
      if (!_disposed) _openConnection();
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
    _subscription?.cancel();
    _subscription = null;
  }
}
