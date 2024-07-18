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
      "version": 8,
      "name": "TREM Map",
      "sources": {
        "tw_county": {
          "type": "geojson",
          "data": Global.geojson["tw_county"],
          "tolerance": 1,
        },
        "tw_town": {
          "type": "geojson",
          "data": Global.geojson["tw_town"],
        },
        /*
          "cn": {
            "type": "geojson",
            "data": "./map/cn.json",
            "tolerance": 1,
          },
          "jp": {
            "type": "geojson",
            "data": "./map/jp.json",
            "tolerance": 1,
          },
          "kp": {
            "type": "geojson",
            "data": "./map/kp.json",
            "tolerance": 1,
          },
          "kr": {
            "type": "geojson",
            "data": "./map/kr.json",
            "tolerance": 1,
          },
          "box": {
            "type": "geojson",
            "data": "./map/box.json",
          }, 
          */
      },
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
          "source": "tw_county",
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
          "source": "tw_county",
          "type": "line",
          "paint": {
            "line-color": context.colors.outline.toHexStringRGB(),
          }
        }
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
