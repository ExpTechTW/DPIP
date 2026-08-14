/// The element cache: when it refreshes, and what it refuses.
///
/// The interesting behaviour is all in the refusals. A feed that is regenerated
/// on every request will hand back identical or *older* elements routinely, and
/// a cache that takes whatever arrives quietly makes its own predictions worse
/// over time. Freshness is therefore decided on the epoch inside the elements,
/// not on the bytes and not on an ETag — which this endpoint does not serve
/// anyway.
library;

import 'package:dpip/core/astro/satellite.dart';
import 'package:dpip/core/astro/tle_source.dart';
import 'package:dpip/core/settings/preference_keys.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The ISS on day 226 of 2026.
const _older = '''
ISS (ZARYA)
1 25544U 98067A   26226.43871707  .00004555  00000+0  89427-4 0  9997
2 25544  51.6329  11.7957 0007493  45.9133 314.2471 15.49439755580788
''';

/// The same object, two days later.
const _newer = '''
ISS (ZARYA)
1 25544U 98067A   26228.43871707  .00004555  00000+0  89427-4 0  9997
2 25544  51.6329  11.7957 0007493  45.9133 314.2471 15.49439755580788
''';

/// Something the parser cannot make sense of.
const _garbage = 'not a two-line element set at all';

class _Bundled implements TleSource {
  const _Bundled();
  @override
  Future<List<TleSet>> load() async => TleSet.parseAll(_older);
}

class _Never implements TleSource {
  const _Never();
  @override
  Future<List<TleSet>> load() async => const [];
}

Future<Prefs> _prefs([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return Prefs(await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var clock = DateTime.utc(2026, 8, 20);

  CachedTleSource source({
    required Prefs prefs,
    TleFetcher? fetch,
    TleSource fallback = const _Bundled(),
  }) => CachedTleSource(
    prefs: prefs,
    now: () => clock,
    fetch: fetch,
    fallback: fallback,
  );

  setUp(() => clock = DateTime.utc(2026, 8, 20));

  test('with no fetcher it is the bundle, and never touches the network', () {
    // The shipping configuration until the app has a route to a feed.
    return _prefs().then((prefs) async {
      final loaded = await source(prefs: prefs).load();
      expect(loaded.single.catalogNumber, 25544);
      expect(
        prefs.getInt(PreferenceKeys.satelliteElementsFetchedAt),
        isNull,
        reason: 'nothing was fetched, so nothing was stamped',
      );
    });
  });

  test('the first load fetches and caches', () async {
    final prefs = await _prefs();
    var calls = 0;
    final loaded = await source(
      prefs: prefs,
      fetch: () async {
        calls++;
        return _newer;
      },
    ).load();
    expect(calls, 1);
    expect(loaded.single.epoch.day, 16); // day 228 of 2026 is 16 August
    expect(prefs.getString(PreferenceKeys.satelliteElements), _newer);
    expect(prefs.getInt(PreferenceKeys.satelliteElementsFetchedAt), isNotNull);
  });

  test('a second load inside the interval does not fetch again', () async {
    final prefs = await _prefs();
    var calls = 0;
    Future<String> fetch() async {
      calls++;
      return _newer;
    }

    await source(prefs: prefs, fetch: fetch).load();
    clock = clock.add(const Duration(hours: 30));
    await source(prefs: prefs, fetch: fetch).load();
    expect(calls, 1, reason: 'still inside the 48-hour window');

    clock = clock.add(const Duration(hours: 20));
    await source(prefs: prefs, fetch: fetch).load();
    expect(calls, 2, reason: 'past the interval it refreshes');
  });

  test('older elements are refused — the cache is never downgraded', () async {
    // The failure this whole design exists to prevent. A feed regenerated per
    // request happily serves an older set, and taking it would make every
    // later prediction worse with no visible symptom.
    final prefs = await _prefs();
    await source(prefs: prefs, fetch: () async => _newer).load();

    clock = clock.add(const Duration(days: 3));
    final loaded = await source(prefs: prefs, fetch: () async => _older).load();

    expect(prefs.getString(PreferenceKeys.satelliteElements), _newer);
    expect(loaded.single.epoch.day, 16);
  });

  test('identical elements are accepted as up to date, not as a change', () {
    return _prefs().then((prefs) async {
      await source(prefs: prefs, fetch: () async => _newer).load();
      final firstStamp = prefs.getInt(
        PreferenceKeys.satelliteElementsFetchedAt,
      );

      clock = clock.add(const Duration(days: 3));
      await source(prefs: prefs, fetch: () async => _newer).load();

      // The stamp moves — we did check — but the stored text is untouched.
      expect(
        prefs.getInt(PreferenceKeys.satelliteElementsFetchedAt),
        greaterThan(firstStamp!),
      );
      expect(prefs.getString(PreferenceKeys.satelliteElements), _newer);
    });
  });

  test('a failed fetch falls back and retries next time, not next day', () async {
    // Waiting out the whole interval after one dropped connection would mean a
    // day of stale elements for a moment of bad signal.
    final prefs = await _prefs();
    var calls = 0;
    final loaded = await source(
      prefs: prefs,
      fetch: () async {
        calls++;
        throw StateError('offline');
      },
    ).load();

    expect(calls, 1);
    expect(loaded.single.catalogNumber, 25544, reason: 'the bundle answered');
    expect(prefs.getInt(PreferenceKeys.satelliteElementsFetchedAt), isNull);

    await source(prefs: prefs, fetch: () async => _newer).load();
    expect(calls, 1);
    expect(prefs.getString(PreferenceKeys.satelliteElements), _newer);
  });

  test('garbage from the feed is ignored, not stored', () async {
    final prefs = await _prefs();
    await source(prefs: prefs, fetch: () async => _newer).load();
    clock = clock.add(const Duration(days: 3));
    await source(prefs: prefs, fetch: () async => _garbage).load();
    expect(prefs.getString(PreferenceKeys.satelliteElements), _newer);
  });

  test('a corrupt cache falls back instead of taking the page down', () async {
    final prefs = await _prefs({
      'astro:satellite:tle': _garbage,
      'astro:satellite:fetchedAt': clock.millisecondsSinceEpoch,
    });
    final loaded = await source(prefs: prefs).load();
    expect(loaded.single.catalogNumber, 25544);
  });

  test('an empty everything is an empty list, not a crash', () async {
    final prefs = await _prefs();
    final loaded = await source(prefs: prefs, fallback: const _Never()).load();
    expect(loaded, isEmpty);
  });

  test('a backwards clock still refreshes', () async {
    // Device clocks jump. Comparing "now minus last" without allowing for a
    // negative would freeze refreshes until real time caught up.
    final prefs = await _prefs();
    await source(prefs: prefs, fetch: () async => _newer).load();
    clock = clock.subtract(const Duration(days: 30));
    var calls = 0;
    await source(
      prefs: prefs,
      fetch: () async {
        calls++;
        return _newer;
      },
    ).load();
    expect(calls, 1);
  });
}
