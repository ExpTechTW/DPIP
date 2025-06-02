import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/morphing_sheet.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';

class RadarMapLayerManager extends MapLayerManager {
  RadarMapLayerManager(super.context, super.controller);

  final currentRadarTime = ValueNotifier<String?>(GlobalProviders.data.radar.firstOrNull);
  final isLoading = ValueNotifier<bool>(false);

  Future<void> _updateRadarTileUrl(String time) async {
    if (currentRadarTime.value == time || isLoading.value) return;

    isLoading.value = true;

    try {
      await remove();
      currentRadarTime.value = time;
      await setup();

      TalkerManager.instance.info('Updated Radar tiles to "$time"');
    } catch (e, s) {
      TalkerManager.instance.error('Failed to update Radar tiles', e, s);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> setup() async {
    if (didSetup) return;

    try {
      if (GlobalProviders.data.radar.isEmpty) {
        final radarList = (await ExpTech().getRadarList()).reversed.toList();
        if (!context.mounted) return;

        GlobalProviders.data.setRadar(radarList);
        currentRadarTime.value = radarList.first;
      }

      final sourceId = MapSourceIds.radar(currentRadarTime.value);
      final layerId = MapLayerIds.radar(currentRadarTime.value);

      final isSourceExists = (await controller.getSourceIds()).contains(sourceId);
      final isLayerExists = (await controller.getLayerIds()).contains(layerId);

      if (isSourceExists && isLayerExists) return;

      if (!isSourceExists) {
        final properties = RasterSourceProperties(
          tiles: ['https://api-1.exptech.dev/api/v1/tiles/radar/${currentRadarTime.value}/{z}/{x}/{y}.png'],
          tileSize: 256,
        );

        await controller.addSource(sourceId, properties);
        TalkerManager.instance.info('Added Source "$sourceId"');

        if (!context.mounted) return;
      }

      if (!isLayerExists) {
        final properties = RasterLayerProperties(visibility: visible ? 'visible' : 'none');

        await controller.addLayer(sourceId, layerId, properties, belowLayerId: BaseMapLayerIds.countyOutline);
        TalkerManager.instance.info('Added Layer "$layerId"');
      }

      didSetup = true;
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.setup', e, s);
    }
  }

  @override
  Future<void> hide() async {
    if (!visible) return;

    final layerId = MapLayerIds.radar(currentRadarTime.value);

    try {
      await controller.setLayerVisibility(layerId, false);
      TalkerManager.instance.info('Hiding Layer "$layerId"');

      visible = false;
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (visible) return;

    final layerId = MapLayerIds.radar(currentRadarTime.value);

    try {
      await controller.setLayerVisibility(layerId, true);
      TalkerManager.instance.info('Showing Layer "$layerId"');

      visible = true;
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.show', e, s);
    }
  }

  @override
  Future<void> remove() async {
    try {
      final layerId = MapLayerIds.radar(currentRadarTime.value);
      final sourceId = MapSourceIds.radar(currentRadarTime.value);

      await controller.removeLayer(layerId);
      TalkerManager.instance.info('Removed Layer "$layerId"');

      await controller.removeSource(sourceId);
      TalkerManager.instance.info('Removed Source "$sourceId"');
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.dispose', e, s);
    }

    didSetup = false;
  }

  @override
  Widget build(BuildContext context) => RadarMapLayerSheet(manager: this);
}

class RadarMapLayerSheet extends StatelessWidget {
  final RadarMapLayerManager manager;

  const RadarMapLayerSheet({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return MorphingSheet(
      title: context.i18n.radar_monitor,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      partialBuilder: (context, controller, sheetController) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Selector<DpipDataModel, UnmodifiableListView<String>>(
            selector: (context, model) => model.radar,
            builder: (context, radar, child) {
              final times = radar.map((time) {
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
                        const Icon(Symbols.radar, size: 24),
                        Text(context.i18n.radar_monitor, style: context.textTheme.titleMedium),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: kMinInteractiveDimension,
                    child: ValueListenableBuilder<String?>(
                      valueListenable: manager.currentRadarTime,
                      builder: (context, currentTime, child) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: grouped.length,
                          itemBuilder: (context, index) {
                            final MapEntry(key: date, value: group) = grouped[index];

                            final children = <Widget>[Text(date)];

                            for (final time in group) {
                              final isSelected = time.value == currentTime;

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
                                                manager._updateRadarTileUrl(time.value);
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
