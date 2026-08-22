import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:dpip/shared/map/map_gsi_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/map/raster_timeline_harness.dart';

void main() {
  test('GSI source follows the documented endpoint and zoom contract', () {
    expect(gsiOriginTileUrl, contains(ApiPaths.mapGsiV1));
    expect(gsiSourceProperties.tiles, [gsiOriginTileUrl]);
    expect(gsiSourceProperties.maxzoom, gsiSourceMaxZoom);
    expect(gsiDisplayMaxZoom, greaterThan(gsiSourceMaxZoom));
    expect(gsiBounds, [114.28579, 10.32677, 122.3283, 26.43722]);
  });

  test('both themes define the same 19 documented style layers', () {
    final dark = gsiStyleLayers(Brightness.dark);
    final light = gsiStyleLayers(Brightness.light);
    final darkIds = dark.map((layer) => layer.id).toList();

    expect(dark, hasLength(19));
    expect(darkIds.toSet(), hasLength(19));
    expect(light.map((layer) => layer.id), darkIds);
    expect(
      dark.map((layer) => layer.group).toSet(),
      GsiLayerGroup.values.toSet(),
    );
    expect(
      darkIds,
      containsAll(<String>[
        'gsi-waterway',
        'gsi-building',
        'gsi-transportation',
        'gsi-housenumber',
      ]),
    );
  });

  test('styles preserve the documented visual safeguards', () {
    final layers = {
      for (final layer in gsiStyleLayers(Brightness.dark)) layer.id: layer,
    };

    expect(
      layers['gsi-water']!.properties.toJson()['fill-color'],
      'rgba(0, 0, 0, 0)',
      reason: 'opaque water would reveal the rectangular dataset bounds',
    );
    expect(layers['gsi-transportation']!.filter, [
      '!=',
      ['get', 'class'],
      'ferry',
    ]);
    expect(layers['gsi-transportation-case']!.filter, [
      '!=',
      ['get', 'class'],
      'ferry',
    ]);
    expect(layers['gsi-building']!.minZoom, 13);
    expect(layers['gsi-poi']!.minZoom, 14);
    expect(layers['gsi-housenumber']!.minZoom, 16);
  });

  test('controller starts cold and retains per-group choices', () {
    final controller = GsiOverlayController();
    addTearDown(controller.dispose);

    expect(controller.enabled, isFalse);
    expect(controller.enabledGroupCount, GsiLayerGroup.values.length);
    expect(controller.revision, 0);

    controller.setGroupEnabled(GsiLayerGroup.buildings, false);
    controller.setEnabled(true);

    expect(controller.enabled, isTrue);
    expect(controller.groupEnabled(GsiLayerGroup.buildings), isFalse);
    expect(controller.enabledGroupCount, GsiLayerGroup.values.length - 1);
    expect(controller.revision, 2);

    controller.restoreAll();
    expect(controller.enabledGroupCount, GsiLayerGroup.values.length);
    expect(controller.revision, 3);
  });

  test('native add, grouped visibility, and removal stay coherent', () async {
    final map = RecordingMapController();
    final selection = GsiOverlayController();
    addTearDown(selection.dispose);

    await addGsiOverlay(
      map,
      brightness: Brightness.dark,
      selection: selection,
      belowLayerId: 'town-outline',
    );

    expect(map.calls.first, 'addSource:$gsiSourceId');
    expect(
      map.calls.where(
        (call) => call.startsWith('add') && call != map.calls.first,
      ),
      hasLength(19),
    );
    for (final layer in gsiStyleLayers(Brightness.dark)) {
      expect(map.belowOf(layer.id), 'town-outline', reason: layer.id);
    }

    selection.setGroupEnabled(GsiLayerGroup.roads, false);
    await applyGsiLayerVisibility(map, selection, Brightness.dark);

    expect(map.propertyBatches, 1);
    expect(map.visibilityOf('gsi-transportation-case'), 'none');
    expect(map.visibilityOf('gsi-transportation'), 'none');
    expect(map.visibilityOf('gsi-building'), 'visible');

    await removeGsiOverlay(map);
    expect(map.calls.last, 'removeSource:$gsiSourceId');
    expect(
      map.calls.where((call) => call.startsWith('removeLayer:')),
      hasLength(19),
    );
  });

  test('GSI PBFs share the immutable map-tile cache path', () {
    final uri = Uri.parse(
      'https://static.lb.exptech.dev/api/v1/map/gsi/14/13703/7034.pbf',
    );

    expect(EtagInterceptor.isBasemapPbf(uri), isTrue);
    expect(EtagInterceptor.isImmutableTile(uri), isTrue);
    expect(EtagInterceptor.immutableAssetMarkers, contains(ApiPaths.mapGsiV1));
  });
}
