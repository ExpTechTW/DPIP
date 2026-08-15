/// The wind-forecast particle animation — a Flutter overlay that advects a
/// cloud of particles through the frame's wind field, mirroring the web demo's
/// GPU pass on the CPU.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/device_info.dart';
import 'package:dpip/core/platform/render_tier.dart';
import 'package:dpip/features/map/presentation/layers/wind_forecast_layer.dart';
import 'package:dpip/features/map/presentation/layers/wind_particle_sim.dart';
import 'package:dpip/features/map/presentation/pages/map_page.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
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
/// pan. The ticker only runs while a wind field is loaded *and* the map tab is
/// the visible one — the shell keeps hidden tabs mounted, so without the
/// visibility check a wind field would keep animating (and rasterising full
/// screen) behind every other tab.
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

  /// Whether the map is actually in front of the user — see [_syncVisibility].
  bool _visible = true;

  /// The shell's visible-tab notifier; `null` outside the shell means the
  /// overlay is always visible.
  VisibleTab? _visibleTab;

  /// Frames actually stepped, and why the last one was not — the watchdog's
  /// only inputs.
  int _steps = 0;
  int _seenSteps = 0;
  int _quietChecks = 0;
  String? _stalledOn;
  bool _stallLogged = false;
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    widget.layer.field.addListener(_onField);
    // Straight assignment: this runs inside the first build, where asking for
    // another one throws.
    _adoptField();
    _probeTier();
    _watchdog = Timer.periodic(_watchdogPeriod, (_) => _checkAlive());
  }

  /// Device class decides the trail buffer's internal resolution (see
  /// [_TrailBuffer.scale]) — the dominant cost of this overlay is rasterising
  /// that buffer, so the low tier cuts it by ~9× while the soft streaks stay
  /// visually the same. Fire-and-forget: until the probe lands the high
  /// setting stands in, and the buffer rebuilds itself at the new size.
  Future<void> _probeTier() async {
    RenderTier tier;
    try {
      tier = renderTierFor(await DeviceInfoService.load());
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'Device tier probe failed');
      tier = RenderTier.high;
    }
    if (!mounted) return;
    _trails.scale = tier == RenderTier.low ? 0.33 : 0.5;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribes to the notifier itself, not to an InheritedWidget rebuild:
    // the shell hands every page the same [VisibleTab] instance, so waiting
    // for a scope update would never re-run this (see VisibleTabScope's doc).
    final visibleTab = VisibleTabScope.of(context);
    if (identical(visibleTab, _visibleTab)) return;
    _visibleTab?.removeListener(_syncVisibility);
    _visibleTab = visibleTab;
    visibleTab?.addListener(_syncVisibility);
    _syncVisibility();
  }

  /// Stops the animation when the map goes out of view, starts it on return.
  ///
  /// The shell's IndexedStack keeps this overlay mounted behind other tabs, and
  /// a pushed full-screen route leaves the branch index untouched, so neither
  /// tears it down. Without this the simulation would keep stepping — and the
  /// trail buffer keep rasterising — for a surface nobody is looking at.
  void _syncVisibility() {
    final visible = _visibleTab?.isOnScreen(MapPage.tabIndex) ?? true;
    if (visible == _visible) return;
    _visible = visible;
    _updateTicker();
  }

  /// Runs the ticker only when there is a field to draw *and* the map tab is
  /// on screen.
  void _updateTicker() {
    final shouldRun = _sim != null && _visible;
    if (shouldRun && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  /// How often the watchdog looks, and how many consecutive quiet looks count
  /// as wedged.
  ///
  /// Two, not one: restarting drops the trail buffer, so a false positive is a
  /// visible flicker. A healthy field produces sixty frames a second, so *zero*
  /// across two full seconds is not a slow device — but a single quiet second
  /// can be, on a frame the engine simply did not schedule.
  static const Duration _watchdogPeriod = Duration(seconds: 1);
  static const int _quietChecksBeforeRestart = 2;

  /// Restarts the animation if it should be running and is not.
  ///
  /// This exists because a frozen wind field has proven able to survive every
  /// recovery the page offers — panning, zooming, scrubbing, leaving the tab
  /// and coming back — and a permanently dead overlay is a far worse outcome
  /// than a one-second hitch. Rather than depend on having found every way it
  /// can wedge, this watches the one thing that matters (are frames being
  /// produced?) and rebuilds the animation when they stop.
  ///
  /// It also logs *why*, once per stall: the reason names which guard is
  /// holding, which is the difference between a report of "the particles froze"
  /// and a fix.
  void _checkAlive() {
    if (!mounted) return;
    final shouldRun = _sim != null && _visible;
    if (!shouldRun || _steps != _seenSteps) {
      _seenSteps = _steps;
      _quietChecks = 0;
      _stallLogged = false;
      return;
    }
    if (++_quietChecks < _quietChecksBeforeRestart) return;

    if (!_stallLogged) {
      _stallLogged = true;
      Log.warning(
        'wind particles stalled: ${_stalledOn ?? 'the ticker stopped firing'} '
        '(ticker active=${_ticker.isActive} muted=${_ticker.muted}, '
        'controller=${widget.layer.mapController != null}, '
        'field=${widget.layer.field.value != null}, visible=$_visible)',
      );
    }

    // A muted ticker is the framework's call (the route is off-stage), not a
    // fault — restarting it would fight the framework and change nothing.
    if (_ticker.muted) return;

    // Rebuild the animation from scratch: a stopped or wedged ticker, a
    // simulation whose field went missing, and a trail buffer that may hold a
    // texture from before the stall.
    _quietChecks = 0;
    if (_ticker.isActive) _ticker.stop();
    _trails.clear();
    _lastCamera = null;
    if (_sim == null) {
      final field = widget.layer.field.value;
      if (field != null) _sim = WindParticleSim(field);
    }
    _updateTicker();
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
    _updateTicker();
  }

  /// Steps the simulation for one frame.
  ///
  /// **Nothing may escape this method.** [Ticker] reschedules itself *after*
  /// the callback returns, so a single throw here stops the animation for the
  /// rest of the session — and `isActive` still reports `true` afterwards, so
  /// [_updateTicker] sees a healthy ticker and never restarts it. That is a
  /// frozen wind field that no amount of panning, zooming or re-selecting the
  /// layer can revive, from one bad frame.
  ///
  /// A bad frame is not hypothetical: `context.size` throws outright while the
  /// render object is dirty for layout, which is exactly the window a rebuild
  /// of this subtree opens.
  void _onTick(Duration _) {
    try {
      _step();
    } catch (error, stackTrace) {
      // Logged, not swallowed silently — but the next frame still runs.
      Log.handle(error, stackTrace, 'wind particle tick');
    }
  }

  void _step() {
    final controller = widget.layer.mapController;
    final sim = _sim;
    // Each bail-out names itself. A frozen field looks identical from the
    // outside whichever of these stopped it, and they need different fixes —
    // a detached controller is a layer-lifecycle bug, a null field is a load
    // that never landed, a null size is a layout that never happened.
    if (!mounted) return _stall('unmounted');
    if (controller == null) return _stall('no map controller');
    if (sim == null) return _stall('no wind field');
    final position = controller.cameraPosition;
    if (position == null) return _stall('no camera');
    final size = context.size;
    if (size == null || size.isEmpty) return _stall('no size');

    final camera = WindCamera(
      centerLat: position.target.latitude,
      centerLng: position.target.longitude,
      zoom: position.zoom,
      bearing: position.bearing,
    );
    final previous = _lastCamera;
    if (previous != null && previous != camera) {
      _trails.clear();
    }
    _lastCamera = camera;

    // The painter needs these at paint time and the widget does not rebuild
    // when the map zooms, so they travel on the buffer rather than as props.
    _trails.zoom = camera.zoom;
    _trails.devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    sim.step(camera, size);
    _repaint.mark();
    _steps++;
    _stalledOn = null;
  }

  void _stall(String reason) => _stalledOn = reason;

  @override
  Widget build(BuildContext context) {
    // Its own layer: this repaints every frame the ticker runs, and it sits in
    // the map's overlay slot alongside chrome that changes only on interaction.
    // Without the boundary each streak frame would dirty that whole layer.
    return RepaintBoundary(
      child: CustomPaint(
        painter: _WindParticlePainter(
          sim: _sim,
          trails: _trails,
          repaint: _repaint,
        ),
        size: Size.infinite,
      ),
    );
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _visibleTab?.removeListener(_syncVisibility);
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
///
/// The buffer renders at [scale] of the device resolution: every frame it is
/// rasterised with `toImageSync` (a synchronous GPU round-trip on the UI
/// thread), so at full resolution it was the dominant cost — and heat — of
/// this page. Streaks are soft, semi-transparent white, so upscaling the
/// buffer reads the same; [scale] 0.5 cuts that raster 4× and the low tier's
/// 0.33 cuts it ~9×.
class _TrailBuffer {
  ui.Image? _image;

  /// Speed buckets for [_stamp], reused across frames. Each bucket is an
  /// interleaved `x,y` [Float32List] for [Canvas.drawRawPoints], so the stamp
  /// path allocates nothing per frame — `drawPoints` would need a fresh
  /// [Offset] per visible particle (up to 6400 of them) for the collector to
  /// chase on the hottest path in the app.
  ///
  /// Typed-data lists are fixed-length, so capacity is preallocated (the worst
  /// case: the whole population in one speed bucket) and [_counts] tracks how
  /// much of it this frame is live; [drawRawPoints] gets a zero-copy sublist
  /// view of just that.
  final List<Float32List> _buckets = List.generate(
    16,
    (_) => Float32List(_bucketCapacity),
    growable: false,
  );

  /// Live point count per bucket this frame.
  ///
  /// 16 bits, not 8: the whole population (6400) can land in one speed bucket
  /// under strong wind, and an 8-bit counter wraps at 255 — the bucket then
  /// draws the wrong point count (or none at all, when the count wraps to 0),
  /// which reads as particles vanishing and stale trails outliving a rotation.
  final Uint16List _counts = Uint16List(16);

  /// Floats per bucket: the largest population (6400 at z3) as x,y pairs.
  static const int _bucketCapacity = 6400 * 2;

  /// Internal render resolution as a fraction of the device's — see the class
  /// doc. Written by the state's device-tier probe; changing it recreates the
  /// buffer on the next [advance] (the size check below).
  double scale = 0.5;

  /// Live camera zoom and device pixel ratio, written by the ticker. The
  /// painter needs both at paint time and neither is known at build time —
  /// the widget does not rebuild when the map zooms.
  double zoom =
      3; // the wind layer's own floor, until the ticker says otherwise
  double devicePixelRatio = 1;

  void clear() {
    _image?.dispose();
    _image = null;
  }

  void dispose() => clear();

  /// Fades what is there, stamps [particles] over it, and returns the result.
  ui.Image advance(Iterable<WindParticle> particles, Size size) {
    final dpr = devicePixelRatio * scale;
    final w = math.max(1, (size.width * dpr).round());
    final h = math.max(1, (size.height * dpr).round());
    final previous = _image;
    if (previous != null && (previous.width != w || previous.height != h)) {
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
          ..color = const Color(0xFFFFFFFF)
              .withValues(alpha: fadeOpacityFor(zoom)),
      );
    }
    _stamp(canvas, particles, dpr);

    final next = recorder.endRecording().toImageSync(w, h);
    old?.dispose();
    _image = next;
    return next;
  }

  /// Stamps one dot per visible particle, in buffer pixels ([dpr] already
  /// includes the buffer's own [scale]).
  ///
  /// The web gives every point its own alpha from a fragment shader; a
  /// [Canvas] carries one colour per call, so the field is bucketed by speed
  /// and drawn a bucket at a time. Sixteen steps across an alpha range of 0.55
  /// is a third of a level apart in 8-bit terms — below what the fade's own
  /// rounding does to it anyway.
  void _stamp(Canvas canvas, Iterable<WindParticle> particles, double dpr) {
    const buckets = 16;
    final points = _buckets;
    final counts = _counts;
    counts.fillRange(0, buckets, 0);
    for (final p in particles) {
      if (!p.visible) continue;
      final t = (p.speed / kWindSpeedScale).clamp(0.0, 1.0);
      final bi = math.min(buckets - 1, (t * buckets).floor());
      final i = counts[bi]++;
      final b = points[bi];
      b[i * 2] = p.sx * dpr;
      b[i * 2 + 1] = p.sy * dpr;
    }
    final paint = Paint()
      ..strokeWidth = pointSizeFor(zoom) * dpr
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < buckets; i++) {
      final count = counts[i];
      if (count == 0) continue;
      // The bucket's midpoint, on the web's ramp: brighter where it is faster.
      final t = (i + 0.5) / buckets;
      paint.color = Color.fromRGBO(255, 255, 255, 0.35 + 0.55 * t);
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.sublistView(points[i], 0, count * 2),
        paint,
      );
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
      // The buffer is scaled down relative to the screen, so bilinear (not
      // `none`, which would show the upscale as hard squares on the dots).
      Paint()..filterQuality = FilterQuality.low,
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
