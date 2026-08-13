import 'dart:typed_data';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/wind_forecast_layer.dart';
import 'package:dpip/features/map/presentation/widgets/wind_particle_overlay.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:dpip/features/weather/domain/wind_forecast_model.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/admin_outline.dart';
import 'package:dpip/shared/map/map_layer_category.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/features/map/presentation/pages/map_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'raster_timeline_harness.dart';

class _FakeWindRepository extends FakeRasterFrameSource
    implements WindForecastRepository {
  _FakeWindRepository(super.frames);

  @override
  String tileUrl(String frame) =>
      'https://host/api/v2/tiles/wind/$frame/{z}/{x}/{y}.webp';

  @override
  Future<Result<WindField>> fetchWindField(String frame) async => Ok(
    WindField(
      width: 2,
      height: 2,
      lat0: 90,
      lon0: 0,
      dLat: -0.25,
      dLon: 0.25,
      uMin: -1,
      uMax: 1,
      vMin: -1,
      vMax: 1,
      timeMs: 0,
      model: 'gfs',
      u: Uint8List.fromList([127, 127, 127, 127]),
      v: Uint8List.fromList([127, 127, 127, 127]),
    ),
  );
}

void main() {
  test('frames chronological', () async {
    final layer = WindForecastMapLayer(
      _FakeWindRepository(['1700000600', '1700000000']),
      model: WindForecastModel.gfs,
    );
    final frames = (await layer.frames()).valueOrNull!;
    expect(frames.map((f) => f.id), ['1700000000', '1700000600']);
  });

  test('id, icon, and model subtitle identify the forecast layer', () {
    final gfs = WindForecastMapLayer(
      _FakeWindRepository(const []),
      model: WindForecastModel.gfs,
    );
    expect(gfs.id, 'wind-gfs');
    expect(gfs.icon, Icons.air);
    expect(WindForecastModel.gfs.subtitle, '0.25° · 1 h');

    final ecmwf = WindForecastMapLayer(
      _FakeWindRepository(const []),
      model: WindForecastModel.ecmwf,
    );
    expect(ecmwf.id, 'wind-ecmwf');
    expect(WindForecastModel.ecmwf.subtitle, '0.25° · 3 h');
  });

  test('both models resolve to the numerical-forecast category', () {
    expect(categoryOf('wind-gfs'), MapLayerCategory.forecast);
    expect(categoryOf('wind-ecmwf'), MapLayerCategory.forecast);
  });

  test(
    'county and township borders are added on attach and removed on clear',
    () async {
      final layer = WindForecastMapLayer(
        _FakeWindRepository(_ids(5)),
        model: WindForecastModel.ecmwf,
      );
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();

      await layer.prepare(controller, frames);
      await layer.show(controller, frames[2]);

      expect(
        controller.calls,
        containsAll([
          'addLineLayer:admin-county-outline',
          'addLineLayer:admin-town-outline',
          'addLineLayer:admin-global-outline',
        ]),
        reason:
            'the wind field covers the base style\'s borders, so its own '
            'county, township, and country frame is drawn over it on attach — '
            '國界 ships on',
      );

      controller.calls.clear();
      await layer.clear(controller);
      expect(
        controller.calls,
        containsAll([
          'removeLayer:admin-county-outline',
          'removeLayer:admin-town-outline',
        ]),
      );
    },
  );

  test(
    'turning the global borders off removes them; on re-adds them',
    () async {
      final layer = WindForecastMapLayer(
        _FakeWindRepository(_ids(5)),
        model: WindForecastModel.ecmwf,
      );
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();

      await layer.prepare(controller, frames);
      await layer.show(controller, frames[2]);
      controller.calls.clear();

      layer.setShowGlobalOutline(false);
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(controller.calls, contains('removeLayer:admin-global-outline'));

      controller.calls.clear();
      layer.setShowGlobalOutline(true);
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(controller.calls, contains('addLineLayer:admin-global-outline'));
    },
  );

  test('turning the town borders off removes them from a live map', () async {
    final layer = WindForecastMapLayer(
      _FakeWindRepository(_ids(5)),
      model: WindForecastModel.gfs,
    );
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);
    controller.calls.clear();

    layer.setShowTownOutline(false);
    // The toggle syncs the map in an unawaited async op; let it drain.
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(controller.calls, contains('removeLayer:admin-town-outline'));
    expect(
      controller.calls,
      isNot(contains('removeLayer:admin-county-outline')),
      reason: 'the county frame must stay when only the town toggle flips',
    );
  });

  test(
    'frames revealed after the first mount anchor below the borders',
    () async {
      final layer = WindForecastMapLayer(
        _FakeWindRepository(_ids(12)),
        model: WindForecastModel.ecmwf,
      );
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();

      await layer.prepare(controller, frames);
      await layer.show(controller, frames[6]);

      // The first frame mounts before the borders exist (attach adds them after
      // the mount), so it sits on top and the borders land above it.
      expect(
        controller.belowOf('${layer.id}-lyr-${frames[6].id}'),
        isNull,
        reason: 'the first frame has no anchor yet — borders add above it',
      );
      expect(controller.calls, contains('addLineLayer:admin-county-outline'));

      // Every later reveal — mid-scrub or settle — anchors under the topmost
      // admin line, so a fresh frame can never cover the borders.
      await layer.show(controller, frames[10], scrubbing: true);
      expect(
        controller.belowOf('${layer.id}-lyr-${frames[10].id}'),
        AdminBoundary.town.lineLayerId,
        reason:
            'county + township borders ship on, so the township line is the '
            'topmost admin stroke the frame must mount below',
      );

      await layer.show(controller, frames[2]);
      expect(
        controller.belowOf('${layer.id}-lyr-${frames[2].id}'),
        AdminBoundary.town.lineLayerId,
        reason: 'a settle re-mount past the ring anchors below the borders too',
      );

      // 國界 ships on, so its frame is already on the map — the anchor must
      // not follow it (the global frame sits lowest; a raster hung under its
      // casing would cover the county and town lines above it).
      expect(
        controller.calls,
        contains('addLineLayer:admin-global-outline'),
        reason: '國界 ships on by default',
      );

      await layer.show(controller, frames[9], scrubbing: true);
      expect(
        controller.belowOf('${layer.id}-lyr-${frames[9].id}'),
        AdminBoundary.town.lineLayerId,
        reason:
            'the topmost admin line stays the township line — the anchor must '
            'not move onto the global frame just because it is on',
      );
    },
  );

  test('clear releases tiles', () async {
    final source = _FakeWindRepository(_ids(5));
    final layer = WindForecastMapLayer(source, model: WindForecastModel.gfs);
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);
    await layer.clear(controller);

    expect(source.released, 1);
  });

  test('showing a frame loads its wind field into the layer', () async {
    final layer = WindForecastMapLayer(
      _FakeWindRepository(_ids(5)),
      model: WindForecastModel.gfs,
    );
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    expect(layer.field.value, isNull);

    await layer.show(controller, frames[0]);
    expect(layer.field.value, isNotNull);
    expect(layer.field.value!.model, 'gfs');

    // Detach stops advertising the grid, so a re-attach animates a fresh field
    // rather than the previous layer's stale one.
    await layer.clear(controller);
    expect(layer.field.value, isNull);
  });

  testWidgets('the overlay slot hosts the particle animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    final layer = WindForecastMapLayer(
      _FakeWindRepository(const []),
      model: WindForecastModel.ecmwf,
    );
    final overlay = layer.buildMapOverlay(
      tester.element(find.byType(Scaffold)),
    );
    expect(overlay, isA<WindParticleOverlay>());
  });

  testWidgets('the ticker runs only while a wind field is loaded', (
    tester,
  ) async {
    final layer = WindForecastMapLayer(
      _FakeWindRepository(const []),
      model: WindForecastModel.gfs,
    );
    // The harness camera is zoom 7 over Taiwan, so a seeded particle must sit
    // inside the viewport and the ticker has somewhere to streak it.
    await layer.onAttached(RecordingMapController());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WindParticleOverlay(layer: layer)),
      ),
    );
    expect(
      tester.binding.transientCallbackCount,
      0,
      reason: 'an empty layer must not run the animation at all',
    );

    layer.field.value = WindField(
      width: 2,
      height: 2,
      lat0: 90,
      lon0: 0,
      dLat: -90,
      dLon: 180,
      uMin: -20,
      uMax: 20,
      vMin: -1,
      vMax: 1,
      timeMs: 0,
      model: 'gfs',
      u: Uint8List.fromList([255, 255, 255, 255]),
      v: Uint8List.fromList([128, 128, 128, 128]),
    );
    await tester.pump();

    expect(
      tester.binding.transientCallbackCount,
      greaterThan(0),
      reason: 'a loaded field must start the ticker that redraws the streaks',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the overlay paints visible streaks, not nothing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final layer = WindForecastMapLayer(
      _FakeWindRepository(const []),
      model: WindForecastModel.gfs,
    );
    // Zoom in so the wind field fills the viewport: the default z7 viewport
    // covers a sliver of the global field (a handful of seeded particles, too
    // few to assert anything about), while this field spans just the Taiwan
    // window the camera sits over. A uniform full-speed field then lands the
    // whole population in one speed bucket — the case that must not lose
    // points.
    await layer.onAttached(
      RecordingMapController(
        camera: const CameraPosition(target: LatLng(23.5, 121), zoom: 4),
      ),
    );
    layer.field.value = WindField(
      width: 2,
      height: 2,
      lat0: 25,
      lon0: 120,
      dLat: -0.75,
      dLon: 1.5,
      uMin: -20,
      uMax: 20,
      vMin: -1,
      vMax: 1,
      timeMs: 0,
      model: 'gfs',
      u: Uint8List.fromList([255, 255, 255, 255]),
      v: Uint8List.fromList([128, 128, 128, 128]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // Black underneath: the streaks are white, and the default Scaffold
          // background is near-white, so on that a blank overlay counts as
          // bright everywhere and the assertion below means nothing.
          body: RepaintBoundary(
            key: const ValueKey('overlayBoundary'),
            child: ColoredBox(
              color: Colors.black,
              child: WindParticleOverlay(layer: layer),
            ),
          ),
        ),
      ),
    );
    // Let the seeded particles accumulate a few frames of trail.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // The tree's *first* RepaintBoundary is Scaffold's (white), not the one
    // the test wraps the black backdrop in — sampling that one would pass on
    // a blank overlay. The boundary is keyed so the finder stays precise.
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('overlayBoundary')),
    );
    // toImage is a real engine async — it must run outside the test's fake
    // clock, or the future never completes.
    ByteData? data;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      data = await image.toByteData();
      image.dispose();
    });
    expect(data, isNotNull);
    final bytes = data!;

    // The painter draws white-on-dark streaks; at least a few sampled pixels
    // must be bright — zero means the CustomPaint produced nothing visible.
    var bright = 0;
    for (var i = 0; i < bytes.lengthInBytes; i += 16) {
      final r = bytes.getUint8(i);
      final g = bytes.getUint8(i + 1);
      final b = bytes.getUint8(i + 2);
      if (r > 160 && g > 160 && b > 160) bright++;
    }
    // The whole population lands in one speed bucket (a uniform full-speed
    // field), so the bright count is really the bucket's draw — thousands of
    // points, not a handful: an 8-bit bucket counter wraps at 255 and drops
    // the bucket (or most of it) entirely, so this threshold is what fails
    // that bug. A blank overlay paints ~0.
    expect(
      bright,
      greaterThan(300),
      reason: 'the particle trails must paint as visible bright pixels',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('streaks appear on a field that arrives after the first build', (
    tester,
  ) async {
    // The field is fetched asynchronously, so in the app it is always null when
    // the overlay first builds — and the painter is handed the simulation by
    // value at build time. Without a rebuild when the field lands, the overlay
    // paints nothing until some unrelated cause rebuilds it, which in practice
    // meant the first pan. Nothing here ever touches the camera.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final layer = WindForecastMapLayer(
      _FakeWindRepository(const []),
      model: WindForecastModel.gfs,
    );
    await layer.onAttached(
      RecordingMapController(
        camera: const CameraPosition(target: LatLng(23.5, 121), zoom: 4),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // Black underneath: the streaks are white, and the default Scaffold
          // background is near-white, so on that a blank overlay counts as
          // bright everywhere and the assertion below means nothing.
          body: RepaintBoundary(
            key: const ValueKey('overlayBoundary'),
            child: ColoredBox(
              color: Colors.black,
              child: WindParticleOverlay(layer: layer),
            ),
          ),
        ),
      ),
    );

    layer.field.value = WindField(
      width: 2,
      height: 2,
      lat0: 25,
      lon0: 120,
      dLat: -0.75,
      dLon: 1.5,
      uMin: -20,
      uMax: 20,
      vMin: -1,
      vMax: 1,
      timeMs: 0,
      model: 'gfs',
      u: Uint8List.fromList([255, 255, 255, 255]),
      v: Uint8List.fromList([128, 128, 128, 128]),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // The tree's *first* RepaintBoundary is Scaffold's (white), not the one
    // the test wraps the black backdrop in — sampling that one would pass on
    // a blank overlay. The boundary is keyed so the finder stays precise.
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('overlayBoundary')),
    );
    ByteData? data;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      data = await image.toByteData();
      image.dispose();
    });
    final bytes = data!;
    var bright = 0;
    for (var i = 0; i < bytes.lengthInBytes; i += 16) {
      if (bytes.getUint8(i) > 160 &&
          bytes.getUint8(i + 1) > 160 &&
          bytes.getUint8(i + 2) > 160) {
        bright++;
      }
    }
    expect(
      bright,
      greaterThan(300),
      reason: 'a field loaded after mount must still start the streaks',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the overlay ticker stops while the map tab is hidden and resumes on '
    'return',
    (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final layer = WindForecastMapLayer(
        _FakeWindRepository(const []),
        model: WindForecastModel.gfs,
      );
      await layer.onAttached(RecordingMapController());

      // The map tab is index 2; start hidden so the first sync already stops
      // the ticker, then make it visible.
      final visibleTab = VisibleTab(0);
      await tester.pumpWidget(
        MaterialApp(
          home: VisibleTabScope(
            visibleTab: visibleTab,
            child: Scaffold(
              body: ColoredBox(
                color: Colors.black,
                child: WindParticleOverlay(layer: layer),
              ),
            ),
          ),
        ),
      );

      layer.field.value = WindField(
        width: 2,
        height: 2,
        lat0: 90,
        lon0: 0,
        dLat: -90,
        dLon: 180,
        uMin: -20,
        uMax: 20,
        vMin: -1,
        vMax: 1,
        timeMs: 0,
        model: 'gfs',
        u: Uint8List.fromList([255, 255, 255, 255]),
        v: Uint8List.fromList([128, 128, 128, 128]),
      );
      await tester.pump();

      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'a hidden map tab must not run the particle ticker at all',
      );

      visibleTab.value = MapPage.tabIndex;
      await tester.pump();
      expect(
        tester.binding.transientCallbackCount,
        greaterThan(0),
        reason: 'entering the map tab starts the animation',
      );

      visibleTab.value = 0;
      await tester.pump();
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'leaving the map tab stops the per-frame raster immediately',
      );
    },
  );

  testWidgets('the options chip offers county, township, and name toggles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final layer = WindForecastMapLayer(
      _FakeWindRepository(const []),
      model: WindForecastModel.gfs,
    );
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(),
      ),
    );
    final chrome = layer.buildTopTrailingChrome(
      tester.element(find.byType(Scaffold)),
      showTownLabels: ValueNotifier(true),
      onShowTownLabelsChanged: (_) {},
      showTerrain: ValueNotifier(true),
      onShowTerrainChanged: (_) {},
      onReloadActive: () async {},
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Align(alignment: Alignment.topRight, child: chrome),
        ),
      ),
    );

    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.radarGlobalOutline), findsOneWidget);
    expect(find.text(l10n.radarCountyOutline), findsOneWidget);
    expect(find.text(l10n.radarTownOutline), findsOneWidget);
    expect(find.text(l10n.mapTownLabels), findsOneWidget);
    // No scan range — a forecast model has no instrument footprint.
    expect(find.text(l10n.radarScanRange), findsNothing);
  });
}

/// [count] frame ids, newest first (the wire order).
List<String> _ids(int count) => [
  for (var i = count - 1; i >= 0; i--) '${1700000000 + i * 600}',
];
