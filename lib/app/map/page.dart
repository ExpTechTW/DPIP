import 'dart:async';

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
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

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

  final Set<MapLayer> _activeLayers = {};

  static const Set<MapLayer> _earthquakeLayers = {MapLayer.monitor, MapLayer.report, MapLayer.tsunami};

  static const Set<MapLayer> _weatherLayers = {
    MapLayer.radar,
    MapLayer.temperature,
    MapLayer.precipitation,
    MapLayer.wind,
  };

  static const Map<MapLayer, Set<MapLayer>> _allowedRadarCombinations = {
    MapLayer.temperature: {MapLayer.radar, MapLayer.temperature},
    MapLayer.precipitation: {MapLayer.radar, MapLayer.precipitation},
    MapLayer.wind: {MapLayer.radar, MapLayer.wind},
  };

  void _setupTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(Duration(milliseconds: GlobalProviders.map.updateIntervalNotifier.value), (timer) {
      if (_activeLayers.contains(MapLayer.monitor)) {
        final manager = _managers[MapLayer.monitor];
        if (manager != null) {
          manager.tick();
        }
      }
    });
  }

  Set<MapLayer> get activeLayers => _activeLayers;

  MapLayer? get primaryLayer {
    for (final layer in [MapLayer.temperature, MapLayer.precipitation, MapLayer.wind]) {
      if (_activeLayers.contains(layer)) {
        return layer;
      }
    }
    return _activeLayers.isNotEmpty ? _activeLayers.first : null;
  }

  Future<void> syncTimeToRadar(String time) async {
    if (!_activeLayers.contains(MapLayer.radar)) return;

    final radarManager = getLayerManager<RadarMapLayerManager>(MapLayer.radar);
    if (radarManager != null) {
      try {
        await radarManager.updateRadarTime(time);
        TalkerManager.instance.info('Synced radar time to: $time');
      } catch (e, s) {
        TalkerManager.instance.error('Failed to sync radar time', e, s);
      }
    }
  }

  void _setupWeatherLayerTimeSync() {
    final temperatureManager = getLayerManager<TemperatureMapLayerManager>(MapLayer.temperature);
    temperatureManager?.onTimeChanged = (time) {
      syncTimeToRadar(time);
    };

    final precipitationManager = getLayerManager<PrecipitationMapLayerManager>(MapLayer.precipitation);
    precipitationManager?.onTimeChanged = (time) {
      syncTimeToRadar(time);
    };

    final windManager = getLayerManager<WindMapLayerManager>(MapLayer.wind);
    windManager?.onTimeChanged = (time) {
      syncTimeToRadar(time);
    };
  }

  Future<void> _syncRadarTimeOnCombination(MapLayer newLayer) async {
    if (!_activeLayers.contains(MapLayer.radar) || !_weatherLayers.contains(newLayer) || newLayer == MapLayer.radar) {
      return;
    }

    String? newTime;
    switch (newLayer) {
      case MapLayer.temperature:
        final manager = getLayerManager<TemperatureMapLayerManager>(MapLayer.temperature);
        newTime = manager?.currentTemperatureTime.value;
      case MapLayer.precipitation:
        final manager = getLayerManager<PrecipitationMapLayerManager>(MapLayer.precipitation);
        newTime = manager?.currentPrecipitationTime.value;
      case MapLayer.wind:
        final manager = getLayerManager<WindMapLayerManager>(MapLayer.wind);
        newTime = manager?.currentWindTime.value;
      default:
    }

    if (newTime != null) {
      await syncTimeToRadar(newTime);
    }
  }

  T? getLayerManager<T extends MapLayerManager>(MapLayer layer) {
    final manager = _managers[layer];
    return manager is T ? manager : null;
  }

  bool _isAllowedCombination(Set<MapLayer> layers) {
    final earthquakeCount = layers.where((l) => _earthquakeLayers.contains(l)).length;
    if (earthquakeCount > 1) return false;

    final weatherLayers = layers.where((l) => _weatherLayers.contains(l)).toSet();
    if (weatherLayers.isEmpty) return true;

    if (weatherLayers.length == 1) return true;

    if (weatherLayers.length == 2) {
      if (weatherLayers.contains(MapLayer.radar)) {
        final otherLayer = weatherLayers.where((l) => l != MapLayer.radar).first;
        return _allowedRadarCombinations.containsKey(otherLayer);
      }
    }

    return false;
  }

  Future<void> toggleLayer(MapLayer layer) async {
    if (!mounted) return;

    try {
      final manager = _managers[layer];
      if (manager == null) {
        showUnimplementedSnackBar(context);
        throw UnimplementedError('Unknown layer: $layer');
      }

      if (_activeLayers.contains(layer)) {
        if (layer == MapLayer.monitor && _activeLayers.length == 1) {
          return;
        }

        await manager.hide();
        setState(() {
          _activeLayers.remove(layer);
        });

        if (_weatherLayers.contains(layer)) {
          final hasOtherWeatherLayers = _activeLayers.any((l) => _weatherLayers.contains(l));
          if (!hasOtherWeatherLayers) {
            await _showMonitorLayer();
          }
        } else if (_earthquakeLayers.contains(layer) && layer != MapLayer.monitor) {
          await _showMonitorLayer();
        }
      } else {
        final newLayers = Set<MapLayer>.from(_activeLayers)..add(layer);

        if (_earthquakeLayers.contains(layer)) {
          await _clearLayerGroup(_earthquakeLayers);
          await _clearLayerGroup(_weatherLayers);
        } else if (_weatherLayers.contains(layer)) {
          final weatherLayersInNew = newLayers.where((l) => _weatherLayers.contains(l)).toSet();
          if (!_isAllowedCombination(weatherLayersInNew)) {
            if (weatherLayersInNew.contains(MapLayer.radar)) {
              final nonRadarWeatherLayers = _weatherLayers.where((l) => l != MapLayer.radar).toSet();
              await _clearLayerGroup(nonRadarWeatherLayers);
            } else {
              await _clearLayerGroup(_weatherLayers);
            }
          }
          await _clearLayerGroup(_earthquakeLayers);
        }

        if (!manager.didSetup) await manager.setup();
        await manager.show();
        setState(() {
          _activeLayers.add(layer);
        });

        await _syncRadarTimeOnCombination(layer);
      }

      if (_activeLayers.isEmpty) {
        await _controller.animateCamera(CameraUpdate.newLatLngZoom(DpipMap.kTaiwanCenter, 6.4));
        await _showMonitorLayer();
      }
    } catch (e, s) {
      TalkerManager.instance.error('_MapPageState.toggleLayer', e, s);
    }
  }

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
    _managers[MapLayer.radar] = RadarMapLayerManager(context, controller);
    _managers[MapLayer.temperature] = TemperatureMapLayerManager(context, controller);
    _managers[MapLayer.precipitation] = PrecipitationMapLayerManager(context, controller);
    _managers[MapLayer.wind] = WindMapLayerManager(context, controller);

    _setupWeatherLayerTimeSync();

    setBaseMapType(_baseMapType);

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
          }),
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
