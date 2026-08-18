import 'dart:convert';

import 'package:dpip/core/network/sse_event.dart';
import 'package:dpip/core/realtime/sse_realtime_source.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:flutter/foundation.dart' show listEquals;

/// The live EEW feed, streamed over Server-Sent Events (`/api/v2/eq/eew?sse=1`).
///
/// Extends the generic [SseRealtimeSource] with the EEW specifics — nothing here
/// touches connection, buffering, or reconnection. [decode] parses each event's
/// `data:` with the same [Eew.fromJson] mapping the one-shot GET used, so the
/// data format is unchanged by the move to SSE.
///
/// Liveness is [SseLiveness.connectionOpen] (the default): the EEW stream is
/// **silent between earthquakes** (empirically tens of seconds with no bytes),
/// so an open connection — not event recency — is the liveness signal; a
/// quiet-but-connected feed stays `live` (connected, no alert) instead of aging
/// to offline. This mirrors the previous fetch-freshness choice ([timestampOf]
/// is null): feed liveness, not payload age, drives staleness.
class EewRealtimeSource extends SseRealtimeSource<List<Eew>> {
  /// [connect] opens one EEW SSE connection — in production
  /// `EarthquakeApi.openEewSse`; the source calls it again to reconnect.
  ///
  /// [cwaOnly] is read fresh on every [decode] (a closure, not a captured
  /// bool) so toggling `EewCwaOnlySettings` takes effect on the very next
  /// event instead of needing the connection to be rebuilt.
  EewRealtimeSource(
    Stream<SseEvent> Function() connect, {
    required this.cwaOnly,
  }) : super(connect: connect, label: 'eew');

  final bool Function() cwaOnly;

  @override
  List<Eew> decode(String data) {
    final all = [
      for (final item in jsonDecode(data) as List)
        Eew.fromJson(item as Map<String, dynamic>),
    ];
    final onlyCwa = cwaOnly();
    return [
      for (final e in all)
        if (!e.isJma && (!onlyCwa || e.isCwa)) e,
    ];
  }

  /// Null on purpose: EEW uses connection/fetch-freshness. `EewInfo.time` recedes
  /// within a single active event while fresh updates keep arriving, so payload
  /// age would false-positive "stale" mid-alert.
  @override
  DateTime? timestampOf(List<Eew> value) => null;

  /// Element-wise equality so the channel dedups emissions (each decoded event
  /// yields a fresh list, whose default identity `==` would never match). `Eew`
  /// is a value type.
  @override
  bool sameData(List<Eew>? a, List<Eew>? b) => listEquals(a, b);
}
