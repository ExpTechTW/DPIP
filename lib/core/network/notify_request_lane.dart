/// The one way to the notify backend's rate-limited routes: a request at a
/// time, never closer together than the server accepts.
library;

import 'dart:async';
import 'dart:collection';

/// Which of two waiting requests to the notify backend goes first.
enum NotifyRequestPriority {
  /// Location reports, device registration and the notify settings: what
  /// decides where this device's alerts go, or what somebody is waiting on.
  device,

  /// The Live Activity token report. Nothing waits on it, so it goes behind
  /// every [device] request — queued, or held for with
  /// [NotifyRequestLane.holdDeferred].
  deferred,
}

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
///   answered or failed.
/// - **[spacing] from the previous request's end**, and so from its start too.
///   The server counts arrivals, and a request whose upload was slow arrives
///   late; the next one, timed from the first one's start, could then land
///   inside the same second. Timed from its end, the first has certainly
///   arrived.
/// - **No wait when idle.** A request with nothing before it inside [spacing]
///   starts at once.
/// - **Device requests first.** Whenever both are waiting, every
///   [NotifyRequestPriority.device] request goes before any
///   [NotifyRequestPriority.deferred] one, and in arrival order within each.
///   The pick is made when the lane is free to start the next request, so a
///   device request that arrives while a deferred one waits out the spacing
///   still goes first.
/// - **Held for a device request on its way.** Waiting in the queue is not
///   enough on its own: a location report spends seconds on a GPS fix before
///   it has a request to queue, and a deferred request that arrives meanwhile
///   would find the lane idle. [holdDeferred] covers that time: while any
///   hold is open, deferred requests wait. A hold never delays a device
///   request, so one that never ends costs the deferred requests of this run
///   and nothing else.
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

  final Queue<_Request<Object?>> _device = Queue<_Request<Object?>>();
  final Queue<_Request<Object?>> _deferred = Queue<_Request<Object?>>();
  int _holds = 0;
  bool _draining = false;
  Duration? _lastEnded;

  static Duration Function() _stopwatch() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  /// Runs [request] in its turn and completes with what it returns or throws.
  Future<T> run<T>(
    Future<T> Function() request, {
    NotifyRequestPriority priority = NotifyRequestPriority.device,
  }) {
    final entry = _Request<T>(request);
    switch (priority) {
      case NotifyRequestPriority.device:
        _device.add(entry);
      case NotifyRequestPriority.deferred:
        _deferred.add(entry);
    }
    _kick();
    return entry.done.future;
  }

  /// Runs [prepare] — work that is about to end in a device request, such as
  /// getting the fix a location report needs — and keeps every deferred
  /// request waiting until it has finished, so none takes the lane first.
  ///
  /// Taken the moment it is called. Device requests are never held.
  Future<T> holdDeferred<T>(Future<T> Function() prepare) async {
    _holds++;
    try {
      return await prepare();
    } finally {
      _holds--;
      if (_holds == 0) _kick();
    }
  }

  void _kick() {
    if (_draining) return;
    _draining = true;
    unawaited(_drain());
  }

  /// The queue the next request comes from, or null when nothing may start.
  Queue<_Request<Object?>>? get _next {
    if (_device.isNotEmpty) return _device;
    if (_deferred.isNotEmpty && _holds == 0) return _deferred;
    return null;
  }

  Future<void> _drain() async {
    try {
      for (var next = _next; next != null; next = _next) {
        final ended = _lastEnded;
        if (ended != null) {
          final wait = ended + spacing - _elapsed();
          if (wait > Duration.zero) {
            // Whatever arrives meanwhile is weighed again before anything
            // starts.
            await _delay(wait);
            continue;
          }
        }
        await next.removeFirst().send();
        _lastEnded = _elapsed();
      }
    } finally {
      // A held deferred request is picked up by the hold's end.
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
