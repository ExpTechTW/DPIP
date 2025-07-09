import 'dart:async';

import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/managers/monitor.dart';
import 'package:dpip/app/map/_lib/managers/precipitation.dart';
import 'package:dpip/app/map/_lib/managers/radar.dart';
import 'package:dpip/app/map/_lib/managers/report.dart';
import 'package:dpip/app/map/_lib/managers/temperature.dart';
// import 'package:dpip/app/map/_lib/managers/tsunami.dart';
import 'package:dpip/app/map/_lib/managers/wind.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/ui/positioned_back_button.dart';
import 'package:dpip/app/map/_widgets/ui/positioned_layer_button.dart';
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
  
  // 改為使用Set來存儲多個活動圖層
  final Set<MapLayer> _activeLayers = {};

  // 定義地震類和氣象類圖層
  static const Set<MapLayer> _earthquakeLayers = {
    MapLayer.monitor,
    MapLayer.report,
    MapLayer.tsunami,
  };

  static const Set<MapLayer> _weatherLayers = {
    MapLayer.radar,
    MapLayer.temperature,
    MapLayer.precipitation,
    MapLayer.wind,
  };

  void _setupTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(Duration(milliseconds: GlobalProviders.map.updateIntervalNotifier.value), (timer) {
      // 只有當強震監視器圖層活動時才進行更新
      if (_activeLayers.contains(MapLayer.monitor)) {
        final manager = _managers[MapLayer.monitor];
        if (manager != null) {
          manager.tick();
        }
      }
    });
  }

  /// 獲取當前活動的圖層
  Set<MapLayer> get activeLayers => _activeLayers;

  /// 切換圖層的顯示狀態
  Future<void> toggleLayer(MapLayer layer) async {
    if (!mounted) return;

    try {
      final manager = _managers[layer];
      if (manager == null) {
        showUnimplementedSnackBar(context);
        throw UnimplementedError('Unknown layer: $layer');
      }

      if (_activeLayers.contains(layer)) {
        // 如果是強震監視器且沒有其他圖層，不允許取消選中
        if (layer == MapLayer.monitor && _activeLayers.length == 1) {
          return;
        }
        
        // 如果圖層已經活動，則隱藏它
        await manager.hide();
        setState(() {
          _activeLayers.remove(layer);
        });
        
        // 只有在氣象類圖層取消且沒有其他氣象類圖層時，才回到強震監視器
        if (_weatherLayers.contains(layer)) {
          final hasOtherWeatherLayers = _activeLayers.any((l) => _weatherLayers.contains(l));
          if (!hasOtherWeatherLayers) {
            await _showMonitorLayer();
          }
        }
        // 如果取消的是地震類圖層（非強震監視器），回到強震監視器
        else if (_earthquakeLayers.contains(layer) && layer != MapLayer.monitor) {
          await _showMonitorLayer();
        }
      } else {
        // 檢查互斥性
        if (_earthquakeLayers.contains(layer)) {
          // 地震類圖層互斥，清除所有其他地震類圖層
          await _clearLayerGroup(_earthquakeLayers);
          // 同時清除氣象類圖層
          await _clearLayerGroup(_weatherLayers);
        } else if (_weatherLayers.contains(layer)) {
          // 氣象類圖層可以複選，但要清除地震類圖層
          await _clearLayerGroup(_earthquakeLayers);
        }

        // 顯示選中的圖層
        if (!manager.didSetup) await manager.setup();
        await manager.show();
        setState(() {
          _activeLayers.add(layer);
        });
      }

      // 如果沒有活動圖層，重置地圖視角並顯示強震監視器
      if (_activeLayers.isEmpty) {
        await _controller.animateCamera(CameraUpdate.newLatLngZoom(DpipMap.kTaiwanCenter, 6.4));
        await _showMonitorLayer();
      }
    } catch (e, s) {
      TalkerManager.instance.error('_MapPageState.toggleLayer', e, s);
    }
  }

  /// 顯示強震監視器圖層
  Future<void> _showMonitorLayer() async {
    if (_activeLayers.contains(MapLayer.monitor)) return;
    
    final manager = _managers[MapLayer.monitor];
    if (manager != null) {
      if (!manager.didSetup) await manager.setup();
      await manager.show();
      setState(() {
        _activeLayers.add(MapLayer.monitor);
      });
    }
  }

  /// 清除指定圖層組
  Future<void> _clearLayerGroup(Set<MapLayer> layers) async {
    for (final layer in layers) {
      if (_activeLayers.contains(layer)) {
        final manager = _managers[layer];
        if (manager != null) {
          await manager.hide();
        }
      }
    }
    setState(() {
      _activeLayers.removeAll(layers);
    });
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

    _managers[MapLayer.monitor] = MonitorMapLayerManager(context, controller);
    _managers[MapLayer.report] = ReportMapLayerManager(context, controller);
    // _managers[MapLayer.tsunami] = TsunamiMapLayerManager(context, controller);
    _managers[MapLayer.radar] = RadarMapLayerManager(context, controller);
    _managers[MapLayer.temperature] = TemperatureMapLayerManager(context, controller);
    _managers[MapLayer.precipitation] = PrecipitationMapLayerManager(context, controller);
    _managers[MapLayer.wind] = WindMapLayerManager(context, controller);

    setBaseMapType(_baseMapType);
    
    // 如果有初始圖層，則顯示它；否則預設顯示強震監視器
    if (widget.initialLayer != null) {
      toggleLayer(widget.initialLayer!);
    } else {
      _showMonitorLayer();
    }
  }

  @override
  void initState() {
    super.initState();

    GlobalProviders.map.updateIntervalNotifier.addListener(_setupTicker);
    _setupTicker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DpipMap(onMapCreated: onMapCreated, tiltGesturesEnabled: true),
          PositionedLayerButton(
            activeLayers: _activeLayers,
            currentBaseMap: _baseMapType,
            onLayerToggled: toggleLayer,
            onBaseMapChanged: setBaseMapType,
          ),
          const PositionedBackButton(),
          ..._activeLayers.map((layer) {
            final manager = _managers[layer];
            if (manager != null) {
              return manager.build(context);
            }
            return const SizedBox.shrink();
          }).toList(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();

    for (final manager in _managers.values) {
      manager.dispose();
    }

    super.dispose();
  }
}
