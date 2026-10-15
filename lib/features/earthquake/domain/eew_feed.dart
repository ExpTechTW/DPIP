/// Folds each snapshot of the live EEW feed into the alert list the app
/// shows — the one place the feed's report order is enforced.
///
/// Every SSE frame is the server's whole current list, and the app used to
/// show each one verbatim. Within one server that is safe: the edge keeps a
/// single entry per agency + event and only ever replaces it with a higher
/// serial. Across servers it is not. The feed is served from more than one
/// region, each fed by its own subscription to the same upstream, and after
/// a failover — or a reconnect that lands on the other region — the new
/// server can be a report behind the old one. Shown verbatim, the card on
/// screen went from 第 3 報 back to 第 2 報: older magnitude, older epicentre,
/// older intensity, presented as the latest word.
///
/// [reduceEewFeed] keeps, per event, the newest report it has seen, and shows
/// that one whenever the server lists the event at all. It never holds an
/// event the server has dropped: what is listed is the server's call, and only
/// *which report* of a listed event is shown is this function's.
///
/// Pure (no clock, no I/O): the caller passes the instant a snapshot arrived.
library;

import 'package:dpip/features/earthquake/domain/eew.dart';

/// What [reduceEewFeed] remembers about one event between snapshots.
class EewTrack {
  const EewTrack({required this.report, required this.firstSeen});

  /// The newest report of the event seen so far.
  final Eew report;

  /// When the event was first listed — what [EewFeedState.memory] is
  /// measured from.
  final DateTime firstSeen;
}

/// The reducer's state between snapshots: the newest report per event, and
/// the list the app shows.
class EewFeedState {
  const EewFeedState._(this._tracks, this.visible);

  /// Before the first snapshot: nothing remembered, nothing shown.
  static const EewFeedState initial = EewFeedState._({}, []);

  /// How long an event's newest serial is remembered after it was first
  /// listed. Long enough to outlast any EEW (the server itself drops an event
  /// four minutes after its origin) and any failover, short enough that the
  /// memory stays a handful of entries.
  static const Duration memory = Duration(hours: 1);

  /// Per [EewIdentityX.eventKey].
  final Map<String, EewTrack> _tracks;

  /// The alerts to show, in the server's order, each at its newest report.
  final List<Eew> visible;

  /// What is remembered about [eventKey], or null — for tests and diagnostics.
  EewTrack? trackOf(String eventKey) => _tracks[eventKey];
}

/// Whether [incoming] supersedes [current] as an event's latest word.
///
/// A higher serial always does; a lower one never does. On an equal serial the
/// incoming copy wins — it is the same report — except that a cancel is never
/// un-done by a copy of the same serial that lacks it.
bool _supersedes(Eew incoming, Eew current) {
  if (incoming.serial != current.serial) {
    return incoming.serial > current.serial;
  }
  return incoming.isCancelled || !current.isCancelled;
}

/// Folds [frame], the server's whole list as it arrived at [now], into
/// [previous].
///
/// The result shows exactly the events [frame] lists, in its order, each at the
/// newest report seen for it — so a lagging server can neither take a card
/// back a serial nor un-cancel an event, but an event it drops leaves the list
/// at once. An event stays remembered while it is listed and for
/// [EewFeedState.memory] after it was first listed, so one that comes back
/// from a lagging server still comes back at its newest report.
EewFeedState reduceEewFeed(
  EewFeedState previous,
  List<Eew> frame,
  DateTime now,
) {
  final tracks = Map<String, EewTrack>.of(previous._tracks);
  final order = <String>[];
  for (final incoming in frame) {
    final key = incoming.eventKey;
    if (!order.contains(key)) order.add(key);
    final track = tracks[key];
    if (track == null) {
      tracks[key] = EewTrack(report: incoming, firstSeen: now);
    } else if (_supersedes(incoming, track.report)) {
      tracks[key] = EewTrack(report: incoming, firstSeen: track.firstSeen);
    }
  }
  // Forget only what is no longer listed: an event the server still lists
  // keeps its first sighting, however long that has been.
  tracks.removeWhere(
    (key, track) =>
        !order.contains(key) &&
        now.difference(track.firstSeen) >= EewFeedState.memory,
  );
  return EewFeedState._(tracks, [for (final key in order) tracks[key]!.report]);
}
