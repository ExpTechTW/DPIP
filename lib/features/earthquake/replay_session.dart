/// Assembles a 重播 (replay) session's realtime channels.
///
/// The presentation layer can't import `data/` directly (the layering gate
/// forbids it — presentation depends on domain, not data), so this factory
/// lives at the feature root instead, mirroring how [earthquakeProviders]
/// assembles the live channels.
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/replay_clock.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/data/eew_replay_source.dart';
import 'package:dpip/features/earthquake/data/rts_replay_source.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/presentation/eew_realtime_controller.dart';
import 'package:dpip/features/earthquake/presentation/rts_realtime_controller.dart';

/// A running RTS + EEW replay: two **page-scoped** [RealtimeChannel]s (never
/// the shared live ones — see `ReportReplayPage`, which owns exactly one of
/// these per visit and disposes it on the way out) plus the [ReplayClock]
/// driving them, bundled so a caller only owns one object.
class ReplaySession {
  ReplaySession._(
    this.clock,
    this.rts,
    this.eew,
    this._rtsChannel,
    this._eewChannel,
  );

  /// Builds a session replaying from [replayTimestamp] (Unix ms) at 1x speed.
  factory ReplaySession(
    ApiClient apiClient,
    Clock serverClock,
    int replayTimestamp,
  ) {
    final api = EarthquakeApi(apiClient);
    final clock = ReplayClock(
      DateTime.fromMillisecondsSinceEpoch(replayTimestamp, isUtc: true),
    );
    final rtsChannel = RealtimeChannel<Rts>(
      source: RtsReplaySource(api, clock),
      clock: serverClock,
      elapsed: SystemElapsed(),
      ticker: const SystemTicker(),
      config: RealtimeConfig.rts,
      label: 'rts-replay',
    );
    final eewChannel = RealtimeChannel<List<Eew>>(
      source: EewReplaySource(api, clock),
      clock: serverClock,
      elapsed: SystemElapsed(),
      ticker: const SystemTicker(),
      config: RealtimeConfig.eew,
      label: 'eew-replay',
    );
    return ReplaySession._(
      clock,
      RtsRealtimeController(rtsChannel),
      EewRealtimeController(eewChannel),
      rtsChannel,
      eewChannel,
    );
  }

  /// Ticks 1:1 with real time from the replay's start instant.
  final ReplayClock clock;

  final RtsRealtimeController rts;
  final EewRealtimeController eew;
  final RealtimeChannel<Rts> _rtsChannel;
  final RealtimeChannel<List<Eew>> _eewChannel;

  /// Begins polling both feeds.
  void start() {
    _rtsChannel.start();
    _eewChannel.start();
  }

  /// Stops polling and releases both channels — call exactly once, when the
  /// replay page is popped.
  /// Stops the polling while the app is backgrounded.
  ///
  /// These channels are built raw — deliberately outside [RealtimeService], so
  /// a replay can't be mistaken for a live feed — which also means the
  /// service's lifecycle pause never reaches them: backgrounding mid-replay
  /// left two network polls a second running for as long as the OS let the
  /// process live. The replay clock keeps ticking on purpose, so a resumed
  /// replay rejoins its timeline instead of freezing where it was left.
  void pause() {
    _rtsChannel.pause(releaseTransport: true);
    _eewChannel.pause(releaseTransport: true);
  }

  /// Restarts the polling on foreground. Idempotent, like the channels' own
  /// resume — the lifecycle listener fires `onResume` after a mere `inactive`
  /// (notification shade) with no preceding pause.
  void resume() {
    _rtsChannel.resume();
    _eewChannel.resume();
  }

  void dispose() {
    rts.dispose();
    eew.dispose();
    _rtsChannel.dispose();
    _eewChannel.dispose();
  }
}
