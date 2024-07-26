import "dart:convert";
import "dart:io";
import "dart:math";

import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";
import "package:maplibre_gl/maplibre_gl.dart";
import "package:path_provider/path_provider.dart";

class DpipMap extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final void Function(MapLibreMapController)? onMapCreated;
  final void Function(Point<double>, LatLng)? onMapClick;
  final void Function()? onMapIdle;
  final void Function(Point<double>, LatLng)? onMapLongClick;
  final void Function()? onStyleLoadedCallback;

  const DpipMap({
    super.key,
    this.initialCameraPosition = const CameraPosition(target: LatLng(23.8, 120.1), zoom: 6),
    this.onMapCreated,
    this.onMapClick,
    this.onMapIdle,
    this.onMapLongClick,
    this.onStyleLoadedCallback,
  });

  @override
  State<DpipMap> createState() => DpipMapState();
}

class DpipMapState extends State<DpipMap> {
  late String style = jsonEncode(
    {
      "version": 8,
      "name": "ExpTech Studio",
      "center": [120.2, 23.6],
      "zoom": 7,
      "sources": {
        "map": {
          "type": "vector",
          "url": "https://api-1.exptech.dev/api/v1/map/tiles/tiles.json",
          "tileSize": 512,
          "buffer": 64
        },
      },
      "sprite": "",
      "glyphs": "https://orangemug.github.io/font-glyphs-v2/glyphs/{fontstack}/{range}.pbf",
      "layers": [
        {
          "id": "background",
          "type": "background",
          "paint": {
            "background-color": context.colors.surface.toHexStringRGB(),
          },
        },
        {
          "id": "county",
          "type": "fill",
          "source": "map",
          "source-layer": "city",
          "paint": {
            // FIXME: workaround waiting for upstream PR to merge
            // https://github.com/material-foundation/flutter-packages/pull/599
            "fill-color": context.colors.surfaceVariant.toHexStringRGB(),
            "fill-opacity": 1,
          },
        },
        {
          "id": "town",
          "type": "fill",
          "source": "map",
          "source-layer": "town",
          "paint": {
            // FIXME: workaround waiting for upstream PR to merge
            // https://github.com/material-foundation/flutter-packages/pull/599
            "fill-color": context.colors.surfaceVariant.toHexStringRGB(),
            "fill-opacity": 1,
          },
        },
        {
          "id": "county-outline",
          "source": "map",
          "source-layer": "city",
          "type": "line",
          "paint": {
            "line-color": context.colors.outline.toHexStringRGB(),
          },
        },
        {
          "id": "global",
          "type": "fill",
          "source": "map",
          "source-layer": "global",
          "paint": {
            // FIXME: workaround waiting for upstream PR to merge
            // https://github.com/material-foundation/flutter-packages/pull/599
            "fill-color": context.colors.surfaceVariant.toHexStringRGB(),
            "fill-opacity": 1,
          },
        },
        {
          "id": "tsunami",
          "type": "line",
          "source": "map",
          "source-layer": "tsunami",
          "paint": {
            // FIXME: workaround waiting for upstream PR to merge
            // https://github.com/material-foundation/flutter-packages/pull/599
            "line-opacity": 0,
            "line-width": 10,
          },
        },
        {
          "id": "box",
          "type": "line",
          "source": "map",
          "source-layer": "box",
          "paint": {
            // FIXME: workaround waiting for upstream PR to merge
            // https://github.com/material-foundation/flutter-packages/pull/599
            "line-color": "#000000",
            "line-opacity": 0,
            "line-width": 2,
          },
        },
      ],
    },
  );

  String? styleAbsoluteFilePath;

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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return MapLibreMap(
      trackCameraPosition: true,
      initialCameraPosition: widget.initialCameraPosition,
      styleString: styleAbsoluteFilePath!,
      onMapCreated: widget.onMapCreated,
      onMapClick: widget.onMapClick,
      onMapIdle: widget.onMapIdle,
      onMapLongClick: widget.onMapLongClick,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: false,
      onStyleLoadedCallback: widget.onStyleLoadedCallback,
    );
  }
}
