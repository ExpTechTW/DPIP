import 'dart:async';

import 'package:dpip/app/home/page.dart';
import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/managers/lightning.dart';
import 'package:dpip/app/map/_lib/managers/monitor.dart';
import 'package:dpip/app/map/_lib/managers/precipitation.dart';
import 'package:dpip/app/map/_lib/managers/radar.dart';
import 'package:dpip/app/map/_lib/managers/report.dart';
import 'package:dpip/app/map/_lib/managers/temperature.dart';
import 'package:dpip/app/map/_lib/managers/tsunami.dart';
import 'package:dpip/app/map/_lib/managers/wind.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/ui/positioned_back_button.dart';
import 'package:dpip/app/map/_widgets/ui/positioned_layer_button.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/extensions/maplibre.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class MapPageOptions {
  final Set<MapLayer>? initialLayers;
  final String? reportId;
  final int? replayTimestamp;

  MapPageOptions({this.initialLayers, this.reportId, this.replayTimestamp});

  factory MapPageOptions.fromQueryParameters(
    Map<String, String> queryParameters,
  ) {
    final layers = queryParameters['layers']?.split(',');
    final report = queryParameters['report'];
    final replay = queryParameters['replay'];

    return MapPageOptions(
      initialLayers: layers
          ?.map((layer) => MapLayer.values.byName(layer))
          .toSet(),
      reportId: report,
      replayTimestamp: replay == null ? null : int.tryParse(replay),
    );
  }
}

class MapPage extends StatefulWidget {
  final MapPageOptions? options;

  const MapPage({super.key, this.options});

  static String route({MapPageOptions? options}) {
    if (options == null) return '/map';

    final parameters = [];

    if (options.initialLayers != null)
      parameters.add(
        'layers=${options.initialLayers!.map((e) => e.name).join(',')}',
      );
    if (options.reportId != null) parameters.add('report=${options.reportId}');
    if (options.replayTimestamp != null)
      parameters.add('replay=${options.replayTimestamp}');

    return "/map?${parameters.join('&')}";
  }

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  late final MapLibreMapController _controller;
  final _managers = <MapLayer, MapLayerManager>{};

  Timer? _ticker;
  late BaseMapType _baseMapType = GlobalProviders.map.baseMap;

  late Set<MapLayer> _activeLayers =
      widget.options?.initialLayers ??
      (widget.options?.replayTimestamp != null ? {MapLayer.monitor} : {});
  Future<void>? _toggleLayerOperation;

  void _setupTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      Duration(
        milliseconds: 1000 ~/ GlobalProviders.map.updateIntervalNotifier.value,
      ),
      (timer) {
        for (final layer in _activeLayers) {
          _managers[layer]?.tick();
        }
      },
    );
  }

  Set<MapLayer> get activeLayers => _activeLayers;

  MapLayer? get primaryLayer {
    for (final layer in [
      MapLayer.temperature,
      MapLayer.precipitation,
      MapLayer.wind,
      MapLayer.lightning,
    ]) {
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
      } catch (e, s) {
        TalkerManager.instance.error('Failed to sync radar time', e, s);
      }
    }
  }

  void _setupWeatherLayerTimeSync() {
    final temperatureManager = getLayerManager<TemperatureMapLayerManager>(
      MapLayer.temperature,
    );
    temperatureManager?.onTimeChanged = (time) {
      syncTimeToRadar(time);
    };

    final precipitationManager = getLayerManager<PrecipitationMapLayerManager>(
      MapLayer.precipitation,
    );
    precipitationManager?.onTimeChanged = (time) {
      syncTimeToRadar(time);
    };

    final windManager = getLayerManager<WindMapLayerManager>(MapLayer.wind);
    windManager?.onTimeChanged = (time) {
      syncTimeToRadar(time);
    };

    final lightningManager = getLayerManager<LightningMapLayerManager>(
      MapLayer.lightning,
    );
    lightningManager?.onTimeChanged = (time) {
      syncTimeToRadar(time);
    };
  }

  Future<void> _syncRadarTimeOnCombination(MapLayer newLayer) async {
    if (!_activeLayers.contains(MapLayer.radar) ||
        !kWeatherLayers.contains(newLayer) ||
        newLayer == MapLayer.radar) {
      return;
    }

    String? newTime;
    switch (newLayer) {
      case MapLayer.temperature:
        final manager = getLayerManager<TemperatureMapLayerManager>(
          MapLayer.temperature,
        );
        newTime = manager?.currentTemperatureTime.value;
      case MapLayer.precipitation:
        final manager = getLayerManager<PrecipitationMapLayerManager>(
          MapLayer.precipitation,
        );
        newTime = manager?.currentPrecipitationTime.value;
      case MapLayer.wind:
        final manager = getLayerManager<WindMapLayerManager>(MapLayer.wind);
        newTime = manager?.currentWindTime.value;
      case MapLayer.lightning:
        final manager = getLayerManager<LightningMapLayerManager>(
          MapLayer.lightning,
        );
        newTime = manager?.currentLightningTime.value;
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

  Future<void> toggleLayer(
    MapLayer layer,
    bool show,
    Set<MapLayer> activeLayers,
  ) async {
    // Wait for any pending operations to complete
    await _toggleLayerOperation;

    // Queue this operation
    _toggleLayerOperation = _performToggleLayer(layer, show, activeLayers);
    await _toggleLayerOperation;
  }

  Future<void> _performToggleLayer(
    MapLayer layer,
    bool show,
    Set<MapLayer> activeLayers,
  ) async {
    if (!mounted) return;

    // Update state immediately to prevent race conditions
    final previousLayers = _activeLayers;
    setState(() => _activeLayers = activeLayers);

    try {
      final manager = _managers[layer];
      if (manager == null) {
        throw UnimplementedError('Unknown layer: $layer');
      }

      if (show) {
        if (!manager.didSetup) await manager.setup();
        await manager.show();
        await _syncRadarTimeOnCombination(layer);
      } else {
        await manager.hide();
      }

      if (_activeLayers.isEmpty) {
        await _controller.animateCamera(
          CameraUpdate.newLatLngZoom(DpipMap.kTaiwanCenter, 6.4),
        );
      }
    } catch (e, s) {
      // Revert state on error
      setState(() => _activeLayers = previousLayers);
      TalkerManager.instance.error('_MapPageState.toggleLayer', e, s);
    }
  }

  Future<void> setBaseMapType(BaseMapType baseMapType) async {
    if (!mounted) return;

    await _controller.setBaseMap(baseMapType);

    setState(() => _baseMapType = baseMapType);
  }

  Future<void> setLayers(Set<MapLayer> layers) async {
    if (!mounted) return;

    for (final layer in layers) {
      final manager = _managers[layer];
      if (manager != null) {
        if (!manager.didSetup) await manager.setup();
        await manager.show();
      }
    }

    setState(() => _activeLayers = layers);
  }

  void onMapCreated(MapLibreMapController controller) {
    setState(() => _controller = controller);
  }

  void onStyleLoaded() {
    final controller = _controller;

    for (final manager in _managers.values) {
      manager.dispose();
    }

    _managers[MapLayer.monitor] = MonitorMapLayerManager(
      context,
      controller,
      isReplayMode: widget.options?.replayTimestamp != null,
      replayTimestamp: widget.options?.replayTimestamp,
    );
    _managers[MapLayer.report] = ReportMapLayerManager(
      context,
      controller,
      initialReportId: widget.options?.reportId,
    );
    _managers[MapLayer.tsunami] = TsunamiMapLayerManager(context, controller);
    _managers[MapLayer.radar] = RadarMapLayerManager(
      context,
      controller,
      getActiveLayerCount: () => _activeLayers.length,
    );
    _managers[MapLayer.temperature] = TemperatureMapLayerManager(
      context,
      controller,
    );
    _managers[MapLayer.precipitation] = PrecipitationMapLayerManager(
      context,
      controller,
    );
    _managers[MapLayer.wind] = WindMapLayerManager(context, controller);
    _managers[MapLayer.lightning] = LightningMapLayerManager(
      context,
      controller,
    );

    _setupWeatherLayerTimeSync();

    setLayers(_activeLayers);
  }

  void _handleBack() {
    for (final layer in _activeLayers) {
      final manager = _managers[layer];
      if (manager != null && !manager.shouldPop) {
        manager.onPopInvoked();
        return;
      }
    }
    context.go(HomePage.route);
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
          DpipMap(
            baseMapType: _baseMapType,
            onMapCreated: onMapCreated,
            onStyleLoadedCallback: onStyleLoaded,
          ),
          PositionedLayerButton(
            activeLayers: _activeLayers,
            currentBaseMap: _baseMapType,
            isReplayMode: widget.options?.replayTimestamp != null,
            onLayerChanged: toggleLayer,
            onBaseMapChanged: setBaseMapType,
          ),
          PositionedBackButton(onPressed: _handleBack),
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
    GlobalProviders.map.updateIntervalNotifier.removeListener(_setupTicker);

    super.dispose();
  }
}

class MapMonitorPage extends StatelessWidget {
  final int replayTimestamp;

  const MapMonitorPage({super.key, required this.replayTimestamp});

  @override
  Widget build(BuildContext context) {
    return MapPage(
      options: MapPageOptions(
        initialLayers: {MapLayer.monitor},
        replayTimestamp: replayTimestamp,
      ),
    );
  }
}
