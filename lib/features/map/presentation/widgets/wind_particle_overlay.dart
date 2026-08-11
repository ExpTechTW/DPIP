/// The wind-forecast particle animation — a Flutter overlay that advects a
/// cloud of particles through the frame's wind field, mirroring the web demo's
/// GPU pass on the CPU.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dpip/features/map/presentation/layers/wind_forecast_layer.dart';
import 'package:dpip/features/map/presentation/layers/wind_particle_sim.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Renders the ECMWF / GFS wind field as flowing streaks, not just a colour
/// wash.
///
/// The map's overlay slot gives the layer a plain widget; this one owns the
/// animation — a [Ticker] steps the simulation every frame and a repaint
/// notifier redraws the [CustomPainter] — while the geometry (projection,
/// advection, recycling) lives in [WindParticleSim] where it is testable
/// without a widget tree.
///
/// The camera comes from the live map controller every tick, so the streaks
/// track pan/zoom/rotate exactly; the trail buffer is screen-space, so it is
/// dropped on any camera change — a streak drawn for one view is wrong for the
/// next, and the web renderer's alternative is to smear the old one across the
/// pan. The ticker only runs while a wind field is loaded, so an empty layer
/// costs nothing.
class WindParticleOverlay extends StatefulWidget {
  const WindParticleOverlay({super.key, required this.layer});

  final WindForecastMapLayer layer;

  @override
  State<WindParticleOverlay> createState() => _WindParticleOverlayState();
}

class _WindParticleOverlayState extends State<WindParticleOverlay>
    with SingleTickerProviderStateMixin {
  /// Marks the painter for redraw each frame without rebuilding the widget
  /// tree — the per-frame path of this overlay.
  final _OverlayRepaint _repaint = _OverlayRepaint();

  late final Ticker _ticker = createTicker(_onTick);

  WindParticleSim? _sim;
  WindCamera? _lastCamera;
  final _TrailBuffer _trails = _TrailBuffer();

  @override
  void initState() {
    super.initState();
    widget.layer.field.addListener(_onField);
    // Straight assignment: this runs inside the first build, where asking for
    // another one throws.
    _adoptField();
  }

  /// The layer loaded a new field (frame scrub or first show) — swap the
  /// simulation and start (or stop) the animation accordingly.
  ///
  /// This has to rebuild, because [_WindParticlePainter] is handed the
  /// simulation by value when [build] runs. The field arrives asynchronously
  /// and is therefore still null at [initState], so a painter built then holds
  /// null and paints nothing however busily the ticker steps behind it. What
  /// broke the illusion was that the first pan repainted the map surface and
  /// rebuilt this overlay with it — so the animation appeared to need a nudge
  /// to start, when what it needed was a build.
  void _onField() {
    if (!mounted) return;
    setState(_adoptField);
  }

  void _adoptField() {
    final field = widget.layer.field.value;
    _sim = field == null ? null : WindParticleSim(field);
    // A new frame's streaks must not grow out of the previous frame's.
    _trails.clear();
    if (field == null) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _onTick(Duration _) {
    final controller = widget.layer.mapController;
    final sim = _sim;
    if (!mounted || controller == null || sim == null) return;
    final position = controller.cameraPosition;
    final size = context.size;
    if (position == null || size == null || size.isEmpty) return;

    final camera = WindCamera(
      centerLat: position.target.latitude,
      centerLng: position.target.longitude,
      zoom: position.zoom,
      bearing: position.bearing,
    );
    final previous = _lastCamera;
    if (previous != null &&
        (previous.centerLat != camera.centerLat ||
            previous.centerLng != camera.centerLng ||
            previous.zoom != camera.zoom ||
            previous.bearing != camera.bearing)) {
      _trails.clear();
    }
    _lastCamera = camera;

    // The painter needs these at paint time and the widget does not rebuild
    // when the map zooms, so they travel on the buffer rather than as props.
    _trails.zoom = camera.zoom;
    _trails.devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    sim.step(camera, size);
    _repaint.mark();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WindParticlePainter(
        sim: _sim,
        trails: _trails,
        repaint: _repaint,
      ),
      size: Size.infinite,
    );
  }

  @override
  void dispose() {
    widget.layer.field.removeListener(_onField);
    _ticker.dispose();
    _repaint.dispose();
    _trails.dispose();
    super.dispose();
  }
}

/// The screen-space accumulation buffer the streaks live in.
///
/// This is the whole trail mechanism, and it is the web renderer's: nothing
/// records where a particle has been. Each frame the previous picture is drawn
/// back at [fadeOpacity] and the current dots are stamped on top, so a streak
/// is the exponential decay of the dots that came before it. The cost is one
/// composite per frame regardless of how long the streaks are — which is what
/// makes six thousand particles affordable, where remembering fifty positions
/// each would be three hundred thousand line segments a frame.
///
/// Held by the [State] rather than the painter, because a painter is rebuilt
/// whenever the widget is and the buffer has to survive that.
class _TrailBuffer {
  ui.Image? _image;

  /// Live camera zoom and device pixel ratio, written by the ticker. The
  /// painter needs both at paint time and neither is known at build time —
  /// the widget does not rebuild when the map zooms.
  double zoom = 3; // the wind layer's own floor, until the ticker says otherwise
  double devicePixelRatio = 1;

  void clear() {
    _image?.dispose();
    _image = null;
  }

  void dispose() => clear();

  /// Fades what is there, stamps [particles] over it, and returns the result.
  ui.Image advance(Iterable<WindParticle> particles, Size size) {
    final dpr = devicePixelRatio;
    final w = math.max(1, (size.width * dpr).round());
    final h = math.max(1, (size.height * dpr).round());
    final previous = _image;
    if (previous != null &&
        (previous.width != w || previous.height != h)) {
      clear();
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final old = _image;
    if (old != null) {
      canvas.drawImage(
        old,
        Offset.zero,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(
            alpha: fadeOpacityFor(zoom),
          ),
      );
    }
    _stamp(canvas, particles, dpr);

    final next = recorder.endRecording().toImageSync(w, h);
    old?.dispose();
    _image = next;
    return next;
  }

  /// Stamps one dot per visible particle, in device pixels.
  ///
  /// The web gives every point its own alpha from a fragment shader; a
  /// [Canvas] carries one colour per call, so the field is bucketed by speed
  /// and drawn a bucket at a time. Sixteen steps across an alpha range of 0.55
  /// is a third of a level apart in 8-bit terms — below what the fade's own
  /// rounding does to it anyway.
  void _stamp(Canvas canvas, Iterable<WindParticle> particles, double dpr) {
    const buckets = 16;
    final points = List.generate(buckets, (_) => <Offset>[], growable: false);
    for (final p in particles) {
      final screen = p.screen;
      if (screen == null) continue;
      final t = (p.speed / kWindSpeedScale).clamp(0.0, 1.0);
      points[math.min(buckets - 1, (t * buckets).floor())].add(screen * dpr);
    }
    final paint = Paint()
      ..strokeWidth = pointSizeFor(zoom) * dpr
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < buckets; i++) {
      if (points[i].isEmpty) continue;
      // The bucket's midpoint, on the web's ramp: brighter where it is faster.
      final t = (i + 0.5) / buckets;
      paint.color = Color.fromRGBO(255, 255, 255, 0.35 + 0.55 * t);
      canvas.drawPoints(ui.PointMode.points, points[i], paint);
    }
  }
}

/// Composites the trail buffer onto the map.
class _WindParticlePainter extends CustomPainter {
  _WindParticlePainter({
    required this.sim,
    required this.trails,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final WindParticleSim? sim;
  final _TrailBuffer trails;

  @override
  void paint(Canvas canvas, Size size) {
    final sim = this.sim;
    if (sim == null || size.isEmpty) return;
    final image = trails.advance(sim.particles, size);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _WindParticlePainter oldDelegate) =>
      oldDelegate.sim != sim;
}

/// A [ChangeNotifier] whose only job is to mark the painter dirty — a private
/// subclass so the state can call [ChangeNotifier.notifyListeners] without the
/// "visible for testing" lint.
class _OverlayRepaint extends ChangeNotifier {
  void mark() => notifyListeners();
}
