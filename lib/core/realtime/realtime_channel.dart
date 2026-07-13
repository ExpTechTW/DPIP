import 'dart:async';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/realtime/staleness.dart';
import 'package:dpip/core/realtime/ticker.dart';

/// The lifecycle surface a [RealtimeService] drives without knowing the payload
/// type `T`, so channels of different types share one background/foreground
/// fan-out.
abstract interface class RealtimeChannelBase {
  /// Begins polling (idempotent). Emits the initial `connecting` state.
  void start();

  /// Stops polling, discards any in-flight fetch, and keeps the last state
  /// (e.g. app backgrounded).
  void pause();

  /// Resumes polling: recomputes status immediately, then refetches.
  void resume();

  /// Recomputes freshness against the clock without a network call — the
  /// synchronous "flip a background snapshot to stale before any await" step.
  void recomputeStatus();

  /// Forces an immediate poll, completing when a poll result has landed.
  Future<void> refreshNow();

  /// Cancels polling and closes the stream.
  void dispose();
}

/// Polls one [RealtimeSource] on a fixed cadence and exposes its freshness as a
/// broadcast [Stream] of [RealtimeState].
///
/// Design guarantees:
/// - **One poll loop per channel**: any number of listeners share a single GET
///   per tick (the broadcast controller fans out).
/// - **Single in-flight fetch**: a slow poll cannot stack or reorder requests;
///   [refreshNow] awaits the one already running rather than starting another.
/// - **Never blanks on failure**: a failed poll keeps the last [data]; status
///   is recomputed purely from elapsed time, so the feed ages live→stale→
///   offline on its own.
/// - **Monotonic freshness**: staleness is measured with a monotonic [Elapsed],
///   so a device-clock jump or [ServerClock] resync can never reclassify a dead
///   feed as live.
/// - **Discards pre-pause fetches**: a fetch that was in flight across a
///   background cycle is dropped by an epoch guard, so a stale result can't
///   re-flip the feed to live after [resume].
/// - **Emit once per real transition**: a new state is pushed only when the
///   observable status or payload changes, not on every 1 Hz poll.
class RealtimeChannel<T> implements RealtimeChannelBase {
  RealtimeChannel({
    required this._source,
    required this._clock,
    required Elapsed elapsed,
    required this._ticker,
    required this._config,
    this._label = 'realtime',
  }) : _elapsed = elapsed,
       _startMark = elapsed.elapsed;

  final RealtimeSource<T> _source;

  /// Wall clock (a [ServerClock] in production): used only for the display
  /// timestamp and for aging a payload's own timestamp — never for the
  /// safety-critical status, which is monotonic.
  final Clock _clock;

  /// Monotonic source the status is measured against.
  final Elapsed _elapsed;

  final Ticker _ticker;
  final RealtimeConfig _config;
  final String _label;

  final StreamController<RealtimeState<T>> _controller =
      StreamController<RealtimeState<T>>.broadcast();

  RealtimeState<T> _current = RealtimeState<T>.connecting();

  /// Monotonic reading when polling last (re)started — the connect-grace base.
  Duration _startMark;

  /// Monotonic reading at the last successful fetch, or null if none yet.
  Duration? _lastSuccessMark;

  /// The data's age at that last successful fetch (zero for fetch-freshness
  /// feeds like EEW; `serverNow − payloadTime` for payload-timestamped feeds).
  Duration? _ageBase;

  /// Bumped whenever polling is invalidated (pause/dispose), so a fetch that
  /// completes after the fact is discarded instead of applied.
  int _epoch = 0;

  bool _fetching = false;
  Future<void>? _inFlight;
  bool _disposed = false;
  TickerHandle? _tickerHandle;

  /// The freshness stream — broadcast; emits only on an observable change.
  Stream<RealtimeState<T>> get states => _controller.stream;

  /// The latest state, always current. Used to seed late subscribers without
  /// replay machinery.
  RealtimeState<T> get state => _current;

  @override
  void start() {
    if (_disposed || _tickerHandle != null) return;
    _startMark = _elapsed.elapsed;
    _publish(); // emit the connecting seed
    _tickerHandle = _ticker.start(_config.pollInterval, _onTick);
    unawaited(_fetch());
  }

  @override
  void pause() {
    _epoch++; // invalidate any in-flight fetch
    _fetching = false;
    _inFlight = null;
    _tickerHandle?.cancel();
    _tickerHandle = null;
  }

  @override
  void resume() {
    if (_disposed) return;
    _startMark = _elapsed.elapsed;
    _recompute(); // flip an aged snapshot to stale/offline before refetching
    _tickerHandle ??= _ticker.start(_config.pollInterval, _onTick);
    unawaited(_fetch());
  }

  @override
  void recomputeStatus() => _recompute();

  @override
  Future<void> refreshNow() async {
    _recompute();
    await _fetch();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _tickerHandle?.cancel();
    _tickerHandle = null;
    _source.dispose(); // release a connection-holding source (e.g. SSE)
    _controller.close();
  }

  void _onTick() {
    _recompute();
    unawaited(_fetch());
  }

  Duration? get _age {
    final base = _ageBase;
    final mark = _lastSuccessMark;
    if (base == null || mark == null) return null;
    return base + (_elapsed.elapsed - mark);
  }

  RealtimeStatus _classify() => classifyStatus(
    age: _age,
    sinceStart: _elapsed.elapsed - _startMark,
    staleAfter: _config.staleAfter,
    offlineAfter: _config.offlineAfter,
  );

  /// Recomputes status from elapsed time only (no network) and emits on change.
  void _recompute() {
    if (_disposed) return;
    final status = _classify();
    if (status != _current.status) {
      _current = _current.copyWith(status: status);
      _publish();
    }
  }

  /// Starts a poll if none is running, else returns the one in flight — so
  /// [refreshNow] always resolves after a result has been folded in.
  Future<void> _fetch() {
    if (_disposed) return Future<void>.value();
    if (_fetching) return _inFlight ?? Future<void>.value();
    _fetching = true;
    final epoch = _epoch;
    return _inFlight = _runFetch(epoch);
  }

  Future<void> _runFetch(int epoch) async {
    try {
      final result = await _source.fetch();
      if (_disposed || epoch != _epoch) return; // paused/disposed mid-flight
      switch (result) {
        case Ok(:final value):
          final now = _clock.now();
          final payloadTime = _source.timestampOf(value);
          _ageBase = payloadTime == null
              ? Duration.zero
              : now.difference(payloadTime);
          _lastSuccessMark = _elapsed.elapsed;
          final status = _classify();
          final changed =
              status != _current.status ||
              !_source.sameData(value, _current.data);
          _current = RealtimeState<T>(
            status: status,
            data: value,
            dataTime: payloadTime ?? now,
            fetchedAt: now,
            consecutiveFailures: 0,
          );
          if (changed) _publish();
        case Err(:final failure):
          final status = _classify();
          final changed = status != _current.status;
          _current = _current.copyWith(
            status: status,
            lastFailure: failure,
            consecutiveFailures: _current.consecutiveFailures + 1,
          );
          Log.warning(
            '[$_label] poll failed '
            '(${_current.consecutiveFailures}×): ${failure.message}',
          );
          if (changed) _publish();
      }
    } catch (error, stackTrace) {
      if (!_disposed && epoch == _epoch) {
        Log.handle(error, stackTrace, '[$_label] poll');
      }
    } finally {
      if (epoch == _epoch) {
        _fetching = false;
        _inFlight = null;
      }
    }
  }

  void _publish() {
    if (_disposed || _controller.isClosed) return;
    _controller.add(_current);
  }
}
