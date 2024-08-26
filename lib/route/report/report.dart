import "dart:async";

import "package:dpip/api/exptech.dart";
import "package:dpip/core/eew.dart";
import "package:dpip/model/report/earthquake_report.dart";
import "package:dpip/model/report/partial_earthquake_report.dart";
import "package:dpip/route/report/report_sheet_content.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/util/extension/color_scheme.dart";
import "package:dpip/util/geojson.dart";
import "package:dpip/util/intensity_color.dart";
import "package:dpip/util/map_utils.dart";
import "package:dpip/widget/map/map.dart";
import "package:flutter/material.dart";
import "package:maplibre_gl/maplibre_gl.dart";
import "package:material_symbols_icons/symbols.dart";

class ReportRoute extends StatefulWidget {
  final PartialEarthquakeReport report;

  const ReportRoute({super.key, required this.report});

  @override
  State<ReportRoute> createState() => _ReportRouteState();
}

class _ReportRouteState extends State<ReportRoute> with TickerProviderStateMixin {
  EarthquakeReport? report;
  final mapController = Completer<MapLibreMapController>();

  late final backgroundColor = Color.lerp(context.colors.surface, context.colors.surfaceTint, 0.08);

  late final decorationTween = DecorationTween(
    begin: BoxDecoration(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      boxShadow: kElevationToShadow[4],
      color: backgroundColor,
    ),
    end: BoxDecoration(
      borderRadius: BorderRadius.zero,
      boxShadow: kElevationToShadow[4],
      color: backgroundColor,
    ),
  ).chain(CurveTween(curve: Curves.linear));

  final opacityTween = Tween(
    begin: 0.0,
    end: 1.0,
  ).chain(CurveTween(curve: Curves.linear));

  late final sheetInitialSize = context.padding.bottom / context.dimension.height + 0.2;
  final sheetController = DraggableScrollableController();
  late final animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late ScrollController scrollController;

  bool isAppBarVisible = false;
  bool isLoading = true;
  bool isLoaded = false;

  void refreshReport() async {
    if (isLoaded) {
      return;
    }

    setState(() => isLoading = true);

    try {
      final isDark = context.theme.brightness == Brightness.dark;

      final data = await ExpTech().getReport(widget.report.id);
      final controller = await mapController.future;

      List markers = [];
      List<double> bounds = [];

      Map<String, int> cityMaxIntensity = {};

      for (var MapEntry(key: areaName, value: area) in data.list.entries) {
        for (var MapEntry(key: _, value: town) in area.town.entries) {
          if (cityMaxIntensity[areaName] == null || cityMaxIntensity[areaName]! < town.intensity) {
            cityMaxIntensity[areaName] = town.intensity;
          }

          markers.add({
            "type": "Feature",
            "properties": {
              "intensity": town.intensity,
            },
            "geometry": {
              "coordinates": [town.lon, town.lat],
              "type": "Point"
            }
          });

          if (bounds.isEmpty) {
            bounds.addAll([town.lat, town.lon, town.lat, town.lon]);
          }

          expandBounds(bounds, LatLng(town.lat, town.lon));
        }
      }

      markers.add({
        "type": "Feature",
        "properties": {
          "intensity": 10, // 10 is for classifying epicenter cross
        },
        "geometry": {
          "coordinates": data.latlng.toGeoJsonCoordinates(),
          "type": "Point",
        }
      });

      expandBounds(bounds, data.latlng);

      await controller.moveCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(bounds[0], bounds[1]),
            northeast: LatLng(bounds[2], bounds[3]),
          ),
          left: 32,
          right: 32,
          top: 32,
          bottom: 212,
        ),
      );

      if (controller.cameraPosition!.zoom > 9) {
        await controller.moveCamera(CameraUpdate.zoomTo(9));
      }

      await controller.addGeoJsonSource(
        "markers-geojson",
        {
          "type": "FeatureCollection",
          "features": markers,
        },
      );

      final waves = GeoJsonBuilder();

      for (var i = 0; i < 10; i++) {
        final distance = psWaveDist(
          data.depth,
          data.time.millisecondsSinceEpoch,
          data.time.millisecondsSinceEpoch + i * 5000,
        );

        if (distance["s_dist"] == null || distance["s_dist"]! < 0) continue;

        waves.addFeature(
          circleFeature(
            center: LatLng(data.latitude, data.longitude),
            radius: distance["s_dist"]!,
          ),
        );
      }

      await controller.addGeoJsonSource(
        "waves-geojson",
        waves.build(),
      );

      if (!mounted) return;

      // await controller.addLayer(
      //   "waves-geojson",
      //   "waves",
      //   LineLayerProperties(
      //     lineColor: context.colors.outline.toHexStringRGB(),
      //   ),
      // );

      await loadIntensityImage(controller, isDark);
      await loadCrossImage(controller);

      await controller.addLayer(
        "markers-geojson",
        "markers",
        const SymbolLayerProperties(
          symbolSortKey: [Expressions.get, "intensity"],
          symbolZOrder: "source",
          iconSize: [
            Expressions.interpolate,
            ["linear"],
            [Expressions.zoom],
            5,
            0.5,
            10,
            1.5,
          ],
          iconImage: [
            Expressions.match,
            [Expressions.get, "intensity"],
            1,
            "intensity-1",
            2,
            "intensity-2",
            3,
            "intensity-3",
            4,
            "intensity-4",
            5,
            "intensity-5",
            6,
            "intensity-6",
            7,
            "intensity-7",
            8,
            "intensity-8",
            9,
            "intensity-9",
            "cross",
          ],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
      );

      if (!mounted) return;

      await controller.setLayerProperties(
        "county",
        FillLayerProperties(
          fillColor: [
            "match",
            ["get", "NAME"],
            ...cityMaxIntensity.entries.expand((entry) => [
                  entry.key,
                  IntensityColor.intensity(entry.value).toHexStringRGB(),
                ]),
            context.colors.surfaceContainerHighest.toHexStringRGB(),
          ],
          fillOpacity: 1,
        ),
      );

      await controller.setLayerProperties(
        "town",
        const FillLayerProperties(fillOpacity: 0),
      );

      setState(() {
        report = data;
        isLoading = false;
        isLoaded = true;
      });
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  void focus(LatLng target) async {
    final controller = await mapController.future;
    sheetController.animateTo(sheetInitialSize, duration: Durations.short4, curve: Easing.standard);
    scrollController.jumpTo(0);
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(target.latitude - 0.03, target.longitude), 10),
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void initState() {
    super.initState();

    sheetController.addListener(() {
      final newSize = sheetController.size;
      double scrollPosition = ((newSize - sheetInitialSize) / (1 - sheetInitialSize)).clamp(0.0, 1.0);

      if (scrollPosition > 1e-5) {
        if (!isAppBarVisible) {
          setState(() => isAppBarVisible = true);
        }
      } else {
        if (isAppBarVisible) {
          setState(() => isAppBarVisible = false);
        }
      }
      animController.animateTo(scrollPosition, duration: Duration.zero);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      elevation: 4,
      title: Text(context.i18n.report),
    );

    return Scaffold(
      body: Stack(
        children: [
          DpipMap(
            onMapCreated: (controller) async {
              mapController.complete(controller);
              await controller.setSymbolIconAllowOverlap(true);
              await controller.setSymbolIconIgnorePlacement(true);
              refreshReport();
            },
          ),
          if (report != null)
            Positioned(
              top: context.padding.top + 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  if (report!.magnitude >= 6 && report!.magnitude < 7 && report!.getLocation().contains("海"))
                    Chip(
                      avatar: Icon(
                        Symbols.tsunami_rounded,
                        color: context.theme.extendedColors.blue,
                      ),
                      label: Text(
                        context.i18n.report_offing,
                        style: TextStyle(
                          color: context.theme.extendedColors.blue,
                        ),
                      ),
                      backgroundColor: Colors.blue.withOpacity(0.16),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                      side: BorderSide(color: context.theme.extendedColors.blue),
                    ),
                  if (report!.magnitude >= 7 && report!.getLocation().contains("海"))
                    Chip(
                      avatar: Icon(Symbols.tsunami_rounded, color: context.colors.error),
                      label: Text(context.i18n.report_tsunami_attention, style: TextStyle(color: context.colors.error)),
                      backgroundColor: Colors.red.withOpacity(0.16),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                      side: BorderSide(color: context.colors.error),
                    ),
                ],
              ),
            ),
          Positioned(
            top: context.padding.top + 4,
            left: 4,
            child: BackButton(
              style: ButtonStyle(
                elevation: const WidgetStatePropertyAll(4),
                shadowColor: WidgetStatePropertyAll(context.colors.shadow),
                surfaceTintColor: WidgetStatePropertyAll(context.colors.surfaceTint),
                backgroundColor: WidgetStatePropertyAll(context.colors.surface),
              ),
            ),
          ),
          Positioned.fill(
            top: context.padding.top + appBar.preferredSize.height - 24,
            child: DraggableScrollableSheet(
              key: const GlobalObjectKey("DraggableScrollableSheet"),
              initialChildSize: sheetInitialSize,
              minChildSize: sheetInitialSize,
              controller: sheetController,
              snap: true,
              builder: (context, controller) {
                scrollController = controller;

                return DecoratedBoxTransition(
                  decoration: animController.drive(decorationTween),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : report == null
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: 8,
                                    child: Text(
                                      context.i18n.report_error,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    flex: 2,
                                    child: IconButton(
                                      icon: const Icon(Symbols.refresh),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: context.colors.onSurface,
                                      ),
                                      onPressed: () {
                                        refreshReport();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ReportSheetContent(report: report!, controller: controller, focus: focus),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Visibility(
              visible: isAppBarVisible,
              child: FadeTransition(
                opacity: animController.drive(opacityTween),
                child: appBar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
