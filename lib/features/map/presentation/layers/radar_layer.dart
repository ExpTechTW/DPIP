import 'dart:async';

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/settings/map_reference_outline_controller.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/map/presentation/layers/admin_outline_chrome.dart';
import 'package:dpip/features/map/presentation/layers/lightning_strike_overlay.dart';
import 'package:dpip/features/map/presentation/layers/radar_scan_range.dart';
import 'package:dpip/features/map/presentation/layers/scan_range_overlay_chrome.dart';
import 'package:dpip/features/map/presentation/layers/wind_arrow_overlay.dart';
import 'package:dpip/features/map/presentation/widgets/radar_overlay_menu.dart';
import 'package:dpip/features/weather/domain/meteor_lightning_repository.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart' show townLabelLayerId;
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The radar echo (雷達回波) raster overlay.
///
/// Everything about scrubbing — the preload ring, tile warming, scoped cancels —
/// lives in [RasterTimelineLayer]; this supplies only radar's identity, its
/// opacity, the dBZ colour key, and the overlays its options chip toggles.
///
/// The echo is mounted **above** the base style's borders (see
/// [rasterBelowLayerId]) and the borders are put back on top as switchable
/// layers ([ScanRangeOverlayChrome]). That is what makes them switchable at
/// all: while they came through from underneath there was no way to get an
/// uninterrupted raster.
///
/// The options chip also carries two **data** overlays: the **lightning**
/// strikes of the frame the echo is showing, drawn by the same
/// [LightningStrikeOverlay] the standalone 閃電 layer uses, and the station
/// **wind** arrows of that same frame, drawn by the same [WindArrowOverlay] the
/// standalone 風向 layer uses. Both follow the timeline rather than the wall
/// clock — scrubbing back an hour moves the marks back with the echo — which is
/// the whole point of putting them here instead of asking the user to compare
/// two layers by memory.
///
/// The two feeds run on their own clocks, so "the same frame" is resolved per
/// overlay rather than assumed: strikes take the snapshot nearest the frame
/// ([_lightningTolerance]), hourly observations the one in effect at it
/// ([_windMaxAge]).
///
/// **At most one of the two is ever on.** Strikes and arrows are both dense
/// point marks over the whole island at the same on-screen size, so together
/// they cover each other and the echo underneath; switching one on therefore
/// switches the other off rather than offering a third, unreadable, state.
class RadarMapLayer extends RasterTimelineLayer
    with AdminOutlineChrome, ScanRangeOverlayChrome {
  RadarMapLayer(
    RadarRepository super.repository,
    this.referenceOutline, {
    required MeteorLightningRepository lightning,
    required MeteorWeatherRepository weather,
    required SettingsStore settings,
  }) : _settings = settings,
       _lightning = LightningStrikeOverlay(
         lightning,
         namespace: 'radar-lightning',
       ),
       _wind = WindArrowOverlay(weather, namespace: 'radar-wind'),
       showLightning = ValueNotifier(
         settings.getBool(SettingKeys.mapRadarShowLightning) ?? false,
       ),
       // A stored `true` on both (an older build, a hand-edited store) would
       // mount two overlays the UI can only describe as one, so lightning —
       // the older option — wins and wind stays off until it is asked for.
       showWind = ValueNotifier(
         (settings.getBool(SettingKeys.mapRadarShowWind) ?? false) &&
             !(settings.getBool(SettingKeys.mapRadarShowLightning) ?? false),
       );

  @override
  final MapReferenceOutlineController referenceOutline;

  final SettingsStore _settings;

  /// The strike marks, on this layer's own source/layer ids so mounting them
  /// here can never collide with the standalone 閃電 layer's mount.
  final LightningStrikeOverlay _lightning;

  /// The wind arrows, likewise on this layer's own ids so they cannot collide
  /// with the standalone 風向 layer's mount.
  final WindArrowOverlay _wind;

  /// Whether the echo also draws its frame's strikes. Persisted, and off by
  /// default: the echo alone is what a reader came for, and every extra mark
  /// on it is one the reader did not ask for.
  final ValueNotifier<bool> showLightning;

  /// Whether the echo also draws its frame's station wind arrows. Same default
  /// and same reason as [showLightning]; never on at the same time as it.
  final ValueNotifier<bool> showWind;

  /// The lightning / weather snapshot times (Unix seconds, ascending) each
  /// overlay can be asked for — the radar timeline has its own, coarser steps,
  /// so the lists are matched by [_nearestId] rather than assumed aligned.
  List<int> _lightningSeconds = const [];
  List<int> _windSeconds = const [];

  /// How far a strike snapshot may sit from the radar frame and still be drawn
  /// on it.
  ///
  /// The radar composite publishes every ten minutes and the strike snapshots
  /// every five, so an exact match is not on offer and some slack is required —
  /// but only that much. Beyond this the overlay draws nothing rather than
  /// something: strikes half an hour out of step with the echo under them are
  /// not a slightly stale picture, they are a different storm.
  static const Duration _lightningTolerance = Duration(minutes: 10);

  /// How old the station observation drawn on a radar frame may be.
  ///
  /// The observation feed is **hourly** — `/meteor/weather/list` steps in
  /// 3600s, and even `latest` lands on the hour — against the echo's ten
  /// minutes. Matched the way the strikes are, nearest-within-ten-minutes, five
  /// of every six frames would have no observation near enough and the arrows
  /// would blink out for most of a scrub. So wind is matched the way an hourly
  /// reading actually applies: each frame draws the newest observation taken
  /// **at or before** it, which is the wind that was blowing under that echo,
  /// and stays drawn until the next hour's reading replaces it. This bounds how
  /// far that can be stretched — a gap in the feed must still go blank rather
  /// than paint two-hour-old wind over a live echo.
  static const Duration _windMaxAge = Duration(hours: 1);

  /// Serialises **both** overlays' map mutations. A scrub can deliver frames
  /// faster than a fetch completes, and two interleaved `setGeoJsonSource`
  /// calls on one source leave whichever finished last on screen — not
  /// whichever frame the timeline is actually on. One chain rather than two,
  /// because switching overlays queues a clear of one and a draw of the other,
  /// and those must not interleave either.
  Future<void> _overlayChain = Future<void>.value();

  /// The controller this layer is mounted on, and the frame it was last asked
  /// to show — what a data toggle needs to catch up to the echo the moment it
  /// is switched on, rather than at the next timeline step.
  MapLibreMapController? _controller;
  MapFrame? _currentFrame;

  /// The radar composite's own ids — the default geometry and layer naming.
  @override
  String get scanRangeSourceId => RadarScanRange.sourceId;

  @override
  String get scanRangeLayerId => RadarScanRange.outlineLayerId;

  @override
  String get scanRangeColor => _rangeColor;

  /// Blue-grey: distinct from every dBZ colour in the scale below, so the
  /// outline is never mistaken for an echo.
  ///
  /// A vector line this app draws, so it *is* colour-vision corrected — unlike
  /// the dBZ scale below. A getter rather than a `const` because the correction
  /// depends on the current setting.
  static String get _rangeColor => '#78909C'.vision;

  /// The echo covers the base style's borders instead of passing under them —
  /// this layer supplies its own on top, and showing both would draw every
  /// boundary twice at two weights. The raster still anchors **under** the
  /// township-name labels, so a place name is never buried under the echo;
  /// the admin borders this layer redraws sit between the two (they mount
  /// after the raster, closer to the labels — see [AdminOutline]).
  @override
  String? get rasterBelowLayerId => townLabelLayerId;

  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required ValueListenable<bool> showTerrain,
    required ValueChanged<bool> onShowTerrainChanged,
    required Future<void> Function() onReloadActive,
  }) => RadarOverlayMenu(
    layer: this,
    showTownLabels: showTownLabels,
    onShowTownLabelsChanged: onShowTownLabelsChanged,
    showTerrain: showTerrain,
    onShowTerrainChanged: onShowTerrainChanged,
  );

  @override
  String get id => 'radar';

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerRadar;

  @override
  IconData get icon => Icons.radar_outlined;

  /// Slightly translucent so terrain and boundaries read through the echo.
  @override
  double get opacity => 0.85;

  /// The dBZ key — CWA's own echo palette.
  ///
  /// **Deliberately not colour-vision corrected.** The echo is a
  /// server-rendered raster and MapLibre's raster layer exposes no colour
  /// matrix, so those pixels keep their original hues; correcting the key would
  /// leave it naming colours that are nowhere on the map, which is worse than a
  /// key that is merely hard to read. Every stop is therefore marked
  /// [ColorVisionFilter.rasterExemptHex] rather than left looking overlooked.
  static final List<ColorStop> _dbzStops = [
    (0, ColorVisionFilter.rasterExemptHex('#00FFFF')),
    (5, ColorVisionFilter.rasterExemptHex('#00A3FF')),
    (10, ColorVisionFilter.rasterExemptHex('#005BFF')),
    (15, ColorVisionFilter.rasterExemptHex('#0000FF')),
    (20, ColorVisionFilter.rasterExemptHex('#00D300')),
    (25, ColorVisionFilter.rasterExemptHex('#00A000')),
    (30, ColorVisionFilter.rasterExemptHex('#CCEA00')),
    (35, ColorVisionFilter.rasterExemptHex('#FFD300')),
    (40, ColorVisionFilter.rasterExemptHex('#FF8800')),
    (45, ColorVisionFilter.rasterExemptHex('#FF1800')),
    (50, ColorVisionFilter.rasterExemptHex('#D30000')),
    (55, ColorVisionFilter.rasterExemptHex('#A00000')),
    (60, ColorVisionFilter.rasterExemptHex('#EA00CC')),
    (65, ColorVisionFilter.rasterExemptHex('#9600FF')),
  ];

  /// The legend follows the data toggles too, so switching an overlay on brings
  /// its key with it.
  @override
  Listenable get chromeListenable =>
      Listenable.merge([super.chromeListenable, showLightning, showWind]);

  /// An overlay's key is appended only while its marks are actually drawn — a
  /// legend naming marks that are not on the map is worse than no legend. At
  /// most one of the two can be on, so at most one key is ever appended.
  @override
  List<SymbolLegendItem> chromeLegendItems(BuildContext context) => [
    ...super.chromeLegendItems(context),
    if (showLightning.value) ...LightningStrikeOverlay.legendItems(context),
    // With the unit, unlike the 風向 layer's own card: this key lands inside
    // the echo's legend under a dBZ scale, with nowhere else to say m/s.
    if (showWind.value)
      ...WindArrowOverlay.legendItems(context, withUnit: true),
  ];

  /// Turns the strike overlay on/off and remembers the choice. Switching it on
  /// switches the wind arrows off — see the class doc.
  void setShowLightning(bool value) {
    if (showLightning.value == value) return;
    if (value) _setShowWind(false);
    showLightning.value = value;
    unawaited(_settings.setBool(SettingKeys.mapRadarShowLightning, value));
    _syncOverlay(value, _applyLightning, _lightning.clear);
  }

  /// Turns the wind overlay on/off and remembers the choice. Switching it on
  /// switches the strikes off — see the class doc.
  void setShowWind(bool value) {
    if (showWind.value == value) return;
    if (value) setShowLightning(false);
    _setShowWind(value);
  }

  /// The wind half of [setShowWind], without the mutual-exclusion step — so
  /// [setShowLightning] can turn the arrows off without recursing back into it.
  void _setShowWind(bool value) {
    if (showWind.value == value) return;
    showWind.value = value;
    unawaited(_settings.setBool(SettingKeys.mapRadarShowWind, value));
    _syncOverlay(value, _applyWind, _wind.clear);
  }

  /// Queues the map work a toggle implies: catch [apply] up to the frame
  /// already on screen (the reader switched this on to see *this* echo's
  /// marks, not the next one's), or [teardown] the overlay.
  ///
  /// Silent with no controller — the layer is not on a map, and [render] mounts
  /// whatever is on when it next is.
  void _syncOverlay(
    bool value,
    Future<void> Function() apply,
    Future<void> Function(MapLibreMapController) teardown,
  ) {
    final controller = _controller;
    if (controller == null) return;
    _enqueueOverlay(value ? apply : () => teardown(controller));
  }

  @override
  Future<void> prepare(
    MapLibreMapController controller,
    List<MapFrame> frames,
  ) async {
    _controller = controller;
    await super.prepare(controller, frames);
    if (showLightning.value) _enqueueOverlay(_ensureLightningFrames);
    if (showWind.value) _enqueueOverlay(_ensureWindFrames);
  }

  @override
  Future<void> show(
    MapLibreMapController controller,
    MapFrame frame, {
    bool scrubbing = false,
  }) {
    _controller = controller;
    _currentFrame = frame;
    // Deliberately not awaited, and deliberately before the raster call: the
    // overlay marks are an extra on top of the echo, and making the echo's
    // reveal wait on their fetch would put a network round-trip inside a scrub.
    if (showLightning.value) {
      _enqueueOverlay(() => _applyLightning(scrubbing: scrubbing));
    }
    if (showWind.value) {
      _enqueueOverlay(() => _applyWind(scrubbing: scrubbing));
    }
    return super.show(controller, frame, scrubbing: scrubbing);
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    _currentFrame = null;
    _controller = null;
    await _lightning.clear(controller);
    await _wind.clear(controller);
    await super.clear(controller);
  }

  @override
  void onStyleReset() {
    _lightning.onStyleReset();
    _wind.onStyleReset();
    super.onStyleReset();
  }

  /// Runs [work] after whatever overlay work is already in flight.
  ///
  /// A scrub delivers frames faster than a snapshot fetch completes, and two
  /// overlapping `setGeoJsonSource` calls on one source leave whichever
  /// finished last on screen — not whichever frame the timeline is on.
  void _enqueueOverlay(Future<void> Function() work) {
    _overlayChain = _overlayChain.then((_) => work()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      Log.handle(error, stackTrace, 'radar data overlay');
    });
  }

  /// Loads the strike snapshot times once, and registers them with the overlay
  /// so it can prefetch around whatever frame is shown.
  Future<void> _ensureLightningFrames() async {
    final controller = _controller;
    if (controller == null || _lightningSeconds.isNotEmpty) return;
    final result = await _lightning.history();
    result.when(
      ok: (seconds) {
        _lightningSeconds = List<int>.of(seconds)..sort();
      },
      err: (failure) {
        // Left empty, so the next frame retries: the strike history is a
        // side dish here, and a failed fetch must not disable the toggle.
        Log.warning('radar lightning history: ${failure.message}');
      },
    );
    if (_lightningSeconds.isEmpty) return;
    await _lightning.prepare(controller, [
      for (final sec in _lightningSeconds) '$sec',
    ]);
  }

  /// Draws the strikes belonging to the frame the echo is showing.
  Future<void> _applyLightning({bool scrubbing = false}) async {
    if (!showLightning.value) return;
    await _ensureLightningFrames();
    final controller = _controller;
    final frame = _currentFrame;
    if (controller == null || !showLightning.value) return;

    final id = frame == null ? null : _nearestId(_lightningSeconds, frame.time);
    if (id == null) {
      // Mounted and empty rather than absent: "the overlay is on and this
      // frame has no matching strike data" is not the same as "off".
      await _lightning.showEmpty(controller);
      return;
    }
    await _lightning.show(controller, id, scrubbing: scrubbing);
  }

  /// Loads the observation snapshot times once, and registers them with the
  /// overlay so it can prefetch around whatever frame is shown.
  Future<void> _ensureWindFrames() async {
    final controller = _controller;
    if (controller == null || _windSeconds.isNotEmpty) return;
    final result = await _wind.history();
    result.when(
      ok: (seconds) {
        _windSeconds = List<int>.of(seconds)..sort();
      },
      err: (failure) {
        // Left empty, so the next frame retries: the observation history is a
        // side dish here, and a failed fetch must not disable the toggle.
        Log.warning('radar wind history: ${failure.message}');
      },
    );
    if (_windSeconds.isEmpty) return;
    await _wind.prepare(controller, [for (final sec in _windSeconds) '$sec']);
  }

  /// Draws the station wind belonging to the frame the echo is showing.
  Future<void> _applyWind({bool scrubbing = false}) async {
    if (!showWind.value) return;
    await _ensureWindFrames();
    final controller = _controller;
    final frame = _currentFrame;
    if (controller == null || !showWind.value) return;

    final id = frame == null ? null : _activeId(_windSeconds, frame.time);
    if (id == null) {
      // Mounted and empty — see [_applyLightning]. Reached only at the far end
      // of the timeline, where the echo predates the observation history, or
      // through a gap in the feed.
      await _wind.showEmpty(controller);
      return;
    }
    await _wind.show(controller, id, scrubbing: scrubbing);
  }

  /// The snapshot in [seconds] nearest [frameTime], or null when the closest
  /// one is further away than [_lightningTolerance].
  static String? _nearestId(List<int> seconds, DateTime frameTime) {
    if (seconds.isEmpty) return null;
    final target = frameTime.millisecondsSinceEpoch ~/ 1000;
    var best = seconds.first;
    var bestDelta = (best - target).abs();
    for (final sec in seconds) {
      final delta = (sec - target).abs();
      if (delta < bestDelta) {
        best = sec;
        bestDelta = delta;
      }
    }
    return bestDelta > _lightningTolerance.inSeconds ? null : '$best';
  }

  /// The newest snapshot in [seconds] taken **at or before** [frameTime] — the
  /// reading that was in effect when the frame was captured — or null when
  /// there is none, or the newest one is older than [_windMaxAge].
  ///
  /// Deliberately never the *nearest*: the snapshot after a frame was taken
  /// later than the echo under it, and drawing it would put a reading from the
  /// future on a past frame. Scrubbing back an hour must show the wind of an
  /// hour ago, not the wind that came next.
  static String? _activeId(List<int> seconds, DateTime frameTime) {
    final target = frameTime.millisecondsSinceEpoch ~/ 1000;
    int? best;
    for (final sec in seconds) {
      if (sec > target) continue;
      if (best == null || sec > best) best = sec;
    }
    if (best == null) return null;
    return target - best > _windMaxAge.inSeconds ? null : '$best';
  }

  @override
  Widget buildLegend(BuildContext context) => ListenableBuilder(
    listenable: chromeListenable,
    builder: (context, _) {
      return MapLegendCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColorScaleLegend(unit: 'dBZ', stops: _dbzStops),
            chromeLegendSection(context),
          ],
        ),
      );
    },
  );
}
