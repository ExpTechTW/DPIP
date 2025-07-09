import 'package:collection/collection.dart';
import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/report/earthquake_report.dart';
import 'package:dpip/api/model/report/partial_earthquake_report.dart';
import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/depth_color.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/extensions/int.dart';
import 'package:dpip/utils/extensions/list.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:dpip/utils/intensity_color.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/magnitude_color.dart';
import 'package:dpip/utils/map_utils.dart';
import 'package:dpip/widgets/list/detail_field_tile.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/report/enlargeable_image.dart';
import 'package:dpip/widgets/report/intensity_box.dart';
import 'package:dpip/widgets/sheet/morphing_sheet.dart';
import 'package:dpip/widgets/sheet/morphing_sheet_controller.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportMapLayerManager extends MapLayerManager {
  ReportMapLayerManager(super.context, super.controller);

  final currentReport = ValueNotifier<PartialEarthquakeReport?>(null);
  final isLoading = ValueNotifier<bool>(false);

  Future<void> _setReport(PartialEarthquakeReport? report, {bool focus = true}) async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      await _removeReport(currentReport.value, focus: focus);

      currentReport.value = report;

      if (report != null) {
        await _addReport(currentReport.value, focus: focus);
      }

      TalkerManager.instance.info('Updated report to "${report?.id}"');
    } catch (e, s) {
      TalkerManager.instance.error('Failed to update report', e, s);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _focus([EarthquakeReport? report]) async {
    if (report != null) {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(report.bounds, left: 48, right: 48, top: 96, bottom: 192),
      );
      return;
    }

    final data = GlobalProviders.data.partialReport;
    var bounds = <double>[];

    for (final report in data) {
      if (bounds.isEmpty) {
        bounds = [report.latitude, report.longitude, report.latitude, report.longitude];
      } else {
        bounds = expandBounds(bounds, report.latlng);
      }
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds.asLatLngBounds, left: 48, right: 48, top: 96, bottom: 192),
    );
  }

  @override
  Future<void> setup() async {
    if (didSetup) return;

    try {
      if (GlobalProviders.data.partialReport.isEmpty) {
        final reportList = await ExpTech().getReportList();
        if (!context.mounted) return;

        GlobalProviders.data.setPartialReport(reportList);
      }

      final sourceId = MapSourceIds.report();
      final layerId = MapLayerIds.report();

      final isSourceExists = (await controller.getSourceIds()).contains(sourceId);
      final isLayerExists = (await controller.getLayerIds()).contains(layerId);

      if (isSourceExists && isLayerExists) return;

      if (!isSourceExists) {
        final data =
            GeoJsonBuilder()
                .setFeatures(GlobalProviders.data.partialReport.reversed.map((report) => report.toGeoJsonFeature()))
                .build();

        final properties = GeojsonSourceProperties(data: data);

        await controller.addSource(sourceId, properties);
        TalkerManager.instance.info('Added Source "$sourceId"');

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
            DateTime.now().millisecondsSinceEpoch - const Duration(days: 14).inMilliseconds,
            0.2,
            GlobalProviders.data.partialReport.first.time.millisecondsSinceEpoch,
            1.0,
          ],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          symbolZOrder: 'source',
          visibility: visible ? 'visible' : 'none',
        );

        await controller.addLayer(sourceId, layerId, properties, belowLayerId: BaseMapLayerIds.userLocation);

        TalkerManager.instance.info('Added Layer "$layerId"');
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
      await _setReport(null, focus: false);
    }

    final layerId = MapLayerIds.report();

    try {
      await controller.setLayerVisibility(layerId, false);
      TalkerManager.instance.info('Hiding Layer "$layerId"');

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
      await controller.setLayerVisibility(layerId, true);
      TalkerManager.instance.info('Showing Layer "$layerId"');

      await _focus();

      visible = true;
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
      TalkerManager.instance.info('Removed Layer "$layerId"');

      await controller.removeSource(sourceId);
      TalkerManager.instance.info('Removed Source "$sourceId"');
    } catch (e, s) {
      TalkerManager.instance.error('ReportMapLayerManager.dispose', e, s);
    }

    didSetup = false;
  }

  @override
  void onPopInvoked() {
    if (currentReport.value == null) return;

    _setReport(null);
  }

  Future<void> _addReport(PartialEarthquakeReport? partial, {bool focus = true}) async {
    if (partial == null) return;

    var report = GlobalProviders.data.report[partial.id];

    try {
      if (report == null) {
        report = await ExpTech().getReport(partial.id);
        if (!context.mounted) return;

        GlobalProviders.data.setReport(partial.id, report);
      }

      final layerId = MapLayerIds.report(report.time.millisecondsSinceEpoch.toString());
      final sourceId = MapSourceIds.report(report.time.millisecondsSinceEpoch.toString());

      final isSourceExists = (await controller.getSourceIds()).contains(sourceId);
      final isLayerExists = (await controller.getLayerIds()).contains(layerId);

      if (isSourceExists && isLayerExists) return;

      if (!isSourceExists) {
        final data = report.toGeoJson().build();
        final properties = GeojsonSourceProperties(data: data);

        await controller.addSource(sourceId, properties);
        TalkerManager.instance.info('Added Source "$sourceId"');

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

        await controller.addLayer(sourceId, layerId, properties);
        TalkerManager.instance.info('Added Layer "$layerId"');
      }

      if (focus) await _focus(report);

      await controller.setLayerVisibility(MapLayerIds.report(), false);
      TalkerManager.instance.info('Hiding Layer "$layerId"');
    } catch (e, s) {
      TalkerManager.instance.error('ReportMapLayerManager._addReport', e, s);
    }
  }

  Future<void> _removeReport(PartialEarthquakeReport? report, {bool focus = true}) async {
    if (report == null) return;

    try {
      final layerId = MapLayerIds.report(report.time.millisecondsSinceEpoch.toString());
      final sourceId = MapSourceIds.report(report.time.millisecondsSinceEpoch.toString());

      final isLayerExists = (await controller.getLayerIds()).contains(layerId);
      final isSourceExists = (await controller.getSourceIds()).contains(sourceId);

      if (isLayerExists) {
        await controller.removeLayer(layerId);
        TalkerManager.instance.info('Removed Layer "$layerId"');
      }

      if (isSourceExists) {
        await controller.removeSource(sourceId);
        TalkerManager.instance.info('Removed Source "$sourceId"');
      }

      if (focus) await _focus();

      await controller.setLayerVisibility(MapLayerIds.report(), true);
      TalkerManager.instance.info('Showing Layer "$layerId"');
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

class _ReportMapLayerSheetState extends State<ReportMapLayerSheet> {
  final morphingSheetController = MorphingSheetController();

  @override
  Widget build(BuildContext context) {
    return MorphingSheet(
      controller: morphingSheetController,
      title: '地震報告'.i18n,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      partialBuilder: (context, controller, sheetController) {
        if (GlobalProviders.data.partialReport.isEmpty) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder(
          valueListenable: widget.manager.currentReport,
          builder: (context, currentReport, child) {
            if (currentReport == null) {
              final report = GlobalProviders.data.partialReport.first;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Selector<DpipDataModel, List<String>>(
                  selector: (context, model) => model.radar,
                  builder: (context, radar, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            spacing: 8,
                            children: [
                              Icon(Symbols.docs_rounded, size: 24, color: context.colors.onSurface),
                              Expanded(
                                child: Text(
                                  '近期的地震報告'.i18n,
                                  style: context.textTheme.titleMedium?.copyWith(color: context.colors.onSurface),
                                ),
                              ),
                              Text(
                                '更多'.i18n,
                                style: context.textTheme.labelSmall?.copyWith(color: context.colors.outline),
                              ),
                              Icon(Symbols.swipe_up_rounded, size: 16, color: context.colors.outline),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report.hasNumber
                                          ? '編號 {number} 顯著有感地震'.i18n.args({'number': report.number})
                                          : report.extractLocation(),
                                      style: context.textTheme.titleMedium,
                                    ),
                                    Text(
                                      report.time.toLocaleDateTimeString(context),
                                      style: context.textTheme.bodyMedium?.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text('M ${report.magnitude.toStringAsFixed(1)}', style: context.textTheme.titleMedium),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            }

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
                                  ? '編號 {number} 顯著有感地震'.i18n.args({'number': currentReport.number})
                                  : '小區域有感地震'.i18n,
                              style: context.textTheme.labelMedium?.copyWith(color: context.colors.outline),
                            ),
                            Text(
                              currentReport.extractLocation(),
                              style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              currentReport.time.toLocaleDateTimeString(context),
                              style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '地震規模'.i18n,
                              style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                            Text(
                              'M ${currentReport.magnitude.toStringAsFixed(1)}',
                              style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '震源深度'.i18n,
                              style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                            Text(
                              '${currentReport.depth}km',
                              style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
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
              final grouped =
                  GlobalProviders.data.partialReport
                      .groupListsBy((report) => report.time.toLocaleFullDateString(context))
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
                        controller.animateTo(0, duration: Durations.short4, curve: Easing.emphasizedDecelerate);
                      },
                    ),
                    floating: true,
                    snap: true,
                    pinned: true,
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: context.padding.bottom),
                    sliver: SliverList.builder(
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final MapEntry(key: date, value: reports) = grouped[index];
                        return ListSection(
                          title: date,
                          children: [
                            for (final report in reports)
                              ListSectionTile(
                                leading: IntensityBox(
                                  intensity: report.intensity,
                                  size: 36,
                                  borderRadius: 8,
                                  border: !report.hasNumber,
                                ),
                                title: report.extractLocation(),
                                subtitle: Text(
                                  '${report.hasNumber ? '${'編號 {number} 顯著有感地震'.i18n.args({'number': report.number})}\n' : ''}${report.time.toLocaleTimeString(context)}・${report.depth}km',
                                ),
                                trailing: Text(
                                  'M ${report.magnitude.toStringAsFixed(1)}',
                                  style: context.textTheme.labelLarge,
                                ),
                                onTap: () {
                                  widget.manager._setReport(report);
                                  sheetController.collapse();
                                },
                              ),
                          ],
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
              content = [const Center(child: CircularProgressIndicator())];
            } else {
              content = [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                                  ? '編號 {number} 顯著有感地震'.i18n.args({'number': report.number})
                                  : '小區域有感地震'.i18n,
                              style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 14),
                            ),
                            Text(
                              report.getLocation(),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      avatar: Icon(Symbols.open_in_new, color: context.colors.onPrimary),
                      label: Text('報告頁面'.i18n),
                      backgroundColor: context.colors.primary,
                      labelStyle: TextStyle(color: context.colors.onPrimary),
                      side: BorderSide(color: context.colors.primary),
                      onPressed: () {
                        launchUrl(report.reportUrl);
                      },
                    ),
                    /* ActionChip(
                        avatar: const Icon(Symbols.replay),
                        label: const Text('重播'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapMonitorPage(data: report.time.millisecondsSinceEpoch - 5000),
                            ),
                          );
                        },
                      ), */
                  ],
                ),
                const Divider(),
                DetailFieldTile(
                  label: '發震時間'.i18n,
                  child: Text(
                    DateFormat('yyyy/MM/dd HH:mm:ss').format(report.time),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                DetailFieldTile(
                  label: '位於'.i18n,
                  child: Text(
                    report.convertLatLon(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DetailFieldTile(
                        label: '地震規模'.i18n,
                        child: Row(
                          children: [
                            Container(
                              height: 12,
                              width: 12,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: MagnitudeColor.magnitude(report.magnitude),
                              ),
                            ),
                            Text(
                              'M ${report.magnitude}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: DetailFieldTile(
                        label: '震源深度'.i18n,
                        child: Row(
                          children: [
                            Container(
                              height: 12,
                              width: 12,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: DepthColor.depth(report.depth),
                              ),
                            ),
                            Text(
                              '${report.depth} km',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                DetailFieldTile(
                  label: '各地震度'.i18n,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final MapEntry(key: areaName, value: area) in report.list.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(areaName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final MapEntry(key: townName, value: town) in area.town.entries)
                                          ActionChip(
                                            padding: const EdgeInsets.all(4),
                                            side: BorderSide(color: IntensityColor.intensity(town.intensity)),
                                            backgroundColor: IntensityColor.intensity(
                                              town.intensity,
                                            ).withValues(alpha: 0.16),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            avatar: AspectRatio(
                                              aspectRatio: 1,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(6),
                                                  color: IntensityColor.intensity(town.intensity),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    town.intensity.asIntensityDisplayLabel,
                                                    style: TextStyle(
                                                      height: 1,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: IntensityColor.onIntensity(town.intensity),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            label: Text(townName),
                                            onPressed: () {
                                              sheetController.collapse();
                                              widget.manager.controller.animateCamera(
                                                CameraUpdate.newLatLng(LatLng(town.lat, town.lon)),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                DetailFieldTile(
                  label: '地震報告圖'.i18n,
                  child: EnlargeableImage(
                    aspectRatio: 4 / 3,
                    heroTag: 'report-image-${report.id}',
                    imageUrl: report.reportImageUrl,
                    imageName: report.reportImageName,
                  ),
                ),
                if (report.hasNumber)
                  DetailFieldTile(
                    label: '震度圖'.i18n,
                    child: EnlargeableImage(
                      aspectRatio: 2334 / 2977,
                      heroTag: 'intensity-image-${report.id}',
                      imageUrl: report.intensityMapImageUrl!,
                      imageName: report.intensityMapImageName!,
                    ),
                  ),
                if (report.hasNumber)
                  DetailFieldTile(
                    label: '最大地動加速度圖'.i18n,
                    child: EnlargeableImage(
                      aspectRatio: 2334 / 2977,
                      heroTag: 'pga-image-${report.id}',
                      imageUrl: report.pgaMapImageUrl!,
                      imageName: report.pgaMapImageName!,
                    ),
                  ),
                if (report.hasNumber)
                  DetailFieldTile(
                    label: '最大地動速度圖'.i18n,
                    child: EnlargeableImage(
                      aspectRatio: 2334 / 2977,
                      heroTag: 'pgv-image-${report.id}',
                      imageUrl: report.pgvMapImageUrl!,
                      imageName: report.pgvMapImageName!,
                    ),
                  ),
              ];
            }

            return CustomScrollView(
              controller: controller,
              slivers: [
                SliverAppBar(
                  title: Text('地震報告'.i18n),
                  leading: BackButton(
                    onPressed: () {
                      widget.manager._setReport(null);
                      controller.animateTo(0, duration: Durations.short4, curve: Easing.emphasizedDecelerate);
                    },
                  ),
                  floating: true,
                  snap: true,
                  pinned: true,
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, context.padding.bottom),
                  sliver: SliverList.list(children: content),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
