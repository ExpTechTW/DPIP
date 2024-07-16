import 'package:dpip/api/exptech.dart';
import 'package:dpip/model/report/earthquake_report.dart';
import 'package:dpip/model/report/partial_earthquake_report.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/widget/report/intensity_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../model/map_style.dart';

class ReportRoute extends HookConsumerWidget {
  final PartialEarthquakeReport report;

  const ReportRoute({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapStyle = ref.watch(mapStyleProvider);
    final sheetController = useRef(DraggableScrollableController()).value;
    final sheetInitialSize = 0.2;
    final animController = useAnimationController(duration: const Duration(milliseconds: 300));
    final reportState = useState<EarthquakeReport?>(null);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final styleJsonFuture = useMemoized(
      () => mapStyle.getStyle(isDark: isDark, scheme: Theme.of(context).colorScheme),
      [isDark],
    );
    final path = useFuture(styleJsonFuture).data;

    final mapController = useRef<MapLibreMapController?>(null);

    void addTileLayer(MapLibreMapController controller) async {
      try {
        await controller.addSource(
          "tile_source",
          const RasterSourceProperties(
            tiles: ["https://api-1.exptech.dev/api/v1/tiles/radar/{z}/{x}/{y}.png"],
            tileSize: 256,
            minzoom: 0,
            maxzoom: 22,
          ),
        );
        await controller.addLayer(
          "tile_source",
          "tile_layer",
          const RasterLayerProperties(rasterOpacity: 0.7),
        );
        print("Tile layer added successfully");
      } catch (e) {
        print("Error adding tile layer: $e");
      }
    }

    final decorationTween = DecorationTween(
      begin: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: context.colors.surface,
      ),
      end: BoxDecoration(
        borderRadius: BorderRadius.zero,
        color: context.colors.surface,
      ),
    ).chain(CurveTween(curve: Curves.linear));

    useEffect(() {
      ExpTech().getReport(this.report.id).then((data) {
        reportState.value = data;
      });

      sheetController.addListener(() {
        final newSize = sheetController.size;
        final scrollPosition = ((newSize - sheetInitialSize) / (1 - sheetInitialSize)).clamp(0.0, 1.0);
        animController.animateTo(scrollPosition, duration: Duration.zero);
      });

      return () {
        sheetController.dispose();
        animController.dispose();
      };
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(this.report.hasNumber ? "編號 ${this.report.number}" : "小區域有感地震"),
      ),
      body: Stack(children: [
        MapLibreMap(
          minMaxZoomPreference: const MinMaxZoomPreference(0, 10),
          initialCameraPosition: const CameraPosition(target: LatLng(23.8, 120.1), zoom: 6),
          styleString: path ?? "",
          onMapCreated: (controller) {
            mapController.value = controller;
          },
          onStyleLoadedCallback: () {
            addTileLayer(mapController.value!);
          },
        ),
        Positioned.fill(
          child: DraggableScrollableSheet(
            initialChildSize: sheetInitialSize,
            minChildSize: sheetInitialSize,
            controller: sheetController,
            snap: true,
            builder: (context, scrollController) {
              return DecoratedBoxTransition(
                decoration: animController.drive(decorationTween),
                child: Container(
                  child: reportState.value == null
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          controller: scrollController,
                          children: [
                            SizedBox(
                              height: 24,
                              child: Center(
                                child: Container(
                                  width: 32,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: context.colors.onSurfaceVariant.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  IntensityBox(intensity: reportState.value!.getMaxIntensity()),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reportState.value!.getLocation(),
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
