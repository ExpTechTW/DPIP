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
/// It also refuses to show a listed event past [EewExpiry]'s backstop. The
/// stream is silent between earthquakes, so an open connection is its only
/// liveness signal — and an open connection whose server has stopped updating
/// its list would otherwise keep the last alert on screen, counting nothing
/// down, for as long as the socket stayed up.
///
/// Pure (no clock, no I/O): the caller passes the instant a snapshot arrived,
/// on the calibrated clock, since it is compared with server-stamped origins.
library;

import 'package:dpip/features/earthquake/domain/eew.dart';

/// How long an alert may stay on screen when nothing takes it down.
///
/// A backstop, not the normal exit: the server drops an event four minutes
/// (240 s) after its origin, and the app follows. These only decide when the
/// app stops believing a list that has gone on naming an event past the point
/// where it can still describe shaking anyone is about to feel.
///
/// The numbers come from S-wave travel time across the area the feed covers,
/// read off the bundled CWA travel-time table: a shallow event's S wave is
/// 600 km out — farther than any point of Taiwan, Penghu, Kinmen or Matsu
/// lies from any epicentre the feed reports — about 145 s after origin. The
/// first report itself lands 10–20 s after origin, and strong shaking goes on
/// for tens of seconds behind the wavefront.
abstract final class EewExpiry {
  /// An ordinary event: gone 250 s after origin — past the S wave's 145 s
  /// to 600 km with the report delay and the shaking behind it to spare, and
  /// deliberately just behind the server's own 240 s, so the backstop never
  /// pre-empts the server's ordinary exit.
  static const Duration standard = Duration(seconds: 250);

  /// A deep, large or 警報 event: gone 400 s after origin.
  ///
  /// A deep focus is felt across the whole island and beyond, and its wave
  /// starts a focal depth away: from 500 km down the S wave needs ~165 s to
  /// reach 600 km epicentral and ~195 s to reach 800 km. A large rupture
  /// lasts tens of seconds itself, keeps being revised for longer, and is
  /// felt past 600 km. A public 警報 is the report people act on. All three
  /// get the extra two and a half minutes.
  static const Duration extended = Duration(seconds: 400);

  /// Focal depth (km) from which an event is "deep" for [extended].
  static const double deepKm = 150;

  /// Magnitude from which an event is "large" for [extended].
  static const double largeMagnitude = 6.0;

  /// A cancelled event: gone 180 s after the cancel was first seen — long
  /// enough for someone who saw the warning arrive to see it withdrawn, short
  /// enough not to sit on Home as if it still mattered.
  static const Duration cancelled = Duration(seconds: 180);

  /// Whatever the origin says, nothing stays past an hour after it was first
  /// listed. Catches an origin time that is wrong — far in the future — which
  /// would otherwise push the windows above out with it.
  static const Duration hardCap = Duration(hours: 1);

  /// How long after origin [report] stays up — [standard] or [extended].
  static Duration lifetimeOf(Eew report) {
    final info = report.info;
    final extend =
        info.depth >= deepKm ||
        info.magnitude >= largeMagnitude ||
        report.isWarning;
    return extend ? extended : standard;
  }
}

/// What [reduceEewFeed] remembers about one event between snapshots.
class EewTrack {
  const EewTrack({
    required this.report,
    required this.firstSeen,
    this.cancelledSince,
  });

  /// The newest report of the event seen so far.
  final Eew report;

  /// When the event was first listed — what [EewFeedState.memory] and
  /// [EewExpiry.hardCap] are measured from.
  final DateTime firstSeen;

  /// When a cancel for the event was first seen; null until then.
  final DateTime? cancelledSince;

  /// The instant this event stops being shown, whether listed or not.
  DateTime get expiresAt {
    final cap = firstSeen.add(EewExpiry.hardCap);
    final cancel = cancelledSince;
    final due = report.isCancelled && cancel != null
        ? cancel.add(EewExpiry.cancelled)
        : DateTime.fromMillisecondsSinceEpoch(
            report.info.time,
            isUtc: true,
          ).add(EewExpiry.lifetimeOf(report));
    return due.isBefore(cap) ? due : cap;
  }

  /// Whether this event is past [expiresAt] at [now].
  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
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

  /// The alerts to show, in the server's order, each at its newest report,
  /// leaving out any past its [EewExpiry] backstop.
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
/// The result shows the events [frame] lists, in its order, each at the
/// newest report seen for it — so a lagging server can neither take a card
/// back a serial nor un-cancel an event, but an event it drops leaves the list
/// at once — less any that are past [EewTrack.expiresAt]. The channel polls
/// once a second with or without a new frame, so an expired event goes within
/// a second of its deadline even when the server has gone quiet. An event
/// stays remembered while it is listed and for [EewFeedState.memory] after it
/// was first listed, so one that comes back from a lagging server still comes
/// back at its newest report.
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
      tracks[key] = EewTrack(
        report: incoming,
        firstSeen: now,
        cancelledSince: incoming.isCancelled ? now : null,
      );
    } else if (_supersedes(incoming, track.report)) {
      tracks[key] = EewTrack(
        report: incoming,
        firstSeen: track.firstSeen,
        // The cancel window runs from the first cancel seen, not from each
        // repeat of it — the same frame is folded again every second.
        cancelledSince: incoming.isCancelled
            ? (track.cancelledSince ?? now)
            : null,
      );
    }
  }
  // Forget only what is no longer listed: an event the server still lists
  // keeps its first sighting, however long that has been.
  tracks.removeWhere(
    (key, track) =>
        !order.contains(key) &&
        now.difference(track.firstSeen) >= EewFeedState.memory,
  );
  return EewFeedState._(tracks, [
    for (final key in order)
      if (!tracks[key]!.isExpiredAt(now)) tracks[key]!.report,
  ]);
}
