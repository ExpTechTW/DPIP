import 'dart:async';

import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/instrumental_intensity_color.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';

class MonitorMapLayerManager extends MapLayerManager {
  final bool isReplayMode;
  final int? replayTimestamp;
  Timer? _blinkTimer;
  bool _isBoxVisible = true;

  MonitorMapLayerManager(
    super.context,
    super.controller, {
    this.isReplayMode = true,
    this.replayTimestamp = 1751918230855,
  }) {
    if (isReplayMode) {
      GlobalProviders.data.setReplayMode(true, replayTimestamp);
    } else {
      GlobalProviders.data.setReplayMode(false);
    }
    _setupBlinkTimer();
  }

  final currentRtsTime = ValueNotifier<String?>(GlobalProviders.data.rts?.time.toString());

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
      try {
        final boxLayerId = MapLayerIds.box();
        final epicenterLayerId = MapLayerIds.eew('x');
        
        await controller.setLayerVisibility(boxLayerId, _isBoxVisible);
        await controller.setLayerVisibility(epicenterLayerId, _isBoxVisible);
        
        _isBoxVisible = !_isBoxVisible;
      } catch (e, s) {
        TalkerManager.instance.error('MonitorMapLayerManager._blinkTimer', e, s);
      }
    });
  }

  Future<void> _focus() async {
    try {
      final location = GlobalProviders.location.coordinateNotifier.value;

      if (location.isValid) {
        await controller.animateCamera(CameraUpdate.newLatLngZoom(location, 7.4));
        TalkerManager.instance.info('Moved Camera to $location');
      } else {
        await controller.animateCamera(CameraUpdate.newLatLngZoom(DpipMap.kTaiwanCenter, 6.4));
        TalkerManager.instance.info('Moved Camera to ${DpipMap.kTaiwanCenter}');
      }
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager._focus', e, s);
    }
  }

  @override
  Future<void> setup() async {
    if (didSetup) return;

    try {
      final sources = await controller.getSourceIds();
      final layers = await controller.getLayerIds();

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

      // 检查所有源和图层是否存在
      final isRtsSourceExists = sources.contains(rtsSourceId);
      final isRtsLayerExists = layers.contains(rtsLayerId);
      final isIntensitySourceExists = sources.contains(intensitySourceId);
      final isIntensityLayerExists = layers.contains(intensityLayerId);
      final isIntensity0SourceExists = sources.contains(intensity0SourceId);
      final isIntensity0LayerExists = layers.contains(intensity0LayerId);
      final isBoxSourceExists = sources.contains(boxSourceId);
      final isBoxLayerExists = layers.contains(boxLayerId);
      final isEewSourceExists = sources.contains(eewSourceId);
      final isEewLayerExists =
          layers.contains(epicenterLayerId) && layers.contains(pWaveLayerId) && layers.contains(sWaveLayerId);

      if (!context.mounted) return;

      // 按顺序添加所有数据源
      if (!isRtsSourceExists) {
        final data = GlobalProviders.data.getRtsGeoJson();
        await controller.addSource(rtsSourceId, GeojsonSourceProperties(data: data));
        TalkerManager.instance.info('Added Source "$rtsSourceId"');
      }

      if (!isIntensity0SourceExists) {
        final data = GlobalProviders.data.getIntensityGeoJson();
        await controller.addSource(intensity0SourceId, GeojsonSourceProperties(data: data));
        TalkerManager.instance.info('Added Source "$intensity0SourceId"');
      }

      if (!isIntensitySourceExists) {
        final data = GlobalProviders.data.getIntensityGeoJson();
        await controller.addSource(intensitySourceId, GeojsonSourceProperties(data: data));
        TalkerManager.instance.info('Added Source "$intensitySourceId"');
      }

      if (!isBoxSourceExists) {
        final data = GlobalProviders.data.getBoxGeoJson();
        await controller.addSource(boxSourceId, GeojsonSourceProperties(data: data));
        TalkerManager.instance.info('Added Source "$boxSourceId"');
      }

      if (!isEewSourceExists) {
        final data = GlobalProviders.data.getEewGeoJson();
        await controller.addSource(eewSourceId, GeojsonSourceProperties(data: data));
        TalkerManager.instance.info('Added Source "$eewSourceId"');
      }

      if (!context.mounted) return;

      // 按顺序从下到上添加图层
      // 1. RTS 图层（最底层）
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

        await controller.addLayer(rtsSourceId, rtsLayerId, properties, belowLayerId: BaseMapLayerIds.userLocation);
        TalkerManager.instance.info('Added Layer "$rtsLayerId"');
      }

      // 2. Intensity0 图层
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
                [Expressions.equal, [Expressions.get, 'intensity'], 0],
                [Expressions.equal, [Expressions.get, 'alert'], 1],
              ],
              1,
              0,
            ],
            0,
          ],
          visibility: 'none',
        );

        await controller.addLayer(intensity0SourceId, intensity0LayerId, properties, belowLayerId: BaseMapLayerIds.userLocation);
        TalkerManager.instance.info('Added Layer "$intensity0LayerId"');
      }

      // 3. Intensity 图层
      if (!isIntensityLayerExists) {
        const properties = SymbolLayerProperties(
          symbolSortKey: [Expressions.get, 'intensity'],
          symbolZOrder: 'source',
          iconSize: [
            Expressions.interpolate,
            ['linear'],
            [Expressions.zoom],
            5,
            0.5,
            10,
            1.5,
          ],
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
            ''
          ],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          visibility: 'none',
        );

        await controller.addLayer(intensitySourceId, intensityLayerId, properties, belowLayerId: BaseMapLayerIds.userLocation);
        TalkerManager.instance.info('Added Layer "$intensityLayerId"');
      }

      // 4. Box 图层
      if (!isBoxLayerExists) {
        final properties = LineLayerProperties(
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
        );

        await controller.addLayer(boxSourceId, boxLayerId, properties, belowLayerId: BaseMapLayerIds.userLocation);
        TalkerManager.instance.info('Added Layer "$boxLayerId"');
      }

      // 5. EEW 图层（P波、S波、震央标记）
      if (!isEewLayerExists) {
        // 5.1 P波圈
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

        // 5.2 S波圈
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

        // 5.3 震央标记（最顶层）
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
    final newRtsTime = newRts?.time.toString();

    if (newRtsTime != currentRtsTime.value) {
      currentRtsTime.value = newRtsTime;
      _updateRtsSource();
      _updateLayerVisibility();
    }
  }

  Future<void> _updateLayerVisibility() async {
    if (!didSetup) return;

    try {
      final rtsLayerId = MapLayerIds.rts();
      final intensityLayerId = MapLayerIds.intensity();
      final intensity0LayerId = MapLayerIds.intensity0();
      final boxLayerId = MapLayerIds.box();
      final hasBox = GlobalProviders.data.rts?.box.isNotEmpty ?? false;

      await controller.setLayerVisibility(rtsLayerId, !hasBox);
      await controller.setLayerVisibility(intensityLayerId, hasBox);
      await controller.setLayerVisibility(intensity0LayerId, hasBox);
      await controller.setLayerVisibility(boxLayerId, hasBox);
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager._updateLayerVisibility', e, s);
    }
  }

  Future<void> _updateRtsSource() async {
    if (!didSetup) return;

    try {
      final rtsSourceId = MapSourceIds.rts();
      final intensitySourceId = MapSourceIds.intensity();
      final intensity0SourceId = MapSourceIds.intensity0();
      final boxSourceId = MapSourceIds.box();

      final isRtsSourceExists = (await controller.getSourceIds()).contains(rtsSourceId);
      final isIntensitySourceExists = (await controller.getSourceIds()).contains(intensitySourceId);
      final isIntensity0SourceExists = (await controller.getSourceIds()).contains(intensity0SourceId);
      final isBoxSourceExists = (await controller.getSourceIds()).contains(boxSourceId);

      if (isRtsSourceExists) {
        final data = GlobalProviders.data.getRtsGeoJson();
        await controller.setGeoJsonSource(rtsSourceId, data);
        TalkerManager.instance.info('Updated RTS source data for time: ${currentRtsTime.value}');
      }

      if (isIntensitySourceExists) {
        final data = GlobalProviders.data.getIntensityGeoJson();
        await controller.setGeoJsonSource(intensitySourceId, data);
        TalkerManager.instance.info('Updated Intensity source data for time: ${currentRtsTime.value}');
      }

      if (isIntensity0SourceExists) {
        final data = GlobalProviders.data.getIntensityGeoJson();
        await controller.setGeoJsonSource(intensity0SourceId, data);
        TalkerManager.instance.info('Updated Intensity0 source data for time: ${currentRtsTime.value}');
      }

      if (isBoxSourceExists) {
        final data = GlobalProviders.data.getBoxGeoJson();
        await controller.setGeoJsonSource(boxSourceId, data);
        TalkerManager.instance.info('Updated Box source data for time: ${currentRtsTime.value}');
      }
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager._updateRtsSource', e, s);
    }
  }

  Future<void> _updateEewSource() async {
    if (!didSetup) return;

    try {
      final sourceId = MapSourceIds.eew();

      final data = GlobalProviders.data.getEewGeoJson();

      // TODO(kamiya4047): needs further optimization
      await controller.setGeoJsonSource(sourceId, data);
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager._updateEewSource', e, s);
    }
  }

  @override
  Future<void> hide() async {
    if (!visible) return;

    final rtsLayerId = MapLayerIds.rts();
    final intensityLayerId = MapLayerIds.intensity();
    final intensity0LayerId = MapLayerIds.intensity0();
    final boxLayerId = MapLayerIds.box();

    final epicenterLayerId = MapLayerIds.eew('x');
    final pWaveLayerId = MapLayerIds.eew('p');
    final sWaveLayerId = MapLayerIds.eew('s');

    try {
      // rts
      await controller.setLayerVisibility(rtsLayerId, false);
      TalkerManager.instance.info('Hiding Layer "$rtsLayerId"');

      // intensity
      await controller.setLayerVisibility(intensityLayerId, false);
      TalkerManager.instance.info('Hiding Layer "$intensityLayerId"');
      await controller.setLayerVisibility(intensity0LayerId, false);
      TalkerManager.instance.info('Hiding Layer "$intensity0LayerId"');
      await controller.setLayerVisibility(boxLayerId, false);
      TalkerManager.instance.info('Hiding Layer "$boxLayerId"');

      // eew
      await controller.setLayerVisibility(epicenterLayerId, false);
      TalkerManager.instance.info('Hiding Layer "$epicenterLayerId"');
      await controller.setLayerVisibility(pWaveLayerId, false);
      TalkerManager.instance.info('Hiding Layer "$pWaveLayerId"');
      await controller.setLayerVisibility(sWaveLayerId, false);
      TalkerManager.instance.info('Hiding Layer "$sWaveLayerId"');

      visible = false;
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (visible) return;

    final rtsLayerId = MapLayerIds.rts();
    final intensityLayerId = MapLayerIds.intensity();
    final intensity0LayerId = MapLayerIds.intensity0();
    final boxLayerId = MapLayerIds.box();
    final epicenterLayerId = MapLayerIds.eew('x');
    final pWaveLayerId = MapLayerIds.eew('p');
    final sWaveLayerId = MapLayerIds.eew('s');

    try {
      final hasBox = GlobalProviders.data.rts?.box.isNotEmpty ?? false;

      await controller.setLayerVisibility(rtsLayerId, !hasBox);
      TalkerManager.instance.info('Showing Layer "$rtsLayerId"');

      await controller.setLayerVisibility(intensityLayerId, hasBox);
      TalkerManager.instance.info('Showing Layer "$intensityLayerId"');
      await controller.setLayerVisibility(intensity0LayerId, hasBox);
      TalkerManager.instance.info('Showing Layer "$intensity0LayerId"');
      await controller.setLayerVisibility(boxLayerId, hasBox);
      TalkerManager.instance.info('Showing Layer "$boxLayerId"');

      await controller.setLayerVisibility(epicenterLayerId, true);
      TalkerManager.instance.info('Showing Layer "$epicenterLayerId"');
      await controller.setLayerVisibility(pWaveLayerId, true);
      TalkerManager.instance.info('Showing Layer "$pWaveLayerId"');
      await controller.setLayerVisibility(sWaveLayerId, true);
      TalkerManager.instance.info('Showing Layer "$sWaveLayerId"');

      await _focus();

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
    GlobalProviders.data.setReplayMode(false);
    GlobalProviders.data.removeListener(_onDataChanged);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
