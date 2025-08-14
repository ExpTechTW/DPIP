import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/weather/weather.dart';
import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/map_legend.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/blurred_container.dart';
import 'package:dpip/widgets/map/map.dart';
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

  DateTime? _lastFetchTime;

  Function(String)? onTimeChanged;

  Future<void> setWindTime(String time) async {
    if (currentWindTime.value == time || isLoading.value) return;

    isLoading.value = true;

    try {
      await remove();
      currentWindTime.value = time;
      await setup();

      onTimeChanged?.call(time);
    } catch (e, s) {
      TalkerManager.instance.error('WindMapLayerManager.setWindTime', e, s);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchData() async {
    final windList = (await ExpTech().getWeatherList()).reversed.toList();
    if (!context.mounted) return;

    GlobalProviders.data.setWind(windList);
    currentWindTime.value ??= windList.first;
    _lastFetchTime = DateTime.now();
  }

  @override
  Future<void> setup() async {
    if (didSetup) return;

    final colors = context.colors;

    try {
      if (GlobalProviders.data.wind.isEmpty) await _fetchData();

      final time = currentWindTime.value;

      if (time == null) throw Exception('Time is null');

      final sourceId = MapSourceIds.wind(time);
      final layerId = MapLayerIds.wind(time);

      final isSourceExists = (await controller.getSourceIds()).contains(sourceId);
      final isLayerExists = (await controller.getLayerIds()).contains(layerId);

      if (!isSourceExists) {
        late final List<WeatherStation> weatherData;

        if (GlobalProviders.data.weatherData.containsKey(time)) {
          weatherData = GlobalProviders.data.weatherData[time]!;
        } else {
          weatherData = await ExpTech().getWeather(time);
          GlobalProviders.data.setWeatherData(time, weatherData);
        }

        final features =
            weatherData
                .where((station) => station.data.wind.direction != -99 && station.data.wind.speed != -99)
                .map((station) => station.toFeatureBuilder())
                .toList();

        final data = GeoJsonBuilder().setFeatures(features).build();

        final properties = GeojsonSourceProperties(data: data);

        await controller.addSource(sourceId, properties);

        if (!context.mounted) return;
      }

      if (!isLayerExists) {
        // arrows
        final properties = SymbolLayerProperties(
          iconImage: [Expressions.get, 'icon'],
          iconSize: [
            Expressions.interpolate,
            ['linear'],
            [Expressions.zoom],
            5,
            0.1,
            15,
            0.8,
          ],
          iconRotate: [Expressions.get, 'wind_direction'],
          iconOpacity: 0.75,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          visibility: visible ? 'visible' : 'none',
        );

        // labels
        final properties2 = SymbolLayerProperties(
          textField: [
            Expressions.concat,
            [Expressions.get, 'name'],
            '\n',
            [
              Expressions.concat,
              [Expressions.get, 'wind_speed'],
              'm/s',
            ],
          ],
          textSize: 10,
          textColor: colors.onSurfaceVariant.toHexStringRGB(),
          textHaloColor: colors.outlineVariant.toHexStringRGB(),
          textHaloWidth: 1,
          textFont: ['Noto Sans TC Bold'],
          textOffset: [0, 2],
          textAnchor: 'top',
          visibility: visible ? 'visible' : 'none',
        );

        await controller.addLayer(sourceId, layerId, properties, belowLayerId: BaseMapLayerIds.userLocation);
        await controller.addLayer(
          sourceId,
          '$layerId-label',
          properties2,
          belowLayerId: BaseMapLayerIds.userLocation,
          minzoom: 10,
        );
      }

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
      await controller.setLayerVisibility('$layerId-label', false);

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
      await controller.setLayerVisibility('$layerId-label', true);

      visible = true;

      if (_lastFetchTime == null || DateTime.now().difference(_lastFetchTime!).inMinutes > 5) await _fetchData();
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
      await controller.removeLayer('$layerId-label');

      await controller.removeSource(sourceId);
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MorphingSheet(
          title: '風向/風速'.i18n,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          partialBuilder: (context, controller, sheetController) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Selector<DpipDataModel, UnmodifiableListView<String>>(
                selector: (context, model) => model.wind,
                builder: (context, wind, child) {
                  final times = wind.map((time) {
                    final t = time.toSimpleDateTimeString().split(' ');
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
                            Text('風向/風速'.i18n, style: context.textTheme.titleMedium),
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
                                                    manager.setWindTime(time.value);
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
        ),
        Positioned(
          top: 24 + 48 + 16,
          left: 24,
          child: SafeArea(
            child: BlurredContainer(
              elevation: 4,
              shadowColor: context.colors.shadow.withValues(alpha: 0.4),
              child: Legend(
                unit: 'm/s',
                items: [
                  LegendItem(
                    icon: const OutlinedIcon(Symbols.navigation_rounded, fill: Color(0xffffffff), size: 20),
                    label: '0.1 - 3.3',
                  ),
                  LegendItem(
                    icon: const OutlinedIcon(Symbols.navigation_rounded, fill: Color(0xff03fff0), size: 20),
                    label: '3.4 - 7.9',
                  ),
                  LegendItem(
                    icon: const OutlinedIcon(Symbols.navigation_rounded, fill: Color(0xff0385ff), size: 20),
                    label: '8.0 - 13.8',
                  ),
                  LegendItem(
                    icon: const OutlinedIcon(Symbols.navigation_rounded, fill: Color(0xff8000ff), size: 20),
                    label: '13.9 - 32.6',
                  ),
                  LegendItem(
                    icon: const OutlinedIcon(Symbols.navigation_rounded, fill: Color(0xffff006b), size: 20),
                    label: '≥ 32.7',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
