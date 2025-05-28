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

  final ValueNotifier<String?> currentRadarTime = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  Future<void> _updateRadarTileUrl(String time) async {
    if (currentRadarTime.value == time || isLoading.value) return;

    isLoading.value = true;
    try {
      currentRadarTime.value = time; // Update the notifier
      await remove();
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
      final isRadarSourceExists = (await controller.getSourceIds()).contains(MapSourceIds.radar);
      final isRadarLayerExists = (await controller.getLayerIds()).contains(MapLayerIds.radar);

      if (isRadarSourceExists && isRadarLayerExists) return;

      if (!isRadarSourceExists) {
        if (GlobalProviders.data.radar.isEmpty) {
          final radarList = (await ExpTech().getRadarList()).reversed.toList();
          if (!context.mounted) return;

          GlobalProviders.data.setRadar(radarList);
        }

        currentRadarTime.value ??= GlobalProviders.data.radar.first;

        final tileUrl = 'https://api-1.exptech.dev/api/v1/tiles/radar/${currentRadarTime.value}/{z}/{x}/{y}.png';

        await controller.addSource(MapSourceIds.radar, RasterSourceProperties(tiles: [tileUrl], tileSize: 256));
        TalkerManager.instance.info('Added Source "${MapSourceIds.radar}"');

        if (!context.mounted) return;
      }

      if (!isRadarLayerExists) {
        await controller.addLayer(
          MapSourceIds.radar,
          MapLayerIds.radar,
          RasterLayerProperties(visibility: visible ? 'visible' : 'none'),
          belowLayerId: BaseMapLayerIds.countyOutline,
        );
        TalkerManager.instance.info('Added Layer "${MapLayerIds.radar}"');
      }

      didSetup = true;
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.setup', e, s);
    }
  }

  @override
  Future<void> hide() async {
    if (!visible) return;

    try {
      await controller.setLayerVisibility(MapLayerIds.radar, false);
      TalkerManager.instance.info('Hiding Layer "${MapLayerIds.radar}"');

      visible = false;
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (visible) return;

    try {
      await controller.setLayerVisibility(MapLayerIds.radar, true);
      TalkerManager.instance.info('Showing Layer "${MapLayerIds.radar}"');

      visible = true;
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.show', e, s);
    }
  }

  @override
  Future<void> remove() async {
    try {
      await controller.removeLayer(MapLayerIds.radar);
      TalkerManager.instance.info('Removed Layer "${MapLayerIds.radar}"');

      await controller.removeSource(MapSourceIds.radar);
      TalkerManager.instance.info('Removed Source "${MapSourceIds.radar}"');
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.dispose', e, s);
    }

    didSetup = false;
  }

  @override
  Widget build(BuildContext context) => RadarMapLayerSheet(manager: this);
}

class RadarMapLayerSheet extends StatefulWidget {
  final RadarMapLayerManager manager;

  const RadarMapLayerSheet({super.key, required this.manager});

  @override
  State<RadarMapLayerSheet> createState() => _RadarMapLayerSheetState();
}

class _RadarMapLayerSheetState extends State<RadarMapLayerSheet> {
  @override
  Widget build(BuildContext context) {
    return MorphingSheet(
      title: context.i18n.radar_monitor,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      partialBuilder: (context, controller) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Selector<DpipDataModel, List<String>>(
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
                      children: [
                        const Icon(Symbols.radar, size: 24),
                        const SizedBox(width: 12),
                        Expanded(child: Text(context.i18n.radar_monitor, style: context.textTheme.titleMedium)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: kMinInteractiveDimension,
                    child: ValueListenableBuilder<String?>(
                      valueListenable: widget.manager.currentRadarTime,
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
                                  valueListenable: widget.manager.isLoading,
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
                                                widget.manager._updateRadarTileUrl(time.value);
                                              },
                                    );
                                  },
                                ),
                              );
                            }

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children:
                                  children.followedBy([
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: VerticalDivider(width: 16, indent: 8, endIndent: 8),
                                    ),
                                  ]).toList(),
                            );
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
