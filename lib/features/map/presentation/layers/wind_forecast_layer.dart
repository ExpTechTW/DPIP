/// A numerical weather prediction (數值預報) wind-field raster overlay — the
/// ECMWF or GFS model rendered as a coloured speed field on the map.
library;

import 'dart:async';

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/settings/map_reference_outline_controller.dart';
import 'package:dpip/features/map/presentation/layers/admin_outline_chrome.dart';
import 'package:dpip/features/map/presentation/widgets/forecast_overlay_menu.dart';
import 'package:dpip/features/map/presentation/layers/wind_particle_native.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:dpip/features/weather/domain/wind_forecast_model.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart' show townLabelLayerId;
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
/// the particle animation — native on Android and iOS
/// ([WindParticleNative]) — driven by the
/// loaded [field].
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
    required this.referenceOutline,
  });

  final WindForecastModel model;

  @override
  final MapReferenceOutlineController referenceOutline;

  /// The wind grid backing the overlay's particles, loaded for the settled
  /// frame. It stays null while the timeline is moving and until that frame's
  /// field arrives; the overlay starts its animation only once this is set.
  final ValueNotifier<WindField?> field = ValueNotifier(null);

  /// The GPU renderer that draws the particles inside the map.
  ///
  /// Where it is available the map draws the particles itself. On
  /// Android that is not a preference but the leak escape: a Flutter overlay
  /// repainting above a platform view leaks a full-screen graphics buffer per
  /// frame under HCPP, and the particles were the only thing in the app
  /// repainting every frame. iOS has no leak, but the same native path is where
  /// map content belongs and keeps one wire for both.
  late final WindParticleNative particles = WindParticleNative(
    field: field,
    interacting: interacting,
  );

  bool _particlesAttached = false;

  /// Whether a finger is currently on the map.
  ///
  /// The particle field is torn down for the whole gesture and reseeded when it
  /// ends. That is cheaper *and* more correct than animating through it: the
  /// population size is a function of zoom, so a pinch re-sizes it on every
  /// frame of the gesture — growing it seeds particles into a viewport that is
  /// still moving, shrinking it truncates the list — and the field arrives at
  /// the final zoom carrying whatever that churn produced. Starting again from
  /// the camera the gesture settled on costs one reseed and is always right.
  final ValueNotifier<bool> interacting = ValueNotifier(false);

  @override
  void onMapGestureStart() => interacting.value = true;

  @override
  void onMapGestureEnd() => interacting.value = false;

  String? _loadedFieldFrame;
  String? _requestedFieldFrame;
  int _fieldGeneration = 0;

  /// The live map controller — shared with the particle overlay, which reads
  /// the camera from it every frame.
  MapLibreMapController? get mapController => controller;

  /// Attaches the native renderer the first time a controller is in hand.
  ///
  /// Lazily rather than in a constructor: the layer outlives any one platform
  /// view, and a controller that has been replaced must not keep a layer bound
  /// to the old one.
  void _ensureParticles(MapLibreMapController controller) {
    if (_particlesAttached || !particles.isSupported) return;
    _particlesAttached = true;
    particles.attach(controller);
  }

  @override
  Future<void> show(
    MapLibreMapController controller,
    MapFrame frame, {
    bool scrubbing = false,
  }) async {
    _ensureParticles(controller);
    if (scrubbing) {
      // A megabyte-scale WND1 grid per crossed frame cannot keep up with a
      // finger. More importantly, displaying the previous grid under a new
      // raster lies about which forecast is driving the particles. Keep them
      // absent for the drag and load only the frame the user finally settles on.
      _invalidateField();
      await super.show(controller, frame, scrubbing: true);
      return;
    }

    final fieldMatches = _loadedFieldFrame == frame.id;
    final requestMatches = _requestedFieldFrame == frame.id;
    if (!fieldMatches && !requestMatches) _invalidateField();
    await super.show(controller, frame, scrubbing: scrubbing);
    if (_loadedFieldFrame != frame.id && _requestedFieldFrame != frame.id) {
      // Raster ordering stays on MapScaffold's serial lane; the large binary
      // fetch does not. A generation check below prevents its late response
      // from publishing after the user has moved elsewhere.
      unawaited(_loadField(frame.id));
    }
  }

  /// This layer's wind repository — [RasterTimelineLayer] only knows it as a
  /// [RasterFrameSource], so the call site narrows it back to the declared
  /// [WindForecastRepository] type.
  WindForecastRepository get _wind => source as WindForecastRepository;

  /// Fetches the WND1 grid for [frameId] and publishes it to [field]. A failed
  /// fetch leaves particles absent and rolls the guard back so showing this
  /// frame again retries instead of skipping it forever.
  Future<void> _loadField(String frameId) async {
    if (frameId == _loadedFieldFrame || frameId == _requestedFieldFrame) return;
    final generation = ++_fieldGeneration;
    _requestedFieldFrame = frameId;
    final result = await _wind.fetchWindField(frameId);
    if (generation != _fieldGeneration || _requestedFieldFrame != frameId) {
      return;
    }
    _requestedFieldFrame = null;
    result.when(
      ok: (windField) {
        _loadedFieldFrame = frameId;
        field.value = windField;
      },
      err: (failure) {
        Log.warning('Wind field for $frameId failed: ${failure.message}');
        _loadedFieldFrame = null;
      },
    );
  }

  void _invalidateField() {
    if (_requestedFieldFrame == null &&
        _loadedFieldFrame == null &&
        field.value == null) {
      return;
    }
    _fieldGeneration++;
    _requestedFieldFrame = null;
    _loadedFieldFrame = null;
    if (field.value != null) field.value = null;
  }

  @override
  Future<void> onDetached(MapLibreMapController controller) async {
    await super.onDetached(controller);
    // The overlay is gone with the layer; stop advertising a field so a
    // re-attach starts clean rather than animating yesterday's grid.
    _invalidateField();
    _particlesAttached = false;
    await particles.detach();
  }

  @override
  void onSurfaceVisibility(bool visible) {
    super.onSurfaceVisibility(visible);
    particles.setSurfaceVisible(visible);
  }

  /// Nothing. The particles are map content now, on every platform.
  ///
  /// There used to be a Flutter-drawn CPU fallback here for anywhere the
  /// native layer could not run. It is gone, and its absence is deliberate:
  /// two renderers behind one feature name meant a platform could quietly be
  /// showing something else entirely. Days were spent comparing "iOS" against
  /// "Android" before the logs revealed that the iOS side was the Simulator
  /// running the fallback while Android ran the real one — the two were never
  /// the same picture, and no amount of tuning was going to align them.
  ///
  /// Where the native layer cannot run, the field renders without particles.
  /// The colour ramp still carries the wind speed, which is the information;
  /// a wrong animation is worse than none.
  @override
  Widget buildMapOverlay(BuildContext context) => const SizedBox.shrink();

  /// The particle overlay reads the live camera on every tick, so it never
  /// needs a rebuild to reproject — and it must not get one: re-keying it on
  /// each camera settle tore down the ticker, reseeded the whole particle
  /// field and threw away the trail buffer on every pan, zoom and tap.
  @override
  bool get overlayFollowsCamera => false;

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
  /// on top — same reasoning as radar. The raster still anchors **under** the
  /// township-name labels, so a place name is never buried under the field; the
  /// admin borders redraw between the two (they mount after the raster, closer
  /// to the labels — see [AdminOutline]).
  @override
  String? get rasterBelowLayerId => townLabelLayerId;

  /// The frame times are forecast valid times, not observations — the timeline
  /// caption must say so instead of the shared "observed" default.
  @override
  String timelineCaption(BuildContext context) =>
      AppLocalizations.of(context).mapTimelineForecast;

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
            //
            // Deliberately *not* corrected for colour vision: the field itself
            // is a server-rendered raster whose pixels MapLibre cannot
            // recolour, so a daltonised key would name colours that are not on
            // the map. The stops stay the tiles' own colours — see
            // [ColorVisionFilter.rasterExemptHex].
            ColorScaleLegend(
              unit: 'm/s',
              stops: <ColorStop>[
                (0, ColorVisionFilter.rasterExemptHex('#282C6E')),
                (2, ColorVisionFilter.rasterExemptHex('#3056A8')),
                (4, ColorVisionFilter.rasterExemptHex('#348CBA')),
                (6, ColorVisionFilter.rasterExemptHex('#40B296')),
                (8, ColorVisionFilter.rasterExemptHex('#68C45E')),
                (11, ColorVisionFilter.rasterExemptHex('#B0D048')),
                (14, ColorVisionFilter.rasterExemptHex('#E2BE4A')),
                (17, ColorVisionFilter.rasterExemptHex('#E28C42')),
                (21, ColorVisionFilter.rasterExemptHex('#D6543C')),
                (25, ColorVisionFilter.rasterExemptHex('#BA3478')),
                (28, ColorVisionFilter.rasterExemptHex('#9E3CB4')),
                (32, ColorVisionFilter.rasterExemptHex('#EED6FF')),
              ],
            ),
            adminLegendSection(context),
          ],
        ),
      );
    },
  );
}
