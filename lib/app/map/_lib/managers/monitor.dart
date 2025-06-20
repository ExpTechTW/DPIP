import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/app/map/_lib/manager.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/instrumental_intensity_color.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/widgets/map/map.dart';

class MonitorMapLayerManager extends MapLayerManager {
  MonitorMapLayerManager(super.context, super.controller);

  final currentRtsTime = ValueNotifier<String?>(GlobalProviders.data.rts?.time.toString());
  final isLoading = ValueNotifier<bool>(false);

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
      final sourceId = MapSourceIds.rts();
      final layerId = MapLayerIds.rts();

      final isSourceExists = (await controller.getSourceIds()).contains(sourceId);
      final isLayerExists = (await controller.getLayerIds()).contains(layerId);

      if (isSourceExists && isLayerExists) return;
      if (!context.mounted) return;

      if (!isSourceExists) {
        final data = GlobalProviders.data.getRtsGeoJson();
        final properties = GeojsonSourceProperties(data: data);

        await controller.addSource(sourceId, properties);
        TalkerManager.instance.info('Added Source "$sourceId"');

        if (!context.mounted) return;
      }

      if (!isLayerExists) {
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

        await controller.addLayer(sourceId, layerId, properties, belowLayerId: BaseMapLayerIds.userLocation);
        TalkerManager.instance.info('Added Layer "$layerId"');
      }

      didSetup = true;

      GlobalProviders.data.addListener(_onRtsDataChanged);
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager.setup', e, s);
    }
  }

  void _onRtsDataChanged() {
    final newRts = GlobalProviders.data.rts;
    final newTime = newRts?.time.toString();

    if (newTime != currentRtsTime.value) {
      currentRtsTime.value = newTime;
      _updateRtsSource();
    }
  }

  Future<void> _updateRtsSource() async {
    if (!didSetup || isLoading.value) return;

    isLoading.value = true;

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
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> hide() async {
    if (!visible) return;

    final layerId = MapLayerIds.rts();

    try {
      await controller.setLayerVisibility(layerId, false);
      TalkerManager.instance.info('Hiding Layer "$layerId"');

      visible = false;
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager.hide', e, s);
    }
  }

  @override
  Future<void> show() async {
    if (visible) return;

    final layerId = MapLayerIds.rts();

    try {
      await controller.setLayerVisibility(layerId, true);
      TalkerManager.instance.info('Showing Layer "$layerId"');

      await _focus();

      visible = true;
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager.show', e, s);
    }
  }

  @override
  Future<void> remove() async {
    final sourceId = MapSourceIds.rts();
    final layerId = MapLayerIds.rts();

    try {
      await controller.removeLayer(layerId);
      TalkerManager.instance.info('Removed Layer "$layerId"');

      await controller.removeSource(sourceId);
      TalkerManager.instance.info('Removed Source "$sourceId"');
    } catch (e, s) {
      TalkerManager.instance.error('MonitorMapLayerManager.dispose', e, s);
    }

    didSetup = false;
  }

  @override
  void dispose() {
    GlobalProviders.data.removeListener(_onRtsDataChanged);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
