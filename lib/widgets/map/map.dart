import "dart:convert";
import "dart:io";
import "dart:math";

import "package:dpip/utils/extensions/build_context.dart";
import "package:flutter/material.dart";
import "package:maplibre_gl/maplibre_gl.dart";
import "package:path_provider/path_provider.dart";

class DpipMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final void Function(MapLibreMapController controller)? onMapCreated;
  final void Function(Point<double>, LatLng)? onMapClick;
  final void Function()? onMapIdle;
  final void Function(Point<double>, LatLng)? onMapLongClick;
  final void Function()? onStyleLoadedCallback;
  final MinMaxZoomPreference? minMaxZoomPreference;
  final bool? rotateGesturesEnabled;
  final bool? zoomGesturesEnabled;
  final bool? doubleClickZoomEnabled;
  final bool? dragEnabled;
  final bool? scrollGesturesEnabled;
  final bool? tiltGesturesEnabled;

  const DpipMap({
    super.key,
    this.initialCameraPosition = const CameraPosition(target: LatLng(23.10, 120.85), zoom: 6.2),
    this.onMapCreated,
    this.onMapClick,
    this.onMapIdle,
    this.onMapLongClick,
    this.onStyleLoadedCallback,
    this.minMaxZoomPreference,
    this.rotateGesturesEnabled,
    this.zoomGesturesEnabled,
    this.doubleClickZoomEnabled,
    this.dragEnabled,
    this.scrollGesturesEnabled,
    this.tiltGesturesEnabled,
  });

  @override
  State<DpipMap> createState() => DpipMapState();
}

class DpipMapState extends State<DpipMap> {
  late String style = jsonEncode({
    "version": 8,
    "name": "ExpTech Studio",
    "center": [120.85, 23.10],
    "zoom": 6.2,
    "sources": {
      "map": {
        "type": "vector",
        "url": "https://lb.exptech.dev/api/v1/map/tiles/tiles.json",
        "tileSize": 512,
        "buffer": 64,
      },
    },
    "sprite": "",
    "glyphs": "https://glyphs.geolonia.com/{fontstack}/{range}.pbf",
    "layers": [
      {
        "id": "background",
        "type": "background",
        "paint": {"background-color": context.colors.surface.toHexStringRGB()},
      },
      {
        "id": "county",
        "type": "fill",
        "source": "map",
        "source-layer": "city",
        "paint": {"fill-color": context.colors.surfaceContainerHigh.toHexStringRGB(), "fill-opacity": 1},
      },
      {
        "id": "town",
        "type": "fill",
        "source": "map",
        "source-layer": "town",
        "paint": {"fill-color": context.colors.surfaceContainerHigh.toHexStringRGB(), "fill-opacity": 1},
      },
      {
        "id": "county-outline",
        "source": "map",
        "source-layer": "city",
        "type": "line",
        "paint": {"line-color": context.colors.outline.toHexStringRGB()},
      },
      {
        "id": "global",
        "type": "fill",
        "source": "map",
        "source-layer": "global",
        "paint": {"fill-color": context.colors.surfaceContainer.toHexStringRGB(), "fill-opacity": 1},
      },
      {
        "id": "tsunami",
        "type": "line",
        "source": "map",
        "source-layer": "tsunami",
        "paint": {"line-opacity": 0, "line-width": 3, "line-join": "round"},
      },
    ],
  });

  String? styleAbsoluteFilePath;

  double adjustedZoom(double zoom) {
    double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    double baseZoomAdjustment = 1.0;
    double mediumZoomAdjustment = 0.3;

    if (devicePixelRatio >= 4.0) {
      return zoom - baseZoomAdjustment;
    } else if (devicePixelRatio >= 3.0) {
      return zoom;
    } else if (devicePixelRatio >= 2.0 && devicePixelRatio < 3.0) {
      return zoom - mediumZoomAdjustment;
    } else {
      return zoom + baseZoomAdjustment;
    }
  }

  @override
  void initState() {
    super.initState();

    getApplicationDocumentsDirectory().then((dir) async {
      final documentDir = dir.path;
      final stylesDir = "$documentDir/styles";

      await Directory(stylesDir).create(recursive: true);

      final styleFile = File("$stylesDir/style.json");

      await styleFile.writeAsString(style);

      setState(() {
        styleAbsoluteFilePath = styleFile.path;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (styleAbsoluteFilePath == null) {
      return const Center(child: CircularProgressIndicator());
    }

    double adjustedZoomValue = adjustedZoom(widget.initialCameraPosition.zoom);

    return MapLibreMap(
      minMaxZoomPreference: widget.minMaxZoomPreference ?? const MinMaxZoomPreference(3, 9),
      trackCameraPosition: true,
      initialCameraPosition: CameraPosition(target: widget.initialCameraPosition.target, zoom: adjustedZoomValue),
      styleString: styleAbsoluteFilePath!,
      onMapCreated: widget.onMapCreated,
      onMapClick: widget.onMapClick,
      onMapIdle: widget.onMapIdle,
      onMapLongClick: widget.onMapLongClick,
      tiltGesturesEnabled: widget.tiltGesturesEnabled ?? false,
      scrollGesturesEnabled: widget.scrollGesturesEnabled ?? true,
      rotateGesturesEnabled: widget.rotateGesturesEnabled ?? false,
      zoomGesturesEnabled: widget.zoomGesturesEnabled ?? true,
      doubleClickZoomEnabled: widget.doubleClickZoomEnabled ?? true,
      dragEnabled: widget.dragEnabled ?? true,
      onStyleLoadedCallback: widget.onStyleLoadedCallback,
      attributionButtonMargins: const Point<double>(-100, -100),
    );
  }
}
