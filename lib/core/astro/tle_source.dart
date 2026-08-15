/// Where element sets come from, and how they stay fresh.
///
/// Split from the propagator on purpose. `satellite.dart` is pure Dart with no
/// Flutter dependency — it can be unit-tested against the published SGP4
/// vectors and run in an isolate — while *which* elements to use is a
/// data-freshness problem and lives here.
///
/// Three tiers, each a real answer when the one above it is unavailable:
///
///   1. **Fetched** — the newest elements, at most once a day.
///   2. **Cached** — the last successful fetch, kept in [SettingsStore].
///   3. **Bundled** — the snapshot shipped with the app. Always present, so a
///      device that has never had a network still predicts passes.
///
/// **Why not ETag.** The obvious design is a conditional request, and it does
/// not work here: CelesTrak's `gp.php` is generated per request and returns no
/// `ETag`, no `Last-Modified` and no `Cache-Control` — an `If-None-Match` is
/// answered with a full 200 and the whole body. Measured, not assumed.
///
/// So freshness is decided on the **epoch inside the elements** instead, which
/// is better than a validator anyway: it is the version number the data
/// already carries. Bytes can change without the orbit being newer (the file
/// is regenerated constantly), and a cache must never be replaced by *older*
/// elements, which a byte comparison cannot tell you. At 3.5 kB a day the
/// bandwidth an ETag would have saved is not worth having.
library;

import 'package:dpip/core/astro/satellite.dart';
import 'package:dpip/core/astro/tle_store.dart';
import 'package:flutter/services.dart' show rootBundle;

/// How long a fetched set is considered fresh.
///
/// Elements are re-issued a few times a day, but a two-day-old set still
/// predicts an ISS pass to well inside a minute — the resolution a reader can
/// act on. Anything shorter is polling a public service for nothing, which
/// CelesTrak's usage guidelines explicitly ask clients not to do, and the
/// pass list is only ever drawn 48 hours ahead anyway.
///
/// The trade is visible rather than buried: the page already shows the element
/// age, so a reader can see when the answer is resting on older data.
const Duration tleRefreshInterval = Duration(hours: 48);

/// Fetches raw TLE text. Injected rather than implemented here so the
/// transport stays a seam: today the app has no route to CelesTrak, because
/// `ApiClient` is region-aware over ExpTech's own hosts and calling a foreign
/// host directly is exactly what the networking rule forbids. When the backend
/// mirrors the feed, this becomes one `ApiClient.get`.
typedef TleFetcher = Future<String> Function();

/// A supply of two-line element sets.
abstract interface class TleSource {
  Future<List<TleSet>> load();
}

/// The snapshot shipped with the app — the floor everything else falls back to.
class BundledTleSource implements TleSource {
  const BundledTleSource();

  @override
  Future<List<TleSet>> load() async => TleSet.parseAll(
    await rootBundle.loadString('assets/astro/satellites.tle'),
  );
}

/// Cached elements, refreshed on a timer, never downgraded.
class CachedTleSource implements TleSource {
  const CachedTleSource({
    required this.store,
    required this.now,
    this.fetch,
    this.fallback = const BundledTleSource(),
    this.refreshInterval = tleRefreshInterval,
  });

  final TleStore store;
  final DateTime Function() now;

  /// Null until the app has a route to a feed; the cache and the bundle still
  /// work, they simply stop getting newer.
  final TleFetcher? fetch;

  final TleSource fallback;
  final Duration refreshInterval;

  /// The best elements available, fetching first if the cache is stale.
  ///
  /// A failed fetch is not an error the caller sees: the cache — or failing
  /// that the bundle — is still a usable answer, and its age is already on the
  /// result for the page to show.
  @override
  Future<List<TleSet>> load() async {
    var stored = await store.read();
    if (_shouldRefresh(stored)) {
      await _refresh(stored);
      stored = await store.read();
    }
    if (stored != null) {
      final parsed = _parse(stored.text);
      if (parsed.isNotEmpty) return parsed;
    }
    return fallback.load();
  }

  bool _shouldRefresh(StoredElements? stored) {
    if (fetch == null) return false;
    if (stored == null) return true;
    final since = now().difference(stored.fetchedAt);
    // A clock that jumped backwards would otherwise freeze the refresh until
    // it caught up.
    return since.isNegative || since >= refreshInterval;
  }

  Future<void> _refresh(StoredElements? stored) async {
    final String text;
    try {
      text = await fetch!();
    } on Object {
      // Leave the timestamp alone so the next call tries again rather than
      // waiting out the whole interval on one failure.
      return;
    }

    final incoming = _parse(text);
    if (incoming.isEmpty) return;

    // Only accept a genuinely newer set. The feed is regenerated constantly,
    // so identical or older elements arrive routinely, and replacing a good
    // cache with an older one would quietly make predictions worse.
    final cached = _parse(stored?.text ?? '');
    if (cached.isNotEmpty && !_isNewer(incoming, cached)) {
      // Record the check without touching the elements.
      await store.write(fetchedAt: now());
      return;
    }

    await store.write(text: text, fetchedAt: now());
  }

  /// Whether [incoming] carries a later epoch than [cached] for any object
  /// they share — the elements' own version number.
  static bool _isNewer(List<TleSet> incoming, List<TleSet> cached) {
    final previous = {for (final set in cached) set.catalogNumber: set.epoch};
    for (final set in incoming) {
      final before = previous[set.catalogNumber];
      if (before == null || set.epoch.isAfter(before)) return true;
    }
    return false;
  }

  /// Parsing must never throw here: a truncated or garbled cache is a reason
  /// to fall back, not to take the page down.
  static List<TleSet> _parse(String text) {
    try {
      return TleSet.parseAll(text);
    } on Object {
      return const [];
    }
  }
}
