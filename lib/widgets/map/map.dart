import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:async/async.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/core/ios_get_location.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/geojson.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/style.dart';

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
  final bool focusUserLocationWhenUpdated;

  static const kTaiwanCenter = LatLng(23.60, 120.85);
  static const kTaiwanZoom = 6.4;
  static const kUserLocationZoom = 7.2;

  const DpipMap({
    super.key,
    this.baseMapType = BaseMapType.exptech,
    this.initialCameraPosition = const CameraPosition(target: kTaiwanCenter, zoom: kTaiwanZoom),
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
    this.focusUserLocationWhenUpdated = false,
  });

  @override
  State<DpipMap> createState() => DpipMapState();

  static double adjustedZoom(BuildContext context, double zoom) {
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
}

class DpipMapState extends State<DpipMap> {
  MapLibreMapController? _controller;
  Future<String>? _stylePathFuture;

  Future<void> _updateUserLocation() async {
    if (!mounted) return;

    final controller = _controller;
    if (controller == null) return;

    try {
      if (Platform.isIOS && GlobalProviders.location.auto) {
        await updateSavedLocationIOS();
      }

      final location = GlobalProviders.location.coordinates;

      final data = location?.toGeoJsonMap() ?? GeoJsonBuilder.empty;

      await controller.setGeoJsonSource(BaseMapSourceIds.userLocation, data);

      if (widget.focusUserLocationWhenUpdated) {
        await controller.moveCamera(CameraUpdate.newLatLngZoom(location!, DpipMap.kUserLocationZoom));
      }
    } catch (e, s) {
      TalkerManager.instance.error('🗺️ failed to update user location', e, s);
    }
  }

  void _initMap() {
    if (_controller == null) return;

    _updateUserLocation();
  }

  @override
  void initState() {
    super.initState();

    GlobalProviders.location.$coordinates.addListener(_updateUserLocation);
  }

  ColorScheme? _lastColors;
  CancelableOperation? _setThemeColorFuture;
  Future<void> setThemeColors(ColorScheme colors) async {
    final controller = _controller;
    if (controller == null) return;

    final layers = [...MapStyle.osmLayers(colors), ...MapStyle.exptechLayers(colors)];

    for (final layer in layers) {
      if (layer['type'] == 'background') continue;

      final json = layer['paint'] as Map<String, dynamic>;
      json.remove('visibility');

      final properties = switch (layer['type']) {
        'fill' => FillLayerProperties.fromJson(json),
        'line' => LineLayerProperties.fromJson(json),
        'symbol' => SymbolLayerProperties.fromJson(json),
        'raster' => RasterLayerProperties.fromJson(json),
        _ => null,
      };

      await controller.setLayerProperties(layer['id'] as String, properties!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_stylePathFuture == null) {
      _stylePathFuture = MapStyle(context, baseMap: widget.baseMapType).save();
    } else if (_lastColors != context.colors) {
      _setThemeColorFuture?.cancel();
      _setThemeColorFuture = CancelableOperation.fromFuture(setThemeColors(context.colors));
    }

    _lastColors = context.colors;
  }

  @override
  Widget build(BuildContext context) {
    final double adjustedZoomValue = DpipMap.adjustedZoom(context, widget.initialCameraPosition.zoom);

    return FutureBuilder(
      future: _stylePathFuture,
      builder: (context, snapshot) {
        final styleString = snapshot.data;

        if (styleString == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ColoredBox(
          color: context.colors.surface,
          child: MapLibreMap(
            minMaxZoomPreference: widget.minMaxZoomPreference ?? const MinMaxZoomPreference(4, 12.5),
            trackCameraPosition: true,
            initialCameraPosition: CameraPosition(target: widget.initialCameraPosition.target, zoom: adjustedZoomValue),
            styleString: styleString,
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
            translucentTextureSurface: true,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    GlobalProviders.location.$coordinates.removeListener(_updateUserLocation);
    super.dispose();
  }
}
