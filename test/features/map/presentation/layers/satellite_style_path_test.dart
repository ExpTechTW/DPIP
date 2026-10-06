/// A thermal band's style change updates the repository path and asks the
/// scaffold to reload. A reflectance band ignores temperature styles. The
/// country outline is added on attach and removed when the toggle goes off.
library;

import 'package:dpip/features/map/presentation/layers/satellite_layer.dart';
import 'package:dpip/features/map/presentation/widgets/satellite_legend.dart';
import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../raster_timeline_harness.dart';

class _Repo extends FakeRasterFrameSource implements SatelliteRepository {
  _Repo() : super(const ['1700000000']);

  String? styleKey;

  @override
  String tileUrl(String frame) => 'https://example.invalid/$frame/{z}/{x}/{y}';

  @override
  void setStyle(String? style) => styleKey = style;
}

class _ThrowingLines extends RecordingMapController {
  @override
  Future<void> addLineLayer(
    String sourceId,
    String layerId,
    LineLayerProperties properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    bool enableInteraction = true,
  }) async {
    throw StateError('style gone');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('style changes reload only when the channel can show them', () async {
    final ir = _Repo();
    final layer = SatelliteMapLayer(
      ir,
      channel: SatelliteChannel.irClean,
      referenceOutline: testReferenceOutline(),
    );
    var reloads = 0;
    layer.setStyle(SatelliteStyle.jma, onReloadActive: () async => reloads++);
    expect(layer.style.value, SatelliteStyle.jma);
    expect(ir.styleKey, 'jma');
    expect(reloads, 1);
    layer.setStyle(SatelliteStyle.jma, onReloadActive: () async => reloads++);
    expect(reloads, 1);

    final vis = _Repo();
    final blue = SatelliteMapLayer(
      vis,
      channel: SatelliteChannel.visibleBlue,
      referenceOutline: testReferenceOutline(),
    );
    blue.setStyle(SatelliteStyle.bd, onReloadActive: () async => reloads++);
    expect(blue.style.value, SatelliteStyle.gray);
    expect(vis.styleKey, isNull);

    expect(layer.id, 'satellite');
    expect(blue.id, 'satellite-${SatelliteChannel.visibleBlue.key}');
    expect(layer.icon, Icons.satellite_alt_outlined);
    expect(layer.opacity, 1);
    expect(layer.rasterBelowLayerId, townLabelLayerId);
  });

  test(
    'the country outline is added, removed, and retried after a throw',
    () async {
      final outline = testReferenceOutline();
      final layer = SatelliteMapLayer(
        _Repo(),
        channel: SatelliteChannel.irClean,
        referenceOutline: outline,
      );
      final map = RecordingMapController();
      await layer.onAttached(map);
      expect(
        map.calls,
        contains('addLineLayer:$satelliteGlobalOutlineLayerId'),
      );
      map.calls.clear();
      layer.setShowGlobalOutline(false);
      await Future<void>.delayed(Duration.zero);
      expect(map.calls, contains('removeLayer:$satelliteGlobalOutlineLayerId'));
      await layer.onDetached(map);

      final retry = SatelliteMapLayer(
        _Repo(),
        channel: SatelliteChannel.ash,
        referenceOutline: testReferenceOutline(),
      );
      await retry.onAttached(_ThrowingLines());
      final fresh = RecordingMapController();
      await retry.onDetached(fresh);
      await retry.onAttached(fresh);
      expect(
        fresh.calls,
        contains('addLineLayer:$satelliteGlobalOutlineLayerId'),
      );
    },
  );

  testWidgets('legend and chrome follow the channel', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final layer = SatelliteMapLayer(
      _Repo(),
      channel: SatelliteChannel.irClean,
      referenceOutline: testReferenceOutline(),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                Text(layer.label(context)),
                Text(layer.subtitle(context)!),
                layer.buildLegend(context),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text(l10n.mapLayerSatelliteB13), findsWidgets);
    expect(find.byType(SatelliteLegend), findsOneWidget);
  });
}
