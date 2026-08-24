/// Drives the GPU wind-particle layer that lives inside the map.
library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/map/presentation/layers/wind_particle_sim.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Binds [WindForecastMapLayer]'s state to the native particle renderer.
///
/// The particles used to be a Flutter widget painted over the map. On Android
/// that is a leak with a stopwatch on it: HCPP allocates a full-screen graphics
/// buffer for every Flutter frame presented above a platform view and never
/// returns it, so a ticker-driven overlay took the process from 394 MB to
/// 8 GB of GPU memory in sixteen seconds. Drawn inside the map instead, the
/// particles produce no Flutter frame at all.
///
/// iOS draws inside the map too, through `MLNCustomStyleLayer`'s Metal encoder
/// (see `WindParticleEngine.swift` in the fork) — there was never a leak there,
/// but the same pass is where map content belongs, and one wire feeds both.
///
/// This class owns only the *conversation* with that renderer — when to add it,
/// what to upload, when to let it run. The simulation itself is gone from Dart;
/// [WindParticleSim] survives as the numeric oracle the native shaders are
/// checked against, not as something that runs in production.
class WindParticleNative {
  WindParticleNative({
    required this.field,
    required this.interacting,
    TargetPlatform? platform,
  }) : _platform = platform ?? defaultTargetPlatform;

  /// The grid to animate; null while the timeline moves or before it arrives.
  final ValueListenable<WindField?> field;

  /// Whether a finger is on the map.
  final ValueListenable<bool> interacting;

  final TargetPlatform _platform;

  MapLibreMapController? _controller;
  WindField? _uploaded;
  bool _added = false;
  bool _playing = false;
  bool _visible = true;
  bool _unavailable = false;

  /// Serialises every native call.
  ///
  /// Ordering is the whole contract here: an `add` that lands after its own
  /// `setField` uploads into a layer that does not exist yet, and a `remove`
  /// that overtakes a `setPlaying` leaves the map stuck in continuous
  /// rendering. Awaiting each call in turn is cheap — there are a handful per
  /// minute, none of them per frame.
  Future<void> _queue = Future<void>.value();

  /// Whether the native renderer is carrying the particles.
  ///
  /// False on platforms without it, and false after the device refused the
  /// layer — the caller falls back to its Flutter overlay rather than showing
  /// nothing.
  bool get isActive => _added && !_unavailable;

  /// Whether this platform should even try.
  ///
  /// Android and iOS. The Android path is the reason this class exists: the
  /// HCPP overlay leak lives in that platform's SurfaceControl, and the map's
  /// GL surface is where drawing costs nothing (see the native layer's class
  /// comment). iOS draws through `MLNCustomStyleLayer`'s Metal encoder in the
  /// map's own pass — same reasoning, no leak to escape — and arrived later;
  /// see `WindParticleEngine.swift` in the fork for how its passes are split.
  bool get isSupported =>
      _platform == TargetPlatform.android || _platform == TargetPlatform.iOS;

  void attach(MapLibreMapController controller) {
    if (!isSupported || _unavailable) return;
    _controller = controller;
    field.addListener(_onFieldChanged);
    interacting.addListener(_onInteractingChanged);
    _enqueue(() async {
      await controller.addWindParticleLayer();
      _added = true;
      await controller.setWindParticleTuning(
        windParticleTuning(pixelRatio: _devicePixelRatio()),
      );
      await _pushField(controller);
      await _pushPlaying(controller);
    });
  }

  /// Releases the native layer. Safe to call when nothing was ever added.
  Future<void> detach() async {
    field.removeListener(_onFieldChanged);
    interacting.removeListener(_onInteractingChanged);
    final controller = _controller;
    _controller = null;
    if (!_added || controller == null) {
      _added = false;
      _playing = false;
      _uploaded = null;
      return;
    }
    _added = false;
    _playing = false;
    _uploaded = null;
    _enqueue(() => controller.removeWindParticleLayer());
    await _queue;
  }

  /// The hosting surface was hidden or revealed.
  void setSurfaceVisible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    _sync();
  }

  void _onFieldChanged() {
    final controller = _controller;
    if (controller == null) return;
    _enqueue(() async {
      await _pushField(controller);
      await _pushPlaying(controller);
    });
  }

  void _onInteractingChanged() => _sync();

  void _sync() {
    final controller = _controller;
    if (controller == null) return;
    _enqueue(() => _pushPlaying(controller));
  }

  Future<void> _pushField(MapLibreMapController controller) async {
    final current = field.value;
    if (identical(current, _uploaded)) return;
    _uploaded = current;
    final payload = current == null ? null : windFieldPayload(current);
    if (payload == null) return;
    await controller.setWindParticleField(payload);
  }

  /// The animation runs only when there is something to animate and someone to
  /// see it. A gesture no longer stops it: the particle count is fixed on the
  /// GPU, so a pinch changes how many are drawn rather than reseeding the
  /// population, and there is nothing left for hiding them to protect.
  Future<void> _pushPlaying(MapLibreMapController controller) async {
    final want = _visible && _uploaded?.source != null;
    if (want == _playing) return;
    _playing = want;
    await controller.setWindParticlePlaying(want);
  }

  void _enqueue(Future<void> Function() action) {
    _queue = _queue.then((_) async {
      if (_unavailable) return;
      try {
        await action();
      } on PlatformException catch (error) {
        if (error.code == 'WIND_LAYER_UNAVAILABLE') {
          // The device cannot host the layer — texture mode is on, so the map
          // has no SurfaceView to draw into. Stop trying and let the caller
          // fall back; this is a configuration difference, not a failure.
          _unavailable = true;
          _added = false;
          Log.warning('Wind particle layer unavailable: ${error.message}');
          return;
        }
        Log.warning('Wind particle layer call failed: ${error.message}');
      } catch (error) {
        Log.warning('Wind particle layer call failed: $error');
      }
    });
  }
}

/// The display scale the point size is expressed in.
///
/// `pointSize` is tuned in logical pixels, but `gl_PointSize` is in physical
/// ones — on a 3x phone an unconverted value draws the field a third of its
/// intended weight, which reads as "the wind is faint today" rather than as a
/// bug. Read from the dispatcher rather than a `BuildContext` because the layer
/// attaches from a controller callback, where there is no element to look up.
double _devicePixelRatio() {
  final views = ui.PlatformDispatcher.instance.views;
  return views.isEmpty ? 1 : views.first.devicePixelRatio;
}

/// The zoom curves as their endpoints, in the wire's shape.
///
/// Sent whole so the numbers keep one home. Evaluating them per zoom in Dart
/// would put a platform call on the camera path — the exact per-frame traffic
/// this design exists to remove — and would leave two copies of the curve to
/// drift apart. `wind_particle_sim.dart` stays their definition; this is a
/// projection of it.
Map<String, double> windParticleTuning({double pixelRatio = 1}) => {
  'zoomLo': kWindZoomLo,
  'zoomHi': kWindZoomHi,
  'particlesLo': kWindParticles.$1,
  'particlesHi': kWindParticles.$2,
  'pointSizeLo': kWindPointSize.$1,
  'pointSizeHi': kWindPointSize.$2,
  'speedFactorLo': kWindSpeedFactor.$1,
  'speedFactorHi': kWindSpeedFactor.$2,
  'fadeOpacityLo': kWindFadeOpacity.$1,
  'fadeOpacityHi': kWindFadeOpacity.$2,
  'dropRate': kWindDropRate,
  'densityCalm': kWindDensityCalm,
  'densityStrong': kWindDensityStrong,
  'speedScale': kWindSpeedScale,
  'pixelRatio': pixelRatio,
};

/// One wind field in the wire's shape, or null when it carries no payload.
///
/// The raw WND1 body goes over untouched, with the header Dart already parsed
/// alongside it. Native does not re-parse: one parser, one place, one set of
/// tests. A field assembled in code rather than decoded has no body and is
/// skipped rather than faked.
Map<String, Object>? windFieldPayload(WindField field) {
  final source = field.source;
  if (source == null) return null;
  return {
    'bytes': source,
    'planeOffset': field.planeOffset,
    'width': field.width,
    'height': field.height,
    'lat0': field.lat0,
    'lon0': field.lon0,
    'dLat': field.dLat,
    'dLon': field.dLon,
    'uMin': field.uMin,
    'uMax': field.uMax,
    'vMin': field.vMin,
    'vMax': field.vMax,
  };
}
