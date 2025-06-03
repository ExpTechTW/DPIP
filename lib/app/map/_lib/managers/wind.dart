import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/sheet/morphing_sheet.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';

class WindData {
  final double latitude;
  final double longitude;
  final int direction;
  final double speed;
  final String id;

  WindData({
    required this.latitude,
    required this.longitude,
    required this.direction,
    required this.speed,
    required this.id,
  });
}

class WindMapLayerManager extends MapLayerManager {
  WindMapLayerManager(super.context, super.controller);

  final currentWindTime = ValueNotifier<String?>(GlobalProviders.data.wind.firstOrNull);
  final isLoading = ValueNotifier<bool>(false);

  Future<void> _updateWindTileUrl(String time) async {
    if (currentWindTime.value == time || isLoading.value) return;

    isLoading.value = true;

    try {
      await remove();
      currentWindTime.value = time;
      await setup();

      TalkerManager.instance.info('Updated Wind tiles to "$time"');
    } catch (e, s) {
      TalkerManager.instance.error('Failed to update Wind tiles', e, s);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> setup() async {
    if (didSetup) return;

    try {
      final sourceId = MapSourceIds.wind(currentWindTime.value);
      final layerId = MapLayerIds.wind(currentWindTime.value);

      final isSourceExists = (await controller.getSourceIds()).contains(sourceId);
      final isLayerExists = (await controller.getLayerIds()).contains(layerId);

      if (isSourceExists && isLayerExists) return;

      didSetup = true;
    } catch (e, s) {
      TalkerManager.instance.error('WindMapLayerManager.setup', e, s);
    }
  }

  @override
  Future<void> hide() async {
    if (!visible) return;

    final layerId = MapLayerIds.wind(currentWindTime.value);

    try {
      await controller.setLayerVisibility(layerId, false);
      TalkerManager.instance.info('Hiding Layer "$layerId"');

      visible = false;
    } catch (e, s) {
      TalkerManager.instance.error('WindMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (visible) return;

    final layerId = MapLayerIds.wind(currentWindTime.value);

    try {
      await controller.setLayerVisibility(layerId, true);
      TalkerManager.instance.info('Showing Layer "$layerId"');

      visible = true;
    } catch (e, s) {
      TalkerManager.instance.error('WindMapLayerManager.show', e, s);
    }
  }

  @override
  Future<void> remove() async {
    try {
      final layerId = MapLayerIds.wind(currentWindTime.value);
      final sourceId = MapSourceIds.wind(currentWindTime.value);

      await controller.removeLayer(layerId);
      TalkerManager.instance.info('Removed Layer "$layerId"');

      await controller.removeSource(sourceId);
      TalkerManager.instance.info('Removed Source "$sourceId"');
    } catch (e, s) {
      TalkerManager.instance.error('WindMapLayerManager.dispose', e, s);
    }

    didSetup = false;
  }

  @override
  Widget build(BuildContext context) => WindMapLayerSheet(manager: this);
}

class WindMapLayerSheet extends StatelessWidget {
  final WindMapLayerManager manager;

  const WindMapLayerSheet({super.key, required this.manager});

  /*class _WindMapLayerSheetState extends State<WindMapLayerSheet> {
  late MapLibreMapController _mapController;

  List<String> weather_list = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;
  bool _showLegend = false;
  String? _selectedStationId;

  List<WindData> windDataList = [];
  Future<void> _initMap(MapLibreMapController controller) async {
    _mapController = controller;
  }

  Future<void> _updateWindData(List<WeatherStation> weatherData) async {
    windDataList =
        weatherData
            .where((station) => station.data.wind.direction != -99 && station.data.wind.speed != -99)
            .map(
              (station) => WindData(
                id: station.id,
                latitude: station.station.lat,
                longitude: station.station.lng,
                direction: (station.data.wind.direction + 180) % 360,
                speed: station.data.wind.speed,
              ),
            )
            .toList();

    await addDynamicWindArrows(windDataList);
    setState(() {});
  }

  Future<void> _loadMap() async {
    if (Platform.isIOS && (Global.preference.getBool('auto-location') ?? false)) {
      await getSavedLocation();
    }
    userLat = Global.preference.getDouble('user-lat') ?? 0.0;
    userLon = Global.preference.getDouble('user-lon') ?? 0.0;

    isUserLocationValid = userLon != 0 && userLat != 0;

    await _mapController.addSource(
      'wind-data',
      const GeojsonSourceProperties(data: {'type': 'FeatureCollection', 'features': []}),
    );

    weather_list = await ExpTech().getWeatherList();

    final List<WeatherStation> weatherData = await ExpTech().getWeather(weather_list.last);

    _updateWindData(weatherData);

    if (isUserLocationValid) {
      await _mapController.addSource(
        'markers-geojson',
        const GeojsonSourceProperties(data: {'type': 'FeatureCollection', 'features': []}),
      );
      await _mapController.setGeoJsonSource('markers-geojson', {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {},
            'geometry': {
              'coordinates': [userLon, userLat],
              'type': 'Point',
            },
          },
        ],
      });
      final cameraUpdate = CameraUpdate.newLatLngZoom(LatLng(userLat, userLon), 8);
      await _mapController.animateCamera(cameraUpdate, duration: const Duration(milliseconds: 1000));
    }

    await _addUserLocationMarker();

    setState(() {});
  }

  Future<void> _addUserLocationMarker() async {
    if (isUserLocationValid) {
      await _mapController.removeLayer('markers');
      await _mapController.addLayer(
        'markers-geojson',
        'markers',
        const SymbolLayerProperties(
          symbolZOrder: 'source',
          iconSize: [
            Expressions.interpolate,
            ['linear'],
            [Expressions.zoom],
            5,
            0.5,
            10,
            1.5,
          ],
          iconImage: 'gps',
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
      );
    }
  }

  Future<void> addDynamicWindArrows(List<WindData> windDataList) async {
    final features =
        windDataList
            .map(
              (data) => {
                'type': 'Feature',
                'properties': {'id': data.id, 'direction': data.direction, 'speed': data.speed},
                'geometry': {
                  'type': 'Point',
                  'coordinates': [data.longitude, data.latitude],
                },
              },
            )
            .toList();

    await _mapController.setGeoJsonSource('wind-data', {'type': 'FeatureCollection', 'features': features});

    await _mapController.removeLayer('wind-circles');
    await _mapController.addLayer(
      'wind-data',
      'wind-circles',
      const CircleLayerProperties(
        circleRadius: [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          5,
          3,
          10,
          6,
        ],
        circleColor: '#808080',
        circleStrokeWidth: 0.8,
        circleStrokeColor: '#FFFFFF',
      ),
      filter: [
        '==',
        ['get', 'speed'],
        0,
      ],
      minzoom: 10,
    );

    await _mapController.removeLayer('wind-speed-0-labels');
    await _mapController.addSymbolLayer(
      'wind-data',
      'wind-speed-0-labels',
      const SymbolLayerProperties(
        textField: [
          Expressions.format,
          ['get', 'speed'],
        ],
        textSize: 12,
        textColor: '#ffffff',
        textHaloColor: '#000000',
        textHaloWidth: 2,
        textFont: ['Noto Sans Regular'],
        textOffset: [
          Expressions.literal,
          [0, 2],
        ],
      ),
      filter: [
        '==',
        ['get', 'speed'],
        0,
      ],
      minzoom: 10,
    );

    await _mapController.removeLayer('wind-arrows');
    await _mapController.addLayer(
      'wind-data',
      'wind-arrows',
      const SymbolLayerProperties(
        iconSize: [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          5,
          0.4,
          10,
          1.2,
        ],
        iconImage: [
          Expressions.step,
          [Expressions.get, 'speed'],
          'wind-1',
          3.4,
          'wind-2',
          8,
          'wind-3',
          13.9,
          'wind-4',
          32.7,
          'wind-5',
        ],
        iconRotate: [Expressions.get, 'direction'],
        textAllowOverlap: true,
        iconAllowOverlap: true,
      ),
      filter: [
        '!=',
        ['get', 'speed'],
        0,
      ],
    );

    _mapController.onFeatureTapped.add((dynamic feature, Point<double> point, LatLng latLng, String layerId) async {
      final features = await _mapController.queryRenderedFeatures(point, ['wind-arrows', 'wind-circles'], null);

      if (features.isNotEmpty) {
        final stationId = features[0]['properties']['id'] as String;
        if (_selectedStationId != null) AdvancedWeatherChart.updateStationId(stationId);
        setState(() {
          _selectedStationId = stationId;
        });
      } else {
        setState(() {
          _selectedStationId = null;
        });
      }
    });

    await _mapController.removeLayer('wind-speed-labels');
    await _mapController.addSymbolLayer(
      'wind-data',
      'wind-speed-labels',
      const SymbolLayerProperties(
        textField: [
          Expressions.format,
          ['get', 'speed'],
        ],
        textSize: 12,
        textColor: '#ffffff',
        textHaloColor: '#000000',
        textHaloWidth: 2,
        textFont: ['Noto Sans Regular'],
        textOffset: [
          Expressions.literal,
          [0, 2],
        ],
      ),
      filter: [
        '!=',
        ['get', 'speed'],
        0,
      ],
      minzoom: 9,
    );
  }

  void _toggleLegend() {
    setState(() {
      _showLegend = !_showLegend;
    });
  }

  Widget _buildLegend() {
    return MapLegend(
      children: [
        _legendItem('wind-1', '0.1 - 3.3 m/s'),
        _legendItem('wind-2', '3.4 - 7.9 m/s'),
        _legendItem('wind-3', '8.0 - 13.8 m/s'),
        _legendItem('wind-4', '13.9 - 32.6 m/s'),
        _legendItem('wind-5', '≥ 32.7 m/s'),
      ],
    );
  }

  Widget _legendItem(String imageName, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Image.asset('assets/map/icons/$imageName.png', width: 24, height: 24),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return MorphingSheet(
      title: context.i18n.wind_direction_and_speed_monitor,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      partialBuilder: (context, controller, sheetController) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Selector<DpipDataModel, UnmodifiableListView<String>>(
            selector: (context, model) => model.wind,
            builder: (context, wind, child) {
              final times = wind.map((time) {
                final t = time.toSimpleDateTimeString(context).split(' ');
                return (date: t[0], time: t[1], value: time);
              });
              final grouped = times.groupListsBy((time) => time.date).entries.toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      spacing: 8,
                      children: [
                        const Icon(Symbols.wind_power_rounded, size: 24),
                        Text(context.i18n.wind_direction_and_speed_monitor, style: context.textTheme.titleMedium),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: kMinInteractiveDimension,
                    child: ValueListenableBuilder<String?>(
                      valueListenable: manager.currentWindTime,
                      builder: (context, currentWindTime, child) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: grouped.length,
                          itemBuilder: (context, index) {
                            final MapEntry(key: date, value: group) = grouped[index];

                            final children = <Widget>[Text(date)];

                            for (final time in group) {
                              final isSelected = time.value == currentWindTime;

                              children.add(
                                ValueListenableBuilder<bool>(
                                  valueListenable: manager.isLoading,
                                  builder: (context, isLoading, child) {
                                    return FilterChip(
                                      selected: isSelected,
                                      showCheckmark: !isLoading,
                                      label: Text(time.time),
                                      side: BorderSide(
                                        color: isSelected ? context.colors.primary : context.colors.outlineVariant,
                                      ),
                                      avatar: isSelected && isLoading ? const LoadingIcon() : null,
                                      onSelected:
                                          isLoading
                                              ? null
                                              : (selected) {
                                                if (!selected) return;
                                                manager._updateWindTileUrl(time.value);
                                              },
                                    );
                                  },
                                ),
                              );
                            }

                            children.add(
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: VerticalDivider(width: 16, indent: 8, endIndent: 8),
                              ),
                            );

                            return Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: children);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
      /*if (_showLegend) Positioned(left: 6, bottom: 50, child: _buildLegend()),
        if (_selectedStationId == null && weather_list.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            child: TimeSelector(
              timeList: weather_list,
              onTimeExpanded: () {
                setState(() {
                  _showLegend = false;
                });
              },
              onTimeSelected: (time) async {
                final List<WeatherStation> weatherData = await ExpTech().getWeather(time);
                await _updateWindData(weatherData);
              },
            ),
          ),
        if (_selectedStationId != null)
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.1,
            snap: true,
            snapSizes: const [0.1, 0.3, 0.7, 1],
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5)),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        width: 40,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                      ),
                      AdvancedWeatherChart(
                        type: 'wind_speed',
                        stationId: _selectedStationId!,
                        onClose: () {
                          setState(() {
                            _selectedStationId = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),*/
    );
  }
}
