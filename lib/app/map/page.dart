import 'dart:async';

import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/managers/precipitation.dart';
import 'package:dpip/app/map/_lib/managers/radar.dart';
import 'package:dpip/app/map/_lib/managers/report.dart';
import 'package:dpip/app/map/_lib/managers/temperature.dart';
// import 'package:dpip/app/map/_lib/managers/tsunami.dart';
import 'package:dpip/app/map/_lib/managers/wind.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/ui/positioned_back_button.dart';
import 'package:dpip/app/map/_widgets/ui/positioned_layer_button.dart';
// import 'package:dpip/app/map/monitor/monitor.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/unimplemented.dart';
import 'package:dpip/widgets/map/map.dart';

class MapPage extends StatefulWidget {
  final MapLayer? initialLayer;

  const MapPage({super.key, this.initialLayer});

  static String route({MapLayer? layer}) => "/map${layer != null ? '?layer=${layer.name}' : ''}";

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  late final MapLibreMapController _controller;
  final _managers = <MapLayer, MapLayerManager>{};

  Timer? _ticker;
  late BaseMapType _baseMapType = GlobalProviders.map.baseMap;
  late MapLayer? _currentLayer = widget.initialLayer ?? GlobalProviders.map.layer;

  void _setupTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(Duration(milliseconds: GlobalProviders.map.updateIntervalNotifier.value), (timer) {
      if (currentLayer != MapLayer.monitor) return;

      final manager = _managers[currentLayer];
      if (manager == null) return;

      manager.tick();
    });
  }

  /// 目前地圖顯示的圖層
  MapLayer? get currentLayer => _currentLayer;

  /// 設定地圖顯示的圖層
  Future<void> setCurrentLayer(MapLayer? layer) async {
    if (!mounted) return;

    await _hideLayers();
    if (!mounted) return;

    try {
      if (layer == null) {
        await _controller.animateCamera(CameraUpdate.newLatLngZoom(DpipMap.kTaiwanCenter, 6.4));
        return;
      }

      final manager = _managers[layer];

      if (manager == null) {
        showUnimplementedSnackBar(context);
        throw UnimplementedError('Unknown layer: $layer');
      }

      if (!manager.didSetup) await manager.setup();

      await _hideLayers();
      await manager.show();
    } catch (e, s) {
      TalkerManager.instance.error('_MapPageState._setCurrentLayer', e, s);
    } finally {
      setState(() => _currentLayer = layer);
    }
  }

  Future<void> setBaseMapType(BaseMapType baseMapType) async {
    if (!mounted) return;

    _hideBaseMapLayers();

    switch (baseMapType) {
      case BaseMapType.exptech:
        await _controller.setLayerVisibility(BaseMapLayerIds.exptechGlobalFill, true);
        await _controller.setLayerVisibility(BaseMapLayerIds.exptechTownFill, true);
        await _controller.setLayerVisibility(BaseMapLayerIds.exptechCountyFill, true);
        await _controller.setLayerVisibility(BaseMapLayerIds.exptechCountyOutline, true);

      case BaseMapType.osm:
        await _controller.setLayerVisibility(BaseMapLayerIds.osmGlobalRaster, true);

      case BaseMapType.google:
        await _controller.setLayerVisibility(BaseMapLayerIds.googleGlobalRaster, true);
    }

    setState(() => _baseMapType = baseMapType);
  }

  /// 隱藏所有圖層
  Future<void> _hideLayers() async {
    if (!mounted) return;

    try {
      for (final manager in _managers.values) {
        await manager.hide();
      }
    } catch (e, s) {
      TalkerManager.instance.error('_MapPageState._hideLayers', e, s);
    }

    setState(() => _currentLayer = null);
  }

  /// 隱藏所有地圖底圖圖層
  void _hideBaseMapLayers() {
    _controller.setLayerVisibility(BaseMapLayerIds.exptechGlobalFill, false);
    _controller.setLayerVisibility(BaseMapLayerIds.exptechTownFill, false);
    _controller.setLayerVisibility(BaseMapLayerIds.exptechCountyFill, false);
    _controller.setLayerVisibility(BaseMapLayerIds.exptechCountyOutline, false);
    _controller.setLayerVisibility(BaseMapLayerIds.osmGlobalRaster, false);
    _controller.setLayerVisibility(BaseMapLayerIds.googleGlobalRaster, false);
  }

  void onMapCreated(MapLibreMapController controller) {
    setState(() => _controller = controller);

    // _managers[MapLayer.monitor] = MonitorMapLayerManager(context, controller);
    _managers[MapLayer.report] = ReportMapLayerManager(context, controller);
    // _managers[MapLayer.tsunami] = TsunamiMapLayerManager(context, controller);
    _managers[MapLayer.radar] = RadarMapLayerManager(context, controller);
    _managers[MapLayer.temperature] = TemperatureMapLayerManager(context, controller);
    _managers[MapLayer.precipitation] = PrecipitationMapLayerManager(context, controller);
    _managers[MapLayer.wind] = WindMapLayerManager(context, controller);

    setBaseMapType(_baseMapType);
    setCurrentLayer(currentLayer);
  }

  @override
  void initState() {
    super.initState();

    GlobalProviders.map.updateIntervalNotifier.addListener(_setupTicker);
    _setupTicker();
  }

  @override
  Widget build(BuildContext context) {
    final manager = _managers[currentLayer];

    return Scaffold(
      body: Stack(
        children: [
          DpipMap(onMapCreated: onMapCreated, tiltGesturesEnabled: true),
          PositionedLayerButton(
            currentLayer: currentLayer,
            currentBaseMap: _baseMapType,
            onChanged: (layer) => setCurrentLayer(layer),
            onBaseMapChanged: (baseMap) => setBaseMapType(baseMap),
          ),
          const PositionedBackButton(),
          if (manager != null) manager.build(context),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
