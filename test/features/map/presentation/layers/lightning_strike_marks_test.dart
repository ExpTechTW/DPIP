/// Strike marks bucket age and kind into the icon id the symbol layer reads,
/// and a cache past forty frames drops the oldest so a later show fetches it
/// again.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/lightning_strike_overlay.dart';
import 'package:dpip/features/weather/domain/lightning_snapshot.dart';
import 'package:dpip/features/weather/domain/meteor_lightning_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

class _Repo implements MeteorLightningRepository {
  final fetched = <int>[];
  bool fail = false;

  @override
  Future<Result<LightningSnapshot>> at(int second) async {
    fetched.add(second);
    if (fail) return const Err(NetworkFailure('down'));
    return Ok(
      LightningSnapshot(
        time: second,
        strikes: [
          LightningStrike(
            type: 1,
            time: second - 30,
            latitude: 23,
            longitude: 121,
          ),
          LightningStrike(
            type: 0,
            time: second - 6 * 60,
            latitude: 23.1,
            longitude: 121.1,
          ),
          LightningStrike(
            type: 0,
            time: second - 11 * 60,
            latitude: 23.2,
            longitude: 121.2,
          ),
          LightningStrike(
            type: 1,
            time: second - 31 * 60,
            latitude: 23.3,
            longitude: 121.3,
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<List<int>>> history() async => const Ok([]);

  @override
  Future<Result<LightningSnapshot>> latest() async => at(0);
}

class _ThrowingGeoJson extends RecordingMapController {
  @override
  Future<void> setGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson,
  ) async {
    throw StateError('source gone');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('age buckets and cg/cc pick the icon id', () async {
    final repo = _Repo();
    final overlay = LightningStrikeOverlay(repo);
    const frame = '1700000000';
    final map = RecordingMapController();
    await overlay.prepare(map, [frame]);
    await overlay.show(map, frame);
    final features = (map.sourceData['lightning-src']!['features'] as List)
        .cast<Map<String, dynamic>>();
    final props = [
      for (final feature in features)
        feature['properties'] as Map<String, dynamic>,
    ];
    expect(props.map((p) => p['icon']), [
      'lightning-cross-5',
      'lightning-dot-10',
      'lightning-dot-30',
      'lightning-cross-60',
    ]);
    expect(props.map((p) => p['kind']), ['cg', 'cc', 'cc', 'cg']);

    final before = repo.fetched.length;
    await overlay.show(map, frame);
    expect(repo.fetched, hasLength(before));
  });

  test('a failed fetch and a thrown clear leave the overlay usable', () async {
    final repo = _Repo()..fail = true;
    final overlay = LightningStrikeOverlay(repo, namespace: 'fail');
    final map = RecordingMapController();
    await overlay.show(map, 'not-a-second');
    await overlay.show(map, '1700000000');
    expect(map.sourceData['fail-src']!['features'], isEmpty);

    final empty = LightningStrikeOverlay(repo, namespace: 'empty');
    await empty.showEmpty(_ThrowingGeoJson());
  });

  test('the forty-first frame drops the oldest from the cache', () async {
    final repo = _Repo();
    final overlay = LightningStrikeOverlay(repo, namespace: 'cache');
    final ids = [for (var i = 0; i < 42; i++) '${1700000000 + i}'];
    final map = RecordingMapController();
    await overlay.prepare(map, ids);
    for (final id in ids) {
      await overlay.show(map, id);
    }
    final fetches = repo.fetched.length;
    await overlay.show(map, ids.first);
    expect(repo.fetched.length, greaterThan(fetches));
  });

  testWidgets('legend crosses and dots paint', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('again'),
                ),
                for (final item in LightningStrikeOverlay.legendItems(context))
                  Row(children: [item.swatch, Text(item.label)]),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text(l10n.lightningLegendCg(60)), findsOneWidget);
    await tester.tap(find.text('again'));
    await tester.pump();
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
