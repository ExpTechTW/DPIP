import 'dart:convert';

import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/realtime/sse_realtime_source.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';

/// The live RTS feed, streamed over Server-Sent Events (`/api/v2/trem/rts?sse=1`).
///
/// Extends the generic [SseRealtimeSource] with the RTS specifics; [decode]
/// parses each event's `data:` with the same [Rts.fromJson] mapping the one-shot
/// GET used, so the data format is unchanged.
///
/// Liveness is [SseLiveness.eventRecency]: a **continuous** ~1 Hz feed whose
/// silence means trouble. Recency is measured with a monotonic clock inside the
/// source, so — unlike keying freshness off the payload's own `time` — a small
/// server/device clock skew can never falsely mark a live feed stale. When new
/// snapshots stop arriving (even on an open connection) the source reports
/// `Err`, and the channel ages it to stale/offline.
class RtsRealtimeSource extends SseRealtimeSource<Rts> {
  /// [connect] opens one RTS SSE connection — in production
  /// `EarthquakeApi.openRtsSse`; the source calls it again to reconnect.
  RtsRealtimeSource(Stream<SseEvent> Function() connect)
    : super(
        connect: connect,
        liveness: const SseLiveness.eventRecency(Duration(seconds: 3)),
        label: 'rts',
      );

  @override
  Rts decode(String data) =>
      Rts.fromJson(jsonDecode(data) as Map<String, dynamic>);

  /// Null: freshness is event-recency (above), not payload age — so clock skew
  /// on the snapshot's `time` can't reclassify a live feed.
  @override
  DateTime? timestampOf(Rts value) => null;
}
