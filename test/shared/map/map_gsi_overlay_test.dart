import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/etag_interceptor.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/shared/map/map_gsi_overlay.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/map/raster_timeline_harness.dart';

void main() {
  test('OSM source follows the documented endpoint and zoom contract', () {
    expect(gsiOriginTileUrl, contains(ApiPaths.mapOsmV1));
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

  test('every OSM setting appears once in a named section', () {
    final grouped = gsiLayerGroupsBySection.values.expand((groups) => groups);

    expect(gsiLayerGroupsBySection.keys, GsiLayerSection.values);
    expect(grouped, hasLength(GsiLayerGroup.values.length));
    expect(grouped.toSet(), GsiLayerGroup.values.toSet());
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

    for (final layer in layers.values.where(
      (layer) => layer.kind == GsiLayerKind.line,
    )) {
      final dash = layer.properties.toJson()['line-dasharray'];
      if (dash != null) {
        expect(
          dash,
          everyElement(isA<num>()),
          reason:
              '${layer.id}: iOS MapLibre Native aborts on a data-driven '
              'line-dasharray expression',
        );
      }
    }
  });

  test('controller starts cold and retains per-group choices', () {
    final controller = GsiOverlayController(SettingsStore.inMemory({}));
    addTearDown(controller.dispose);

    expect(controller.enabled, isFalse);
    expect(
      controller.enabledGroupCount,
      GsiLayerGroup.values.length - gsiDefaultDisabledGroups.length,
    );
    expect(controller.groupEnabled(GsiLayerGroup.parks), isFalse);
    expect(controller.groupEnabled(GsiLayerGroup.boundaries), isFalse);
    expect(controller.revision, 0);

    controller.setGroupEnabled(GsiLayerGroup.buildings, false);
    controller.setEnabled(true);

    expect(controller.enabled, isTrue);
    expect(controller.groupEnabled(GsiLayerGroup.buildings), isFalse);
    expect(
      controller.enabledGroupCount,
      GsiLayerGroup.values.length - gsiDefaultDisabledGroups.length - 1,
    );
    expect(controller.revision, 2);

    controller.restoreAll();
    expect(controller.enabledGroupCount, GsiLayerGroup.values.length);
    expect(controller.revision, 3);
  });

  test(
    'a choice persists — a fresh controller on the same store reads it back',
    () {
      final settings = SettingsStore.inMemory({});
      final first = GsiOverlayController(settings);
      addTearDown(first.dispose);
      first.setEnabled(true);
      first.setGroupEnabled(GsiLayerGroup.parks, true);
      first.setGroupEnabled(GsiLayerGroup.buildings, false);

      final second = GsiOverlayController(settings);
      addTearDown(second.dispose);

      expect(second.enabled, isTrue);
      expect(second.groupEnabled(GsiLayerGroup.parks), isTrue);
      expect(second.groupEnabled(GsiLayerGroup.buildings), isFalse);
    },
  );

  test(
    "forceEnabled starts the surface on without overwriting a saved 'off'",
    () {
      final settings = SettingsStore.inMemory({'map.gsiEnabled': false});
      final controller = GsiOverlayController(settings, forceEnabled: true);
      addTearDown(controller.dispose);

      expect(controller.enabled, isTrue);
      expect(settings.getBool(SettingKeys.mapGsiEnabled), isFalse);
    },
  );

  test('a stale saved group name is dropped instead of crashing', () {
    final settings = SettingsStore.inMemory({
      'map.gsiEnabledGroups': ['roads', 'no-longer-a-group'],
    });
    final controller = GsiOverlayController(settings);
    addTearDown(controller.dispose);

    expect(controller.enabledGroupCount, 1);
    expect(controller.groupEnabled(GsiLayerGroup.roads), isTrue);
  });

  test('enabling OSM synchronously turns mutually-exclusive terrain off', () {
    final terrain = ValueNotifier<bool>(true);
    final controller = GsiOverlayController(
      SettingsStore.inMemory({}),
      mutuallyExclusiveTerrain: terrain,
    );
    addTearDown(terrain.dispose);
    addTearDown(controller.dispose);

    controller.setEnabled(true);

    expect(controller.enabled, isTrue);
    expect(terrain.value, isFalse);
  });

  test('an OSM-first surface starts enabled with terrain off', () {
    final terrain = ValueNotifier<bool>(true);
    final controller = GsiOverlayController(
      SettingsStore.inMemory({}),
      mutuallyExclusiveTerrain: terrain,
      forceEnabled: true,
    );
    addTearDown(terrain.dispose);
    addTearDown(controller.dispose);

    expect(controller.enabled, isTrue);
    expect(terrain.value, isFalse);
  });

  test('native add, grouped visibility, and removal stay coherent', () async {
    final map = RecordingMapController();
    final selection = GsiOverlayController(SettingsStore.inMemory({}));
    addTearDown(selection.dispose);

    await addGsiOverlay(
      map,
      brightness: Brightness.dark,
      selection: selection,
      belowLayerId: townOutlineLayerId,
      groundBelowLayerId: townFillLayerId,
    );

    expect(map.calls.first, 'addSource:$gsiSourceId');
    expect(
      map.calls.where(
        (call) => call.startsWith('add') && call != map.calls.first,
      ),
      hasLength(19),
    );
    for (final layer in gsiStyleLayers(Brightness.dark)) {
      // The ground goes under the township fill (which carries the shaking
      // wash); everything thin stays above it.
      expect(
        map.belowOf(layer.id),
        layer.kind == GsiLayerKind.fill ? townFillLayerId : townOutlineLayerId,
        reason: layer.id,
      );
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

  test('the shaking wash sits over OSM ground, under OSM roads', () async {
    // 強震監視器 and 重播 tint the island by recolouring the baked `town` fill.
    // With every OSM layer anchored at one place, the overlay's 0.9-opacity
    // landcover painted straight over that wash, and a township with no OSM
    // polygon under it was the only one that still showed its colour — a map
    // whose blank patches read as "no shaking here".
    final map = RecordingMapController();
    final selection = GsiOverlayController(SettingsStore.inMemory({}));
    addTearDown(selection.dispose);

    await addGsiOverlay(
      map,
      brightness: Brightness.dark,
      selection: selection,
      belowLayerId: townOutlineLayerId,
      groundBelowLayerId: townFillLayerId,
    );

    for (final layer in gsiStyleLayers(Brightness.dark)) {
      final ground = layer.kind == GsiLayerKind.fill;
      expect(
        map.isAbove(townFillLayerId, layer.id),
        ground,
        reason: '${layer.id} vs the wash',
      );
    }
    // Named outright, so a layer changing kind cannot quietly move sides.
    expect(map.isAbove(townFillLayerId, 'gsi-landcover'), isTrue);
    expect(map.isAbove(townFillLayerId, 'gsi-building'), isTrue);
    expect(map.isAbove('gsi-transportation', townFillLayerId), isTrue);
    expect(map.isAbove('gsi-place', townFillLayerId), isTrue);
    // …and the base map's own borders still end up over all of it.
    expect(map.isAbove(townOutlineLayerId, 'gsi-place'), isTrue);
    expect(map.isAbove(outlineLayerId, 'gsi-transportation'), isTrue);
  });

  test('OSM PBFs share the immutable map-tile cache path', () {
    final uri = Uri.parse(
      'https://static.lb.exptech.dev/api/v1/map/gsi/14/13703/7034.pbf',
    );

    expect(EtagInterceptor.isBasemapPbf(uri), isTrue);
    expect(EtagInterceptor.isImmutableTile(uri), isTrue);
    expect(EtagInterceptor.immutableAssetMarkers, contains(ApiPaths.mapOsmV1));
  });
}
