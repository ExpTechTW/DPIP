import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/map_legend.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/blurred_container.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/morphing_sheet.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';

class RadarMapLayerManager extends MapLayerManager {
  RadarMapLayerManager(super.context, super.controller, {this.getActiveLayerCount});

  final currentRadarTime = ValueNotifier<String?>(GlobalProviders.data.radar.firstOrNull);
  final isLoading = ValueNotifier<bool>(false);
  final isPlaying = ValueNotifier<bool>(false);
  final playStartTime = ValueNotifier<String?>(null);
  final playEndTime = ValueNotifier<String?>(null);

  Timer? _playTimer;
  final Set<String> _preloadedLayers = {};
  final int Function()? getActiveLayerCount;

  Future<void> updateRadarTime(String time) async {
    if (isPlaying.value) {
      stopAutoPlay();
      TalkerManager.instance.info('Auto-play stopped due to external control');
    }

    if (playStartTime.value != null) {
      final radarList = GlobalProviders.data.radar;
      final startIndex = radarList.indexOf(playStartTime.value);
      final newCurrentIndex = radarList.indexOf(time);

      if (startIndex != -1 && newCurrentIndex != -1 && newCurrentIndex > startIndex) {
        final newStartIndex = newCurrentIndex + 1;
        if (newStartIndex < radarList.length) {
          playStartTime.value = radarList[newStartIndex];
          TalkerManager.instance.info('Moved start time to right of current time: ${radarList[newStartIndex]}');

          final nextIndex = newStartIndex + 1;
          if (nextIndex < radarList.length) {
            playEndTime.value = radarList[nextIndex];
            TalkerManager.instance.info('Set end time to next item: ${playEndTime.value}');
          } else {
            playEndTime.value = null;
            TalkerManager.instance.info('Cleared end time because start time is at the end');
          }
        }
      }
    }

    await _updateRadarTileUrl(time);
    await _preloadAdjacentLayers(time);
  }

  void setPlayStartTime(String time) {
    if (time == currentRadarTime.value) {
      TalkerManager.instance.info('Cannot set current time as play start time');
      return;
    }

    final radarList = GlobalProviders.data.radar;
    final startIndex = radarList.indexOf(time);
    final currentIndex = currentRadarTime.value != null ? radarList.indexOf(currentRadarTime.value) : -1;

    if (startIndex != -1 && currentIndex != -1 && startIndex < currentIndex) {
      final newCurrentIndex = startIndex - 1;
      if (newCurrentIndex >= 0) {
        updateRadarTime(radarList[newCurrentIndex]);
        TalkerManager.instance.info('Moved current time to left of start time: ${radarList[newCurrentIndex]}');
      }
    }

    playStartTime.value = time;

    if (startIndex != -1) {
      final nextIndex = startIndex + 1;
      if (nextIndex < radarList.length) {
        playEndTime.value = radarList[nextIndex];
        TalkerManager.instance.info('Set end time to next item: ${playEndTime.value}');
      } else {
        playEndTime.value = null;
        TalkerManager.instance.info('Cleared end time because start time is at the end');
      }
    }

    TalkerManager.instance.info('Set play start time to: $time');
  }

  bool get canPlay {
    if (playStartTime.value == null) return true;

    final radarList = GlobalProviders.data.radar;
    final startIndex = radarList.indexOf(playStartTime.value);
    final currentIndex = currentRadarTime.value != null ? radarList.indexOf(currentRadarTime.value) : -1;

    return startIndex != -1 && currentIndex != -1 && startIndex > currentIndex;
  }

  bool get isMultiLayerMode {
    final count = getActiveLayerCount?.call() ?? 1;
    final isMulti = count > 1;

    if (isMulti && isPlaying.value) {
      stopAutoPlay();
    }

    return isMulti;
  }

  Future<void> _updateRadarTileUrl(String time) async {
    if (currentRadarTime.value == time || isLoading.value) return;

    isLoading.value = true;

    try {
      if (currentRadarTime.value != null) {
        await _hideLayer(currentRadarTime.value!);
      }

      currentRadarTime.value = time;

      await _setupAndShowLayer(time);

      TalkerManager.instance.info('Updated Radar tiles to "$time"');
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager._updateRadarTileUrl', e, s);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _setupAndShowLayer(String time) async {
    final sourceId = MapSourceIds.radar(time);
    final layerId = MapLayerIds.radar(time);

    final isSourceExists = (await controller.getSourceIds()).contains(sourceId);
    final isLayerExists = (await controller.getLayerIds()).contains(layerId);

    if (!isSourceExists) {
      final properties = RasterSourceProperties(
        tiles: ['https://api-1.exptech.dev/api/v1/tiles/radar/$time/{z}/{x}/{y}.png'],
        tileSize: 256,
      );

      await controller.addSource(sourceId, properties);
      TalkerManager.instance.info('Added Source "$sourceId"');
    }

    if (!isLayerExists) {
      final properties = RasterLayerProperties(visibility: visible ? 'visible' : 'none');

      await controller.addLayer(sourceId, layerId, properties, belowLayerId: BaseMapLayerIds.exptechCountyOutline);
      TalkerManager.instance.info('Added Layer "$layerId"');
    } else if (visible) {
      await controller.setLayerVisibility(layerId, true);
    }

    _preloadedLayers.add(time);
  }

  Future<void> _hideLayer(String time) async {
    final layerId = MapLayerIds.radar(time);

    try {
      await controller.setLayerVisibility(layerId, false);
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager._hideLayer', e, s);
    }
  }

  Future<void> _preloadAdjacentLayers(String currentTime) async {
    final radarList = GlobalProviders.data.radar;
    if (radarList.isEmpty) return;

    final currentIndex = radarList.indexOf(currentTime);
    if (currentIndex == -1) return;

    final layersToPreload = <String>[];

    for (int i = 1; i <= 3; i++) {
      if (currentIndex - i >= 0) {
        layersToPreload.add(radarList[currentIndex - i]);
      }
      if (currentIndex + i < radarList.length) {
        layersToPreload.add(radarList[currentIndex + i]);
      }
    }

    for (final time in layersToPreload) {
      if (!_preloadedLayers.contains(time)) {
        try {
          await _setupAndShowLayer(time);
          await _hideLayer(time);
          TalkerManager.instance.info('Preloaded radar layer: $time');
        } catch (e, s) {
          TalkerManager.instance.error('Failed to preload radar layer: $time', e, s);
        }
      }
    }
  }

  void toggleAutoPlay() {
    if (isPlaying.value) {
      stopAutoPlay();
    } else {
      startAutoPlay();
    }
  }

  void startAutoPlay() {
    if (isPlaying.value) return;

    if (playStartTime.value == null) {
      final radarList = GlobalProviders.data.radar;
      if (radarList.isNotEmpty) {
        playStartTime.value = radarList.last;
      }
    }

    if (playStartTime.value != null && playEndTime.value != null) {
      final radarList = GlobalProviders.data.radar;
      final startIndex = radarList.indexOf(playStartTime.value);
      final endIndex = radarList.indexOf(playEndTime.value);

      if (startIndex != -1 && endIndex != -1 && startIndex <= endIndex) {
        playEndTime.value = currentRadarTime.value;
      }
    } else if (playEndTime.value == null) {
      playEndTime.value = currentRadarTime.value;
    }

    if (playStartTime.value == null || playEndTime.value == null) {
      TalkerManager.instance.error('Cannot start auto-play: missing start or end time');
      return;
    }

    _updateRadarTileUrl(playStartTime.value!);

    isPlaying.value = true;
    _playTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      _playNext();
    });

    TalkerManager.instance.info('Started radar auto-play from: ${playStartTime.value} to: ${playEndTime.value}');
  }

  void stopAutoPlay() {
    if (!isPlaying.value) return;

    isPlaying.value = false;
    _playTimer?.cancel();
    _playTimer = null;
    _isWaitingForRestart = false;

    playStartTime.value = null;
    playEndTime.value = null;

    TalkerManager.instance.info('Stopped radar auto-play');
  }

  bool _isWaitingForRestart = false;

  void _playNext() {
    final radarList = GlobalProviders.data.radar;
    if (radarList.isEmpty || currentRadarTime.value == null || _isWaitingForRestart) return;

    final currentIndex = radarList.indexOf(currentRadarTime.value);
    if (currentIndex == -1) return;

    final startIndex = playStartTime.value != null ? radarList.indexOf(playStartTime.value) : -1;
    final endIndex = playEndTime.value != null ? radarList.indexOf(playEndTime.value) : -1;

    if (startIndex == -1 || endIndex == -1) {
      if (playStartTime.value != null) {
        _updateRadarTileUrl(playStartTime.value!);
      }
      return;
    }

    final nextIndex = currentIndex - 1;

    if (nextIndex >= endIndex) {
      final nextTime = radarList[nextIndex];
      _updateRadarTileUrl(nextTime);
    } else {
      _isWaitingForRestart = true;
      TalkerManager.instance.info('Reached end time, scheduling restart in 1 second');
      Timer(const Duration(milliseconds: 1000), () {
        if (isPlaying.value && playStartTime.value != null && _isWaitingForRestart) {
          TalkerManager.instance.info('Restarting from start time: ${playStartTime.value}');
          _updateRadarTileUrl(playStartTime.value!);
          _isWaitingForRestart = false;
        } else {
          TalkerManager.instance.info(
            'Restart cancelled - playing: ${isPlaying.value}, startTime: ${playStartTime.value}, waiting: $_isWaitingForRestart',
          );
        }
      });
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
      TalkerManager.instance.error('RadarMapLayerManager._focus', e, s);
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

      await _setupAndShowLayer(currentRadarTime.value!);
      await _preloadAdjacentLayers(currentRadarTime.value!);

      didSetup = true;
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.setup', e, s);
    }
  }

  @override
  Future<void> hide() async {
    if (!visible) return;

    stopAutoPlay();

    try {
      for (final time in _preloadedLayers) {
        await _hideLayer(time);
      }

      visible = false;
      TalkerManager.instance.info('Hidden all radar layers');
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (visible) return;

    try {
      if (currentRadarTime.value != null) {
        final layerId = MapLayerIds.radar(currentRadarTime.value);
        await controller.setLayerVisibility(layerId, true);
        TalkerManager.instance.info('Showing Layer "$layerId"');
      }

      await _focus();

      visible = true;
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.show', e, s);
    }
  }

  @override
  Future<void> remove() async {
    stopAutoPlay();

    try {
      for (final time in _preloadedLayers.toList()) {
        final layerId = MapLayerIds.radar(time);
        final sourceId = MapSourceIds.radar(time);

        await controller.removeLayer(layerId).catchError((_) {});
        await controller.removeSource(sourceId).catchError((_) {});
        TalkerManager.instance.info('Removed radar layer and source for "$time"');
      }

      _preloadedLayers.clear();
    } catch (e, s) {
      TalkerManager.instance.error('RadarMapLayerManager.remove', e, s);
    }

    didSetup = false;
  }

  @override
  void dispose() {
    stopAutoPlay();
    currentRadarTime.dispose();
    isLoading.dispose();
    isPlaying.dispose();
    playStartTime.dispose();
    playEndTime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isMultiLayerMode) {
      return const SizedBox.shrink();
    }
    return RadarMapLayerSheet(manager: this);
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final Color borderColor;

  const _LegendItem({required this.label, required this.color, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
        ),
        Text(label, style: context.textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant, height: 1)),
      ],
    );
  }
}

class RadarMapLayerSheet extends StatelessWidget {
  final RadarMapLayerManager manager;

  const RadarMapLayerSheet({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MorphingSheet(
          title: '雷達回波'.i18n,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          partialBuilder: (context, controller, sheetController) {
            return Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 4),
                        child: SizedBox(
                          height: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                spacing: 8,
                                children: [
                                  Icon(Symbols.radar_rounded, size: 24, color: context.colors.onSurface),
                                  Text(
                                    '雷達回波'.i18n,
                                    style: context.textTheme.titleMedium?.copyWith(color: context.colors.onSurface),
                                  ),
                                  AnimatedBuilder(
                                    animation: Listenable.merge([
                                      manager.currentRadarTime,
                                      manager.playStartTime,
                                      manager.isPlaying,
                                    ]),
                                    builder: (context, child) {
                                      final currentTime = manager.currentRadarTime.value;

                                      if (currentTime == null) return const SizedBox.shrink();

                                      try {
                                        final timeFormatted = currentTime.toSimpleDateTimeString(context);
                                        final timeData = timeFormatted.split(' ');
                                        final date = timeData.length > 1 ? timeData[0] : '';
                                        final time = timeData.length > 1 ? timeData[1] : timeData[0];

                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: context.colors.surfaceContainer.withValues(alpha: 0.6),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: context.colors.outline),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            spacing: 4,
                                            children: [
                                              Icon(
                                                Icons.schedule_rounded,
                                                size: 12,
                                                color: context.colors.onSurfaceVariant,
                                              ),
                                              if (date.isNotEmpty) ...[
                                                Text(
                                                  date,
                                                  style: context.textTheme.labelSmall?.copyWith(
                                                    color: context.colors.onSurfaceVariant,
                                                    height: 1,
                                                  ),
                                                ),
                                                Container(
                                                  width: 0.5,
                                                  height: 14,
                                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                                  color: context.colors.outline,
                                                ),
                                              ],
                                              Text(
                                                time,
                                                style: context.textTheme.bodySmall?.copyWith(
                                                  color: context.colors.onSurface,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      } catch (e) {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                ],
                              ),
                              AnimatedBuilder(
                                animation: Listenable.merge([
                                  manager.isPlaying,
                                  manager.playStartTime,
                                  manager.currentRadarTime,
                                ]),
                                builder: (context, child) {
                                  final isPlaying = manager.isPlaying.value;
                                  final startTime = manager.playStartTime.value;
                                  final canPlay = manager.canPlay;

                                  final shouldHide = startTime == null && !isPlaying;

                                  if (shouldHide) {
                                    return const SizedBox.shrink();
                                  }

                                  return IconButton(
                                    onPressed: canPlay || isPlaying ? manager.toggleAutoPlay : null,
                                    icon: Icon(
                                      isPlaying ? Symbols.pause_rounded : Symbols.play_arrow_rounded,
                                      size: 24,
                                      color: context.colors.primary,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: Listenable.merge([manager.playStartTime, manager.isPlaying]),
                        builder: (context, child) {
                          final startTime = manager.playStartTime.value;
                          final isPlaying = manager.isPlaying.value;

                          if (isPlaying) {
                            return const SizedBox.shrink();
                          }

                          if (startTime == null && !isPlaying) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                              child: Text(
                                '長按設定播放起點'.i18n,
                                style: context.textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: Column(
                              children: [
                                Row(
                                  spacing: 8,
                                  children: [
                                    _LegendItem(
                                      label: '目前時間'.i18n,
                                      color: context.colors.primaryContainer,
                                      borderColor: context.colors.primary,
                                    ),
                                    _LegendItem(
                                      label: '播放起點'.i18n,
                                      color: context.colors.tertiaryContainer,
                                      borderColor: context.colors.tertiary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: manager.isPlaying,
                        builder: (context, isPlaying, child) {
                          if (isPlaying) {
                            return Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  manager.currentRadarTime,
                                  manager.playStartTime,
                                  manager.playEndTime,
                                ]),
                                builder: (context, child) {
                                  return _RadarProgressBar(manager: manager);
                                },
                              ),
                            );
                          }

                          return SizedBox(
                            height: kMinInteractiveDimension,
                            child: ValueListenableBuilder<String?>(
                              valueListenable: manager.currentRadarTime,
                              builder: (context, currentTime, child) {
                                return ValueListenableBuilder<String?>(
                                  valueListenable: manager.playStartTime,
                                  builder: (context, startTime, child) {
                                    return _AutoScrollingTimeList(
                                      grouped: grouped,
                                      currentTime: currentTime,
                                      startTime: startTime,
                                      manager: manager,
                                      shouldFocusOnShow: true,
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
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
              child: ColorLegend(
                reverse: true,
                unit: 'dBZ',
                items: [
                  ColorLegendItem(color: const Color(0xff00ffff), value: 0),
                  ColorLegendItem(color: const Color(0xff00a3ff), value: 5),
                  ColorLegendItem(color: const Color(0xff005bff), value: 10),
                  ColorLegendItem(color: const Color(0xff0000ff), value: 15, blendTail: false),
                  ColorLegendItem(color: const Color(0xff00ff00), value: 16, hidden: true),
                  ColorLegendItem(color: const Color(0xff00d300), value: 20),
                  ColorLegendItem(color: const Color(0xff00a000), value: 25),
                  ColorLegendItem(color: const Color(0xffccea00), value: 30),
                  ColorLegendItem(color: const Color(0xffffd300), value: 35),
                  ColorLegendItem(color: const Color(0xffff8800), value: 40),
                  ColorLegendItem(color: const Color(0xffff1800), value: 45),
                  ColorLegendItem(color: const Color(0xffd30000), value: 50),
                  ColorLegendItem(color: const Color(0xffa00000), value: 55),
                  ColorLegendItem(color: const Color(0xffea00cc), value: 60),
                  ColorLegendItem(color: const Color(0xff9600ff), value: 65),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AutoScrollingTimeList extends StatefulWidget {
  final List<MapEntry<String, List<({String date, String time, String value})>>> grouped;
  final String? currentTime;
  final String? startTime;
  final RadarMapLayerManager manager;
  final bool shouldFocusOnShow;

  const _AutoScrollingTimeList({
    required this.grouped,
    required this.currentTime,
    required this.startTime,
    required this.manager,
    this.shouldFocusOnShow = false,
  });

  @override
  State<_AutoScrollingTimeList> createState() => _AutoScrollingTimeListState();
}

class _AutoScrollingTimeListState extends State<_AutoScrollingTimeList> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _chipKeys = {};
  String? _lastCurrentTime;

  @override
  void initState() {
    super.initState();
    for (final group in widget.grouped) {
      for (final time in group.value) {
        _chipKeys[time.value] = GlobalKey();
      }
    }

    if (widget.shouldFocusOnShow && widget.currentTime != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _scrollToCurrentTime();
          }
        });
      });
    }
  }

  @override
  void didUpdateWidget(_AutoScrollingTimeList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentTime != _lastCurrentTime && widget.currentTime != null) {
      _lastCurrentTime = widget.currentTime;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentTime();
      });
    }
  }

  void _scrollToCurrentTime() {
    if (widget.currentTime == null || !_scrollController.hasClients) return;

    final key = _chipKeys[widget.currentTime];
    if (key?.currentContext == null) return;

    try {
      final RenderBox? renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final RenderBox? scrollViewBox =
          _scrollController.position.context.storageContext.findRenderObject() as RenderBox?;
      if (scrollViewBox == null) return;

      if (!renderBox.attached) return;

      final position = renderBox.localToGlobal(Offset.zero);
      final localPosition = scrollViewBox.globalToLocal(position);

      final targetOffset =
          _scrollController.offset + localPosition.dx - (scrollViewBox.size.width / 2) + (renderBox.size.width / 2);

      final clampedOffset = targetOffset.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );

      if ((clampedOffset - _scrollController.offset).abs() > 20) {
        _scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: widget.grouped.length,
      itemBuilder: (context, index) {
        final MapEntry(key: date, value: group) = widget.grouped[index];

        final children = <Widget>[Text(date)];

        for (final time in group) {
          final isSelected = time.value == widget.currentTime;
          final isStartTime = time.value == widget.startTime;

          children.add(
            ValueListenableBuilder<bool>(
              valueListenable: widget.manager.isLoading,
              builder: (context, isLoading, child) {
                Color chipColor;
                Color borderColor;
                Color textColor;

                if (isSelected) {
                  chipColor = context.colors.primaryContainer;
                  borderColor = context.colors.primary;
                  textColor = context.colors.onPrimaryContainer;
                } else if (isStartTime) {
                  chipColor = context.colors.tertiaryContainer;
                  borderColor = context.colors.tertiary;
                  textColor = context.colors.onTertiaryContainer;
                } else {
                  chipColor = context.colors.surface.withValues(alpha: 0.6);
                  borderColor = context.colors.outlineVariant;
                  textColor = context.colors.onSurfaceVariant;
                }

                return GestureDetector(
                  onLongPress:
                      isLoading
                          ? null
                          : () {
                            widget.manager.setPlayStartTime(time.value);
                          },
                  child: FilterChip(
                    key: _chipKeys[time.value],
                    selected: isSelected,
                    showCheckmark: !isLoading,
                    label: Text(time.time, style: TextStyle(color: textColor)),
                    backgroundColor: chipColor,
                    side: BorderSide(color: borderColor),
                    avatar: isSelected && isLoading ? const LoadingIcon() : null,
                    onSelected:
                        isLoading
                            ? null
                            : (selected) {
                              if (!selected) return;
                              widget.manager.updateRadarTime(time.value);
                            },
                  ),
                );
              },
            ),
          );
        }

        children.add(
          const Padding(padding: EdgeInsets.only(right: 8), child: VerticalDivider(width: 16, indent: 8, endIndent: 8)),
        );

        return Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: children);
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _RadarProgressBar extends StatelessWidget {
  final RadarMapLayerManager manager;

  const _RadarProgressBar({required this.manager});

  @override
  Widget build(BuildContext context) {
    final currentTime = manager.currentRadarTime.value;
    final startTime = manager.playStartTime.value;
    final endTime = manager.playEndTime.value;

    if (currentTime == null || startTime == null || endTime == null) {
      return const SizedBox.shrink();
    }

    final radarList = GlobalProviders.data.radar;
    final currentIndex = radarList.indexOf(currentTime);
    final startIndex = radarList.indexOf(startTime);
    final endIndex = radarList.indexOf(endTime);

    if (currentIndex == -1 || startIndex == -1 || endIndex == -1) {
      return const SizedBox.shrink();
    }

    double progress = 0.0;
    if (startIndex != endIndex) {
      progress = (startIndex - currentIndex) / (startIndex - endIndex);
      progress = progress.clamp(0.0, 1.0);
    }

    return Row(
      spacing: 8,
      children: [
        Icon(Icons.play_circle_rounded, size: 16, color: context.colors.primary),
        Text('播放進度'.i18n, style: context.textTheme.labelSmall?.copyWith(color: context.colors.onSurface, height: 1)),
        Expanded(child: LinearProgressIndicator(value: progress, year2023: false)),
        Text(
          '${(progress * 100).round()}%',
          style: context.textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
