import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

abstract class MapLayerManager {
  final BuildContext context;
  final MapLibreMapController controller;

  bool didSetup = false;
  bool disposed = false;
  bool visible = false;

  MapLayerManager(this.context, this.controller);

  /// 初始化圖層，並將 [didSetup] 設為 `true`
  Future<void> setup();

  /// 隱藏圖層
  Future<void> hide();

  /// 顯示圖層
  Future<void> show();

  /// 釋放資源，釋放後的圖層將無法再被使用
  Future<void> dispose();
}

class RadarMapLayerManager extends MapLayerManager {
  RadarMapLayerManager(super.context, super.controller);

  @override
  Future<void> setup() async {
    if (disposed) throw Exception('RadarMapLayerManager is disposed');

    try {
      final isRadarSourceExists = (await controller.getSourceIds()).contains(MapSourceIds.radar);
      final isRadarLayerExists = (await controller.getLayerIds()).contains(MapLayerIds.radar);

      if (isRadarSourceExists && isRadarLayerExists) return;

      if (!isRadarSourceExists) {
        final radarList = await ExpTech().getRadarList();
        if (!context.mounted) return;

        final tileUrl = 'https://api-1.exptech.dev/api/v1/tiles/radar/${radarList.last}/{z}/{x}/{y}.png';

        await controller.addSource(MapSourceIds.radar, RasterSourceProperties(tiles: [tileUrl], tileSize: 256));
        TalkerManager.instance.info('Added Source "${MapSourceIds.radar}"');

        if (!context.mounted) return;
      }

      if (!isRadarLayerExists) {
        await controller.addLayer(
          MapSourceIds.radar,
          MapLayerIds.radar,
          const RasterLayerProperties(visibility: 'none'),
          belowLayerId: BaseMapLayerIds.countyOutline,
        );
        TalkerManager.instance.info('Added Layer "${MapLayerIds.radar}"');
      }

      didSetup = true;
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.setup', e, s);
    }
  }

  @override
  Future<void> hide() async {
    if (disposed) throw Exception('RadarMapLayerManager is disposed');
    if (!visible) return;

    try {
      await controller.setLayerVisibility(MapLayerIds.radar, false);
      TalkerManager.instance.info('Hiding Layer "${MapLayerIds.radar}"');

      visible = false;
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (disposed) throw Exception('RadarMapLayerManager is disposed');
    if (visible) return;

    try {
      await controller.setLayerVisibility(MapLayerIds.radar, true);
      TalkerManager.instance.info('Showing Layer "${MapLayerIds.radar}"');

      visible = true;
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.show', e, s);
    }
  }

  @override
  Future<void> dispose() async {
    if (disposed) throw Exception('RadarMapLayerManager is disposed');

    try {
      await controller.removeLayer(MapLayerIds.radar);
      TalkerManager.instance.info('Removed Layer "${MapLayerIds.radar}"');

      await controller.removeSource(MapSourceIds.radar);
      TalkerManager.instance.info('Removed Source "${MapSourceIds.radar}"');
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.dispose', e, s);
    }

    disposed = true;
    didSetup = false;
  }
}
