import 'dart:async';

import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_widgets/layer_toggle_sheet.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/material.dart';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class MapPage extends StatefulWidget {
  final MapLayer? initialLayer;

  const MapPage({super.key, this.initialLayer});

  static String route({MapLayer? layer}) => "/map${layer != null ? '?layer=${layer.name}' : ''}";

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _managers = <MapLayer, MapLayerManager>{};

  Timer? _ticker;
  late MapLayer? _currentLayer = widget.initialLayer;

  void _setupTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(Duration(milliseconds: GlobalProviders.map.updateIntervalNotifier.value), (timer) {
      _tick();
    });
  }

  void _tick() {
    if (_currentLayer != MapLayer.monitor) return;

    final data = GlobalProviders.data.eew;
    if (data.isEmpty) return;
  }

  /// 目前地圖顯示的圖層
  MapLayer? get currentLayer => _currentLayer;

  /// 設定地圖顯示的圖層
  Future<void> setCurrentLayer(MapLayer? layer) async {
    if (!mounted) return;

    if (layer == null) {
      await _hideLayers();
      return;
    }

    final manager = _managers[layer];

    if (manager == null) throw UnimplementedError('Unknown layer: $layer');

    try {
      if (!manager.didSetup) await manager.setup();

      await _hideLayers();
      await manager.show();

      _currentLayer = layer;
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

    _currentLayer = null;
  }

  /// 釋放所有圖層
  Future<void> _disposeLayers() async {
    if (!mounted) return;

    try {
      for (final MapEntry(:key, :value) in _managers.entries) {
        if (key == _currentLayer) _currentLayer = null;
        await value.dispose();
        _managers.remove(key);
      }
    } catch (e, s) {
      TalkerManager.instance.error('_MapPageState._disposeLayers', e, s);
    }
  }

  void onMapCreated(MapLibreMapController controller) {
    _managers[MapLayer.radar] = RadarMapLayerManager(context, controller);
    if (_currentLayer != null) setCurrentLayer(_currentLayer!);
  }

  @override
  void initState() {
    super.initState();

    GlobalProviders.map.updateIntervalNotifier.addListener(_setupTicker);
    _setupTicker();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DpipMap(onMapCreated: onMapCreated),
        Positioned(
          top: 24,
          right: 24,
          child: SafeArea(
            child: IconButton.filledTonal(
              icon: const Icon(Symbols.layers_rounded),
              onPressed:
                  () => showModalBottomSheet(
                    context: context,
                    useRootNavigator: true,
                    useSafeArea: true,
                    isScrollControlled: true,
                    constraints: context.bottomSheetConstraints,
                    builder:
                        (context) =>
                            LayerToggleSheet(currentLayer: currentLayer, onChanged: (layer) => setCurrentLayer(layer)),
                  ),
            ),
          ),
        ),
        Positioned(
          top: 24,
          left: 24,
          child: SafeArea(
            child: IconButton.filledTonal(icon: const Icon(Symbols.arrow_back_rounded), onPressed: context.pop),
          ),
        ),
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
