import 'dart:async';

/// A repeating time signal, behind a seam so the poll cadence is testable.
///
/// Production uses [SystemTicker] (a `Timer.periodic`). Tests inject a fake
/// whose `fire()` advances time deterministically, so poll/staleness scenarios
/// run under `flutter test` with no real clock and no waiting.
abstract interface class Ticker {
  /// Starts calling [onTick] every [interval] until the returned handle is
  /// cancelled.
  TickerHandle start(Duration interval, void Function() onTick);
}

/// Cancels a running [Ticker].
abstract interface class TickerHandle {
  void cancel();
}

/// A [Ticker] backed by `Timer.periodic`.
class SystemTicker implements Ticker {
  const SystemTicker();

  @override
  TickerHandle start(Duration interval, void Function() onTick) =>
      _SystemTickerHandle(Timer.periodic(interval, (_) => onTick()));
}

class _SystemTickerHandle implements TickerHandle {
  _SystemTickerHandle(this._timer);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}
