import 'dart:async';

import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/managers/radar.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/ui/positioned_back_button.dart';
import 'package:dpip/app/map/_widgets/ui/positioned_layer_button.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';

class MapPage extends StatefulWidget {
  final MapLayer? initialLayer;

  const MapPage({super.key, this.initialLayer});

  static String route({MapLayer? layer}) => "/map${layer != null ? '?layer=${layer.name}' : ''}";

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final _managers = <MapLayer, MapLayerManager>{};

  Timer? _ticker;
  late MapLayer? _currentLayer = widget.initialLayer;

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

    final manager = _managers[layer];

    if (manager == null) throw UnimplementedError('Unknown layer: $layer');

    try {
      if (!manager.didSetup) await manager.setup();

      await _hideLayers();
      await manager.show();

      setState(() => _currentLayer = layer);
    } catch (e, s) {
      TalkerManager.instance.error('_MapPageState._setCurrentLayer', e, s);
    }
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

  /// 釋放所有圖層
  Future<void> _disposeLayers() async {
    if (!mounted) return;

    try {
      for (final MapEntry(:key, :value) in _managers.entries) {
        if (key == currentLayer) setState(() => _currentLayer = null);
        await value.remove();
        _managers.remove(key);
      }
    } catch (e, s) {
      TalkerManager.instance.error('_MapPageState._disposeLayers', e, s);
    }
  }

  void onMapCreated(MapLibreMapController controller) {
    _managers[MapLayer.radar] = RadarMapLayerManager(context, controller);
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

    return Stack(
      children: [
        DpipMap(onMapCreated: onMapCreated),
        PositionedLayerButton(currentLayer: currentLayer, onChanged: (layer) => setCurrentLayer(layer)),
        const PositionedBackButton(),
        if (manager != null) manager.build(context),
      ],
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _disposeLayers();
    super.dispose();
  }
}
