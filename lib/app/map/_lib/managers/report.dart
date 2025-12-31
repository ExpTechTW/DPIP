import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/api/model/report/earthquake_report.dart';
import 'package:dpip/api/model/report/partial_earthquake_report.dart';
import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/depth_color.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/extensions/iterable.dart';
import 'package:dpip/utils/extensions/number.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:dpip/utils/intensity_color.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/magnitude_color.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/report/enlargeable_image.dart';
import 'package:dpip/widgets/report/intensity_box.dart';
import 'package:dpip/widgets/responsive/responsive_container.dart';
import 'package:dpip/widgets/sheet/morphing_sheet.dart';
import 'package:dpip/widgets/sheet/morphing_sheet_controller.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportMapLayerManager extends MapLayerManager {
  String? initialReportId;

  ReportMapLayerManager(
    super.context,
    super.controller, {
    this.initialReportId,
  });

  final currentReport = ValueNotifier<PartialEarthquakeReport?>(null);
  final isLoading = ValueNotifier<bool>(false);
  final dataNotifier = ValueNotifier<int>(0);
  final shouldExpandOnReturn = ValueNotifier<bool>(false);
  double savedScrollOffset = 0.0;
  String? _lastPartialContentKey;
  bool _shouldResetScroll = false;

  DateTime? _lastFetchTime;
  int _currentPage = 1;
  final hasMore = ValueNotifier<bool>(true);
  final isLoadingMore = ValueNotifier<bool>(false);
  static const int _pageSize = 50;

  Future<void> setReport(String? reportId, {bool focus = true}) async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      await _removeReport(currentReport.value, focus: focus);

      PartialEarthquakeReport? report;
      if (reportId != null) {
        report = GlobalProviders.data.partialReport.firstWhereOrNull(
          (r) => r.id == reportId,
        );
      }

      currentReport.value = report;

      if (report != null) {
        _shouldResetScroll = true;
        await _addReport(currentReport.value, focus: focus);
      }

      TalkerManager.instance.info('Updated report to "$reportId"');
    } catch (e, s) {
      TalkerManager.instance.error('ReportMapLayerManager.setReport', e, s);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _focus([EarthquakeReport? report]) async {
    if (report != null) {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          report.bounds,
          left: 48,
          right: 48,
          top: 96,
          bottom: 192,
        ),
      );
      return;
    }

    final data = GlobalProviders.data.partialReport;
    var bounds = <double>[];

    for (final report in data) {
      if (bounds.isEmpty) {
        bounds = [
          report.latitude,
          report.longitude,
          report.latitude,
          report.longitude,
        ];
      } else {
        bounds.expandBounds(report.latlng);
      }
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds.asLatLngBounds,
        left: 48,
        right: 48,
        top: 96,
        bottom: 192,
      ),
    );
  }

  Future<void> _fetchData({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      hasMore.value = true;
      isLoadingMore.value = false;
    }

    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;

    try {
      final reportList = await ExpTech().getReportList(
        limit: _pageSize,
        page: _currentPage,
      );
      if (!context.mounted) return;

      if (reportList.isEmpty) {
        hasMore.value = false;
      } else {
        if (reset) {
          GlobalProviders.data.setPartialReport(reportList);
          _lastPartialContentKey = null;
        } else {
          GlobalProviders.data.appendPartialReport(reportList);
        }

        if (reportList.length < _pageSize) {
          hasMore.value = false;
        } else {
          _currentPage++;
        }

        dataNotifier.value++;
      }

      _lastFetchTime = DateTime.now();
    } catch (e, s) {
      TalkerManager.instance.error('ReportMapLayerManager._fetchData', e, s);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!isLoadingMore.value && hasMore.value) {
      await _fetchData();
    }
  }

  String? _getPartialContentKey() {
    final reports = GlobalProviders.data.partialReport;
    if (reports.isEmpty) return null;
    final firstReport = reports.first;
    return '${firstReport.id}-${firstReport.time.millisecondsSinceEpoch}';
  }

  @override
  Future<void> setup() async {
    if (didSetup) return;

    try {
      if (GlobalProviders.data.partialReport.isEmpty) {
        await _fetchData(reset: true);
      }

      final sourceId = MapSourceIds.report();
      final layerId = MapLayerIds.report();

      final isSourceExists = (await controller.getSourceIds()).contains(
        sourceId,
      );
      final isLayerExists = (await controller.getLayerIds()).contains(layerId);

      if (isSourceExists && isLayerExists) return;

      if (!isSourceExists) {
        final data = GeoJsonBuilder()
            .setFeatures(
              GlobalProviders.data.partialReport.reversed.map(
                (report) => report.toGeoJsonFeature(),
              ),
            )
            .build();

        final properties = GeojsonSourceProperties(data: data);

        await controller.addSource(sourceId, properties);

        if (!context.mounted) return;
      }

      if (!isLayerExists) {
        final properties = SymbolLayerProperties(
          iconImage: [Expressions.get, 'icon'],
          iconSize: [
            Expressions.interpolate,
            ['linear'],
            [Expressions.get, 'magnitude'],
            1,
            0.1,
            10,
            0.6,
          ],
          iconOpacity: [
            Expressions.interpolate,
            ['linear'],
            [Expressions.get, 'time'],
            DateTime.now().millisecondsSinceEpoch -
                const Duration(days: 14).inMilliseconds,
            0.2,
            GlobalProviders
                .data
                .partialReport
                .first
                .time
                .millisecondsSinceEpoch,
            1.0,
          ],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          symbolZOrder: 'source',
          visibility: visible && initialReportId == null ? 'visible' : 'none',
        );

        await controller.addLayer(
          sourceId,
          layerId,
          properties,
          belowLayerId: BaseMapLayerIds.userLocation,
        );
      }

      didSetup = true;
    } catch (e, s) {
      TalkerManager.instance.error('ReportMapLayerManager.setup', e, s);
    }
  }

  @override
  Future<void> hide() async {
    if (!visible) return;

    if (currentReport.value != null) {
      await setReport(null, focus: false);
    }

    final layerId = MapLayerIds.report();

    try {
      await controller.setLayerVisibility(layerId, false);

      visible = false;
    } catch (e, s) {
      TalkerManager.instance.error('ReportMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (visible) return;

    final layerId = MapLayerIds.report();

    try {
      if (initialReportId != null) {
        await setReport(initialReportId);
        initialReportId = null;
      } else {
        await controller.setLayerVisibility(layerId, true);

        await _focus();
      }

      visible = true;

      if (_lastFetchTime == null ||
          DateTime.now().difference(_lastFetchTime!).inMinutes > 5) {
        await _fetchData(reset: true);
      }
    } catch (e, s) {
      TalkerManager.instance.error('ReportMapLayerManager.show', e, s);
    }
  }

  @override
  Future<void> remove() async {
    try {
      final layerId = MapLayerIds.report();
      final sourceId = MapSourceIds.report();

      await controller.removeLayer(layerId);
      await controller.removeSource(sourceId);
    } catch (e, s) {
      TalkerManager.instance.error('ReportMapLayerManager.dispose', e, s);
    }

    didSetup = false;
  }

  @override
  bool get shouldPop => currentReport.value == null;

  @override
  void onPopInvoked() {
    if (currentReport.value == null) return;

    shouldExpandOnReturn.value = true;
    setReport(null);
  }

  Future<void> _addReport(
    PartialEarthquakeReport? partial, {
    bool focus = true,
  }) async {
    if (partial == null) return;

    var report = GlobalProviders.data.report[partial.id];

    try {
      if (report == null) {
        report = await ExpTech().getReport(partial.id);
        if (!context.mounted) return;

        GlobalProviders.data.setReport(partial.id, report);
      }

      final layerId = MapLayerIds.report(
        report.time.millisecondsSinceEpoch.toString(),
      );
      final sourceId = MapSourceIds.report(
        report.time.millisecondsSinceEpoch.toString(),
      );

      final isSourceExists = (await controller.getSourceIds()).contains(
        sourceId,
      );
      final isLayerExists = (await controller.getLayerIds()).contains(layerId);

      if (isSourceExists && isLayerExists) return;

      if (!isSourceExists) {
        final data = report.toGeoJson().build();
        final properties = GeojsonSourceProperties(data: data);

        await controller.addSource(sourceId, properties);

        if (!context.mounted) return;
      }

      if (!isLayerExists) {
        const properties = SymbolLayerProperties(
          iconImage: [Expressions.get, 'icon'],
          iconSize: kSymbolIconSize,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          symbolZOrder: 'source',
        );

        await controller.addLayer(
          sourceId,
          layerId,
          properties,
          belowLayerId: BaseMapLayerIds.userLocation,
        );
      }

      if (focus) await _focus(report);

      await controller.setLayerVisibility(MapLayerIds.report(), false);
    } catch (e, s) {
      TalkerManager.instance.error('ReportMapLayerManager._addReport', e, s);
    }
  }

  Future<void> _removeReport(
    PartialEarthquakeReport? report, {
    bool focus = true,
  }) async {
    if (report == null) return;

    try {
      final layerId = MapLayerIds.report(
        report.time.millisecondsSinceEpoch.toString(),
      );
      final sourceId = MapSourceIds.report(
        report.time.millisecondsSinceEpoch.toString(),
      );

      final isLayerExists = (await controller.getLayerIds()).contains(layerId);
      final isSourceExists = (await controller.getSourceIds()).contains(
        sourceId,
      );

      if (isLayerExists) {
        await controller.removeLayer(layerId);
      }

      if (isSourceExists) {
        await controller.removeSource(sourceId);
      }

      if (focus) await _focus();

      await controller.setLayerVisibility(MapLayerIds.report(), true);
    } catch (e, s) {
      TalkerManager.instance.error('ReportMapLayerManager._removeReport', e, s);
    }
  }

  @override
  Widget build(BuildContext context) => ReportMapLayerSheet(manager: this);
}

class ReportMapLayerSheet extends StatefulWidget {
  final ReportMapLayerManager manager;

  const ReportMapLayerSheet({super.key, required this.manager});

  @override
  State<ReportMapLayerSheet> createState() => _ReportMapLayerSheetState();
}

class SafeImageSection extends StatefulWidget {
  final Widget Function(VoidCallback onError) builder;

  const SafeImageSection({
    super.key,
    required this.builder,
  });

  @override
  State<SafeImageSection> createState() => _SafeImageSectionState();
}

class _SafeImageSectionState extends State<SafeImageSection> {
  bool _hasError = false;
  int _retryKey = 0;

  void _onImageError() {
    if (_hasError) return;
    _hasError = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _retryKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _GeneratingView(onRetry: _retry);
    }

    return KeyedSubtree(
      key: ValueKey(_retryKey),
      child: widget.builder(_onImageError),
    );
  }
}

class _GeneratingView extends StatelessWidget {
  final VoidCallback onRetry;

  const _GeneratingView({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2334 / 2977,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('CWA 正在製圖中'.i18n),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text('重新載入'.i18n),
          ),
        ],
      ),
    );
  }
}

class _ReportMapLayerSheetState extends State<ReportMapLayerSheet> {
  final morphingSheetController = MorphingSheetController();
  ScrollController? _listScrollController;

  @override
  void initState() {
    super.initState();
    widget.manager.shouldExpandOnReturn.addListener(_onShouldExpandChanged);
  }

  @override
  void dispose() {
    widget.manager.shouldExpandOnReturn.removeListener(_onShouldExpandChanged);
    _listScrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_listScrollController == null || !_listScrollController!.hasClients) {
      return;
    }

    final maxScroll = _listScrollController!.position.maxScrollExtent;
    final currentScroll = _listScrollController!.offset;
    final delta = 200.0;

    if (maxScroll - currentScroll <= delta) {
      widget.manager.loadMore();
    }
  }

  void _onShouldExpandChanged() {
    if (!widget.manager.shouldExpandOnReturn.value) return;
    widget.manager.shouldExpandOnReturn.value = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      morphingSheetController.expand().then((_) {
        if (!mounted) return;
        final offset = widget.manager.savedScrollOffset;
        if (_listScrollController != null &&
            _listScrollController!.hasClients &&
            offset > 0) {
          _listScrollController!.jumpTo(offset);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.manager.dataNotifier,
      builder: (context, value, child) {
        final partialKey = widget.manager._getPartialContentKey();
        final shouldUpdateKey =
            partialKey != widget.manager._lastPartialContentKey;
        if (shouldUpdateKey) {
          widget.manager._lastPartialContentKey = partialKey;
        }

        return ResponsiveContainer(
          mode: ResponsiveMode.panel,
          child: MorphingSheet(
            key: partialKey != null ? ValueKey(partialKey) : null,
            controller: morphingSheetController,
            title: '地震報告'.i18n,
            borderRadius: .circular(16),
            elevation: 4,
            partialBuilder: (context, controller, sheetController) {
              if (GlobalProviders.data.partialReport.isEmpty) {
                return const SizedBox.shrink();
              }

              return ValueListenableBuilder(
                valueListenable: widget.manager.currentReport,
                builder: (context, currentReport, child) {
                  // Show the first report from partial report list
                  if (currentReport == null) {
                    final report = GlobalProviders.data.partialReport.first;

                    final locationString = report.extractLocation();
                    final location =
                        Location.tryParse(locationString)?.dynamicName ??
                        locationString;

                    return Padding(
                      padding: const .symmetric(vertical: 8),
                      child: Selector<DpipDataModel, List<String>>(
                        selector: (context, model) => model.radar,
                        builder: (context, radar, child) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              Padding(
                                padding: const .symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  spacing: 8,
                                  children: [
                                    Icon(
                                      Symbols.docs_rounded,
                                      size: 24,
                                      color: context.colors.onSurface,
                                    ),
                                    Expanded(
                                      child: Text(
                                        '近期的地震報告'.i18n,
                                        style: context.texts.titleMedium
                                            ?.copyWith(
                                              color: context.colors.onSurface,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      '更多'.i18n,
                                      style: context.texts.labelSmall?.copyWith(
                                        color: context.colors.outline,
                                      ),
                                    ),
                                    Icon(
                                      Symbols.swipe_up_rounded,
                                      size: 16,
                                      color: context.colors.outline,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const .symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  spacing: 8,
                                  children: [
                                    IntensityBox(
                                      intensity: report.intensity,
                                      size: 48,
                                      borderRadius: 12,
                                      border: !report.hasNumber,
                                    ),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            report.hasNumber
                                                ? '編號 {number} 顯著有感地震'.i18n
                                                      .args({
                                                        'number': report.number,
                                                      })
                                                : location,
                                            style: context.texts.titleMedium,
                                          ),
                                          Text(
                                            report.time.toLocaleDateTimeString(
                                              context,
                                            ),
                                            style: context.texts.bodyMedium
                                                ?.copyWith(
                                                  color: context
                                                      .colors
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'M ${report.magnitude.toStringAsFixed(1)}',
                                      style: context.texts.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }

                  // Show the current report with details

                  final locationString = currentReport.extractLocation();
                  final location =
                      Location.tryParse(locationString)?.dynamicName ??
                      locationString;

                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 12,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 2,
                                children: [
                                  Text(
                                    currentReport.hasNumber
                                        ? '編號 {number} 顯著有感地震'.i18n.args({
                                            'number': currentReport.number,
                                          })
                                        : '小區域有感地震'.i18n,
                                    style: context.texts.labelMedium?.copyWith(
                                      color: context.colors.outline,
                                    ),
                                  ),
                                  Text(
                                    location,
                                    style: context.texts.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    currentReport.time.toLocaleDateTimeString(
                                      context,
                                    ),
                                    style: context.texts.bodyMedium?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IntensityBox(
                              intensity: currentReport.intensity,
                              size: 56,
                              borderRadius: 12,
                              border: !currentReport.hasNumber,
                            ),
                          ],
                        ),
                        Row(
                          spacing: 16,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '地震規模'.i18n,
                                    style: context.texts.bodyMedium?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    'M ${currentReport.magnitude.toStringAsFixed(1)}',
                                    style: context.texts.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '震源深度'.i18n,
                                    style: context.texts.bodyMedium?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '${currentReport.depth}km',
                                    style: context.texts.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            fullBuilder: (context, controller, sheetController) {
              return ValueListenableBuilder(
                valueListenable: widget.manager.currentReport,
                builder: (context, currentReport, child) {
                  if (currentReport == null) {
                    if (_listScrollController != controller) {
                      _listScrollController?.removeListener(_onScroll);
                      _listScrollController = controller;
                      controller.addListener(_onScroll);
                    }

                    final grouped = GlobalProviders.data.partialReport
                        .groupListsBy(
                          (report) =>
                              report.time.toLocaleFullDateString(context),
                        )
                        .entries
                        .toList();

                    return CustomScrollView(
                      controller: controller,
                      slivers: [
                        SliverAppBar(
                          title: Text('地震報告'.i18n),
                          leading: BackButton(
                            onPressed: () {
                              sheetController.collapse();
                              controller.animateTo(
                                0,
                                duration: Durations.short4,
                                curve: Easing.emphasizedDecelerate,
                              );
                            },
                          ),
                          floating: true,
                          snap: true,
                          pinned: true,
                        ),
                        SliverPadding(
                          padding: .only(
                            bottom: context.padding.bottom,
                          ),
                          sliver: SliverList.builder(
                            itemCount: grouped.length + 1,
                            itemBuilder: (context, index) {
                              if (index == grouped.length) {
                                return ValueListenableBuilder(
                                  valueListenable: widget.manager.isLoadingMore,
                                  builder: (context, isLoadingMoreValue, child) {
                                    return ValueListenableBuilder(
                                      valueListenable: widget.manager.hasMore,
                                      builder: (context, hasMoreValue, child) {
                                        if (!hasMoreValue &&
                                            GlobalProviders
                                                .data
                                                .partialReport
                                                .isNotEmpty) {
                                          return Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Center(
                                              child: Text(
                                                '沒有更多資料'.i18n,
                                                style: context.texts.bodyMedium
                                                    ?.copyWith(
                                                      color: context
                                                          .colors
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ),
                                          );
                                        }

                                        if (isLoadingMoreValue) {
                                          return const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }

                                        return const SizedBox.shrink();
                                      },
                                    );
                                  },
                                );
                              }

                              final MapEntry(key: date, value: reports) =
                                  grouped[index];

                              final length = reports.length;

                              return SegmentedList(
                                label: Text(date),
                                children: reports.mapIndexed((index, report) {
                                  final locationString = report
                                      .extractLocation();
                                  final location =
                                      Location.tryParse(
                                        locationString,
                                      )?.dynamicName ??
                                      locationString;

                                  return SegmentedListTile(
                                    isFirst: index == 0,
                                    isLast: index == length - 1,
                                    leading: IntensityBox(
                                      intensity: report.intensity,
                                      size: 36,
                                      borderRadius: 8,
                                      border: !report.hasNumber,
                                    ),
                                    title: Text(location),
                                    subtitle: Text(
                                      '${report.hasNumber ? '${'編號 {number} 顯著有感地震'.i18n.args({'number': report.number})}\n' : ''}${report.time.toLocaleTimeString(context)}・${report.depth}km',
                                    ),
                                    trailing: Text(
                                      'M ${report.magnitude.toStringAsFixed(1)}',
                                      style: context.texts.labelLarge,
                                    ),
                                    onTap: () {
                                      if (controller.hasClients) {
                                        widget.manager.savedScrollOffset =
                                            controller.offset;
                                      }
                                      widget.manager.setReport(report.id);
                                      sheetController.collapse();
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  final report = GlobalProviders.data.report[currentReport.id];
                  late List<Widget> content;

                  if (report == null) {
                    content = [
                      const Center(child: CircularProgressIndicator()),
                    ];
                  } else {
                    final locationString = report.getLocation();
                    final location =
                        Location.tryParse(locationString)?.dynamicName ??
                        locationString;

                    content = [
                      Padding(
                        padding: const .symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            IntensityBox(intensity: report.getMaxIntensity()),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    report.hasNumber
                                        ? '編號 {number} 顯著有感地震'.i18n.args({
                                            'number': report.number,
                                          })
                                        : '小區域有感地震'.i18n,
                                    style: TextStyle(
                                      color: context.colors.onSurfaceVariant,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    location,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const .symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            ActionChip(
                              avatar: Icon(
                                Symbols.open_in_new,
                                color: context.colors.onPrimary,
                              ),
                              label: Text('報告頁面'.i18n),
                              backgroundColor: context.colors.primary,
                              labelStyle: TextStyle(
                                color: context.colors.onPrimary,
                              ),
                              side: BorderSide(color: context.colors.primary),
                              onPressed: () {
                                launchUrl(report.reportUrl);
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Symbols.replay),
                              label: Text('重播'.i18n),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapMonitorPage(
                                      replayTimestamp:
                                          report.time.millisecondsSinceEpoch -
                                          2000,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SegmentedList(
                        label: Text('詳細資訊'),
                        children: [
                          SegmentedListTile(
                            isFirst: true,
                            label: Text('發震時間'.i18n),
                            title: Text(
                              DateFormat(
                                'yyyy/MM/dd HH:mm:ss',
                              ).format(report.time),
                            ),
                          ),
                          SegmentedListTile(
                            label: Text('位於'.i18n),
                            title: Text(report.convertLatLon()),
                          ),
                          SegmentedListTile(
                            label: Text('發震時間'.i18n),
                            title: Text(
                              DateFormat(
                                'yyyy/MM/dd HH:mm:ss',
                              ).format(report.time),
                            ),
                          ),
                          Row(
                            spacing: 2,
                            children: [
                              Expanded(
                                child: SegmentedListTile(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: .circular(16),
                                  ),
                                  label: Text('地震規模'.i18n),
                                  title: Row(
                                    children: [
                                      Container(
                                        height: 12,
                                        width: 12,
                                        margin: const .only(right: 6),
                                        decoration: BoxDecoration(
                                          borderRadius: .circular(10),
                                          color: MagnitudeColor.magnitude(
                                            report.magnitude,
                                          ),
                                        ),
                                      ),
                                      BodyText.large(
                                        'M ${report.magnitude}',
                                        weight: .bold,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SegmentedListTile(
                                  borderRadius: BorderRadius.only(
                                    bottomRight: .circular(16),
                                  ),
                                  label: Text('震源深度'.i18n),
                                  title: Row(
                                    children: [
                                      Container(
                                        height: 12,
                                        width: 12,
                                        margin: const .only(right: 6),
                                        decoration: BoxDecoration(
                                          borderRadius: .circular(10),
                                          color: getDepthColor(report.depth),
                                        ),
                                      ),
                                      Text('${report.depth} km'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SegmentedList(
                        label: Text('各地震度'.i18n),
                        children: [
                          for (final (
                                index,
                                MapEntry(key: areaName, value: area),
                              )
                              in report.list.entries.indexed)
                            SegmentedListTile(
                              isFirst: index == 0,
                              isLast: index == report.list.length - 1,
                              title: Text(areaName),
                              content: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final MapEntry(
                                        key: townName,
                                        value: town,
                                      )
                                      in area.town.entries)
                                    ActionChip(
                                      padding: const EdgeInsets.all(
                                        4,
                                      ),
                                      side: BorderSide(
                                        color: IntensityColor.intensity(
                                          town.intensity,
                                        ),
                                      ),
                                      backgroundColor: IntensityColor.intensity(
                                        town.intensity,
                                      ).withValues(alpha: 0.16),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      avatar: AspectRatio(
                                        aspectRatio: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: .circular(6),
                                            color: IntensityColor.intensity(
                                              town.intensity,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              town
                                                  .intensity
                                                  .asIntensityDisplayLabel,
                                              style: TextStyle(
                                                height: 1,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    IntensityColor.onIntensity(
                                                      town.intensity,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      label: Text(townName),
                                      onPressed: () {
                                        sheetController.collapse();
                                        widget.manager.controller.animateCamera(
                                          CameraUpdate.newLatLng(
                                            LatLng(
                                              town.lat,
                                              town.lon,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SegmentedList(
                        label: Text('地震報告圖'.i18n),
                        children: [
                          Padding(
                            padding: const .symmetric(horizontal: 8),
                            child: EnlargeableImage(
                              aspectRatio: 4 / 3,
                              heroTag: 'report-image-${report.id}',
                              imageUrl: report.reportImageUrl,
                              imageName: report.reportImageName,
                            ),
                          ),
                        ],
                      ),
                      if (report.hasNumber &&
                          report.intensityMapImageUrl != null)
                        SegmentedList(
                          label: Text('震度圖'.i18n),
                          children: [
                            Padding(
                              padding: const .symmetric(
                                horizontal: 8,
                              ),
                              child: SafeImageSection(
                                builder: (onError) => EnlargeableImage(
                                  aspectRatio: 2334 / 2977,
                                  heroTag: 'intensity-image-${report.id}',
                                  imageUrl: report.intensityMapImageUrl!,
                                  imageName: report.intensityMapImageName!,
                                  onLoadFailed: onError,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (report.hasNumber && report.pgaMapImageUrl != null)
                        SegmentedList(
                          label: Text('最大地動加速度圖'.i18n),
                          children: [
                            Padding(
                              padding: const .symmetric(
                                horizontal: 8,
                              ),
                              child: SafeImageSection(
                                builder: (onError) => EnlargeableImage(
                                  aspectRatio: 2334 / 2977,
                                  heroTag: 'pga-image-${report.id}',
                                  imageUrl: report.pgaMapImageUrl!,
                                  imageName: report.pgaMapImageName!,
                                  onLoadFailed: onError,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (report.hasNumber && report.pgvMapImageUrl != null)
                        SegmentedList(
                          label: Text('最大地動速度圖'.i18n),
                          children: [
                            Padding(
                              padding: const .symmetric(
                                horizontal: 8,
                              ),
                              child: SafeImageSection(
                                builder: (onError) => EnlargeableImage(
                                  aspectRatio: 2334 / 2977,
                                  heroTag: 'pgv-image-${report.id}',
                                  imageUrl: report.pgvMapImageUrl!,
                                  imageName: report.pgvMapImageName!,
                                  onLoadFailed: onError,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ];
                  }

                  if (widget.manager._shouldResetScroll) {
                    widget.manager._shouldResetScroll = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (controller.hasClients) {
                        controller.jumpTo(0);
                      }
                    });
                  }

                  return CustomScrollView(
                    controller: controller,
                    slivers: [
                      SliverAppBar(
                        title: Text('地震報告'.i18n),
                        leading: BackButton(
                          onPressed: () {
                            widget.manager.shouldExpandOnReturn.value = true;
                            widget.manager.setReport(null);
                          },
                        ),
                        floating: true,
                        snap: true,
                        pinned: true,
                      ),
                      SliverList.list(children: content),
                      SliverPadding(
                        padding: .only(
                          bottom: context.padding.bottom + 16,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
