/// [LightningMapLayer]: identity and timeline plumbing only — every mark on
/// the map is drawn by `LightningStrikeOverlay` (covered on its own), so this
/// pins what the layer itself adds: id/icon/timeline chrome, the localized
/// label, the seconds-to-[MapFrame] mapping in `frames()` (including that a
/// history failure propagates rather than being swallowed), and that
/// `prepare`/`show`/`clear`/`onStyleReset` hand off to the overlay correctly
/// against a real controller and a real repository.
///
/// Never asserts on the overlay's own internals (icon baking, the prefetch
/// window, the snapshot cache) — only on what reaches the controller through
/// this layer's public surface. `EmptyLightningRepository` in
/// raster_timeline_harness.dart always answers with zero strikes, which can't
/// exercise the age-bucket / cg-vs-cc derivation, so the fixture below carries
/// one real strike per age bucket instead.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/lightning_layer.dart';
import 'package:dpip/features/weather/domain/lightning_snapshot.dart';
import 'package:dpip/features/weather/domain/meteor_lightning_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

/// A [MeteorLightningRepository] fixture with two frames: an older one with no
/// strikes, and a newer one carrying a strike in every age bucket (5/10/30/60
/// min) and both [LightningStrike.type]s, so the overlay's per-feature age and
/// kind derivation has real data to compute over.
class _FakeLightningRepository implements MeteorLightningRepository {
  _FakeLightningRepository(this._bySecond);

  final Map<int, LightningSnapshot> _bySecond;

  /// Every second asked of [at], in call order — lets a test prove the layer
  /// passed the right frame straight through to the overlay/repository.
  final List<int> atRequests = [];

  @override
  Future<Result<List<int>>> history() async =>
      Ok(_bySecond.keys.toList()..sort());

  @override
  Future<Result<LightningSnapshot>> latest() async {
    final seconds = _bySecond.keys.toList()..sort();
    return Ok(_bySecond[seconds.last]!);
  }

  @override
  Future<Result<LightningSnapshot>> at(int second) async {
    atRequests.add(second);
    final snapshot = _bySecond[second];
    if (snapshot == null) return const Err(NotFoundFailure('no snapshot'));
    return Ok(snapshot);
  }
}

/// Fails every call — for pinning that [LightningMapLayer.frames] surfaces a
/// [Failure] rather than swallowing it.
class _FailingHistoryRepository implements MeteorLightningRepository {
  @override
  Future<Result<List<int>>> history() async =>
      const Err(NetworkFailure('offline'));

  @override
  Future<Result<LightningSnapshot>> latest() async =>
      const Err(NetworkFailure('offline'));

  @override
  Future<Result<LightningSnapshot>> at(int second) async =>
      const Err(NetworkFailure('offline'));
}

const _oldFrameSnapshot = LightningSnapshot(time: 1000, strikes: []);

const _newFrameSnapshot = LightningSnapshot(
  time: 2000,
  strikes: [
    // 100 s old -> bucket 5. Cloud-to-ground -> "cg" / cross mark.
    LightningStrike(type: 1, time: 1900, latitude: 23.1, longitude: 121.1),
    // 400 s old -> bucket 10. Cloud-to-cloud -> "cc" / dot mark.
    LightningStrike(type: 0, time: 1600, latitude: 23.2, longitude: 121.2),
    // 1000 s old -> bucket 30. Cloud-to-ground.
    LightningStrike(type: 1, time: 1000, latitude: 23.3, longitude: 121.3),
    // 4000 s old -> bucket 60 (the open-ended bucket). Cloud-to-cloud.
    LightningStrike(type: 0, time: -2000, latitude: 23.4, longitude: 121.4),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  _FakeLightningRepository repositoryWithFrames() => _FakeLightningRepository({
    1000: _oldFrameSnapshot,
    2000: _newFrameSnapshot,
  });

  test('identity: id, icon and timeline chrome', () {
    final layer = LightningMapLayer(repositoryWithFrames());
    expect(layer.id, 'lightning');
    expect(layer.icon, Icons.bolt_outlined);
    expect(layer.usesTimeline, isTrue);
    // The scaffold owns the timeline widget for a timeline layer, so this
    // layer reports no resting chrome of its own.
    expect(layer.bottomChromeFraction, 0);
  });

  testWidgets('label reads the localized lightning string', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    final layer = LightningMapLayer(repositoryWithFrames());
    expect(
      layer.label(context),
      AppLocalizations.of(context).mapLayerLightning,
    );
  });

  test(
    'frames maps each history second into a chronological MapFrame',
    () async {
      final layer = LightningMapLayer(repositoryWithFrames());

      final result = await layer.frames();

      expect(result.valueOrNull, [
        MapFrame(
          id: '1000',
          time: DateTime.fromMillisecondsSinceEpoch(1000000, isUtc: true),
        ),
        MapFrame(
          id: '2000',
          time: DateTime.fromMillisecondsSinceEpoch(2000000, isUtc: true),
        ),
      ]);
    },
  );

  test(
    'frames propagates a history failure rather than swallowing it',
    () async {
      final layer = LightningMapLayer(_FailingHistoryRepository());

      final result = await layer.frames();

      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, isA<NetworkFailure>());
    },
  );

  test('frames is empty when the repository has no history yet', () async {
    final layer = LightningMapLayer(EmptyLightningRepository());

    final result = await layer.frames();

    expect(result.valueOrNull, isEmpty);
  });

  test('prepare mounts the shared source and symbol layer', () async {
    final layer = LightningMapLayer(repositoryWithFrames());
    final controller = RecordingMapController();
    final frames = (await layer.frames()).valueOrNull!;

    await layer.prepare(controller, frames);

    expect(controller.calls, [
      'removeLayer:lightning-lyr',
      'removeSource:lightning-src',
      'addSource:lightning-src',
      'addSymbolLayer:lightning-lyr',
    ]);
  });

  group('show', () {
    test(
      'publishes one feature per strike, keyed by age bucket and kind',
      () async {
        final layer = LightningMapLayer(repositoryWithFrames());
        final controller = RecordingMapController();
        final frames = (await layer.frames()).valueOrNull!;
        await layer.prepare(controller, frames);

        await layer.show(controller, frames.last);

        final geoJson = controller.sourceData['lightning-src']!;
        final features = List<Map<String, dynamic>>.from(
          geoJson['features'] as List,
        );
        expect(features, hasLength(4));

        expect(features[0]['properties'], {
          'kind': 'cg',
          'age': 5,
          'icon': 'lightning-cross-5',
        });
        // GeoJSON coordinate order is [longitude, latitude], not [latitude,
        // longitude] — easy to transpose silently since both are doubles.
        expect(features[0]['geometry'], {
          'type': 'Point',
          'coordinates': [121.1, 23.1],
        });
        expect(features[1]['properties'], {
          'kind': 'cc',
          'age': 10,
          'icon': 'lightning-dot-10',
        });
        expect(features[2]['properties'], {
          'kind': 'cg',
          'age': 30,
          'icon': 'lightning-cross-30',
        });
        expect(features[3]['properties'], {
          'kind': 'cc',
          'age': 60,
          'icon': 'lightning-dot-60',
        });
      },
    );

    test(
      'on an empty-strike frame still publishes an empty FeatureCollection',
      () async {
        final layer = LightningMapLayer(repositoryWithFrames());
        final controller = RecordingMapController();
        final frames = (await layer.frames()).valueOrNull!;
        await layer.prepare(controller, frames);

        await layer.show(controller, frames.first);

        expect(controller.sourceData['lightning-src'], {
          'type': 'FeatureCollection',
          'features': <dynamic>[],
        });
      },
    );

    test(
      'ignores a scrubbing request for a frame that was never warmed',
      () async {
        final layer = LightningMapLayer(repositoryWithFrames());
        final controller = RecordingMapController();
        final frame = MapFrame(
          id: '2000',
          time: DateTime.fromMillisecondsSinceEpoch(2000000, isUtc: true),
        );
        // Deliberately skip prepare(): the cache is empty, so a live scrub must
        // skip the frame instead of blocking the gesture on a fetch.

        await layer.show(controller, frame, scrubbing: true);

        expect(controller.calls, [
          'removeLayer:lightning-lyr',
          'removeSource:lightning-src',
          'addSource:lightning-src',
          'addSymbolLayer:lightning-lyr',
        ]);
      },
    );

    test(
      'fetches directly when the frame was never warmed by prepare',
      () async {
        final repository = repositoryWithFrames();
        final layer = LightningMapLayer(repository);
        final controller = RecordingMapController();
        final frame = MapFrame(
          id: '2000',
          time: DateTime.fromMillisecondsSinceEpoch(2000000, isUtc: true),
        );
        // Deliberately skip prepare(): a non-scrubbing show must still work
        // standalone rather than depending on it having run first.

        await layer.show(controller, frame);

        expect(repository.atRequests, [2000]);
        final geoJson = controller.sourceData['lightning-src']!;
        expect(geoJson['features'], hasLength(4));
      },
    );
  });

  test('clear removes the mounted source and layer', () async {
    final layer = LightningMapLayer(repositoryWithFrames());
    final controller = RecordingMapController();
    final frames = (await layer.frames()).valueOrNull!;
    await layer.prepare(controller, frames);

    await layer.clear(controller);

    expect(controller.calls, [
      'removeLayer:lightning-lyr',
      'removeSource:lightning-src',
      'addSource:lightning-src',
      'addSymbolLayer:lightning-lyr',
      'removeLayer:lightning-lyr',
      'removeSource:lightning-src',
    ]);
  });

  test('onStyleReset forgets the mount without touching the controller, '
      'so the next prepare re-mounts from scratch', () async {
    final layer = LightningMapLayer(repositoryWithFrames());
    final controller = RecordingMapController();
    final frames = (await layer.frames()).valueOrNull!;
    await layer.prepare(controller, frames);
    final callsAfterFirstPrepare = List<String>.of(controller.calls);

    layer.onStyleReset();
    expect(
      controller.calls,
      callsAfterFirstPrepare,
      reason: 'onStyleReset must not touch the controller directly',
    );

    await layer.prepare(controller, frames);

    expect(controller.calls, [
      ...callsAfterFirstPrepare,
      'removeLayer:lightning-lyr',
      'removeSource:lightning-src',
      'addSource:lightning-src',
      'addSymbolLayer:lightning-lyr',
    ]);
  });

  testWidgets('buildLegend keys every age x kind combination, with no unit', (
    tester,
  ) async {
    final layer = LightningMapLayer(repositoryWithFrames());
    // SymbolLegend reads AppLocalizations unconditionally (for the optional
    // unit row), so it needs a real delegate even though lightning's legend
    // passes no unit at all.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(builder: (context) => layer.buildLegend(context)),
        ),
      ),
    );

    expect(find.byType(MapLegendCard), findsOneWidget);
    final legend = tester.widget<SymbolLegend>(find.byType(SymbolLegend));
    expect(legend.unit, isNull);

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);
    expect(legend.items.map((item) => item.label).toList(), [
      for (final minutes in const [5, 10, 30, 60]) ...[
        l10n.lightningLegendCg(minutes),
        l10n.lightningLegendCc(minutes),
      ],
    ]);
  });
}
