import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/ticker.dart';

/// Composition root for the realtime spine: owns the shared [ServerClock] and
/// the registry of channels, fans app lifecycle transitions out to them, and
/// keeps the clock calibrated with a periodic background NTP resync.
///
/// Flutter-free, so lifecycle behaviour is tested by calling [onForeground] /
/// [onBackground] directly (the `AppLifecycleListener` adapter lives in
/// `realtime_lifecycle.dart`) and the resync cadence via an injected [Ticker].
class RealtimeService {
  RealtimeService(
    this._clock, {
    this._ticker = const SystemTicker(),
    this._clockSyncInterval = const Duration(seconds: 60),
  });

  final ServerClock _clock;
  final Ticker _ticker;
  final Duration _clockSyncInterval;
  final List<RealtimeChannelBase> _channels = [];

  TickerHandle? _clockSyncHandle;

  /// The shared corrected clock (also each channel's injected `Clock`).
  ServerClock get clock => _clock;

  /// Registers a channel to receive lifecycle events. Call before [startAll].
  void register(RealtimeChannelBase channel) => _channels.add(channel);

  /// Starts every registered channel and the periodic clock resync (call after
  /// the first frame). The initial sync is kicked off at bootstrap; the ticker
  /// then re-anchors every [_clockSyncInterval].
  void startAll() {
    for (final channel in _channels) {
      channel.start();
    }
    _startClockSync();
  }

  /// App went to background: pause every channel (stop polling, keep state) and
  /// halt the resync ticker to save battery. (On iOS the process is suspended
  /// anyway; [onForeground] re-anchors on return.)
  void onBackground() {
    for (final channel in _channels) {
      channel.pause();
    }
    _stopClockSync();
  }

  /// App returned to foreground. Order is the anti-"stale-as-live" property:
  /// recompute status on **all** channels synchronously (so an aged background
  /// snapshot flips to stale/offline immediately), then resume polling — all
  /// before any `await`, so a quick re-background can't leave the loop running
  /// and a slow clock sync can't stall the resume. The clock resync is
  /// fire-and-forget because EEW staleness is monotonic and offset-independent;
  /// the offset only refines payload-timestamped feeds.
  void onForeground() {
    for (final channel in _channels) {
      channel.recomputeStatus();
    }
    for (final channel in _channels) {
      channel.resume();
    }
    _clock.sync().ignore();
    _startClockSync();
  }

  /// Disposes every channel and stops the resync ticker.
  void dispose() {
    _stopClockSync();
    for (final channel in _channels) {
      channel.dispose();
    }
    _channels.clear();
  }

  void _startClockSync() {
    _clockSyncHandle ??= _ticker.start(
      _clockSyncInterval,
      () => _clock.sync().ignore(),
    );
  }

  void _stopClockSync() {
    _clockSyncHandle?.cancel();
    _clockSyncHandle = null;
  }
}
