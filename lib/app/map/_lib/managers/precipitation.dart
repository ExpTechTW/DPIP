import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/weather/rain.dart';
import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/morphing_sheet.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';

class RainData {
  final double latitude;
  final double longitude;
  final double rainfall;
  final String stationName;
  final String county;
  final String town;
  final String id;

  RainData({
    required this.latitude,
    required this.longitude,
    required this.rainfall,
    required this.stationName,
    required this.county,
    required this.town,
    required this.id,
  });
}

class PrecipitationMapLayerManager extends MapLayerManager {
  PrecipitationMapLayerManager(super.context, super.controller);

  final currentPrecipitationTime = ValueNotifier<String?>(GlobalProviders.data.precipitation.firstOrNull);
  final isLoading = ValueNotifier<bool>(false);

  Future<void> _updatePrecipitationTileUrl(String time) async {
    if (currentPrecipitationTime.value == time || isLoading.value) return;

    isLoading.value = true;

    try {
      await remove();
      currentPrecipitationTime.value = time;
      await setup();

      TalkerManager.instance.info('Updated Precipitation tiles to "$time"');
    } catch (e, s) {
      TalkerManager.instance.error('Failed to update Precipitation tiles', e, s);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _focus() async {
    try {
      final location = GlobalProviders.location.coordinateNotifier.value;

      if (location.isValid) {
        await controller.animateCamera(CameraUpdate.newLatLngZoom(location, 7.4));
        TalkerManager.instance.info('Moved Camera to $location');
      } else {
        await controller.animateCamera(CameraUpdate.newLatLngZoom(DpipMap.kTaiwanCenter, 6.4));
        TalkerManager.instance.info('Moved Camera to ${DpipMap.kTaiwanCenter}');
      }
    } catch (e, s) {
      TalkerManager.instance.error('PrecipitationMapLayerManager._focus', e, s);
    }
  }

  @override
  Future<void> setup() async {
    if (didSetup) return;

    try {
      if (GlobalProviders.data.temperature.isEmpty) {
        final precipitationList = (await ExpTech().getRainList()).reversed.toList();
        if (!context.mounted) return;

        GlobalProviders.data.setPrecipitation(precipitationList);
        currentPrecipitationTime.value = precipitationList.first;
      }

      final time = currentPrecipitationTime.value;

      if (time == null) throw Exception('Time is null');

      final sourceId = MapSourceIds.precipitation(time);
      final layerId = MapLayerIds.precipitation(time);

      final isSourceExists = (await controller.getSourceIds()).contains(sourceId);
      final isLayerExists = (await controller.getLayerIds()).contains(layerId);

      if (!isSourceExists) {
        late final List<RainStation> rainData;

        if (GlobalProviders.data.rainData.containsKey(time)) {
          rainData = GlobalProviders.data.rainData[time]!;
        } else {
          rainData = await ExpTech().getRain(time);
          GlobalProviders.data.setRainData(time, rainData);
        }

        /*final features =
        rainData
            .where((station) => station.data.air.temperature != -99)
            .map((station) => station.toFeatureBuilder())
            .toList();

        final data = GeoJsonBuilder().setFeatures(features).build();

        final properties = GeojsonSourceProperties(data: data);

        await controller.addSource(sourceId, properties);*/
        TalkerManager.instance.info('Added Source "$sourceId"');

        if (!context.mounted) return;
      }

      if (!isLayerExists) {
        final properties = CircleLayerProperties(
          circleRadius: [
            Expressions.interpolate,
            ['linear'],
            [Expressions.zoom],
            7,
            5,
            12,
            15,
          ],
          circleColor: [
            Expressions.interpolate,
            ['linear'],
            [Expressions.get, 'rainfall'],
            0,
            '#c2c2c2',
            10,
            '#9cfcff',
            30,
            '#059bff',
            50,
            '#39ff03',
            100,
            '#fffb03',
            200,
            '#ff9500',
            300,
            '#ff0000',
            500,
            '#fb00ff',
            1000,
            '#960099',
            2000,
            '#000000',
          ],
          circleOpacity: 0.7,
          circleStrokeWidth: 0.2,
          circleStrokeColor: '#000000',
          circleStrokeOpacity: 0.7,
          visibility: visible ? 'visible' : 'none',
        );

        await controller.addLayer(sourceId, layerId, properties, belowLayerId: BaseMapLayerIds.userLocation);
        TalkerManager.instance.info('Added Layer "$layerId"');
      }

      if (isSourceExists && isLayerExists) return;

      didSetup = true;
    } catch (e, s) {
      TalkerManager.instance.error('PrecipitationMapLayerManager.setup', e, s);
    }
  }

  @override
  Future<void> hide() async {
    if (!visible) return;

    final layerId = MapLayerIds.precipitation(currentPrecipitationTime.value);

    try {
      await controller.setLayerVisibility(layerId, false);
      TalkerManager.instance.info('Hiding Layer "$layerId"');

      visible = false;
    } catch (e, s) {
      TalkerManager.instance.error('PrecipitationMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (visible) return;

    final layerId = MapLayerIds.precipitation(currentPrecipitationTime.value);

    try {
      await controller.setLayerVisibility(layerId, true);
      TalkerManager.instance.info('Showing Layer "$layerId"');

      await _focus();

      visible = true;
    } catch (e, s) {
      TalkerManager.instance.error('PrecipitationMapLayerManager.show', e, s);
    }
  }

  @override
  Future<void> remove() async {
    try {
      final layerId = MapLayerIds.precipitation(currentPrecipitationTime.value);
      final sourceId = MapSourceIds.precipitation(currentPrecipitationTime.value);

      await controller.removeLayer(layerId);
      TalkerManager.instance.info('Removed Layer "$layerId"');

      await controller.removeSource(sourceId);
      TalkerManager.instance.info('Removed Source "$sourceId"');
    } catch (e, s) {
      TalkerManager.instance.error('PrecipitationMapLayerManager.dispose', e, s);
    }

    didSetup = false;
  }

  @override
  Widget build(BuildContext context) => PrecipitationMapLayerSheet(manager: this);
}

class PrecipitationMapLayerSheet extends StatelessWidget {
  final PrecipitationMapLayerManager manager;

  const PrecipitationMapLayerSheet({super.key, required this.manager});

  /*class _PrecipitationMapLayerSheetState extends State<PrecipitationMapLayerSheet> {
  late MapLibreMapController _mapController;

  List<String> rainTimeList = [];
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;
  bool _showLegend = false;
  String? _selectedStationId;

  List<RainData> rainDataList = [];
  String selectedTimestamp = '';
  String selectedInterval = 'now'; // 默認選擇 "now"

  Future<void> _initMap(MapLibreMapController controller) async {
    _mapController = controller;
  }

  Future<void> _loadMap() async {
    if (Platform.isIOS && (Global.preference.getBool('auto-location') ?? false)) {
      await getSavedLocation();
    }
    userLat = Global.preference.getDouble('user-lat') ?? 0.0;
    userLon = Global.preference.getDouble('user-lon') ?? 0.0;

    isUserLocationValid = !(userLon == 0 || userLat == 0);

    await _mapController.addSource(
      'rain-data',
      const GeojsonSourceProperties(data: {'type': 'FeatureCollection', 'features': []}),
    );

    rainTimeList = await ExpTech().getRainList();

    if (rainTimeList.isNotEmpty) {
      selectedTimestamp = rainTimeList.last;
      await updateRainData(selectedTimestamp, selectedInterval);
    }

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

  Future<void> updateRainData(String timestamp, String interval) async {
    final List<RainStation> rainData = await ExpTech().getRain(timestamp);

    rainDataList =
        rainData
            .map((station) {
              double rainfall;
              switch (interval) {
                case 'now':
                  rainfall = station.data.now;
                case '10m':
                  rainfall = station.data.tenMinutes;
                case '1h':
                  rainfall = station.data.oneHour;
                case '3h':
                  rainfall = station.data.threeHours;
                case '6h':
                  rainfall = station.data.sixHours;
                case '12h':
                  rainfall = station.data.twelveHours;
                case '24h':
                  rainfall = station.data.twentyFourHours;
                case '2d':
                  rainfall = station.data.twoDays;
                case '3d':
                  rainfall = station.data.threeDays;
                default:
                  rainfall = station.data.now;
              }

              if (rainfall == -99) {
                return null;
              }

              return RainData(
                id: station.id,
                latitude: station.station.lat,
                longitude: station.station.lng,
                rainfall: rainfall,
                stationName: station.station.name,
                county: station.station.county,
                town: station.station.town,
              );
            })
            .whereType<RainData>()
            .toList();

    await addRainCircles(rainDataList);
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

  Future<void> addRainCircles(List<RainData> rainDataList) async {
    final features =
        rainDataList
            .map(
              (data) => {
                'type': 'Feature',
                'properties': {'id': data.id, 'rainfall': data.rainfall},
                'geometry': {
                  'type': 'Point',
                  'coordinates': [data.longitude, data.latitude],
                },
              },
            )
            .toList();

    await _mapController.setGeoJsonSource('rain-data', {'type': 'FeatureCollection', 'features': features});

    await _mapController.removeLayer('rain-0-circles');
    await _mapController.addLayer(
      'rain-data',
      'rain-0-circles',
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
        ['get', 'rainfall'],
        0,
      ],
      minzoom: 10,
    );

    await _mapController.removeLayer('rain-0-labels');
    await _mapController.addSymbolLayer(
      'rain-data',
      'rain-0-labels',
      const SymbolLayerProperties(
        textField: ['get', 'rainfall'],
        textSize: 12,
        textColor: '#ffffff',
        textHaloColor: '#000000',
        textHaloWidth: 1,
        textFont: ['Noto Sans Regular'],
        textOffset: [
          Expressions.literal,
          [0, 2],
        ],
      ),
      filter: [
        '==',
        ['get', 'rainfall'],
        0,
      ],
      minzoom: 10,
    );

    await _mapController.removeLayer('rain-circles');
    await _mapController.addLayer(
      'rain-data',
      'rain-circles',
      const CircleLayerProperties(
        circleRadius: [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          7,
          5,
          12,
          15,
        ],
        circleColor: [
          Expressions.interpolate,
          ['linear'],
          [Expressions.get, 'rainfall'],
          0,
          '#c2c2c2',
          10,
          '#9cfcff',
          30,
          '#059bff',
          50,
          '#39ff03',
          100,
          '#fffb03',
          200,
          '#ff9500',
          300,
          '#ff0000',
          500,
          '#fb00ff',
          1000,
          '#960099',
          2000,
          '#000000',
        ],
        circleOpacity: 0.7,
        circleStrokeWidth: 0.2,
        circleStrokeColor: '#000000',
        circleStrokeOpacity: 0.7,
      ),
      filter: [
        '!=',
        ['get', 'rainfall'],
        0,
      ],
    );

    _mapController.onFeatureTapped.add((dynamic feature, Point<double> point, LatLng latLng, String layerId) async {
      final features = await _mapController.queryRenderedFeatures(point, ['rain-circles', 'rain-0-circles'], null);

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

    await _mapController.removeLayer('rain-labels');
    await _mapController.addSymbolLayer(
      'rain-data',
      'rain-labels',
      const SymbolLayerProperties(
        textField: ['get', 'rainfall'],
        textSize: 12,
        textColor: '#ffffff',
        textHaloColor: '#000000',
        textHaloWidth: 1,
        textFont: ['Noto Sans Regular'],
        textOffset: [
          Expressions.literal,
          [0, 2],
        ],
      ),
      filter: [
        '!=',
        ['get', 'rainfall'],
        0,
      ],
      minzoom: 9,
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return MorphingSheet(
      title: context.i18n.precipitation_monitor,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      partialBuilder: (context, controller, sheetController) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Selector<DpipDataModel, UnmodifiableListView<String>>(
            selector: (context, model) => model.precipitation,
            builder: (context, precipitation, child) {
              final times = precipitation.map((time) {
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
                        const Icon(Symbols.humidity_percentage_rounded, size: 24),
                        Text(context.i18n.precipitation_monitor, style: context.textTheme.titleMedium),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: kMinInteractiveDimension,
                    child: ValueListenableBuilder<String?>(
                      valueListenable: manager.currentPrecipitationTime,
                      builder: (context, currentPrecipitationTime, child) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: grouped.length,
                          itemBuilder: (context, index) {
                            final MapEntry(key: date, value: group) = grouped[index];

                            final children = <Widget>[Text(date)];

                            for (final time in group) {
                              final isSelected = time.value == currentPrecipitationTime;

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
                                                manager._updatePrecipitationTileUrl(time.value);
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
    );
  }
}
