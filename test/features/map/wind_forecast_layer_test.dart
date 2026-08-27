import 'dart:async';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/wind_forecast_layer.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:dpip/features/weather/domain/wind_forecast_model.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer_category.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

class _ControlledWindRepository extends FakeRasterFrameSource
    implements WindForecastRepository {
  _ControlledWindRepository(super.frames);

  final List<String> requested = [];
  final Map<String, Completer<Result<WindField>>> _pending = {};

  @override
  String tileUrl(String frame) =>
      'https://host/api/v2/tiles/wind/$frame/{z}/{x}/{y}.webp';

  @override
  Future<Result<WindField>> fetchWindField(String frame) {
    requested.add(frame);
    final pending = Completer<Result<WindField>>();
    _pending[frame] = pending;
    return pending.future;
  }

  void complete(String frame, String marker) {
    _pending.remove(frame)!.complete(Ok(_windField(marker)));
  }
}

WindField _windField(String marker) => WindField(
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
  model: marker,
  u: Uint8List.fromList([127, 127, 127, 127]),
  v: Uint8List.fromList([127, 127, 127, 127]),
);

void main() {
  test('frames chronological', () async {
    final layer = WindForecastMapLayer(
      _FakeWindRepository(['1700000600', '1700000000']),
      model: WindForecastModel.gfs,
      referenceOutline: testReferenceOutline(),
    );
    final frames = (await layer.frames()).valueOrNull!;
    expect(frames.map((f) => f.id), ['1700000000', '1700000600']);
  });

  test('id, icon, and model subtitle identify the forecast layer', () {
    final gfs = WindForecastMapLayer(
      _FakeWindRepository(const []),
      model: WindForecastModel.gfs,
      referenceOutline: testReferenceOutline(),
    );
    expect(gfs.id, 'wind-gfs');
    expect(gfs.icon, Icons.air);
    expect(WindForecastModel.gfs.subtitle, '0.25° · 1 h');

    final ecmwf = WindForecastMapLayer(
      _FakeWindRepository(const []),
      model: WindForecastModel.ecmwf,
      referenceOutline: testReferenceOutline(),
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
        referenceOutline: testReferenceOutline(),
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
            'county, township and national frame is drawn over it on attach',
      );

      controller.calls.clear();
      await layer.clear(controller);
      expect(
        controller.calls,
        containsAll([
          'removeLayer:admin-county-outline',
          'removeLayer:admin-town-outline',
          'removeLayer:admin-global-outline',
        ]),
      );
    },
  );

  test('turning the global borders off removes them from a live map', () async {
    final layer = WindForecastMapLayer(
      _FakeWindRepository(_ids(5)),
      model: WindForecastModel.ecmwf,
      referenceOutline: testReferenceOutline(),
    );
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[2]);
    expect(
      controller.calls,
      contains('addLineLayer:admin-global-outline'),
      reason: 'the national border ships on by default',
    );

    controller.calls.clear();
    layer.setShowGlobalOutline(false);
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(controller.calls, contains('removeLayer:admin-global-outline'));
  });

  test('turning the town borders off removes them from a live map', () async {
    final layer = WindForecastMapLayer(
      _FakeWindRepository(_ids(5)),
      model: WindForecastModel.gfs,
      referenceOutline: testReferenceOutline(),
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

  test('clear releases tiles', () async {
    final source = _FakeWindRepository(_ids(5));
    final layer = WindForecastMapLayer(
      source,
      model: WindForecastModel.gfs,
      referenceOutline: testReferenceOutline(),
    );
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
      referenceOutline: testReferenceOutline(),
    );
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    expect(layer.field.value, isNull);

    await layer.show(controller, frames[0]);
    await pumpEventQueue();
    expect(layer.field.value, isNotNull);
    expect(layer.field.value!.model, 'gfs');

    // Detach stops advertising the grid, so a re-attach animates a fresh field
    // rather than the previous layer's stale one.
    await layer.clear(controller);
    expect(layer.field.value, isNull);
  });

  test(
    'scrubbing clears particles and fetches only the settled frame',
    () async {
      final source = _ControlledWindRepository(_ids(3));
      final layer = WindForecastMapLayer(
        source,
        model: WindForecastModel.gfs,
        referenceOutline: testReferenceOutline(),
      );
      final frames = (await layer.frames()).valueOrNull!;
      final controller = RecordingMapController();

      await layer.prepare(controller, frames);
      await layer.show(controller, frames[0]);
      source.complete(frames[0].id, 'initial');
      await pumpEventQueue();
      expect(layer.field.value?.model, 'initial');

      await layer.show(controller, frames[1], scrubbing: true);
      expect(layer.field.value, isNull);
      expect(source.requested, [
        frames[0].id,
      ], reason: 'crossed frames must not download a WND1 grid');

      // The raster already shows frame 1, but finger-up must still settle its
      // ring and start exactly one binary request for that final frame.
      await layer.show(controller, frames[1]);
      expect(source.requested, [frames[0].id, frames[1].id]);
      source.complete(frames[1].id, 'settled');
      await pumpEventQueue();
      expect(layer.field.value?.model, 'settled');
    },
  );

  test('a late old WND1 response cannot overwrite the latest frame', () async {
    final source = _ControlledWindRepository(_ids(3));
    final layer = WindForecastMapLayer(
      source,
      model: WindForecastModel.gfs,
      referenceOutline: testReferenceOutline(),
    );
    final frames = (await layer.frames()).valueOrNull!;
    final controller = RecordingMapController();

    await layer.prepare(controller, frames);
    await layer.show(controller, frames[0]);
    await layer.show(controller, frames[1]);

    source.complete(frames[1].id, 'new');
    await pumpEventQueue();
    expect(layer.field.value?.model, 'new');

    source.complete(frames[0].id, 'old');
    await pumpEventQueue();
    expect(
      layer.field.value?.model,
      'new',
      reason: 'the superseded request completed last and must be discarded',
    );
  });

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
      referenceOutline: testReferenceOutline(),
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
