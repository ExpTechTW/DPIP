import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/morphing_sheet.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

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

    await _updateRadarTileUrl(time);
    await _preloadAdjacentLayers(time);
  }

  void setPlayStartTime(String time) {
    if (time == currentRadarTime.value) {
      TalkerManager.instance.info('Cannot set current time as play start time');
      return;
    }

    playStartTime.value = time;

    if (playEndTime.value != null) {
      final radarList = GlobalProviders.data.radar;
      final startIndex = radarList.indexOf(time);
      final endIndex = radarList.indexOf(playEndTime.value!);

      if (startIndex != -1 && endIndex != -1 && startIndex <= endIndex) {
        playEndTime.value = null;
        TalkerManager.instance.info('Cleared end time because start time is after end time');
      }
    }

    TalkerManager.instance.info('Set play start time to: $time');
  }

  bool get canPlay {
    if (playStartTime.value == null) return true;

    final radarList = GlobalProviders.data.radar;
    final startIndex = radarList.indexOf(playStartTime.value!);

    if (playEndTime.value == null) {
      final currentIndex = currentRadarTime.value != null ? radarList.indexOf(currentRadarTime.value!) : -1;
      return startIndex != -1 && currentIndex != -1 && startIndex > currentIndex;
    }

    final endIndex = radarList.indexOf(playEndTime.value!);

    return startIndex != -1 && endIndex != -1 && startIndex > endIndex;
  }

  bool get isMultiLayerMode {
    final count = getActiveLayerCount?.call() ?? 1;
    final isMulti = count > 1;

    if (isMulti && isPlaying.value) {
      stopAutoPlay();
    }

    return isMulti;
  }

  bool isFrameAfterPlayback(String time) {
    if (playEndTime.value == null || playStartTime.value == null) return false;

    final radarList = GlobalProviders.data.radar;
    final startIndex = radarList.indexOf(playStartTime.value!);
    final endIndex = radarList.indexOf(playEndTime.value!);
    final timeIndex = radarList.indexOf(time);

    if (startIndex == -1 || endIndex == -1 || timeIndex == -1) return false;

    return timeIndex < startIndex && timeIndex > endIndex;
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

    playEndTime.value = currentRadarTime.value;

    if (playStartTime.value == null) {
      final radarList = GlobalProviders.data.radar;
      if (radarList.isNotEmpty) {
        playStartTime.value = radarList.last;
      }
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

    final currentIndex = radarList.indexOf(currentRadarTime.value!);
    if (currentIndex == -1) return;

    final startIndex = playStartTime.value != null ? radarList.indexOf(playStartTime.value!) : -1;
    final endIndex = playEndTime.value != null ? radarList.indexOf(playEndTime.value!) : -1;

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
        final layerId = MapLayerIds.radar(currentRadarTime.value!);
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

        try {
          await controller.removeLayer(layerId);
          await controller.removeSource(sourceId);
          TalkerManager.instance.info('Removed radar layer and source for "$time"');
        } catch (e) {}
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

class RadarMapLayerSheet extends StatelessWidget {
  final RadarMapLayerManager manager;

  const RadarMapLayerSheet({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return MorphingSheet(
      title: '雷達回波'.i18n,
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
                      children: [
                        Icon(Symbols.radar_rounded, size: 24, color: context.colors.onSurface),
                        const SizedBox(width: 8),
                        Text(
                          '雷達回波'.i18n,
                          style: context.textTheme.titleMedium?.copyWith(color: context.colors.onSurface),
                        ),
                        const Spacer(),
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            manager.isPlaying,
                            manager.playStartTime,
                            manager.playEndTime,
                            manager.currentRadarTime,
                          ]),
                          builder: (context, child) {
                            final isPlaying = manager.isPlaying.value;
                            final startTime = manager.playStartTime.value;
                            final endTime = manager.playEndTime.value;
                            final canPlay = manager.canPlay;

                            final shouldHide =
                                (startTime == null && !isPlaying) ||
                                (startTime != null && endTime != null && !canPlay && !isPlaying);

                            if (shouldHide) {
                              return const SizedBox(width: 24, height: 24);
                            }

                            return InkWell(
                              onTap: canPlay || isPlaying ? manager.toggleAutoPlay : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                child: Icon(
                                  isPlaying ? Symbols.pause_rounded : Symbols.play_arrow_rounded,
                                  size: 24,
                                  color: context.colors.primary,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: Listenable.merge([manager.currentRadarTime, manager.playStartTime, manager.isPlaying]),
                    builder: (context, child) {
                      final currentTime = manager.currentRadarTime.value;
                      final hasStartTime = manager.playStartTime.value != null;
                      final isPlaying = manager.isPlaying.value;

                      if (currentTime == null) return const SizedBox.shrink();

                      try {
                        final timeFormatted = currentTime.toSimpleDateTimeString(context);
                        final timeData = timeFormatted.split(' ');
                        final date = timeData.length > 1 ? timeData[0] : '';
                        final time = timeData.length > 1 ? timeData[1] : timeData[0];

                        return Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule_rounded, size: 12, color: context.colors.onSurfaceVariant),
                                  const SizedBox(width: 3),
                                  if (date.isNotEmpty) ...[
                                    Text(
                                      date,
                                      style: context.textTheme.bodySmall?.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                  ],
                                  Text(
                                    time,
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: context.colors.onSurface,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } catch (e) {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  AnimatedBuilder(
                    animation: Listenable.merge([manager.playStartTime, manager.isPlaying]),
                    builder: (context, child) {
                      final startTime = manager.playStartTime.value;
                      final isPlaying = manager.isPlaying.value;

                      if (startTime == null && !isPlaying) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildLegendItem(context, '目前播放', context.colors.primary),
                                const SizedBox(width: 12),
                                _buildLegendItem(context, '播放起點', Colors.orange),
                                const SizedBox(width: 12),
                                _buildLegendItem(context, '播放結束', Colors.red),
                                const SizedBox(width: 12),
                                _buildLegendItem(context, '播放範圍', Colors.green),
                              ],
                            ),
                            if (startTime == null && !isPlaying) ...[
                              const SizedBox(height: 2),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '長按設定播放起點'.i18n,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colors.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      manager.playStartTime,
                      manager.isPlaying,
                      manager.playEndTime,
                      manager.currentRadarTime,
                    ]),
                    builder: (context, child) {
                      final startTime = manager.playStartTime.value;
                      final isPlaying = manager.isPlaying.value;
                      final endTime = manager.playEndTime.value;
                      final canPlay = manager.canPlay;

                      bool shouldShowButton = true;
                      if (startTime == null && !isPlaying) {
                        shouldShowButton = false;
                      }
                      if (startTime != null && endTime != null && !canPlay && !isPlaying) {
                        shouldShowButton = false;
                      }

                      if (!isPlaying && !shouldShowButton) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '長按設定播放起點'.i18n,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  SizedBox(
                    height: kMinInteractiveDimension,
                    child: ValueListenableBuilder<String?>(
                      valueListenable: manager.currentRadarTime,
                      builder: (context, currentTime, child) {
                        return ValueListenableBuilder<String?>(
                          valueListenable: manager.playStartTime,
                          builder: (context, startTime, child) {
                            return ValueListenableBuilder<String?>(
                              valueListenable: manager.playEndTime,
                              builder: (context, endTime, child) {
                                return _AutoScrollingTimeList(
                                  grouped: grouped,
                                  currentTime: currentTime,
                                  startTime: startTime,
                                  endTime: endTime,
                                  manager: manager,
                                );
                              },
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

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.onSurface.withValues(alpha: 0.8),
            fontSize: 11,
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
  final String? endTime;
  final RadarMapLayerManager manager;

  const _AutoScrollingTimeList({
    required this.grouped,
    required this.currentTime,
    required this.startTime,
    required this.endTime,
    required this.manager,
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
          final isEndTime = time.value == widget.endTime;
          final isInPlayRange = widget.manager.isFrameAfterPlayback(time.value);

          children.add(
            ValueListenableBuilder<bool>(
              valueListenable: widget.manager.isLoading,
              builder: (context, isLoading, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: widget.manager.isPlaying,
                  builder: (context, isPlaying, child) {
                    Color chipColor;
                    Color borderColor;
                    bool isHighlighted = false;

                    if (isSelected) {
                      chipColor = context.colors.primary;
                      borderColor = context.colors.primary;
                      isHighlighted = true;
                    } else if (isStartTime) {
                      chipColor = Colors.orange;
                      borderColor = Colors.orange;
                      isHighlighted = true;
                    } else if (isEndTime) {
                      chipColor = Colors.red;
                      borderColor = Colors.red;
                      isHighlighted = true;
                    } else if (isInPlayRange) {
                      chipColor = Colors.green;
                      borderColor = Colors.green;
                      isHighlighted = true;
                    } else {
                      chipColor = context.colors.surfaceContainerHighest;
                      borderColor = context.colors.outlineVariant;
                      isHighlighted = false;
                    }

                    return GestureDetector(
                      onLongPress:
                          isLoading || isPlaying
                              ? null
                              : () {
                                widget.manager.setPlayStartTime(time.value);
                              },
                      child: FilterChip(
                        key: _chipKeys[time.value],
                        selected: isHighlighted,
                        showCheckmark: !isLoading,
                        label: Text(time.time, style: TextStyle(color: isHighlighted ? Colors.white : null)),
                        backgroundColor: isHighlighted ? chipColor.withValues(alpha: 0.2) : chipColor,
                        selectedColor: chipColor,
                        side: BorderSide(color: borderColor),
                        avatar: isSelected && isLoading ? const LoadingIcon() : null,
                        onSelected:
                            isLoading || isPlaying
                                ? null
                                : (selected) {
                                  if (!selected) return;
                                  widget.manager.updateRadarTime(time.value);
                                },
                      ),
                    );
                  },
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
