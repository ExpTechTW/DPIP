import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/weather/lightning.dart';
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
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class LightningData {
  final double latitude;
  final double longitude;
  final int type;
  final int time;

  LightningData({required this.latitude, required this.longitude, required this.type, required this.time});
}

class LightningMapLayerManager extends MapLayerManager {
  LightningMapLayerManager(super.context, super.controller);

  final currentLightningTime = ValueNotifier<String?>(GlobalProviders.data.lightning.firstOrNull);
  final isLoading = ValueNotifier<bool>(false);

  DateTime? _lastFetchTime;

  Function(String)? onTimeChanged;

  Future<void> setLightningTime(String time) async {
    if (currentLightningTime.value == time || isLoading.value) return;

    isLoading.value = true;

    try {
      await remove();
      currentLightningTime.value = time;
      await setup();

      onTimeChanged?.call(time);
    } catch (e, s) {
      TalkerManager.instance.error('LightningMapLayerManager.setLightningTime', e, s);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchData() async {
    final lightningList = (await ExpTech().getLightningList()).reversed.toList();
    if (!context.mounted) return;

    GlobalProviders.data.setLightning(lightningList);
    currentLightningTime.value ??= lightningList.first;
    _lastFetchTime = DateTime.now();
  }

  @override
  Future<void> setup() async {
    if (didSetup) return;

    try {
      if (GlobalProviders.data.lightning.isEmpty) await _fetchData();

      final time = currentLightningTime.value;

      if (time == null) throw Exception('Time is null');

      final sourceId = MapSourceIds.lightning(time);
      final layerId = MapLayerIds.lightning(time);

      final isSourceExists = (await controller.getSourceIds()).contains(sourceId);
      final isLayerExists = (await controller.getLayerIds()).contains(layerId);

      if (!isSourceExists) {
        late final List<Lightning> lightningData;

        if (GlobalProviders.data.lightningData.containsKey(time)) {
          lightningData = GlobalProviders.data.lightningData[time]!;
        } else {
          lightningData = await ExpTech().getLightning(time);
          GlobalProviders.data.setLightningData(time, lightningData);
        }

        // final currentTime = int.parse(time);
        // final features = lightningData.map((data) => data.toFeatureBuilder(currentTime)).toList();

        // final data = GeoJsonBuilder().setFeatures(features).build();

        // final properties = GeojsonSourceProperties(data: data);

        // await controller.addSource(sourceId, properties);

        if (!context.mounted) return;
      }

      if (!isLayerExists) {
        final properties = SymbolLayerProperties(
          iconSize: [
            Expressions.interpolate,
            ['linear'],
            [Expressions.zoom],
            5,
            0.5,
            10,
            1.3,
          ],
          iconImage: [
            Expressions.match,
            ['get', 'type'],
            '1-5',
            'lightning-1-5',
            '1-10',
            'lightning-1-10',
            '1-30',
            'lightning-1-30',
            '1-60',
            'lightning-1-60',
            '0-5',
            'lightning-0-5',
            '0-10',
            'lightning-0-10',
            '0-30',
            'lightning-0-30',
            '0-60',
            'lightning-0-60',
          ],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          visibility: visible ? 'visible' : 'none',
        );

        await controller.addLayer(sourceId, layerId, properties, belowLayerId: BaseMapLayerIds.userLocation);
      }

      if (isSourceExists && isLayerExists) return;

      didSetup = true;
    } catch (e, s) {
      TalkerManager.instance.error('LightningMapLayerManager.setup', e, s);
    }
  }

  @override
  Future<void> hide() async {
    if (!visible) return;

    final layerId = MapLayerIds.lightning(currentLightningTime.value);

    try {
      await controller.setLayerVisibility(layerId, false);
      await controller.setLayerVisibility('$layerId-label', false);

      visible = false;
    } catch (e, s) {
      TalkerManager.instance.error('LightningMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (visible) return;

    final layerId = MapLayerIds.lightning(currentLightningTime.value);

    try {
      await controller.setLayerVisibility(layerId, true);
      await controller.setLayerVisibility('$layerId-label', true);

      visible = true;

      if (_lastFetchTime == null || DateTime.now().difference(_lastFetchTime!).inMinutes > 5) await _fetchData();
    } catch (e, s) {
      TalkerManager.instance.error('LightningMapLayerManager.show', e, s);
    }
  }

  @override
  Future<void> remove() async {
    try {
      final layerId = MapLayerIds.lightning(currentLightningTime.value);
      final sourceId = MapSourceIds.lightning(currentLightningTime.value);

      await controller.removeLayer(layerId);
      await controller.removeLayer('$layerId-label');

      await controller.removeSource(sourceId);
    } catch (e, s) {
      TalkerManager.instance.error('LightningMapLayerManager.dispose', e, s);
    }

    didSetup = false;
  }

  @override
  Widget build(BuildContext context) => LightningMapLayerSheet(manager: this);
}

class LightningMapLayerSheet extends StatelessWidget {
  final LightningMapLayerManager manager;

  const LightningMapLayerSheet({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MorphingSheet(
          title: '閃電'.i18n,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          partialBuilder: (context, controller, sheetController) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Selector<DpipDataModel, UnmodifiableListView<String>>(
                selector: (context, model) => model.lightning,
                builder: (context, lightning, child) {
                  final times = lightning.map((time) {
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
                            Text('閃電'.i18n, style: context.textTheme.titleMedium),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: kMinInteractiveDimension,
                        child: ValueListenableBuilder<String?>(
                          valueListenable: manager.currentLightningTime,
                          builder: (context, currentLightningTime, child) {
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: grouped.length,
                              itemBuilder: (context, index) {
                                final MapEntry(key: date, value: group) = grouped[index];

                                final children = <Widget>[Text(date)];

                                for (final time in group) {
                                  final isSelected = time.value == currentLightningTime;

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
                                                    manager.setLightningTime(time.value);
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
                items: [
                  LegendItem(
                    icon: const OutlinedIcon(Symbols.navigation_rounded, fill: Color(0xffffffff), size: 20),
                    label: '5 分鐘內對地閃電',
                  ),
                  LegendItem(
                    icon: const OutlinedIcon(Symbols.navigation_rounded, fill: Color(0xff03fff0), size: 20),
                    label: '10 分鐘內對地閃電',
                  ),
                  LegendItem(
                    icon: const OutlinedIcon(Symbols.navigation_rounded, fill: Color(0xff0385ff), size: 20),
                    label: '30 分鐘內對地閃電',
                  ),
                  LegendItem(
                    icon: const OutlinedIcon(Symbols.navigation_rounded, fill: Color(0xff8000ff), size: 20),
                    label: '60 分鐘內對地閃電',
                  ),
                  LegendItem(
                    icon: const OutlinedIcon(Symbols.navigation_rounded, fill: Color(0xffff006b), size: 20),
                    label: '5 分鐘內雲間閃電',
                  ),
                  LegendItem(
                    icon: const OutlinedIcon(Symbols.navigation_rounded, fill: Color(0xffff006b), size: 20),
                    label: '10 分鐘內雲間閃電',
                  ),
                  LegendItem(
                    icon: const OutlinedIcon(Symbols.navigation_rounded, fill: Color(0xffff006b), size: 20),
                    label: '30 分鐘內雲間閃電',
                  ),
                  LegendItem(
                    icon: const OutlinedIcon(Symbols.navigation_rounded, fill: Color(0xffff006b), size: 20),
                    label: '60 分鐘內雲間閃電',
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
