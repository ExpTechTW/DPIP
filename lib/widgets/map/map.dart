import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:dpip/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path_provider/path_provider.dart';

enum BaseMapType { exptech, osm, google }

class BaseMapSourceIds {
  const BaseMapSourceIds._();

  static const map = 'map';
  static const userLocation = 'user-location';

  static Iterable<String> values() sync* {
    yield map;
    yield userLocation;
  }
}

class BaseMapLayerIds {
  const BaseMapLayerIds._();

  static const exptechGlobalFill = 'exptech-global';
  static const exptechTownFill = 'exptech-town';
  static const exptechCountyFill = 'exptech-county';
  static const exptechCountyOutline = 'exptech-county-outline';

  static const osmGlobalRaster = 'osm-global';
  static const googleGlobalRaster = 'google-global';

  static const userLocation = 'user-location';

  static Iterable<String> values() sync* {
    yield exptechGlobalFill;
    yield exptechTownFill;
    yield exptechCountyFill;
    yield exptechCountyOutline;
    yield userLocation;
  }
}

class DpipMap extends StatefulWidget {
  final BaseMapType baseMapType;
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

  /// Whether to set camera focus to user location when the user longitude or latitude is updated.
  ///
  /// Default is `false`.
  final bool focusUserLocationOnValueUpdate;

  static const kTaiwanCenter = LatLng(23.60, 120.85);

  const DpipMap({
    super.key,
    this.baseMapType = BaseMapType.exptech,
    this.initialCameraPosition = const CameraPosition(target: kTaiwanCenter, zoom: 6.4),
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
    this.focusUserLocationOnValueUpdate = false,
  });

  @override
  State<DpipMap> createState() => DpipMapState();
}

class DpipMapState extends State<DpipMap> {
  String _getStyleJson(String spritePath) {
    final colors = context.colors;

    return jsonEncode({
      'version': 8,
      'name': 'ExpTech Studio',
      'center': [120.85, 23.10],
      'zoom': 6.2,
      'sources': {
        'map': {
          'type': 'vector',
          'url': 'https://lb.exptech.dev/api/v1/map/tiles/tiles.json',
          'tileSize': 512,
          'buffer': 64,
        },
        'osm': {
          'type': 'raster',
          'tiles': ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
          'tileSize': 256,
          'attribution': '&copy; OpenStreetMap Contributors',
          'maxzoom': 19,
        },
        'google': {
          'type': 'raster',
          'tiles': ['https://mts1.google.com/vt/lyrs=p&hl=zh-TW&x={x}&y={y}&z={z}'],
          'tileSize': 256,
          'attribution': '&copy; Google Maps',
          'maxzoom': 19,
        },
      },
      'sprite': spritePath,
      'glyphs': 'https://glyphs.geolonia.com/{fontstack}/{range}.pbf',
      'layers': [
        {
          'id': 'background',
          'type': 'background',
          'paint': {'background-color': colors.surface.toHexStringRGB()},
        },
        {
          'id': BaseMapLayerIds.osmGlobalRaster,
          'type': 'raster',
          'source': 'osm',
          'layout': {'visibility': widget.baseMapType == BaseMapType.osm ? 'visible' : 'none'},
        },
        {
          'id': BaseMapLayerIds.googleGlobalRaster,
          'type': 'raster',
          'source': 'google',
          'layout': {'visibility': widget.baseMapType == BaseMapType.google ? 'visible' : 'none'},
        },
        {
          'id': BaseMapLayerIds.exptechCountyFill,
          'type': 'fill',
          'source': 'map',
          'source-layer': 'city',
          'paint': {'fill-color': colors.surfaceContainerHigh.toHexStringRGB(), 'fill-opacity': 1},
          'layout': {'visibility': widget.baseMapType == BaseMapType.exptech ? 'visible' : 'none'},
        },
        {
          'id': BaseMapLayerIds.exptechTownFill,
          'type': 'fill',
          'source': 'map',
          'source-layer': 'town',
          'paint': {'fill-color': colors.surfaceContainerHigh.toHexStringRGB(), 'fill-opacity': 1},
          'layout': {'visibility': widget.baseMapType == BaseMapType.exptech ? 'visible' : 'none'},
        },
        {
          'id': BaseMapLayerIds.exptechCountyOutline,
          'source': 'map',
          'source-layer': 'city',
          'type': 'line',
          'paint': {'line-color': colors.outline.toHexStringRGB()},
          'layout': {'visibility': 'visible'},
        },
        {
          'id': BaseMapLayerIds.exptechGlobalFill,
          'type': 'fill',
          'source': 'map',
          'source-layer': 'global',
          'paint': {'fill-color': colors.surfaceContainer.toHexStringRGB(), 'fill-opacity': 1},
          'layout': {'visibility': widget.baseMapType == BaseMapType.exptech ? 'visible' : 'none'},
        },
        {
          'id': 'tsunami',
          'type': 'line',
          'source': 'map',
          'source-layer': 'tsunami',
          'paint': {'line-opacity': 0, 'line-width': 3, 'line-join': 'round'},
        },
      ],
    });
  }

  MapLibreMapController? _controller;
  String? styleAbsoluteFilePath;

  double adjustedZoom(double zoom) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    const double baseZoomAdjustment = 1.0;
    const double mediumZoomAdjustment = 0.3;

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

  Future<void> _updateUserLocation() async {
    if (!mounted) return;

    try {
      final controller = _controller;
      if (controller == null) return;

      if (Platform.isIOS && GlobalProviders.location.auto) {
        await getSavedLocation();
      }

      final location = GlobalProviders.location.coordinateNotifier.value;

      const sourceId = BaseMapSourceIds.userLocation;
      const layerId = BaseMapLayerIds.userLocation;

      final isSourceExists = (await controller.getSourceIds()).contains(sourceId);
      final isLayerExists = (await controller.getLayerIds()).contains(layerId);

      if (!location.isValid) {
        if (isLayerExists) {
          await controller.removeLayer(layerId);
          TalkerManager.instance.info('Removed Layer "$layerId"');
        }

        if (isSourceExists) {
          await controller.removeSource(sourceId);
          TalkerManager.instance.info('Removed Source "$sourceId"');
        }

        await controller.moveCamera(CameraUpdate.newLatLngZoom(DpipMap.kTaiwanCenter, 6.2));
        TalkerManager.instance.info('Moved Camera to ${DpipMap.kTaiwanCenter}');
        return;
      }

      if (!isSourceExists) {
        await controller.addSource(
          sourceId,
          GeojsonSourceProperties(data: GeoJsonBuilder().addFeature(location.toFeatureBuilder()).build()),
        );
        TalkerManager.instance.info('Added Source "$sourceId"');
      } else {
        await controller.setGeoJsonSource(sourceId, GeoJsonBuilder().addFeature(location.toFeatureBuilder()).build());
        TalkerManager.instance.info('Updated Source "$sourceId"');
      }

      if (!isLayerExists) {
        await controller.addLayer(
          sourceId,
          layerId,
          const SymbolLayerProperties(
            symbolZOrder: 'source',
            iconImage: 'gps',
            iconSize: kSymbolIconSize,
            iconAllowOverlap: true,
            iconIgnorePlacement: true,
          ),
        );
        TalkerManager.instance.info('Added Layer "$layerId"');
      }

      await controller.moveCamera(CameraUpdate.newLatLngZoom(location, 7));
      TalkerManager.instance.info('Moved Camera to $location');
    } catch (e, s) {
      TalkerManager.instance.error('DpipMap._updateUserLocation', e, s);
    }
  }

  void _initMap() {
    if (_controller == null) return;

    _updateUserLocation();
  }

  @override
  void initState() {
    super.initState();

    GlobalProviders.location.coordinateNotifier.addListener(_updateUserLocation);

    getApplicationDocumentsDirectory().then((dir) async {
      final documentDir = dir.path;
      final mapDir = '$documentDir/map';

      await Directory(mapDir).create(recursive: true);

      // Copy sprite.png
      final spritePngData = await rootBundle.load('assets/sprites.png');
      final spritePngFile = File('$mapDir/sprites.png');
      await spritePngFile.writeAsBytes(spritePngData.buffer.asUint8List());
      final spritePngFile2x = File('$mapDir/sprites@2x.png');
      await spritePngFile2x.writeAsBytes(spritePngData.buffer.asUint8List());
      TalkerManager.instance.info('Copied sprite.png to $spritePngFile');

      // Copy sprite.json
      final spriteJsonData = await rootBundle.load('assets/sprites.json');
      final spriteJsonFile = File('$mapDir/sprites.json');
      await spriteJsonFile.writeAsBytes(spriteJsonData.buffer.asUint8List());
      final spriteJsonFile2x = File('$mapDir/sprites@2x.json');
      await spriteJsonFile2x.writeAsBytes(spriteJsonData.buffer.asUint8List());
      TalkerManager.instance.info('Copied sprite.json to $spriteJsonFile');

      final spriteUri = '${spriteJsonFile.parent.uri}sprites';
      TalkerManager.instance.info('Sprite is $spriteUri');

      // Create style.json
      final styleJsonData = _getStyleJson(spriteUri);
      final styleJsonFile = File('$mapDir/style.json');
      await styleJsonFile.writeAsString(styleJsonData);

      setState(() => styleAbsoluteFilePath = styleJsonFile.uri.toFilePath());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (styleAbsoluteFilePath == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final double adjustedZoomValue = adjustedZoom(widget.initialCameraPosition.zoom);

    return MapLibreMap(
      minMaxZoomPreference: widget.minMaxZoomPreference ?? const MinMaxZoomPreference(3, 9),
      trackCameraPosition: true,
      initialCameraPosition: CameraPosition(target: widget.initialCameraPosition.target, zoom: adjustedZoomValue),
      styleString: styleAbsoluteFilePath!,
      tiltGesturesEnabled: widget.tiltGesturesEnabled ?? false,
      scrollGesturesEnabled: widget.scrollGesturesEnabled ?? true,
      rotateGesturesEnabled: widget.rotateGesturesEnabled ?? false,
      zoomGesturesEnabled: widget.zoomGesturesEnabled ?? true,
      doubleClickZoomEnabled: widget.doubleClickZoomEnabled ?? true,
      dragEnabled: widget.dragEnabled ?? true,
      attributionButtonMargins: const Point<double>(-100, -100),
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapCreated?.call(controller);
      },
      onMapClick: widget.onMapClick,
      onMapIdle: widget.onMapIdle,
      onMapLongClick: widget.onMapLongClick,
      onStyleLoadedCallback: () {
        _initMap();
        widget.onStyleLoadedCallback?.call();
      },
    );
  }

  @override
  void dispose() {
    GlobalProviders.location.coordinateNotifier.removeListener(_updateUserLocation);
    super.dispose();
  }
}
