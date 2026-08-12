/// A numerical weather prediction (數值預報) wind-field raster overlay — the
/// ECMWF or GFS model rendered as a coloured speed field on the map.
library;

import 'dart:async';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/map/presentation/layers/admin_outline_chrome.dart';
import 'package:dpip/features/map/presentation/widgets/forecast_overlay_menu.dart';
import 'package:dpip/features/map/presentation/widgets/wind_particle_overlay.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:dpip/features/weather/domain/wind_forecast_model.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The wind forecast (風場) raster overlay for one model.
///
/// Everything about scrubbing lives in [RasterTimelineLayer]; this supplies the
/// model's identity, its opacity, the shared wind-speed colour key, the two
/// admin-border overlays its options chip toggles ([AdminOutlineChrome]), and
/// the particle animation ([WindParticleOverlay]) that rides the loaded
/// [field].
///
/// The tiles are a semi-transparent speed wash, so the layer draws its own
/// county / township borders **over** the field the same way radar does over
/// its echo. The 0.25° grids stop publishing tiles at zoom 7, so the view is
/// capped there too — past it there is nothing further to see, only the same
/// cell drawn larger ([satellite-tiles-go/web/index.html]).
class WindForecastMapLayer extends RasterTimelineLayer with AdminOutlineChrome {
  WindForecastMapLayer(
    WindForecastRepository super.repository, {
    required this.model,
  });

  final WindForecastModel model;

  /// The wind grid backing the overlay's particles, reloaded on every shown
  /// frame. Null until the first frame's field arrives; the overlay starts its
  /// animation only once this is set.
  final ValueNotifier<WindField?> field = ValueNotifier(null);

  String? _loadedFieldFrame;

  /// The live map controller — shared with the particle overlay, which reads
  /// the camera from it every frame.
  MapLibreMapController? get mapController => controller;

  @override
  Future<void> show(
    MapLibreMapController controller,
    MapFrame frame, {
    bool scrubbing = false,
  }) async {
    await super.show(controller, frame, scrubbing: scrubbing);
    await _loadField(frame.id);
  }

  /// This layer's wind repository — [RasterTimelineLayer] only knows it as a
  /// [RasterFrameSource], so the call site narrows it back to the declared
  /// [WindForecastRepository] type.
  WindForecastRepository get _wind => source as WindForecastRepository;

  /// Fetches the WND1 grid for [frameId] and publishes it to [field]. A failed
  /// fetch keeps the previous field — scrubbing through a gap shows the last
  /// known wind rather than a blank — and rolls the guard back so the next
  /// show of this frame retries instead of skipping it forever.
  Future<void> _loadField(String frameId) async {
    if (frameId == _loadedFieldFrame) return;
    _loadedFieldFrame = frameId;
    final result = await _wind.fetchWindField(frameId);
    result.when(
      ok: (windField) => field.value = windField,
      err: (failure) {
        Log.warning('Wind field for $frameId failed: ${failure.message}');
        _loadedFieldFrame = null;
      },
    );
  }

  @override
  Future<void> onDetached(MapLibreMapController controller) async {
    await super.onDetached(controller);
    // The overlay is gone with the layer; stop advertising a field so a
    // re-attach starts clean rather than animating yesterday's grid.
    field.value = null;
    _loadedFieldFrame = null;
  }

  @override
  Widget buildMapOverlay(BuildContext context) =>
      WindParticleOverlay(layer: this);

  @override
  String get id => 'wind-${model.key}';

  @override
  IconData get icon => Icons.air;

  @override
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (model) {
      WindForecastModel.ecmwf => l10n.mapLayerWindForecastEcmwf,
      WindForecastModel.gfs => l10n.mapLayerWindForecastGfs,
    };
  }

  @override
  String? subtitle(BuildContext context) => model.subtitle;

  /// The tile colours carry their own alpha — the field is a semi-transparent
  /// wash, not an opaque sheet.
  @override
  double get opacity => 1.0;

  /// The field covers the base style's borders, so this layer supplies its own
  /// on top — same reasoning as radar.
  @override
  String? get rasterBelowLayerId => null;

  /// The frame times are forecast valid times, not observations — the timeline
  /// caption must say so instead of the shared "observed" default.
  @override
  String timelineCaption(BuildContext context) =>
      AppLocalizations.of(context).mapTimelineForecast;

  /// The wind endpoints serve one model run at a time (older runs' frames 404),
  /// so the oldest frame is the run's issue time — the timeline can name when
  /// this forecast was actually produced.
  @override
  bool get framesAreOneRun => true;

  /// Basin-wide framing — the wind view starts a level below radar's floor so
  /// a whole typhoon-scale system fits.
  @override
  double get mapMinZoom => 3;

  /// The 0.25° grids stop publishing tiles at zoom 7; capping the view keeps
  /// the user from zooming into a detail the model never had.
  @override
  double get mapMaxZoom => 7;

  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required ValueListenable<bool> showTerrain,
    required ValueChanged<bool> onShowTerrainChanged,
    required Future<void> Function() onReloadActive,
  }) => ForecastOverlayMenu(
    layer: this,
    showTownLabels: showTownLabels,
    onShowTownLabelsChanged: onShowTownLabelsChanged,
    showTerrain: showTerrain,
    onShowTerrainChanged: onShowTerrainChanged,
  );

  @override
  Widget buildLegend(BuildContext context) => ListenableBuilder(
    listenable: adminChromeListenable,
    builder: (context, _) {
      return MapLegendCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The ramp is fixed in m/s, so the legend is drawn once and stays
            // true for every frame and both models — the same decision as
            // `satellite-tiles-go/web/wind.js` (SPEED_COLORS / SPEED_SCALE).
            const ColorScaleLegend(
              unit: 'm/s',
              stops: [
                (0, '#282C6E'),
                (2, '#3056A8'),
                (4, '#348CBA'),
                (6, '#40B296'),
                (8, '#68C45E'),
                (11, '#B0D048'),
                (14, '#E2BE4A'),
                (17, '#E28C42'),
                (21, '#D6543C'),
                (25, '#BA3478'),
                (28, '#9E3CB4'),
                (32, '#EED6FF'),
              ],
            ),
            adminLegendSection(context),
          ],
        ),
      );
    },
  );
}
