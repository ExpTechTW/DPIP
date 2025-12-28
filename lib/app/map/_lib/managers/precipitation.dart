import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/weather/rain.dart';
import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/map_legend.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/blurred_container.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/morphing_sheet.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

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

  static const precipitationIntervals = [
    'now',
    '10m',
    '1h',
    '3h',
    '6h',
    '12h',
    '24h',
    '2d',
    '3d',
  ];

  // Label layout constants for precipitation labels
  static const double kLabelBaseOffset = 1.0;
  static const double kLabelLineHeight = 1.1;

  final currentPrecipitationTime = ValueNotifier<String?>(
    GlobalProviders.data.precipitation.firstOrNull,
  );
  final currentPrecipitationInterval = ValueNotifier<String>('now');
  final isLoading = ValueNotifier<bool>(false);

  DateTime? _lastFetchTime;

  Function(String)? onTimeChanged;

  Future<void> setPrecipitationTime(String time) async {
    if (currentPrecipitationTime.value == time || isLoading.value) return;

    isLoading.value = true;

    try {
      await remove();
      currentPrecipitationTime.value = time;
      await setup();

      onTimeChanged?.call(time);
    } catch (e, s) {
      TalkerManager.instance.error(
        'PrecipitationMapLayerManager.setPrecipitationTime',
        e,
        s,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setPrecipitationInterval(String interval) async {
    if (currentPrecipitationInterval.value == interval) return;

    try {
      final layerId = MapLayerIds.precipitation(currentPrecipitationTime.value);
      final showLayerId = '$layerId-$interval';
      final hideLayerId = '$layerId-${currentPrecipitationInterval.value}';

      await controller.setLayerVisibility(showLayerId, true);
      await controller.setLayerVisibility('$showLayerId-label-name', true);
      await controller.setLayerVisibility('$showLayerId-label-value', true);

      await controller.setLayerVisibility(hideLayerId, false);
      await controller.setLayerVisibility('$hideLayerId-label-name', false);
      await controller.setLayerVisibility('$hideLayerId-label-value', false);

      currentPrecipitationInterval.value = interval;
    } catch (e, s) {
      TalkerManager.instance.error(
        'PrecipitationMapLayerManager.setPrecipitationInterval',
        e,
        s,
      );
    }
  }

  Future<void> _focus() async {
    try {
      final location = GlobalProviders.location.coordinates;

      if (location != null && location.isValid) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(location, 7.4),
        );
      } else {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(DpipMap.kTaiwanCenter, 6.4),
        );
      }
    } catch (e, s) {
      TalkerManager.instance.error('PrecipitationMapLayerManager._focus', e, s);
    }
  }

  Future<void> _fetchData() async {
    try {
      final precipitationList = (await ExpTech().getRainList()).reversed
          .toList();
      if (!context.mounted) return;

      GlobalProviders.data.setPrecipitation(precipitationList);
      currentPrecipitationTime.value ??= precipitationList.first;
      _lastFetchTime = DateTime.now();
    } catch (e, s) {
      TalkerManager.instance.error(
        'PrecipitationMapLayerManager._fetchData',
        e,
        s,
      );
    }
  }

  @override
  Future<void> setup() async {
    if (didSetup) return;

    final colors = context.colors;

    try {
      if (GlobalProviders.data.precipitation.isEmpty) {
        await _fetchData();
      }

      final time = currentPrecipitationTime.value;

      if (time == null) throw Exception('Time is null');

      final sourceId = MapSourceIds.precipitation(time);
      final layerId = MapLayerIds.precipitation(time);

      final isSourceExists = (await controller.getSourceIds()).contains(
        sourceId,
      );
      final isLayerExists = (await controller.getLayerIds()).contains(layerId);

      if (!isSourceExists) {
        late final List<RainStation> rainData;

        if (GlobalProviders.data.rainData.containsKey(time)) {
          rainData = GlobalProviders.data.rainData[time]!;
        } else {
          rainData = await ExpTech().getRain(time);
          GlobalProviders.data.setRainData(time, rainData);
        }

        final features = rainData.map((station) => station.toFeatureBuilder());

        final data = GeoJsonBuilder().setFeatures(features).build();

        final properties = GeojsonSourceProperties(data: data);

        await controller.addSource(sourceId, properties);

        if (!context.mounted) return;
      }

      if (!isLayerExists) {
        final Map<String, LayerProperties> properties = {
          for (final interval in precipitationIntervals)
            ...({
              interval: CircleLayerProperties(
                circleColor: [
                  Expressions.interpolate,
                  ['linear'],
                  [Expressions.get, interval],
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
                circleRadius: kCircleIconSize,
                circleOpacity: 0.75,
                circleStrokeColor: colors.outlineVariant.toHexStringRGB(),
                circleStrokeWidth: 0.5,
                circleStrokeOpacity: 0.75,
                visibility: interval == currentPrecipitationInterval.value
                    ? 'visible'
                    : 'none',
              ),
              '$interval-label-name': SymbolLayerProperties(
                textField: [Expressions.get, 'name'],
                textSize: 10,
                textColor: colors.onSurfaceVariant.toHexStringRGB(),
                textHaloColor: colors.outlineVariant.toHexStringRGB(),
                textHaloWidth: 1,
                textFont: ['Noto Sans TC Bold'],
                textOffset: [0, kLabelBaseOffset],
                textAnchor: 'top',
                textAllowOverlap: true,
                textIgnorePlacement: true,
                visibility: interval == currentPrecipitationInterval.value
                    ? 'visible'
                    : 'none',
              ),
              '$interval-label-value': SymbolLayerProperties(
                textField: [
                  Expressions.concat,
                  [Expressions.get, interval],
                  'mm',
                ],
                textSize: 10,
                textColor: colors.onSurfaceVariant.toHexStringRGB(),
                textHaloColor: colors.outlineVariant.toHexStringRGB(),
                textHaloWidth: 1,
                textFont: ['Noto Sans TC Bold'],
                textOffset: [0, kLabelBaseOffset + kLabelLineHeight * 1],
                textAnchor: 'top',
                textAllowOverlap: true,
                textIgnorePlacement: true,
                visibility: interval == currentPrecipitationInterval.value
                    ? 'visible'
                    : 'none',
              ),
            }),
        };

        await Future.wait(
          properties.entries.map((entry) {
            // Detect label entries more precisely using '-label-' marker
            final isValueLayer = entry.key.contains('-label-');
            final interval = isValueLayer
                ? entry.key.split('-label-')[0]
                : entry.key;

            return controller.addLayer(
              sourceId,
              '$layerId-${entry.key}',
              entry.value,
              belowLayerId: BaseMapLayerIds.userLocation,
              minzoom: isValueLayer ? 10 : null,
              filter: [
                Expressions.larger,
                [Expressions.get, interval],
                0,
              ],
            );
          }),
        );
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
    final hideLayerId = '$layerId-${currentPrecipitationInterval.value}';
    final hideNameLayerId =
        '$layerId-${currentPrecipitationInterval.value}-label-name';
    final hideValueLayerId =
        '$layerId-${currentPrecipitationInterval.value}-label-value';

    try {
      await controller.setLayerVisibility(hideLayerId, false);
      await controller.setLayerVisibility(hideNameLayerId, false);
      await controller.setLayerVisibility(hideValueLayerId, false);

      visible = false;
    } catch (e, s) {
      TalkerManager.instance.error('PrecipitationMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (visible) return;

    final layerId = MapLayerIds.precipitation(currentPrecipitationTime.value);
    final showLayerId = '$layerId-${currentPrecipitationInterval.value}';
    final showNameLayerId =
        '$layerId-${currentPrecipitationInterval.value}-label-name';
    final showValueLayerId =
        '$layerId-${currentPrecipitationInterval.value}-label-value';

    try {
      await controller.setLayerVisibility(showLayerId, true);
      await controller.setLayerVisibility(showNameLayerId, true);
      await controller.setLayerVisibility(showValueLayerId, true);

      await _focus();

      visible = true;

      if (_lastFetchTime == null ||
          DateTime.now().difference(_lastFetchTime!).inMinutes > 5)
        await _fetchData();
    } catch (e, s) {
      TalkerManager.instance.error('PrecipitationMapLayerManager.show', e, s);
    }
  }

  @override
  Future<void> remove() async {
    try {
      final layerId = MapLayerIds.precipitation(currentPrecipitationTime.value);
      final sourceId = MapSourceIds.precipitation(
        currentPrecipitationTime.value,
      );

      final removals = <Future<void>>[];
      for (final interval in precipitationIntervals) {
        removals.add(controller.removeLayer('$layerId-$interval'));
        removals.add(controller.removeLayer('$layerId-$interval-label-name'));
        removals.add(controller.removeLayer('$layerId-$interval-label-value'));
      }
      removals.add(controller.removeSource(sourceId));
      await Future.wait(removals);
    } catch (e, s) {
      TalkerManager.instance.error('PrecipitationMapLayerManager.remove', e, s);
    }

    didSetup = false;
  }

  @override
  Widget build(BuildContext context) =>
      PrecipitationMapLayerSheet(manager: this);
}

class PrecipitationMapLayerSheet extends StatelessWidget {
  final PrecipitationMapLayerManager manager;

  const PrecipitationMapLayerSheet({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    String getIntervalLabel(String interval) => switch (interval) {
      'now' => '今日'.i18n,
      '10m' => '10 分鐘'.i18n,
      '1h' => '1 小時'.i18n,
      '3h' => '3 小時'.i18n,
      '6h' => '6 小時'.i18n,
      '12h' => '12 小時'.i18n,
      '24h' => '24 小時'.i18n,
      '2d' => '2 天'.i18n,
      '3d' => '3 天'.i18n,
      _ => interval,
    };

    return Stack(
      children: [
        MorphingSheet(
          title: '降水'.i18n,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          partialBuilder: (context, controller, sheetController) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Selector<DpipDataModel, UnmodifiableListView<String>>(
                selector: (context, model) => model.precipitation,
                builder: (context, precipitation, header) {
                  final times = precipitation.map((time) {
                    final t = time.toSimpleDateTimeString().split(' ');
                    return (date: t[0], time: t[1], value: time);
                  });
                  final grouped = times
                      .groupListsBy((time) => time.date)
                      .entries
                      .toList();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      header!,
                      SizedBox(
                        height: kMinInteractiveDimension,
                        child: ValueListenableBuilder<String?>(
                          valueListenable: manager.currentPrecipitationInterval,
                          builder:
                              (context, currentPrecipitationInterval, child) {
                                const intervals = PrecipitationMapLayerManager
                                    .precipitationIntervals;

                                return ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: intervals.length,
                                  itemBuilder: (context, index) {
                                    final interval = intervals[index];
                                    final isSelected =
                                        interval ==
                                        currentPrecipitationInterval;

                                    return ValueListenableBuilder<bool>(
                                      valueListenable: manager.isLoading,
                                      builder: (context, isLoading, child) {
                                        return FilterChip(
                                          selected: isSelected,
                                          showCheckmark: !isLoading,
                                          label: Text(
                                            getIntervalLabel(interval),
                                          ),
                                          side: BorderSide(
                                            color: isSelected
                                                ? context.colors.primary
                                                : context.colors.outlineVariant,
                                          ),
                                          avatar: isSelected && isLoading
                                              ? const LoadingIcon()
                                              : null,
                                          onSelected: isLoading
                                              ? null
                                              : (selected) {
                                                  if (!selected) return;
                                                  manager
                                                      .setPrecipitationInterval(
                                                        interval,
                                                      );
                                                },
                                        );
                                      },
                                    );
                                  },
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: 8),
                                );
                              },
                        ),
                      ),
                      SizedBox(
                        height: kMinInteractiveDimension,
                        child: ValueListenableBuilder<String?>(
                          valueListenable: manager.currentPrecipitationTime,
                          builder: (context, currentPrecipitationTime, child) {
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              scrollDirection: Axis.horizontal,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: grouped.length,
                              itemBuilder: (context, index) {
                                final MapEntry(key: date, value: group) =
                                    grouped[index];

                                final children = <Widget>[Text(date)];

                                for (final time in group) {
                                  final isSelected =
                                      time.value == currentPrecipitationTime;

                                  children.add(
                                    ValueListenableBuilder<bool>(
                                      valueListenable: manager.isLoading,
                                      builder: (context, isLoading, child) {
                                        return FilterChip(
                                          selected: isSelected,
                                          showCheckmark: !isLoading,
                                          label: Text(time.time),
                                          side: BorderSide(
                                            color: isSelected
                                                ? context.colors.primary
                                                : context.colors.outlineVariant,
                                          ),
                                          avatar: isSelected && isLoading
                                              ? const LoadingIcon()
                                              : null,
                                          onSelected: isLoading
                                              ? null
                                              : (selected) {
                                                  if (!selected) return;
                                                  manager.setPrecipitationTime(
                                                    time.value,
                                                  );
                                                },
                                        );
                                      },
                                    ),
                                  );
                                }

                                children.add(
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: VerticalDivider(
                                      width: 16,
                                      indent: 8,
                                      endIndent: 8,
                                    ),
                                  ),
                                );

                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 8,
                                  children: children,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      const Icon(Symbols.water_drop_rounded, size: 24),
                      Text('降水'.i18n, style: context.texts.titleMedium),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          top: 24 + 48 + 16,
          left: 24,
          child: SafeArea(
            child: BlurredContainer(
              elevation: 4,
              shadowColor: context.colors.shadow.withValues(alpha: 0.4),
              child: ColorLegend(
                unit: 'mm',
                items: [
                  ColorLegendItem(color: const Color(0xffc2c2c2), value: 0),
                  ColorLegendItem(color: const Color(0xFF9CFCFF), value: 10),
                  ColorLegendItem(color: const Color(0xFF059BFF), value: 30),
                  ColorLegendItem(color: const Color(0xFF39FF03), value: 50),
                  ColorLegendItem(color: const Color(0xFFFFFB03), value: 100),
                  ColorLegendItem(color: const Color(0xFFFF9500), value: 200),
                  ColorLegendItem(color: const Color(0xFFFF0000), value: 300),
                  ColorLegendItem(color: const Color(0xFFFB00FF), value: 500),
                  ColorLegendItem(color: const Color(0xFF960099), value: 1000),
                  ColorLegendItem(color: const Color(0xFF000000), value: 2000),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
