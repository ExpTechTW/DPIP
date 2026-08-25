import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/shared/map/basemap_overlay_sync.dart';
import 'package:dpip/shared/map/map_gsi_overlay.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter/material.dart' show Brightness;
import 'package:flutter_test/flutter_test.dart';

import 'raster_timeline_harness.dart';

void main() {
  group('BasemapOverlaySync', () {
    late RecordingMapController controller;
    late GsiOverlayController gsi;
    late BasemapOverlaySync sync;
    var showTerrain = true;
    var current = true;

    setUp(() {
      controller = RecordingMapController();
      gsi = GsiOverlayController(SettingsStore.inMemory({}));
      sync = BasemapOverlaySync();
      showTerrain = true;
      current = true;
    });

    Future<void> run() => sync.sync(
      controller,
      showTerrain: () => showTerrain,
      gsi: gsi,
      brightness: Brightness.dark,
      stillCurrent: () => current,
    );

    test(
      'a fresh style with baked terrain needs no calls when nothing changed',
      () async {
        sync.onStyleLoaded(bakedTerrain: true);
        await run();
        expect(controller.calls, isEmpty);
      },
    );

    test('terrain off removes the baked DEM and hillshade', () async {
      sync.onStyleLoaded(bakedTerrain: true);
      showTerrain = false;
      await run();
      expect(controller.calls, [
        'removeLayer:$terrainHillshadeLayerId',
        'removeSource:$terrainSourceId',
      ]);
      // Idempotent — a second sync makes no further calls.
      await run();
      expect(controller.calls, hasLength(2));
    });

    test(
      'terrain on adds the runtime DEM and hillshade below the town outline',
      () async {
        sync.onStyleLoaded(bakedTerrain: false);
        await run();
        expect(controller.calls, [
          'addSource:$terrainSourceId',
          'addHillshadeLayer:$terrainHillshadeLayerId',
        ]);
        expect(controller.sourceProperties[terrainSourceId], isNotNull);
        expect(controller.belowOf(terrainHillshadeLayerId), townOutlineLayerId);
      },
    );

    test('OSM on mounts the GSI overlay instead of terrain', () async {
      sync.onStyleLoaded(bakedTerrain: true);
      showTerrain = false;
      gsi.setEnabled(true);
      await run();
      expect(controller.calls, [
        'removeLayer:$terrainHillshadeLayerId',
        'removeSource:$terrainSourceId',
        'addSource:$gsiSourceId',
        // Every GSI group is enabled by default, so all layers mount.
        for (final l in gsiStyleLayers(Brightness.dark))
          switch (l.kind) {
            GsiLayerKind.fill => 'addFillLayer:${l.id}',
            GsiLayerKind.line => 'addLineLayer:${l.id}',
            GsiLayerKind.symbol => 'addSymbolLayer:${l.id}',
          },
      ]);
    });

    test('OSM off tears the overlay down again', () async {
      sync.onStyleLoaded(bakedTerrain: false);
      gsi.setEnabled(true);
      await run();
      controller.calls.clear();
      gsi.setEnabled(false);
      await run();
      expect(controller.calls, [
        for (final l in gsiStyleLayers(Brightness.dark).reversed)
          'removeLayer:${l.id}',
        'removeSource:$gsiSourceId',
        // Terrain comes back once OSM is off (the mutual exclusion releases).
        'addSource:$terrainSourceId',
        'addHillshadeLayer:$terrainHillshadeLayerId',
      ]);
    });

    test('a group change re-applies visibility without remounting', () async {
      sync.onStyleLoaded(bakedTerrain: false);
      gsi.setEnabled(true);
      await run();
      controller.calls.clear();
      gsi.setGroupEnabled(GsiLayerGroup.poi, false);
      await run();
      expect(controller.propertyBatches, 1, reason: 'one visibility batch');
      expect(controller.calls, [
        for (final l in gsiStyleLayers(Brightness.dark)) 'set:${l.id}:null',
      ]);
      // No re-add of the source or layers.
      expect(controller.calls.where((c) => c.startsWith('add')), isEmpty);
    });

    test('style reload resets the on-map bookkeeping', () async {
      sync.onStyleLoaded(bakedTerrain: false);
      await run();
      expect(controller.calls, isNotEmpty);
      // Reload: baked terrain now present; runtime layers are gone.
      controller.calls.clear();
      sync.onStyleLoaded(bakedTerrain: true);
      await run();
      expect(controller.calls, isEmpty);
    });

    test('a controller swap mid-sync stops the reconciliation', () async {
      sync.onStyleLoaded(bakedTerrain: false);
      current = false;
      await run();
      expect(controller.calls, isEmpty);
    });
  });
}
