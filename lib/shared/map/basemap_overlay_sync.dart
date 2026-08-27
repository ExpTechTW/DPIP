/// Applying a surface's base-map options — terrain relief, the OSM detailed
/// overlay, and (via the caller) township labels — to a live MapLibre
/// controller, one instance per map surface.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/shared/map/map_gsi_overlay.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter/material.dart' show Brightness;
import 'package:maplibre_gl/maplibre_gl.dart';

/// Runtime DEM source — identical to what the baked style declares (see
/// [exptechVectorStyle]), so a surface can rebuild the relief after removing
/// it, with no drift between the two descriptions.
const RasterDemSourceProperties terrainSourceProps = RasterDemSourceProperties(
  tiles: [terrainOriginTileUrl],
  bounds: [110.0, 10.0, 132.0, 35.0],
  minzoom: 0,
  maxzoom: terrainSourceMaxZoom,
  tileSize: 512,
  encoding: 'mapbox',
);

/// Runtime hillshade layer — same id, same paint as the baked style.
const HillshadeLayerProperties terrainLayerProps = HillshadeLayerProperties(
  hillshadeIlluminationDirection: terrainIlluminationDirection,
  hillshadeExaggeration: terrainExaggeration,
);

/// The on-map bookkeeping behind the base-map toggles every interactive
/// surface shares (map tab, report detail). A style reload wipes every runtime
/// layer, so [onStyleLoaded] forgets what was mounted and [sync] reconciles
/// against the current settings.
///
/// OSM and terrain are mutually exclusive (the vector overlay brings its own
/// land surface), so [sync] unmounts whichever is no longer selected before
/// mounting its replacement — that way the OSM PBF and DEM tile bursts never
/// overlap. The exclusivity itself is enforced by the caller's controllers
/// ([GsiOverlayController] flips its `mutuallyExclusiveTerrain` notifier);
/// this class only reflects the resulting state.
class BasemapOverlaySync {
  bool _terrainOnMap = false;
  bool _gsiOnMap = false;
  int _gsiAppliedRevision = -1;

  /// The style was (re)loaded: runtime overlays are gone, and the baked
  /// terrain is present on the map iff [bakedTerrain].
  void onStyleLoaded({required bool bakedTerrain}) {
    _terrainOnMap = bakedTerrain;
    _gsiOnMap = false;
    _gsiAppliedRevision = -1;
  }

  /// Reconciles the live map with the current settings, re-reading them after
  /// every native call so a toggle made mid-sync wins. [stillCurrent] guards
  /// every await — the surface may have swapped controllers (a platform-view
  /// recreate) or gone away while a call was in flight.
  Future<void> sync(
    MapLibreMapController controller, {
    required bool Function() showTerrain,
    required GsiOverlayController gsi,
    required Brightness brightness,
    required bool Function() stillCurrent,
  }) async {
    while (stillCurrent()) {
      final showGsi = gsi.enabled;
      final effectiveTerrain = showTerrain() && !showGsi;
      final revision = gsi.revision;
      try {
        // Unmount everything no longer selected before mounting its
        // replacement, so the two tile bursts cannot overlap.
        if (!effectiveTerrain && _terrainOnMap) {
          await controller.removeLayer(terrainHillshadeLayerId);
          if (!stillCurrent()) return;
          await controller.removeSource(terrainSourceId);
          if (!stillCurrent()) return;
          _terrainOnMap = false;
        }
        if (!showGsi && _gsiOnMap) {
          await removeGsiOverlay(controller);
          if (!stillCurrent()) return;
          _gsiOnMap = false;
          _gsiAppliedRevision = revision;
        }

        if (effectiveTerrain && !_terrainOnMap) {
          await controller.addSource(terrainSourceId, terrainSourceProps);
          if (!stillCurrent()) return;
          await controller.addHillshadeLayer(
            terrainSourceId,
            terrainHillshadeLayerId,
            terrainLayerProps,
            belowLayerId: townOutlineLayerId,
          );
          if (!stillCurrent()) return;
          _terrainOnMap = true;
        } else if (showGsi && !_gsiOnMap) {
          await addGsiOverlay(
            controller,
            brightness: brightness,
            selection: gsi,
            belowLayerId: townOutlineLayerId,
          );
          if (!stillCurrent()) return;
          _gsiOnMap = true;
          _gsiAppliedRevision = revision;
        } else if (showGsi && _gsiAppliedRevision != revision) {
          await applyGsiLayerVisibility(controller, gsi, brightness);
          if (!stillCurrent()) return;
          _gsiAppliedRevision = revision;
        }
      } catch (error, stackTrace) {
        Log.handle(error, stackTrace, 'base-map overlay sync');
        return;
      }
      // A toggle landed during the awaits — restart against the new state.
      // Compare the *recomputed* effective terrain (live value minus the OSM
      // exclusion) rather than the raw live value: with OSM on, the raw value
      // is legitimately true while nothing is on the map, and comparing it to
      // the effective false would loop forever.
      if (gsi.enabled == showGsi &&
          (showTerrain() && !gsi.enabled) == effectiveTerrain &&
          gsi.revision == revision) {
        return;
      }
    }
  }
}
