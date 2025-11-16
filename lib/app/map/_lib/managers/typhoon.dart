import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/morphing_sheet.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class TyphoonMapLayerManager extends MapLayerManager {
  TyphoonMapLayerManager(super.context, super.controller);

  final currentTyphoonTime = ValueNotifier<String?>(GlobalProviders.data.typhoon.firstOrNull);
  final isLoading = ValueNotifier<bool>(false);

  Map<String, dynamic> typhoonData = {};
  List<String> typhoonList = [];
  int selectedTyphoonId = -1;
  List<String> sourceList = [];
  List<String> layerList = [];
  List<String> typhoon_name_list = [];
  List<int> typhoon_id_list = [];
  String selectedTimestamp = '';
  bool isUserLocationValid = false;

  DateTime? _lastFetchTime;

  Function(String)? onTimeChanged;

  Future<void> setTyphoonTime(String time) async {
    if (currentTyphoonTime.value == time || isLoading.value) return;

    isLoading.value = true;

    try {
      await remove();
      currentTyphoonTime.value = time;
      await setup();

      onTimeChanged?.call(time);
    } catch (e, s) {
      TalkerManager.instance.error('TyphoonMapLayerManager.setTyphoonTime', e, s);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _focus() async {
    try {
      final location = GlobalProviders.location.coordinates;

      if (location != null && location.isValid) {
        await controller.animateCamera(CameraUpdate.newLatLngZoom(location, 7.4));
      }
    } catch (e, s) {
      TalkerManager.instance.error('TyphoonMapLayerManager._focus', e, s);
    }
  }

  Future<void> _fetchData() async {
    try {
      typhoonData = await ExpTech().getTyphoonGeojson();

      if (!context.mounted) return;

      GlobalProviders.data.setTyphoon(typhoonList);
      currentTyphoonTime.value ??= typhoonList.first;
      _lastFetchTime = DateTime.now();
    } catch (e, s) {
      TalkerManager.instance.error('TyphoonMapLayerManager._fetchData', e, s);
    }
  }

  @override
  Future<void> setup() async {
    if (didSetup) return;

    try {
      if (typhoonData.isEmpty) {
        typhoonData = await ExpTech().getTyphoonGeojson();
      }

      const sourceId = 'typhoon-geojson';
      final sources = await controller.getSourceIds();
      if (!sources.contains(sourceId)) {
        await controller.addSource(
          sourceId,
          GeojsonSourceProperties(data: typhoonData),
        );
      }

      if (!(await controller.getLayerIds()).contains('typhoon-path')) {
        await controller.addLayer(
          sourceId,
          'typhoon-path',
          const LineLayerProperties(
            lineColor: [
              'match', ['get', 'color'],
              0, '#1565C0', // 藍色
              1, '#4CAF50', // 綠色
              2, '#FFC107', // 黃色
              3, '#FF5722', // 橙色
              '#757575', // 默認灰色
            ],
            lineWidth: 2,
          ),
        );
      }

      if (!(await controller.getLayerIds()).contains('typhoon-points')) {
        await controller.addLayer(
          sourceId,
          'typhoon-points',
          const CircleLayerProperties(
            circleRadius: 3,
            circleColor: [
              'match', ['get', 'color'],
              0, '#1565C0',
              1, '#4CAF50',
              2, '#FFC107',
              3, '#FF5722',
              '#757575',
            ],
            circleStrokeWidth: 2,
            circleStrokeColor: '#FFFFFF',
          ),
          filter: [
            'all',
            ['!=', ['get', 'forecast'], true],
          ],
        );
      }

      if (!(await controller.getLayerIds()).contains('typhoon-wind-circle')) {
        await controller.addLayer(
          sourceId,
          'typhoon-wind-circle',
          const FillLayerProperties(
            fillColor: 'rgba(255, 0, 0, 0.1)',
            fillOutlineColor: 'rgba(255, 0, 0, 0.6)',
          ),
          filter: [
            'all',
            ['==', ['geometry-type'], 'Polygon'],
            ['==', ['get', 'type'], 'wind-circle'],
            ['==', ['get', 'forecast'], true],
            ['==', ['get', 'tau'], 0],
          ],
          belowLayerId: BaseMapLayerIds.userLocation,
        );
      }

      didSetup = true;
    } catch (e, s) {
      TalkerManager.instance.error('TyphoonMapLayerManager.setup', e, s);
    }
  }

  @override
  Future<void> hide() async {
    if (!visible) return;

    final time = currentTyphoonTime.value;
    if (time == null) return;

    final layerId = MapLayerIds.typhoon(time);

    try {
      await controller.setLayerVisibility(layerId, false);

      visible = false;
    } catch (e, s) {
      TalkerManager.instance.error('TyphoonMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (visible) return;

    final time = currentTyphoonTime.value;
    if (time == null) return;

    final layerId = MapLayerIds.typhoon(time);

    try {
      await controller.setLayerVisibility(layerId, true);

      await _focus();

      visible = true;

      if (_lastFetchTime == null || DateTime.now().difference(_lastFetchTime!).inMinutes > 5) await _fetchData();
    } catch (e, s) {
      TalkerManager.instance.error('TyphoonMapLayerManager.show', e, s);
    }
  }

  @override
  Future<void> remove() async {
    try {
      final time = currentTyphoonTime.value;
      if (time == null) return;

      final layerId = MapLayerIds.typhoon(time);
      final sourceId = MapSourceIds.typhoon(time);

      await controller.removeLayer(layerId);

      await controller.removeSource(sourceId);
    } catch (e, s) {
      TalkerManager.instance.error('TyphoonMapLayerManager.remove', e, s);
    }

    didSetup = false;
  }

  @override
  Widget build(BuildContext context) => TyphoonMapLayerSheet(manager: this);
}

class TyphoonMapLayerSheet extends StatelessWidget {
  final TyphoonMapLayerManager manager;

  const TyphoonMapLayerSheet({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MorphingSheet(
          title: '颱風'.i18n,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          partialBuilder: (context, controller, sheetController) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Selector<DpipDataModel, UnmodifiableListView<String>>(
                selector: (context, model) => model.typhoon,
                builder: (context, typhoon, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          spacing: 8,
                          children: [
                            const Icon(Symbols.bolt, size: 24),
                            Text('颱風'.i18n, style: context.textTheme.titleMedium),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
