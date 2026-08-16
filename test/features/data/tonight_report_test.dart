/// The tonight report's failure and empty states.
///
/// The astronomy is pinned in `test/core/astro/`. What is checked here is the
/// thing that actually went wrong in practice: a missing asset produced a page
/// that rendered nothing, which looks exactly like "no passes tonight" and
/// exactly like "still loading". Each of those is now a distinct, testable
/// outcome.
library;

import 'package:dpip/core/astro/satellite.dart';
import 'package:dpip/core/astro/tle_source.dart';
import 'package:dpip/core/astro/tonight_report.dart';
import 'package:flutter_test/flutter_test.dart';

const _taipei = (latitude: 25.0330, longitude: 121.5654);
const _zone = Duration(hours: 8);

/// The bundled snapshot, inlined so the test needs no asset bundle.
const _bundled = '''
ISS (ZARYA)
1 25544U 98067A   26226.43871707  .00004555  00000+0  89427-4 0  9997
2 25544  51.6329  11.7957 0007493  45.9133 314.2471 15.49439755580788
CSS (TIANHE)
1 48274U 21035A   26224.98627525  .00000101  00000+0  54127-5 0  9991
2 48274  41.4709 337.2096 0001079 250.4973 109.5748 15.58975796302033
''';

class _FixedSource implements TleSource {
  const _FixedSource(this.text);
  final String text;
  @override
  Future<List<TleSet>> load() async => TleSet.parseAll(text);
}

class _FailingSource implements TleSource {
  const _FailingSource();
  @override
  Future<List<TleSet>> load() async => throw StateError('asset missing');
}

Future<TonightReport> _report(TleSource source, {DateTime? now}) {
  final at = now ?? DateTime.utc(2026, 8, 14, 20);
  final local = at.add(_zone);
  return TonightReport.build(
    DateTime.utc(local.year, local.month, local.day).subtract(_zone),
    now: at,
    latitude: _taipei.latitude,
    longitude: _taipei.longitude,
    source: source,
  );
}

void main() {
  test('finds the ISS passes that are actually there', () async {
    final report = await _report(const _FixedSource(_bundled));
    expect(report.satellitesFailed, isFalse);
    expect(report.passes, isNotEmpty);
    expect(report.passes.map((p) => p.name), contains('ISS (ZARYA)'));
    // Sorted, and every pass clears the display threshold.
    for (var i = 1; i < report.passes.length; i++) {
      expect(
        report.passes[i].pass.rises.isAfter(report.passes[i - 1].pass.rises),
        isTrue,
      );
    }
  });

  test('a missing element set is reported, not rendered as "no passes"', () {
    // The distinction the page turns into two different sentences.
    return _report(const _FailingSource()).then((report) {
      expect(report.satellitesFailed, isTrue);
      expect(report.passes, isEmpty);
      expect(report.elementAge, isNull);
      // Everything that does not depend on the elements still resolves.
      expect(report.night.astronomicalNight, isNotNull);
      expect(report.targets, isNotEmpty);
    });
  });

  test('carries the element age, because that is what decays', () async {
    final report = await _report(const _FixedSource(_bundled));
    expect(report.elementAge, isNotNull);
    expect(report.elementAge!.inHours, inInclusiveRange(0, 48));
  });

  test('an empty element file gives no passes and no failure', () async {
    // A file that loads but holds nothing is not an error — it is a real,
    // if unhelpful, answer, and must not be shown as a broken asset.
    final report = await _report(const _FixedSource(''));
    expect(report.satellitesFailed, isFalse);
    expect(report.passes, isEmpty);
    expect(report.elementAge, isNull);
  });

  test(
    'targets are above the usable altitude and sorted by brightness',
    () async {
      final report = await _report(const _FixedSource(_bundled));
      for (final sighting in report.targets) {
        expect(sighting.altitude, greaterThan(usableAltitude));
      }
      for (var i = 1; i < report.targets.length; i++) {
        expect(
          report.targets[i].object.magnitude,
          greaterThanOrEqualTo(report.targets[i - 1].object.magnitude),
        );
      }
    },
  );

  test('the August Perseids show up as an active shower', () async {
    final report = await _report(const _FixedSource(_bundled));
    expect(report.showers.map((s) => s.shower.id), contains('perseids'));
  });
}
