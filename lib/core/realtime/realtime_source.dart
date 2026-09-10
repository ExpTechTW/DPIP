import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';

/// The transport + freshness-reference seam a [RealtimeChannel] polls.
///
/// One implementation per feed (EEW now, RTS later). Implementing this is the
/// only work a new feed needs — the channel, state model, lifecycle, and
/// staleness are all reused. A future WebSocket transport is just a different
/// implementation of [fetch]; nothing else in the spine changes.
abstract class RealtimeSource<T> {
  const RealtimeSource();

  /// Fetches the latest payload, mapping transport failures to a [Failure].
  Future<Result<T>> fetch();

  /// The payload's own freshness instant, or **null** to use fetch-freshness
  /// (staleness measured from the last successful fetch instead of a timestamp
  /// inside the payload). EEW returns null: its payload timestamp recedes within
  /// one active event, so feed-liveness is the right freshness signal.
  DateTime? timestampOf(T value);

  /// Whether two payloads are observably identical, used to suppress duplicate
  /// stream emissions. Defaults to value equality; override for collections
  /// whose default `==` is identity (e.g. `List`).
  bool sameData(T? a, T? b) => identical(a, b) || a == b;

  /// Whether a fetch failure means there is simply no data for the requested
  /// point in time, rather than a fault worth counting. The channel still
  /// records it as `lastFailure` — that is what a replay page reads to say the
  /// instant has no snapshot instead of calling itself disconnected — but does
  /// not count it toward `consecutiveFailures` and does not log it.
  ///
  /// **A noise switch, not a liveness one.** Freshness is unaffected either
  /// way: the channel ages its status from elapsed time alone, so a source that
  /// ignores every failure still goes stale and then offline on schedule and
  /// nothing here can present a dead feed as current.
  ///
  /// Only a replay source has cause to override it — it polls a fixed instant
  /// in the past, where "this far back is no longer retained" is an answer, not
  /// a fault. For a live feed every failure is a real one; leave this alone.
  bool isIgnorableFailure(Failure failure) => false;

  /// Drops any transport the source is holding open while the app is in the
  /// background, where nothing is watching the feed.
  ///
  /// A poll source needs nothing here: the channel simply stops calling [fetch],
  /// so it costs nothing while paused. A **connection-holding** source does not
  /// get that for free — an idle socket keeps the radio awake and keeps taking
  /// delivery of a continuous feed (RTS streams ~1 Hz) that no one will read.
  /// Overriding this is safe for the safety-critical feeds because background
  /// alerting is push's job, never the stream's.
  void pause() {}

  /// Re-opens whatever [pause] dropped. The channel calls this before its first
  /// post-resume [fetch], and a source that reconnects asynchronously simply
  /// answers `Err` until it is back — the same answer it gives on any reconnect,
  /// so the channel ages the feed with its ordinary logic.
  void resume() {}

  /// Releases any transport the source holds (e.g. an open SSE connection). A
  /// poll source is stateless per [fetch] and uses this no-op default; a
  /// connection-holding source (SSE) overrides it. The channel calls this from
  /// its own `dispose()`, so a source never outlives its channel.
  void dispose() {}
}
