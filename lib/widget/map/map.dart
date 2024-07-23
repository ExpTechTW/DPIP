import 'dart:convert';
import 'dart:math';

import 'package:dpip/global.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:dpip/widget/map/marker/custom_marker.dart';
import 'package:dpip/widget/map/marker/marker.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

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
  final _markers = <Marker>[];
  final _markerStates = <MarkerState>[];
  late MapLibreMapController _mapController;

  late String style = jsonEncode(
    {
      'version': 8,
      'name': 'ExpTech Studio',
      'center': [120.2, 23.6],
      'zoom': 7,
      'sources': {
        'map': {
          'type': 'vector',
          'url': 'https://api-1.exptech.dev/api/v1/map/tiles/tiles.json',
        },
      },
      'sprite': '',
      'glyphs': 'https://orangemug.github.io/font-glyphs/glyphs/{fontstack}/{range}.pbf',
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
            "fill-color": [
              "match",
              [
                "number",
                ["feature-state", "intensity"],
                0
              ],
              9,
              IntensityColor.intensity9.toHexStringRGB(),
              8,
              IntensityColor.intensity8.toHexStringRGB(),
              7,
              IntensityColor.intensity7.toHexStringRGB(),
              6,
              IntensityColor.intensity6.toHexStringRGB(),
              5,
              IntensityColor.intensity5.toHexStringRGB(),
              4,
              IntensityColor.intensity4.toHexStringRGB(),
              3,
              IntensityColor.intensity3.toHexStringRGB(),
              2,
              IntensityColor.intensity2.toHexStringRGB(),
              1,
              IntensityColor.intensity1.toHexStringRGB(),
              context.colors.surfaceContainerHighest.toHexStringRGB(),
            ],
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
          }
        },
        {
          "id": "global",
          "type": "line",
          "source": "map",
          "source-layer": "global",
          "paint": {
            "line-color": context.colors.outline.toHexStringRGB(),
          }
        },
      ],
    },
  );

  void _updateMarkerPosition() {
    final coordinates = <LatLng>[];

    for (final markerState in _markerStates) {
      coordinates.add(markerState.getCoordinate());
    }

    _mapController.toScreenLocationBatch(coordinates).then((points) {
      _markerStates.asMap().forEach((i, state) {
        state.updatePosition(points[i]);
      });
    });
  }

  void addMarker(CustomMarker m) async {
    final point = await _mapController.toScreenLocation(m.coordinate);

    setState(() {
      _markers.add(
        Marker(
          initialPosition: point,
          coordinate: m.coordinate,
          size: m.size,
          zIndex: m.zIndex,
          addMarkerState: (state) {
            _markerStates.add(state);
          },
          child: m.child,
        ),
      );
      _markers.sort((a, b) => a.zIndex - b.zIndex);
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          trackCameraPosition: true,
          initialCameraPosition: widget.initialCameraPosition,
          styleString: style,
          onMapCreated: (controller) {
            setState(() => _mapController = controller);
            controller.addListener(() {
              if (controller.isCameraMoving) {
                _updateMarkerPosition();
              }
            });
            if (widget.onMapCreated != null) {
              widget.onMapCreated!(controller);
            }
          },
          onMapClick: widget.onMapClick,
          onMapIdle: widget.onMapIdle,
          onMapLongClick: widget.onMapLongClick,
          onCameraIdle: () {
            _updateMarkerPosition();
          },
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: false,
          onStyleLoadedCallback: widget.onStyleLoadedCallback,
        ),
        Stack(
          children: _markers,
        )
      ],
    );
  }
}
