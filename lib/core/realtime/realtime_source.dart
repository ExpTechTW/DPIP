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

  /// Releases any transport the source holds (e.g. an open SSE connection). A
  /// poll source is stateless per [fetch] and uses this no-op default; a
  /// connection-holding source (SSE) overrides it. The channel calls this from
  /// its own `dispose()`, so a source never outlives its channel.
  void dispose() {}
}
