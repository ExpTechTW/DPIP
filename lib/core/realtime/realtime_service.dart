import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/server_clock.dart';

/// Composition root for the realtime spine: owns the shared [ServerClock] and
/// the registry of channels, and fans app lifecycle transitions out to them.
///
/// Flutter-free, so lifecycle behaviour is tested by calling [onForeground] /
/// [onBackground] directly (the `AppLifecycleListener` adapter lives in
/// `realtime_lifecycle.dart`).
class RealtimeService {
  RealtimeService(this._clock);

  final ServerClock _clock;
  final List<RealtimeChannelBase> _channels = [];

  /// The shared corrected clock (also each channel's injected `Clock`).
  ServerClock get clock => _clock;

  /// Registers a channel to receive lifecycle events. Call before [startAll].
  void register(RealtimeChannelBase channel) => _channels.add(channel);

  /// Starts every registered channel (call after the first frame).
  void startAll() {
    for (final channel in _channels) {
      channel.start();
    }
  }

  /// App went to background: pause every channel (stop polling, keep state).
  void onBackground() {
    for (final channel in _channels) {
      channel.pause();
    }
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
  }

  /// Disposes every channel.
  void dispose() {
    for (final channel in _channels) {
      channel.dispose();
    }
    _channels.clear();
  }
}
