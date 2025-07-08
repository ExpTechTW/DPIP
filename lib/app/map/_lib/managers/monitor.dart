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
  MonitorMapLayerManager(super.context, super.controller);

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

      final eewSourceId = MapSourceIds.eew();
      final epicenterLayerId = MapLayerIds.eew('x');
      final pWaveLayerId = MapLayerIds.eew('p');
      final sWaveLayerId = MapLayerIds.eew('s');

      final isRtsSourceExists = sources.contains(rtsSourceId);
      final isRtsLayerExists = layers.contains(rtsLayerId);
      final isEewSourceExists = sources.contains(eewSourceId);
      final isEewLayerExists =
          layers.contains(epicenterLayerId) && layers.contains(pWaveLayerId) && layers.contains(sWaveLayerId);

      if (!context.mounted) return;

      if (!isRtsSourceExists) {
        final data = GlobalProviders.data.getRtsGeoJson();
        final properties = GeojsonSourceProperties(data: data);

        await controller.addSource(rtsSourceId, properties);
        TalkerManager.instance.info('Added Source "$rtsSourceId"');

        if (!context.mounted) return;
      }

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

        if (!context.mounted) return;
      }

      if (!isEewSourceExists) {
        final data = GlobalProviders.data.getEewGeoJson();
        final properties = GeojsonSourceProperties(data: data);

        await controller.addSource(eewSourceId, properties);
        TalkerManager.instance.info('Added Source "$eewSourceId"');

        if (!context.mounted) return;
      }

      if (!isEewLayerExists) {
        final epicenterProperties = SymbolLayerProperties(
          iconImage: 'cross-7',
          iconSize: kSymbolIconSize,
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          symbolZOrder: 'source',
          visibility: visible ? 'visible' : 'none',
        );
        final pWaveProperties = LineLayerProperties(
          lineColor: Colors.cyan.toHexStringRGB(),
          lineWidth: 2,
          visibility: visible ? 'visible' : 'none',
        );
        final sWaveProperties = LineLayerProperties(
          lineColor: Colors.red.toHexStringRGB(),
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
    }
  }

  Future<void> _updateRtsSource() async {
    if (!didSetup) return;

    try {
      final sourceId = MapSourceIds.rts();

      final isSourceExists = (await controller.getSourceIds()).contains(sourceId);

      if (isSourceExists) {
        final data = GlobalProviders.data.getRtsGeoJson();
        await controller.setGeoJsonSource(sourceId, data);
        TalkerManager.instance.info('Updated RTS source data for time: ${currentRtsTime.value}');
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

    final epicenterLayerId = MapLayerIds.eew('x');
    final pWaveLayerId = MapLayerIds.eew('p');
    final sWaveLayerId = MapLayerIds.eew('s');

    try {
      // rts
      await controller.setLayerVisibility(rtsLayerId, false);
      TalkerManager.instance.info('Hiding Layer "$rtsLayerId"');

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
    final epicenterLayerId = MapLayerIds.eew('x');
    final pWaveLayerId = MapLayerIds.eew('p');
    final sWaveLayerId = MapLayerIds.eew('s');

    try {
      await controller.setLayerVisibility(rtsLayerId, true);
      TalkerManager.instance.info('Showing Layer "$rtsLayerId"');

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
    GlobalProviders.data.removeListener(_onDataChanged);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
