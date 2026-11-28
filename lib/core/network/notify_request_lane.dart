/// The one way to the notify backend's rate-limited routes: a request at a
/// time, never closer together than the server accepts.
library;

import 'dart:async';
import 'dart:collection';

/// Sends every request that shares the notify backend's per-IP rate limit one
/// at a time, and at least [spacing] apart.
///
/// notify-server-go keeps one limiter per client address for `/v2/location`
/// and for the `/v2/notify/{token}…` routes (`IPRateLimiter` in its
/// `internal/httpapi/httpapi.go`): a request that arrives less than a second
/// after the one before it, or is the 21st inside a minute, is answered 429.
/// Each of the app's senders throttles itself, but nothing kept two of them out
/// of the same second — and when the one refused was a location report, the
/// fix was gone, and alerts went on being sent for the township the device had
/// left. So the senders share this lane instead of each keeping its own
/// distance:
///
/// - **One in flight.** The next request starts only when the previous one has
///   answered or failed, in the order they arrived.
/// - **[spacing] from the previous request's end**, and so from its start too.
///   The server counts arrivals, and a request whose upload was slow arrives
///   late; the next one, timed from the first one's start, could then land
///   inside the same second. Timed from its end, the first has certainly
///   arrived.
/// - **No wait when idle.** A request with nothing before it inside [spacing]
///   starts at once.
///
/// The minute budget is not counted here: at [minSpacing], 20 requests take 22
/// seconds of nothing else, and no sender produces that — a location report a
/// minute at most, a registration a day, settings only as fast as somebody taps
/// them.
///
/// Requests made outside Dart do not pass through it: the native background
/// reporters, which run while no isolate does, and other devices behind the
/// same address. A 429 from either is a failure like any other, and each sender
/// retries its own.
class NotifyRequestLane {
  NotifyRequestLane({
    this.spacing = minSpacing,
    Duration Function()? elapsed,
    Future<void> Function(Duration wait)? delay,
  }) : _elapsed = elapsed ?? _stopwatch(),
       _delay = delay ?? Future<void>.delayed;

  /// The server's limit is one request a second per address, and twenty a
  /// minute (`IPMinInterval`, `IPMaxRequests` and `IPWindow` in
  /// notify-server-go). The extra tenth of a second is margin for the server's
  /// millisecond clock and the time between a response and the next start.
  static const Duration minSpacing = Duration(milliseconds: 1100);

  /// The least time between one request's end and the next one's start.
  final Duration spacing;

  /// A monotonic clock: the gap is between two of this lane's own moments, so
  /// neither calibrated nor wall time applies, and a clock change must not
  /// stretch or skip it.
  final Duration Function() _elapsed;

  /// Waits; must advance [_elapsed] by at least the duration it is given.
  final Future<void> Function(Duration wait) _delay;

  final Queue<_Request<Object?>> _waiting = Queue<_Request<Object?>>();
  bool _draining = false;
  Duration? _lastEnded;

  static Duration Function() _stopwatch() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  /// Runs [request] in its turn and completes with what it returns or throws.
  Future<T> run<T>(Future<T> Function() request) {
    final entry = _Request<T>(request);
    _waiting.add(entry);
    if (!_draining) {
      _draining = true;
      unawaited(_drain());
    }
    return entry.done.future;
  }

  Future<void> _drain() async {
    try {
      while (_waiting.isNotEmpty) {
        final ended = _lastEnded;
        if (ended != null) {
          final wait = ended + spacing - _elapsed();
          if (wait > Duration.zero) {
            await _delay(wait);
            continue;
          }
        }
        await _waiting.removeFirst().send();
        _lastEnded = _elapsed();
      }
    } finally {
      _draining = false;
    }
  }
}

class _Request<T> {
  _Request(this._request);

  final Future<T> Function() _request;
  final Completer<T> done = Completer<T>();

  /// Never throws: the outcome belongs to whoever is waiting on [done].
  Future<void> send() async {
    try {
      done.complete(await _request());
    } catch (error, stackTrace) {
      done.completeError(error, stackTrace);
    }
  }
}
