/// Decides whether a replay's event had any EEW at all, without walking the
/// whole timeline.
///
/// Lives at the feature root for the same reason [ReplaySession] does: the
/// replay page is presentation and may not import `data/`.
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';

/// How far before a report's origin time a replay starts.
///
/// The legacy player opened two seconds early; keeping the constant shared
/// means the replay page can recover the event's origin time from the start
/// instant it was handed, without the route carrying both.
const Duration replayLeadIn = Duration(seconds: 2);

/// The three instants sampled relative to the origin time.
///
/// `/api/v2/eq/eew/{sec}` answers with the bulletins that are **still active**
/// at that second, not the ones issued in it: for the 2026-11-01 M5.6 event
/// the endpoint stayed empty until origin + 20 s, returned the same serial
/// from +30 s to +120 s, and was empty again by +300 s. So "start, middle,
/// end" is one sample before any bulletin could exist, one inside the window
/// where a first bulletin is still up, and one past it — where only a re-issued
/// serial could appear.
const List<Duration> replayProbeOffsets = [
  Duration(seconds: -60),
  Duration(seconds: 120),
  Duration(seconds: 300),
];

/// What three samples can honestly say about an event's EEW.
enum ReplayEewVerdict {
  /// At least one sample carried a bulletin. The card itself comes from the
  /// live poll as the replayed clock reaches it — this only rules absence out.
  found,

  /// All three samples answered successfully with an empty list.
  none,

  /// A sample failed (timeout, dropped connection, 5xx). Three samples cannot
  /// say anything then: a dead network must never read as "no data".
  undecided,
}

/// Samples [replayProbeOffsets] once, concurrently, and folds the answers into
/// a [ReplayEewVerdict].
///
/// This is deliberately not a crawl of the window: at one request per second a
/// ten-minute event is 600 requests before the page can say anything, which is
/// both slow and impolite. Three concurrent GETs answer the only question the
/// UI needs — may it say "nothing was found".
class ReplayEewProbe {
  ReplayEewProbe(
    ApiClient client, {
    required this.origin,
    required bool Function() cwaOnly,
  }) : _api = EarthquakeApi(client),
       _cwaOnlyFilter = cwaOnly;

  final EarthquakeApi _api;

  /// The report's origin time — the reference [replayProbeOffsets] are
  /// measured from.
  final DateTime origin;

  /// Read per sample, like [EewReplaySource] does, so the probe applies the
  /// same JMA/CWA filter the replayed feed will.
  final bool Function() _cwaOnlyFilter;

  /// Runs the three samples. Never throws: a failed sample folds into
  /// [ReplayEewVerdict.undecided].
  Future<ReplayEewVerdict> run() async {
    final samples = await Future.wait([
      for (final offset in replayProbeOffsets) _sample(origin.add(offset)),
    ]);
    if (samples.any((sample) => sample == null)) {
      return ReplayEewVerdict.undecided;
    }
    final found = samples.any((sample) => sample!.isNotEmpty);
    return found ? ReplayEewVerdict.found : ReplayEewVerdict.none;
  }

  /// The bulletins at [instant], filtered exactly as [EewReplaySource] filters
  /// them, or null when the request failed.
  Future<List<Eew>?> _sample(DateTime instant) async {
    final seconds = instant.millisecondsSinceEpoch ~/ 1000;
    final result = await guardResult(() async {
      final json = await _api.getEewAt(seconds);
      final all = [
        for (final item in json) Eew.fromJson(item as Map<String, dynamic>),
      ];
      final onlyCwa = _cwaOnlyFilter();
      return [
        for (final eew in all)
          if (!eew.isJma && (!onlyCwa || eew.isCwa)) eew,
      ];
    });
    return result.valueOrNull;
  }
}

/// Which of the EEW slot's shapes the replay page should draw.
enum ReplayEewSlot {
  /// An alert set is on screen: the card is drawn.
  card,

  /// Nothing yet and nothing to say: the first answer has not arrived.
  pending,

  /// The feed answered and this second carries no bulletin, but the event has
  /// not been ruled out.
  waiting,

  /// Polls are failing and being retried. Never says "no data".
  retrying,

  /// Polls have failed long enough for the feed to be offline.
  unavailable,

  /// The three samples found nothing across the event.
  none,
}

/// Decides what the slot shows, as a pure function so the precedence is
/// testable without a page: a card always wins (late data must replace any
/// message), then failures (a dead feed must never borrow the wording of an
/// empty one), then the sampled verdict, then "not yet".
ReplayEewSlot replayEewSlot({
  required bool hasAlerts,
  required RealtimeState<List<Eew>> feed,
  required ReplayEewVerdict? verdict,
}) {
  if (hasAlerts) return ReplayEewSlot.card;
  if (feed.consecutiveFailures >= 2) {
    return feed.status == RealtimeStatus.offline
        ? ReplayEewSlot.unavailable
        : ReplayEewSlot.retrying;
  }
  if (!feed.hasData) return ReplayEewSlot.pending;
  if (verdict == ReplayEewVerdict.none) return ReplayEewSlot.none;
  return ReplayEewSlot.waiting;
}
