/// One place that decides how long anything is kept, and one schedule that
/// enforces it.
///
/// Retention used to be each store's own business, run at whatever moment that
/// store happened to touch the disk: the mesh log pruned at bootstrap, the app
/// log inside a buffered write, the network buckets inside their flush, the
/// HTTP cache every 96 rows written. Every one of those is *activity*-driven,
/// and they share a failure: an app that is **left running** goes quiet, and
/// quiet is exactly when nothing prunes.
///
/// That is not an edge case here. A phone on a desk for three days never
/// bootstraps again; the log stops buffering once nothing is failing, the
/// network buckets stop flushing once no request is made, and the mesh log
/// goes still the moment the radio disconnects — so each of them keeps
/// whatever it had, for as long as the process lives.
///
/// So the windows live here, together, and the schedule is explicit: once at
/// startup, then hourly for as long as the app runs.
library;

import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/logging/log_store.dart';
import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/network/etag_cache_store.dart';
import 'package:dpip/core/network/network_usage_store.dart';

/// How often retention runs while the app is alive.
///
/// An hour is far shorter than any window it enforces, so a sweep is almost
/// always a no-op `DELETE` against an indexed column — cheap enough that the
/// cadence can be about *bounding the overshoot* rather than about cost. It
/// bounds it at an hour: a 24-hour table never holds more than 25.
const Duration retentionInterval = Duration(hours: 1);

/// Runs every store's retention on one schedule.
///
/// Deliberately not a `ChangeNotifier` and not injected anywhere: nothing
/// observes retention, and nothing should be able to depend on it having run.
/// Each store still enforces its own window on read, so a missed sweep costs
/// disk, never correctness.
class RetentionService {
  RetentionService({
    required this.mesh,
    required this.logs,
    required this.usage,
    required this.httpCache,
  });

  // Every store is nullable: a database that would not open is a degraded
  // app, not a dead one, and retention over nothing is nothing to do.

  /// Mesh conversation (30 days) plus the radio and neighbour series (24h).
  final MeshStore? mesh;

  /// The persisted app log (24h).
  final LogStore? logs;

  /// Network accounting buckets, trimmed to the reporting window.
  final NetworkUsageStore? usage;

  /// The HTTP cache. Byte-budgeted rather than time-limited, so this is a
  /// carry-over check: a session that ended over budget stays over until
  /// enough writes happen to trigger the amortized sweep, and on an idle app
  /// that is never.
  final EtagCacheStore? httpCache;

  Timer? _timer;

  /// Whether a sweep is in flight, so the hourly tick cannot stack up behind a
  /// slow one on a busy disk.
  bool _running = false;

  /// Sweeps now, then every [retentionInterval].
  ///
  /// The immediate sweep is the "first launch" half: an app opened once a week
  /// does its whole cleanup there, and the timer never gets a chance to fire.
  void start() {
    if (_timer != null) return;
    unawaited(sweep());
    _timer = Timer.periodic(retentionInterval, (_) => unawaited(sweep()));
  }

  /// Drops everything past its window, everywhere. Never throws — each store
  /// already logs its own failure, and a failed sweep must not take down
  /// whatever asked for it.
  Future<void> sweep() async {
    if (_running) return;
    _running = true;
    final started = DateTime.now();
    try {
      await mesh?.prune();
      await logs?.prune();
      await usage?.prune();
      await httpCache?.prune();
      // Talker's in-memory ring, which the log *viewer* reads. Nothing else
      // bounds it: the table it mirrors has its own retention, but the
      // in-process history simply grows for as long as the app runs.
      Log.pruneOlderThan(logRetention);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'retention sweep');
    } finally {
      _running = false;
    }
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    Log.debug('retention: swept in ${elapsed}ms');
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
