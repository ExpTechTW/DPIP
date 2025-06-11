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

  static const precipitationIntervals = ['now', '10m', '1h', '3h', '6h', '12h', '24h', '2d', '3d'];

  final currentPrecipitationTime = ValueNotifier<String?>(GlobalProviders.data.precipitation.firstOrNull);
  final currentPrecipitationInterval = ValueNotifier<String>('now');
  final isLoading = ValueNotifier<bool>(false);

  Future<void> setPrecipitationTime(String time) async {
    if (currentPrecipitationTime.value == time || isLoading.value) return;

    isLoading.value = true;

    try {
      await remove();
      currentPrecipitationTime.value = time;
      await setup();

      TalkerManager.instance.info('Updated Precipitation data to "$time"');
    } catch (e, s) {
      TalkerManager.instance.error('PrecipitationMapLayerManager.setPrecipitationTime', e, s);
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
      TalkerManager.instance.info('Showing Layer "$showLayerId"');

      await controller.setLayerVisibility(hideLayerId, false);
      TalkerManager.instance.info('Hiding Layer "$hideLayerId"');

      currentPrecipitationInterval.value = interval;
    } catch (e, s) {
      TalkerManager.instance.error('PrecipitationMapLayerManager.setPrecipitationInterval', e, s);
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
      if (GlobalProviders.data.precipitation.isEmpty) {
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

        final features = rainData.map((station) => station.toFeatureBuilder());

        final data = GeoJsonBuilder().setFeatures(features).build();

        final properties = GeojsonSourceProperties(data: data);

        await controller.addSource(sourceId, properties);
        TalkerManager.instance.info('Added Source "$sourceId"');

        if (!context.mounted) return;
      }

      if (!isLayerExists) {
        final properties = {
          for (final interval in precipitationIntervals)
            interval: CircleLayerProperties(
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
              circleOpacity: [
                'case',
                [
                  '<',
                  [Expressions.get, interval],
                  0,
                ],
                0,
                0.7,
              ],
              circleStrokeWidth: 0.2,
              circleStrokeColor: '#000000',
              circleStrokeOpacity: [
                'case',
                [
                  '<',
                  [Expressions.get, interval],
                  0,
                ],
                0,
                0.7,
              ],
              visibility: interval == currentPrecipitationInterval.value ? 'visible' : 'none',
            ),
        };

        await Future.wait(
          properties.entries.map(
            (entry) => controller
                .addLayer(sourceId, '$layerId-${entry.key}', entry.value, belowLayerId: BaseMapLayerIds.userLocation)
                .then((value) {
                  TalkerManager.instance.info('Added Layer "$layerId-${entry.key}"');
                }),
          ),
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

    try {
      await controller.setLayerVisibility(hideLayerId, false);
      TalkerManager.instance.info('Hiding Layer "$hideLayerId"');

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

    try {
      await controller.setLayerVisibility(showLayerId, true);
      TalkerManager.instance.info('Showing Layer "$showLayerId"');

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

      for (final interval in precipitationIntervals) {
        await controller.removeLayer('$layerId-$interval');
        TalkerManager.instance.info('Removed Layer "$layerId-$interval"');
      }

      await controller.removeSource(sourceId);
      TalkerManager.instance.info('Removed Source "$sourceId"');
    } catch (e, s) {
      TalkerManager.instance.error('PrecipitationMapLayerManager.remove', e, s);
    }

    didSetup = false;
  }

  @override
  Widget build(BuildContext context) => PrecipitationMapLayerSheet(manager: this);
}

class PrecipitationMapLayerSheet extends StatelessWidget {
  final PrecipitationMapLayerManager manager;

  const PrecipitationMapLayerSheet({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    String getIntervalLabel(String interval) => switch (interval) {
      'now' => '今日',
      '10m' => '10 分鐘',
      '1h' => '1 小時',
      '3h' => '3 小時',
      '6h' => '6 小時',
      '12h' => '12 小時',
      '24h' => '24 小時',
      '2d' => '2 天',
      '3d' => '3 天',
      _ => interval,
    };

    return MorphingSheet(
      title: '降水',
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      partialBuilder: (context, controller, sheetController) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Selector<DpipDataModel, UnmodifiableListView<String>>(
            selector: (context, model) => model.precipitation,
            builder: (context, precipitation, header) {
              final times = precipitation.map((time) {
                final t = time.toSimpleDateTimeString(context).split(' ');
                return (date: t[0], time: t[1], value: time);
              });
              final grouped = times.groupListsBy((time) => time.date).entries.toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header!,
                  SizedBox(
                    height: kMinInteractiveDimension,
                    child: ValueListenableBuilder<String?>(
                      valueListenable: manager.currentPrecipitationInterval,
                      builder: (context, currentPrecipitationInterval, child) {
                        const intervals = PrecipitationMapLayerManager.precipitationIntervals;

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: intervals.length,
                          itemBuilder: (context, index) {
                            final interval = intervals[index];
                            final isSelected = interval == currentPrecipitationInterval;

                            return ValueListenableBuilder<bool>(
                              valueListenable: manager.isLoading,
                              builder: (context, isLoading, child) {
                                return FilterChip(
                                  selected: isSelected,
                                  showCheckmark: !isLoading,
                                  label: Text(getIntervalLabel(interval)),
                                  side: BorderSide(
                                    color: isSelected ? context.colors.primary : context.colors.outlineVariant,
                                  ),
                                  avatar: isSelected && isLoading ? const LoadingIcon() : null,
                                  onSelected:
                                      isLoading
                                          ? null
                                          : (selected) {
                                            if (!selected) return;
                                            manager.setPrecipitationInterval(interval);
                                          },
                                );
                              },
                            );
                          },
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
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
                                                manager.setPrecipitationTime(time.value);
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                spacing: 8,
                children: [
                  const Icon(Symbols.water_drop_rounded, size: 24),
                  Text('降水', style: context.textTheme.titleMedium),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
