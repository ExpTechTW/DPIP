import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/weather/weather.dart';
import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/morphing_sheet.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

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

  @override
  Future<void> setup() async {
    if (didSetup) return;

    try {
      if (GlobalProviders.data.wind.isEmpty) {
        final windList = (await ExpTech().getWeatherList()).reversed.toList();
        if (!context.mounted) return;

        GlobalProviders.data.setWind(windList);
        currentWindTime.value = windList.first;
      }

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
        final properties = SymbolLayerProperties(
          iconImage: [Expressions.get, 'icon'],
          iconSize: kSymbolIconSize,
          iconRotate: [Expressions.get, 'wind_direction'],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          visibility: visible ? 'visible' : 'none',
        );

        await controller.addLayer(sourceId, layerId, properties, belowLayerId: BaseMapLayerIds.userLocation);
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
    return MorphingSheet(
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
    );
  }
}
