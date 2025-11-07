import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:dpip/global.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:styled_text/styled_text.dart';

import 'package:dpip/api/model/eew.dart';
import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/eew.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/data.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/int.dart';
import 'package:dpip/utils/instrumental_intensity_color.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:dpip/widgets/sheet/morphing_sheet.dart';

class MonitorMapLayerManager extends MapLayerManager {
  final bool isReplayMode;
  final int? replayTimestamp;
  Timer? _blinkTimer;
  bool _isBoxVisible = true;
  Timer? _focusTimer;
  bool _isFocusing = false;
  static const double kCameraPadding = 80.0;

  // Cached bounds for performance optimization
  List<LatLng>? _cachedBounds;
  int? _lastRtsTime;
  LatLngBounds? _lastZoomBounds;

  // Cache for EEW updates - only update when changed
  String? _lastEewDataHash;

  // Cache autoZoom setting to avoid repeated Provider queries
  bool _autoZoomEnabled = true;

  // Cached layer and source IDs to avoid repeated string calculations
  late final String _rtsSourceId = MapSourceIds.rts();
  late final String _rtsLayerId = MapLayerIds.rts();
  late final String _intensitySourceId = MapSourceIds.intensity();
  late final String _intensityLayerId = MapLayerIds.intensity();
  late final String _intensity0SourceId = MapSourceIds.intensity0();
  late final String _intensity0LayerId = MapLayerIds.intensity0();
  late final String _boxSourceId = MapSourceIds.box();
  late final String _boxLayerId = MapLayerIds.box();
  late final String _eewSourceId = MapSourceIds.eew();
  late final String _epicenterLayerId = MapLayerIds.eew('x');
  late final String _pWaveLayerId = MapLayerIds.eew('p');
  late final String _sWaveLayerId = MapLayerIds.eew('s');

  MonitorMapLayerManager(
    super.context,
    super.controller, {
    this.isReplayMode = false,
    this.replayTimestamp = 0, //1761222483000,
  }) {
    if (isReplayMode) {
      GlobalProviders.data.setReplayMode(true, replayTimestamp);
    } else {
      GlobalProviders.data.setReplayMode(false);
    }
    _setupBlinkTimer();
  }

  final currentRtsTime = ValueNotifier<int?>(GlobalProviders.data.rts?.time);

  static final kRtsCircleColor = [
    Expressions.interpolate,
    ['linear'],
    [Expressions.get, 'i'],
    -3,
    InstrumentalIntensityColor.intensity_3.toHexStringRGB(),
    -2,
    InstrumentalIntensityColor.intensity_2.toHexStringRGB(),
    -1,
    InstrumentalIntensityColor.intensity_1.toHexStringRGB(),
    0,
    InstrumentalIntensityColor.intensity0.toHexStringRGB(),
    1,
    InstrumentalIntensityColor.intensity1.toHexStringRGB(),
    2,
    InstrumentalIntensityColor.intensity2.toHexStringRGB(),
    3,
    InstrumentalIntensityColor.intensity3.toHexStringRGB(),
    4,
    InstrumentalIntensityColor.intensity4.toHexStringRGB(),
    5,
    InstrumentalIntensityColor.intensity5.toHexStringRGB(),
    6,
    InstrumentalIntensityColor.intensity6.toHexStringRGB(),
    7,
    InstrumentalIntensityColor.intensity7.toHexStringRGB(),
  ];

  static const kRtsCircleRadius = [
    Expressions.interpolate,
    ['linear'],
    [Expressions.zoom],
    4,
    2,
    12,
    8,
  ];

  void _setupBlinkTimer() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!didSetup) return;

      try {
        _isBoxVisible = !_isBoxVisible;

        // Batch blink visibility updates without querying layer IDs every time
        await Future.wait([
          controller.setLayerVisibility(_boxLayerId, _isBoxVisible),
          controller.setLayerVisibility(_epicenterLayerId, _isBoxVisible),
        ]);
      } catch (e, s) {
        TalkerManager.instance.error('MonitorMapLayerManager._blinkTimer', e, s);
      }
    });
  }

  Future<void> _focus() async {
    try {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(DpipMap.kTaiwanCenter, 6.4));
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager._focus', e, s);
    }
  }

  /// Extracts all coordinates from detection areas (GeoJSON polygons) that are present
  /// in the current RTS data. Uses caching to avoid recalculating bounds when
  /// RTS data hasn't changed. Returns empty list if no detection areas exist.
  List<LatLng> _getFocusBounds() {
    final rts = GlobalProviders.data.rts;
    final currentTime = rts?.time;

    // Return cached bounds if RTS data hasn't changed
    if (_cachedBounds != null && _lastRtsTime == currentTime) {
      return _cachedBounds!;
    }

    final coords = <LatLng>[];
    if (rts != null && rts.box.isNotEmpty) {
      // Pre-allocate list capacity to avoid dynamic resizing
      final boxKeys = rts.box.keys.toSet();

      for (final area in Global.boxGeojson.features) {
        if (area == null) continue;

        final id = area.properties!['ID'].toString();
        if (!boxKeys.contains(id)) continue;

        final geometry = area.geometry! as GeoJSONPolygon;
        final coordinates = geometry.coordinates[0] as List;

        // Direct iteration without type checking in loop
        for (var i = 0; i < coordinates.length; i++) {
          final coord = coordinates[i] as List;
          coords.add(LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble()));
        }
      }
    }

    // Cache the result
    _cachedBounds = coords;
    _lastRtsTime = currentTime;
    return coords;
  }

  /// Checks if the new bounds have changed significantly from the last zoom bounds
  /// Only zooms if the change is greater than 10% in any dimension
  bool _shouldZoomToBounds(LatLngBounds newBounds) {
    if (_lastZoomBounds == null) return true;

    final lastBounds = _lastZoomBounds!;
    final latDiff = (newBounds.northeast.latitude - newBounds.southwest.latitude).abs();
    final lngDiff = (newBounds.northeast.longitude - newBounds.southwest.longitude).abs();
    final lastLatDiff = (lastBounds.northeast.latitude - lastBounds.southwest.latitude).abs();
    final lastLngDiff = (lastBounds.northeast.longitude - lastBounds.southwest.longitude).abs();

    // Safety check for division by zero (very small bounds)
    const minBoundSize = 0.0001; // ~11 meters
    if (lastLatDiff < minBoundSize || lastLngDiff < minBoundSize) return true;

    // Check if bounds have changed by more than 10%
    final latChange = (latDiff - lastLatDiff).abs() / lastLatDiff;
    final lngChange = (lngDiff - lastLngDiff).abs() / lastLngDiff;

    return latChange > 0.1 || lngChange > 0.1;
  }
  /// Calculates the bounding box from coordinates and animates the map camera
  /// to fit all detection areas with padding. Only zooms if the bounds have
  /// changed significantly (>10%) from the last zoom to prevent excessive zooming.
  Future<void> _updateMapBounds(List<LatLng> coordinates) async {
    if (coordinates.isEmpty) return;

    // Initialize with first coordinate for better performance
    var minLat = coordinates[0].latitude;
    var maxLat = minLat;
    var minLng = coordinates[0].longitude;
    var maxLng = minLng;

    // Start from index 1 since we used index 0 for initialization
    for (var i = 1; i < coordinates.length; i++) {
      final lat = coordinates[i].latitude;
      final lng = coordinates[i].longitude;

      if (lat < minLat) {
        minLat = lat;
      } else if (lat > maxLat) {
        maxLat = lat;
      }

      if (lng < minLng) {
        minLng = lng;
      } else if (lng > maxLng) {
        maxLng = lng;
      }
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Only zoom if bounds have changed significantly
    if (!_shouldZoomToBounds(bounds)) return;

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        left: kCameraPadding,
        top: kCameraPadding,
        right: kCameraPadding,
        bottom: kCameraPadding,
      ),
      duration: const Duration(milliseconds: 500),
    );

    _lastZoomBounds = bounds;
  }

  Future<void> _focusReset() async {
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(DpipMap.kTaiwanCenter, 6.4),
    );
  }

  /// Automatically adjusts the map camera to fit all detection areas (boxes)
  /// when RTS data contains detection zones. Runs every 2 seconds when enabled.
  /// If no detection areas exist, resets to the default Taiwan center view.
  /// Uses caching and debouncing to optimize performance.
  Future<void> _autoFocus() async {
    if (!visible || !context.mounted || !_autoZoomEnabled) return;

    try {
      final bounds = _getFocusBounds();
      if (bounds.isNotEmpty) {
        await _updateMapBounds(bounds);
      } else {
        await _focusReset();
      }
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager._autoFocus', e, s);
    }
  }

  void _startFocusTimer() {
    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!_isFocusing) {
        _isFocusing = true;
        await _autoFocus();
        _isFocusing = false;
      }
    });
  }

  void _stopFocusTimer() {
    _focusTimer?.cancel();
    _focusTimer = null;
  }

  @override
  Future<void> setup() async {
    if (didSetup) return;

    final colors = context.colors;

    try {
      // Single batch query for sources and layers
      final results = await Future.wait([
        controller.getSourceIds(),
        controller.getLayerIds(),
      ]);
      final sources = results[0];
      final layers = results[1];

      final rtsSourceId = MapSourceIds.rts();
      final rtsLayerId = MapLayerIds.rts();
      final intensitySourceId = MapSourceIds.intensity();
      final intensityLayerId = MapLayerIds.intensity();
      final intensity0SourceId = MapSourceIds.intensity0();
      final intensity0LayerId = MapLayerIds.intensity0();
      final boxSourceId = MapSourceIds.box();
      final boxLayerId = MapLayerIds.box();
      final eewSourceId = MapSourceIds.eew();
      final epicenterLayerId = MapLayerIds.eew('x');
      final pWaveLayerId = MapLayerIds.eew('p');
      final sWaveLayerId = MapLayerIds.eew('s');

      final existingSources = sources.toSet();
      final existingLayers = layers.toSet();

      // Check layer existence
      final isRtsLayerExists = existingLayers.contains(rtsLayerId);
      final isIntensity0LayerExists = existingLayers.contains(intensity0LayerId);
      final isIntensityLayerExists = existingLayers.contains(intensityLayerId);
      final isBoxLayerExists = existingLayers.contains(boxLayerId);
      final isEewLayerExists = existingLayers.contains(epicenterLayerId) &&
                               existingLayers.contains(pWaveLayerId) &&
                               existingLayers.contains(sWaveLayerId);

      if (!context.mounted) return;

      // Prepare GeoJSON data (reuse intensity data)
      final intensityData = GlobalProviders.data.getIntensityGeoJson();
      final sourceAdditions = <Future<void>>[];

      if (!existingSources.contains(rtsSourceId)) {
        sourceAdditions.add(
          controller.addSource(rtsSourceId, GeojsonSourceProperties(data: GlobalProviders.data.getRtsGeoJson()))
              .then((_) => TalkerManager.instance.info('Added Source "$rtsSourceId"')),
        );
      }

      if (!existingSources.contains(intensity0SourceId)) {
        sourceAdditions.add(
          controller.addSource(intensity0SourceId, GeojsonSourceProperties(data: intensityData))
              .then((_) => TalkerManager.instance.info('Added Source "$intensity0SourceId"')),
        );
      }

      if (!existingSources.contains(intensitySourceId)) {
        sourceAdditions.add(
          controller.addSource(intensitySourceId, GeojsonSourceProperties(data: intensityData))
              .then((_) => TalkerManager.instance.info('Added Source "$intensitySourceId"')),
        );
      }

      if (!existingSources.contains(boxSourceId)) {
        sourceAdditions.add(
          controller.addSource(boxSourceId, GeojsonSourceProperties(data: GlobalProviders.data.getBoxGeoJson()))
              .then((_) => TalkerManager.instance.info('Added Source "$boxSourceId"')),
        );
      }

      if (!existingSources.contains(eewSourceId)) {
        sourceAdditions.add(
          controller.addSource(eewSourceId, GeojsonSourceProperties(data: GlobalProviders.data.getEewGeoJson()))
              .then((_) => TalkerManager.instance.info('Added Source "$eewSourceId"')),
        );
      }

      // Add all sources in parallel
      if (sourceAdditions.isNotEmpty) {
        await Future.wait(sourceAdditions);
      }

      if (!context.mounted) return;

      if (!isRtsLayerExists) {
        final properties = CircleLayerProperties(
          circleColor: kRtsCircleColor,
          circleRadius: kRtsCircleRadius,
          circleOpacity: [
            Expressions.caseExpression,
            [Expressions.has, 'i'],
            1,
            0,
          ],
          circleStrokeColor: context.colors.outlineVariant.toHexStringRGB(),
          circleStrokeWidth: 1,
          circleSortKey: [
            Expressions.coalesce,
            [Expressions.get, 'i'],
            -5,
          ],
          visibility: visible ? 'visible' : 'none',
        );
        final properties2 = SymbolLayerProperties(
          textField: [
            Expressions.format,
            [Expressions.get, 'id'],
            {
              'text-font': [
                Expressions.literal,
                ['Noto Sans TC Bold'],
              ],
            },
            '\n',
            {},
            [
              Expressions.caseExpression,
              [
                Expressions.all,
                [Expressions.has, 'city'],
                [Expressions.has, 'town'],
              ],
              [
                Expressions.concat,
                [Expressions.get, 'city'],
                ' ',
                [Expressions.get, 'town'],
              ],
              '海外測站'.i18n,
            ],
            {
              'text-font': [
                Expressions.literal,
                ['Noto Sans TC Bold'],
              ],
            },
            '\n',
            {},
            [
              Expressions.caseExpression,
              [
                Expressions.all,
                [Expressions.has, 'i'],
                [Expressions.has, 'pga'],
                [Expressions.has, 'pgv'],
              ],
              [
                Expressions.concat,
                [
                  Expressions.concat,
                  '即時震度：'.i18n,
                  [Expressions.get, 'i'],
                ],
                '\n',
                [
                  Expressions.concat,
                  '地動加速度：'.i18n,
                  [Expressions.get, 'pga'],
                  'gal',
                ],
                '\n',
                [
                  Expressions.concat,
                  '地動速度：'.i18n,
                  [Expressions.get, 'pgv'],
                  'cm/s',
                ],
              ],
              '無資料'.i18n,
            ],
            {},
          ],
          textSize: 10,
          textColor: colors.onSurfaceVariant.toHexStringRGB(),
          textHaloColor: colors.outlineVariant.toHexStringRGB(),
          textHaloWidth: 1,
          textFont: ['Noto Sans TC Regular'],
          textRadialOffset: 1.5,
          textAnchor: 'top',
          textJustify: 'auto',
          textVariableAnchor: [
            'top',
            'bottom',
            'left',
            'right',
            'top-left',
            'bottom-left',
            'top-right',
            'bottom-right',
          ],
          visibility: visible ? 'visible' : 'none',
        );

        await controller.addLayer(rtsSourceId, rtsLayerId, properties, belowLayerId: BaseMapLayerIds.userLocation);
        TalkerManager.instance.info('Added Layer "$rtsLayerId"');

        await controller.addLayer(
          rtsSourceId,
          '$rtsLayerId-label',
          properties2,
          belowLayerId: BaseMapLayerIds.userLocation,
          minzoom: 10,
        );
        TalkerManager.instance.info('Added Layer "$rtsLayerId-label"');
      }

      if (!isIntensity0LayerExists) {
        final properties = CircleLayerProperties(
          circleColor: Colors.grey.toHexStringRGB(),
          circleRadius: kRtsCircleRadius,
          circleOpacity: [
            Expressions.caseExpression,
            [Expressions.has, 'intensity'],
            [
              Expressions.caseExpression,
              [
                Expressions.all,
                [
                  Expressions.equal,
                  [Expressions.get, 'intensity'],
                  0,
                ],
                [
                  Expressions.equal,
                  [Expressions.get, 'alert'],
                  1,
                ],
              ],
              1,
              0,
            ],
            0,
          ],
          visibility: 'none',
        );

        await controller.addLayer(
          intensity0SourceId,
          intensity0LayerId,
          properties,
          belowLayerId: BaseMapLayerIds.userLocation,
        );
        TalkerManager.instance.info('Added Layer "$intensity0LayerId"');
      }

      if (!isIntensityLayerExists) {
        const properties = SymbolLayerProperties(
          symbolSortKey: [Expressions.get, 'intensity'],
          symbolZOrder: 'source',
          iconSize: kSymbolIconSize,
          iconImage: [
            Expressions.match,
            [Expressions.get, 'intensity'],
            1,
            'intensity-1',
            2,
            'intensity-2',
            3,
            'intensity-3',
            4,
            'intensity-4',
            5,
            'intensity-5',
            6,
            'intensity-6',
            7,
            'intensity-7',
            8,
            'intensity-8',
            9,
            'intensity-9',
            '',
          ],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          visibility: 'none',
        );

        await controller.addLayer(
          intensitySourceId,
          intensityLayerId,
          properties,
          belowLayerId: BaseMapLayerIds.userLocation,
        );
        TalkerManager.instance.info('Added Layer "$intensityLayerId"');
      }

      if (!isBoxLayerExists) {
        const properties = LineLayerProperties(
          lineWidth: 2,
          lineColor: [
            Expressions.match,
            [Expressions.get, 'i'],
            9,
            '#FF0000',
            8,
            '#FF0000',
            7,
            '#FF0000',
            6,
            '#FF0000',
            5,
            '#FF0000',
            4,
            '#FF0000',
            3,
            '#EAC100',
            2,
            '#EAC100',
            1,
            '#00DB00',
            '#00DB00',
          ],
          visibility: 'none',
          lineSortKey: [Expressions.get, 'i'],
        );

        await controller.addLayer(boxSourceId, boxLayerId, properties, belowLayerId: BaseMapLayerIds.userLocation);
        TalkerManager.instance.info('Added Layer "$boxLayerId"');
      }

      if (!isEewLayerExists) {
        final pWaveProperties = LineLayerProperties(
          lineColor: Colors.cyan.toHexStringRGB(),
          lineWidth: 2,
          visibility: visible ? 'visible' : 'none',
        );

        await controller.addLayer(
          eewSourceId,
          pWaveLayerId,
          pWaveProperties,
          enableInteraction: false,
          belowLayerId: BaseMapLayerIds.userLocation,
          filter: [
            Expressions.equal,
            [Expressions.get, 'type'],
            'p',
          ],
        );
        TalkerManager.instance.info('Added Layer "$pWaveLayerId"');

        final sWaveProperties = LineLayerProperties(
          lineColor: Colors.red.toHexStringRGB(),
          lineWidth: 2,
          visibility: visible ? 'visible' : 'none',
        );

        await controller.addLayer(
          eewSourceId,
          sWaveLayerId,
          sWaveProperties,
          enableInteraction: false,
          belowLayerId: BaseMapLayerIds.userLocation,
          filter: [
            Expressions.equal,
            [Expressions.get, 'type'],
            's',
          ],
        );
        TalkerManager.instance.info('Added Layer "$sWaveLayerId"');

        final epicenterProperties = SymbolLayerProperties(
          iconImage: 'cross-7',
          iconSize: kSymbolIconSize,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          symbolZOrder: 'source',
          visibility: visible ? 'visible' : 'none',
        );

        await controller.addLayer(
          eewSourceId,
          epicenterLayerId,
          epicenterProperties,
          belowLayerId: BaseMapLayerIds.userLocation,
          filter: [
            Expressions.equal,
            [Expressions.get, 'type'],
            'x',
          ],
        );
        TalkerManager.instance.info('Added Layer "$epicenterLayerId"');
      }

      didSetup = true;
      _startFocusTimer();
      GlobalProviders.data.addListener(_onDataChanged);
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager.setup', e, s);
    }
  }

  @override
  void tick() {
    if (!didSetup) return;

    _updateEewSource();
  }

  void _onDataChanged() {
    final newRts = GlobalProviders.data.rts;
    final newRtsTime = newRts?.time;

    if (newRtsTime != currentRtsTime.value) {
      currentRtsTime.value = newRtsTime;
      // Invalidate cached bounds when RTS data changes
      _cachedBounds = null;
      _lastRtsTime = null;

      // Batch all map updates together for the same timestamp
      _updateRtsDataAndLayers();
    }
  }

  /// Updates both RTS sources and layer visibility in a single operation
  /// This ensures all map changes for the same timestamp happen atomically
  Future<void> _updateRtsDataAndLayers() async {
    if (!didSetup) return;

    try {
      // Single call to get all source IDs
      final sourceIds = await controller.getSourceIds();
      final existingSources = sourceIds.toSet();

      // Prepare all updates (sources + visibility) in parallel
      final updates = <Future<void>>[];

      // Update sources
      if (existingSources.contains(_rtsSourceId)) {
        updates.add(controller.setGeoJsonSource(_rtsSourceId, GlobalProviders.data.getRtsGeoJson()));
      }

      if (existingSources.contains(_intensitySourceId) || existingSources.contains(_intensity0SourceId)) {
        final intensityData = GlobalProviders.data.getIntensityGeoJson();
        if (existingSources.contains(_intensitySourceId)) {
          updates.add(controller.setGeoJsonSource(_intensitySourceId, intensityData));
        }
        if (existingSources.contains(_intensity0SourceId)) {
          updates.add(controller.setGeoJsonSource(_intensity0SourceId, intensityData));
        }
      }

      if (existingSources.contains(_boxSourceId)) {
        updates.add(controller.setGeoJsonSource(_boxSourceId, GlobalProviders.data.getBoxGeoJson()));
      }

      // Update layer visibility if visible
      if (visible) {
        final hasBox = GlobalProviders.data.rts?.box.isNotEmpty ?? false;

        updates.addAll([
          controller.setLayerVisibility(_rtsLayerId, !hasBox),
          controller.setLayerVisibility('$_rtsLayerId-label', !hasBox),
          controller.setLayerVisibility(_intensityLayerId, hasBox),
          controller.setLayerVisibility(_intensity0LayerId, hasBox),
          controller.setLayerVisibility(_boxLayerId, hasBox),
        ]);
      }

      // Execute all updates in parallel
      if (updates.isNotEmpty) {
        await Future.wait(updates);
        TalkerManager.instance.info('Updated RTS data and layers for time: ${currentRtsTime.value}');
      }
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager._updateRtsDataAndLayers', e, s);
    }
  }


  Future<void> _updateEewSource() async {
    if (!didSetup) return;

    try {
      final eewData = GlobalProviders.data.eew;

      // Create a simple hash from EEW data to detect changes
      // Only update if the data actually changed
      final currentHash = eewData.isEmpty
          ? ''
          : '${eewData.length}_${eewData.first.serial}_${eewData.first.info.time}';

      if (currentHash == _lastEewDataHash) return;

      _lastEewDataHash = currentHash;
      final data = GlobalProviders.data.getEewGeoJson();
      await controller.setGeoJsonSource(_eewSourceId, data);
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager._updateEewSource', e, s);
    }
  }

  @override
  Future<void> hide() async {
    if (!visible) return;

    try {
      _blinkTimer?.cancel();
      _blinkTimer = null;

      // Batch hide all layers in parallel
      await Future.wait([
        controller.setLayerVisibility(_rtsLayerId, false),
        controller.setLayerVisibility('$_rtsLayerId-label', false),
        controller.setLayerVisibility(_intensityLayerId, false),
        controller.setLayerVisibility(_intensity0LayerId, false),
        controller.setLayerVisibility(_boxLayerId, false),
        controller.setLayerVisibility(_epicenterLayerId, false),
        controller.setLayerVisibility(_pWaveLayerId, false),
        controller.setLayerVisibility(_sWaveLayerId, false),
      ]);

      visible = false;
      _stopFocusTimer();
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (visible) return;

    try {
      _setupBlinkTimer();

      final hasBox = GlobalProviders.data.rts?.box.isNotEmpty ?? false;

      // Batch show all layers in parallel, then focus
      await Future.wait([
        controller.setLayerVisibility(_rtsLayerId, !hasBox),
        controller.setLayerVisibility('$_rtsLayerId-label', !hasBox),
        controller.setLayerVisibility(_intensityLayerId, hasBox),
        controller.setLayerVisibility(_intensity0LayerId, hasBox),
        controller.setLayerVisibility(_boxLayerId, hasBox),
        controller.setLayerVisibility(_epicenterLayerId, true),
        controller.setLayerVisibility(_pWaveLayerId, true),
        controller.setLayerVisibility(_sWaveLayerId, true),
        _focus(),
      ]);

      visible = true;
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager.show', e, s);
    }
  }

  @override
  Future<void> remove() async {
    final rtsSourceId = MapSourceIds.rts();
    final rtsLayerId = MapLayerIds.rts();
    final intensitySourceId = MapSourceIds.intensity();
    final intensityLayerId = MapLayerIds.intensity();
    final intensity0SourceId = MapSourceIds.intensity0();
    final intensity0LayerId = MapLayerIds.intensity0();
    final boxSourceId = MapSourceIds.box();
    final boxLayerId = MapLayerIds.box();

    final eewSourceId = MapSourceIds.eew();
    final epicenterLayerId = MapLayerIds.eew('x');
    final pWaveLayerId = MapLayerIds.eew('p');
    final sWaveLayerId = MapLayerIds.eew('s');

    try {
      // rts
      await controller.removeLayer(rtsLayerId);
      TalkerManager.instance.info('Removed Layer "$rtsLayerId"');
      await controller.removeLayer('$rtsLayerId-label');
      TalkerManager.instance.info('Removed Layer "$rtsLayerId-label"');
      await controller.removeSource(rtsSourceId);
      TalkerManager.instance.info('Removed Source "$rtsSourceId"');

      // intensity
      await controller.removeLayer(intensityLayerId);
      TalkerManager.instance.info('Removed Layer "$intensityLayerId"');
      await controller.removeSource(intensitySourceId);
      TalkerManager.instance.info('Removed Source "$intensitySourceId"');

      // intensity0
      await controller.removeLayer(intensity0LayerId);
      TalkerManager.instance.info('Removed Layer "$intensity0LayerId"');
      await controller.removeSource(intensity0SourceId);
      TalkerManager.instance.info('Removed Source "$intensity0SourceId"');

      // box
      await controller.removeLayer(boxLayerId);
      TalkerManager.instance.info('Removed Layer "$boxLayerId"');
      await controller.removeSource(boxSourceId);
      TalkerManager.instance.info('Removed Source "$boxSourceId"');

      // eew
      await controller.removeLayer(epicenterLayerId);
      TalkerManager.instance.info('Removed Layer "$epicenterLayerId"');
      await controller.removeLayer(pWaveLayerId);
      TalkerManager.instance.info('Removed Layer "$pWaveLayerId"');
      await controller.removeLayer(sWaveLayerId);
      TalkerManager.instance.info('Removed Layer "$sWaveLayerId"');
      await controller.removeSource(eewSourceId);
      TalkerManager.instance.info('Removed Source "$eewSourceId"');
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager.remove', e, s);
    }

    didSetup = false;
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _stopFocusTimer();
    GlobalProviders.data.setReplayMode(false);
    GlobalProviders.data.removeListener(_onDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MonitorMapLayerSheet(manager: this);
}

class MonitorMapLayerSheet extends StatefulWidget {
  final MonitorMapLayerManager manager;

  const MonitorMapLayerSheet({super.key, required this.manager});

  @override
  State<MonitorMapLayerSheet> createState() => _MonitorMapLayerSheetState();
}

class _MonitorMapLayerSheetState extends State<MonitorMapLayerSheet> {
  late int localIntensity;
  late int localArrivalTime;
  Timer? _timer;
  int countdown = 0;

  bool _isCollapsed = true;

  void _toggleCollapse() {
    setState(() => _isCollapsed = !_isCollapsed);
  }

  void _updateCountdown() {
    final remainingSeconds = ((localArrivalTime - GlobalProviders.data.currentTime) / 1000).floor();
    if (remainingSeconds < -1) return;

    setState(() => countdown = remainingSeconds);
  }

  // Build common alert badge with count indicator
  Widget _buildAlertBadge(int eewCount, {double iconSize = 16, bool showLabel = false}) {
    final colors = context.colors;
    final theme = context.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.error,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: eewCount > 1 || showLabel
          ? const EdgeInsets.fromLTRB(8, 6, 12, 6)
          : const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(Symbols.crisis_alert_rounded, color: colors.onError, weight: 700, size: iconSize),
          if (showLabel)
            Text('EEW'.i18n, style: theme.labelLarge!.copyWith(color: colors.onError, fontWeight: FontWeight.bold))
          else if (eewCount > 1)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '1', style: theme.labelMedium!.copyWith(color: colors.onError, fontWeight: FontWeight.bold)),
                  TextSpan(text: '/$eewCount', style: theme.labelMedium!.copyWith(color: colors.onError.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Build collapsed or expanded EEW info
  Widget _buildEewContent(Eew data, int eewCount, bool hasLocation) {
    final colors = context.colors;
    final theme = context.textTheme;

    if (_isCollapsed) {
      // Collapsed view - compact info
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 8,
                children: [
                  _buildAlertBadge(eewCount),
                  Text(
                    '#${data.serial} ${data.info.time.toSimpleDateTimeString()} ${data.info.location}',
                    style: theme.bodyMedium!.copyWith(fontWeight: FontWeight.bold, color: colors.onErrorContainer),
                  ),
                ],
              ),
              Icon(Symbols.expand_less_rounded, color: colors.onErrorContainer, size: 24),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: hasLocation
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StyledText(
                        text: '規模 <bold>M{magnitude}</bold>,所在地預估<bold>{intensity}</bold>'.i18n.args({
                          'magnitude': data.info.magnitude.toStringAsFixed(1),
                          'intensity': localIntensity.asIntensityLabel,
                        }),
                        style: theme.bodyMedium!.copyWith(color: colors.onErrorContainer),
                        tags: {'bold': StyledTextTag(style: const TextStyle(fontWeight: FontWeight.bold))},
                      ),
                      Text(
                        countdown > 0 ? '{countdown}秒後抵達'.i18n.args({'countdown': countdown}) : '已抵達'.i18n,
                        style: theme.bodyMedium!.copyWith(fontWeight: FontWeight.bold, color: colors.onErrorContainer, height: 1, leadingDistribution: TextLeadingDistribution.even),
                      ),
                    ],
                  )
                : StyledText(
                    text: '規模 <bold>M{magnitude}</bold>,深度<bold>{depth}</bold>公里'.i18n.args({
                      'magnitude': data.info.magnitude.toStringAsFixed(1),
                      'depth': data.info.depth.toStringAsFixed(1),
                    }),
                    style: theme.bodyMedium!.copyWith(color: colors.onErrorContainer),
                    tags: {'bold': StyledTextTag(style: const TextStyle(fontWeight: FontWeight.bold))},
                  ),
          ),
        ],
      );
    } else {
      // Expanded view - detailed info
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 8,
                children: [
                  _buildAlertBadge(eewCount, iconSize: 22, showLabel: true),
                  Text('第 {serial} 報'.i18n.args({'serial': data.serial}), style: theme.bodyLarge!.copyWith(color: colors.onErrorContainer)),
                ],
              ),
              Icon(Symbols.expand_more_rounded, color: colors.onErrorContainer, size: 24),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: StyledText(
              text: hasLocation
                  ? '{time} 左右,<bold>{location}</bold>附近發生有感地震,預估規模 <bold>M{magnitude}</bold>、所在地最大震度<bold>{intensity}</bold>。'.i18n.args({
                      'time': data.info.time.toSimpleDateTimeString(),
                      'location': data.info.location,
                      'magnitude': data.info.magnitude.toStringAsFixed(1),
                      'intensity': localIntensity.asIntensityLabel,
                    })
                  : '{time} 左右,<bold>{location}</bold>附近發生有感地震,預估規模 <bold>M{magnitude}</bold>、深度<bold>{depth}</bold>公里。'.i18n.args({
                      'time': data.info.time.toSimpleDateTimeString(),
                      'location': data.info.location,
                      'magnitude': data.info.magnitude.toStringAsFixed(1),
                      'depth': data.info.depth.toStringAsFixed(1),
                    }),
              style: theme.bodyLarge!.copyWith(color: colors.onErrorContainer),
              tags: {'bold': StyledTextTag(style: const TextStyle(fontWeight: FontWeight.bold))},
            ),
          ),
          if (hasLocation) _buildLocationDetails(),
        ],
      );
    }
  }

  // Build location-specific details (intensity and countdown)
  Widget _buildLocationDetails() {
    return Selector<SettingsLocationModel, String?>(
      selector: (context, model) => model.code,
      builder: (context, code, child) {
        if (code == null) return const SizedBox.shrink();

        final colors = context.colors;
        final theme = context.textTheme;

        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('所在地預估'.i18n, style: theme.labelLarge!.copyWith(color: colors.onErrorContainer.withValues(alpha: 0.6))),
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Text(
                            localIntensity.asIntensityLabel,
                            style: theme.displayMedium!.copyWith(fontWeight: FontWeight.bold, color: colors.onErrorContainer, height: 1, leadingDistribution: TextLeadingDistribution.even),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(color: colors.onErrorContainer.withValues(alpha: 0.4), width: 24),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('震波'.i18n, style: theme.labelLarge!.copyWith(color: colors.onErrorContainer.withValues(alpha: 0.6))),
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: countdown > 0
                              ? RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(text: countdown.toString(), style: TextStyle(fontSize: theme.displayMedium!.fontSize! * 1.15)),
                                      TextSpan(text: ' 秒'.i18n, style: TextStyle(fontSize: theme.labelLarge!.fontSize)),
                                    ],
                                    style: theme.displayMedium!.copyWith(fontWeight: FontWeight.bold, color: colors.onErrorContainer, height: 1, leadingDistribution: TextLeadingDistribution.even),
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              : Text(
                                  '抵達'.i18n,
                                  style: theme.displayMedium!.copyWith(fontSize: theme.displayMedium!.fontSize! * 0.81, fontWeight: FontWeight.bold, color: colors.onErrorContainer, height: 1, leadingDistribution: TextLeadingDistribution.even),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<DpipDataModel, UnmodifiableListView<Eew>>(
      selector: (_, data) => data.eew,
      builder: (context, activeEew, child) {
        return Stack(
          children: [
            MorphingSheet(
              title: '強震監視器'.i18n,
              borderRadius: BorderRadius.circular(16),
              elevation: 4,
              borderWidth: activeEew.isNotEmpty ? 2 : null,
              borderColor: activeEew.isNotEmpty ? context.colors.error : null,
              backgroundColor: activeEew.isNotEmpty ? context.colors.errorContainer : null,
              partialBuilder: (context, controller, sheetController) {
                if (activeEew.isEmpty) {
                  return Padding(padding: const EdgeInsets.all(12), child: Text('目前沒有生效中的地震速報'.i18n));
                }

                final data = activeEew.first;
                final hasLocation = GlobalProviders.location.coordinates != null;

                // Calculate location-specific info if available
                if (hasLocation) {
                  final info = eewLocationInfo(
                    data.info.magnitude,
                    data.info.depth,
                    data.info.latitude,
                    data.info.longitude,
                    GlobalProviders.location.coordinates!.latitude,
                    GlobalProviders.location.coordinates!.longitude,
                  );

                  localIntensity = intensityFloatToInt(info.i);
                  localArrivalTime = (data.info.time + sWaveTimeByDistance(data.info.depth, info.dist)).floor();

                  WidgetsBinding.instance.addPostFrameCallback((_) => _updateCountdown());
                  _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
                }

                return InkWell(
                  onTap: _toggleCollapse,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildEewContent(data, activeEew.length, hasLocation),
                  ),
                );
              },
            ),
            Positioned(
              top: 24,
              left: 95,
              right: 95,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ValueListenableBuilder<int?>(
                    valueListenable: widget.manager.currentRtsTime,
                    builder: (context, currentTimeMillis, child) {
                      String displayTime = 'N/A';
                      if (currentTimeMillis != null && currentTimeMillis > 0) {
                        displayTime = currentTimeMillis.toLocaleDateTimeString(context);
                      }
                      return Container(
                        padding: const EdgeInsets.all(8),
                        width: 230,
                        decoration: BoxDecoration(
                          color: context.colors.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          displayTime,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.colors.onSurface, fontSize: 16),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
