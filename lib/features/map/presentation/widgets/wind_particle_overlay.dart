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

  /// Whether a finger is on the map — the field is hidden for the duration.
  bool _interacting = false;

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
    widget.layer.interacting.addListener(_onInteracting);
    // Straight assignment: this runs inside the first build, where asking for
    // another one throws.
    _adoptField();
    _probeTier();
  }

  /// Device class decides how long the streaks are, which is now what this
  /// overlay's cost scales with: each frame of tail is one more
  /// `drawRawPoints` over the visible population. A shorter tail on the low
  /// tier is a slightly shorter streak, not a coarser one. Fire-and-forget:
  /// until the probe lands the full length stands in.
  Future<void> _probeTier() async {
    RenderTier tier;
    try {
      tier = renderTierFor(await DeviceInfoService.load());
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'Device tier probe failed');
      tier = RenderTier.high;
    }
    if (!mounted) return;
    _trails.tailFrames = tier == RenderTier.low
        ? 6
        : _TrailBuffer.historyFrames;
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

  /// Whether the animation should be running at all: there is a field, the map
  /// tab is on screen, and no gesture is in progress.
  bool get _shouldAnimate => _sim != null && _visible && !_interacting;

  /// Runs the ticker only while [_shouldAnimate].
  void _updateTicker() {
    final shouldRun = _shouldAnimate;
    if (shouldRun && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
    if (shouldRun) {
      _watchdog ??= Timer.periodic(_watchdogPeriod, (_) => _checkAlive());
    } else {
      _watchdog?.cancel();
      _watchdog = null;
      _quietChecks = 0;
      _stallLogged = false;
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
    final shouldRun = _shouldAnimate;
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

  /// Clears the field for the duration of a gesture and reseeds it after.
  ///
  /// The whole overlay goes quiet in between — no stepping, no drawing, no
  /// history — so a pan, pinch or rotate costs this page nothing at all. The
  /// reseed then happens once, against the camera the gesture actually settled
  /// on, rather than the field chasing a viewport that is still moving.
  void _onInteracting() {
    if (!mounted) return;
    final interacting = widget.layer.interacting.value;
    if (interacting == _interacting) return;
    setState(() {
      _interacting = interacting;
      // A streak drawn before the gesture describes a view that is gone.
      _trails.clear();
      _lastCamera = null;
      if (interacting) {
        _updateTicker();
      } else {
        // Reseed from scratch: the population size follows zoom, and this is
        // the first moment the zoom is final.
        _adoptField();
      }
    });
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

    final previous = _lastCamera;
    final target = position.target;
    final unchanged =
        previous != null &&
        previous.centerLat == target.latitude &&
        previous.centerLng == target.longitude &&
        previous.zoom == position.zoom &&
        previous.bearing == position.bearing;
    final camera = unchanged
        ? previous
        : WindCamera(
            centerLat: target.latitude,
            centerLng: target.longitude,
            zoom: position.zoom,
            bearing: position.bearing,
          );
    if (previous != null && !unchanged) {
      _trails.clear();
    }
    _lastCamera = camera;

    // The painter needs the zoom at paint time and the widget does not rebuild
    // when the map zooms, so it travels on the buffer rather than as a prop.
    _trails.zoom = camera.zoom;

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
          // Null for the whole gesture: the painter draws nothing, so the
          // particles are simply gone until the map settles.
          sim: _interacting ? null : _sim,
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
    widget.layer.interacting.removeListener(_onInteracting);
    widget.layer.field.removeListener(_onField);
    _ticker.dispose();
    _repaint.dispose();
    _trails.dispose();
    super.dispose();
  }
}

/// The streaks, as the last [historyFrames] frames of particle positions.
///
/// This used to be an accumulation buffer: each frame the previous picture was
/// drawn back at a fade opacity, the new dots stamped over it, and the result
/// rasterised with `toImageSync` — one synchronous GPU round-trip on the UI
/// thread, every frame. Elegant, and the source of the bug that would not die:
/// when that readback returns a stale texture, the overlay shows a frozen
/// picture *while everything behind it keeps working perfectly*. The
/// simulation steps, the ticker fires, the painter is marked dirty — so no
/// amount of watching for a stalled animation can detect it, and no pan, zoom
/// or restart clears it. Rotating the map hammers that path hardest, because
/// every frame of a rotation discards the buffer and demands a fresh readback.
///
/// So there is no readback any more, and no texture that can go stale. A
/// streak is simply the last N frames of dots drawn together with an alpha
/// ramp — the same picture the fade produced, built from data the CPU owns
/// outright. The trade is a fixed number of extra `drawRawPoints` calls per
/// frame instead of one composite, against a failure mode that cannot happen.
class _TrailBuffer {
  /// How many frames of history make a streak. The old exponential fade
  /// (~0.95 a frame) stayed visible for roughly this long before it sank into
  /// the background, so the streaks read about the same length.
  static const int historyFrames = 14;
  static const int _speedBuckets = 16;
  static const int _bucketCapacity = 6400 * 2;

  static final List<Color> _headColors = List.generate(_speedBuckets, (i) {
    final t = (i + 0.5) / _speedBuckets;
    return Color.fromRGBO(255, 255, 255, 0.35 + 0.55 * t);
  }, growable: false);

  static final List<List<Color>> _tailColors = List.generate(
    historyFrames + 1,
    (tail) => List.generate(tail, (index) {
      final age = index + 1;
      final t = 1.0 - (age - 1) / tail;
      return Color.fromRGBO(255, 255, 255, 0.5 * t * t);
    }, growable: false),
    growable: false,
  );

  final Paint _paint = Paint()..strokeCap = StrokeCap.round;

  /// Speed buckets for the newest frame, reused across frames. Each bucket is
  /// an interleaved `x,y` [Float32List] for [Canvas.drawRawPoints], so the
  /// stamp path allocates nothing per frame — `drawPoints` would need a fresh
  /// [Offset] per visible particle (up to 6400 of them) for the collector to
  /// chase on the hottest path in the app.
  final List<Float32List> _buckets = List.generate(
    _speedBuckets,
    (_) => Float32List(_bucketCapacity),
    growable: false,
  );

  /// Live point count per bucket this frame.
  ///
  /// 16 bits, not 8: the whole population (6400) can land in one speed bucket
  /// under strong wind, and an 8-bit counter wraps at 255 — the bucket then
  /// draws the wrong point count (or none at all, when the count wraps to 0),
  /// which reads as particles vanishing.
  final Uint16List _counts = Uint16List(_speedBuckets);

  /// The tail: a ring of past frames, each a flat `x,y` list of the positions
  /// that were visible then. Positions, not particles — a particle that
  /// respawns must not drag its old streak across the screen to the new place.
  final List<Float32List> _history = List.generate(
    historyFrames,
    (_) => Float32List(_bucketCapacity),
    growable: false,
  );
  final Uint16List _historyCounts = Uint16List(historyFrames);
  int _head = 0;
  int _filled = 0;

  /// Live camera zoom, written by the ticker: the painter needs it at paint
  /// time and it is not known at build time — the widget does not rebuild when
  /// the map zooms.
  double zoom =
      3; // the wind layer's own floor, until the ticker says otherwise

  /// How many frames of tail to actually draw, set from the device tier.
  int tailFrames = historyFrames;

  /// Drops the tail. Called on any camera change: a streak drawn for one view
  /// is wrong for the next, and smearing it across the pan is worse than
  /// starting over.
  void clear() {
    _head = 0;
    _filled = 0;
    _historyCounts.fillRange(0, historyFrames, 0);
  }

  void dispose() => clear();

  /// Draws the tail then the head, oldest first so newer dots sit on top.
  void paint(Canvas canvas, Iterable<WindParticle> particles) {
    final paint = _paint..strokeWidth = pointSizeFor(zoom);

    // The tail, uniform white, fading with age. Oldest first.
    final tail = math.min(_filled, tailFrames);
    for (var age = tail; age >= 1; age--) {
      final slot = (_head - age) % historyFrames;
      final index = slot < 0 ? slot + historyFrames : slot;
      final count = _historyCounts[index];
      if (count == 0) continue;
      // The same linear alpha ramp as before, cached because it depends only
      // on the bounded tail length rather than any frame data.
      paint.color = _tailColors[tail][age - 1];
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.sublistView(_history[index], 0, count * 2),
        paint,
      );
    }

    _stampAndRecordHead(canvas, particles, paint);
  }

  /// The newest frame: bucketed by speed for the draw (the head of each streak
  /// is brighter where the wind is stronger) and recorded flat into the
  /// history ring for the next frames' tails — one pass over the population,
  /// where stamping and recording separately walked it twice a frame.
  ///
  /// The web gives every point its own alpha from a fragment shader; a
  /// [Canvas] carries one colour per call, so the field is bucketed and drawn a
  /// bucket at a time. Sixteen steps across an alpha range of 0.55 is a third
  /// of a level apart in 8-bit terms — below what rounding does to it anyway.
  void _stampAndRecordHead(
    Canvas canvas,
    Iterable<WindParticle> particles,
    Paint paint,
  ) {
    final points = _buckets;
    final counts = _counts;
    counts.fillRange(0, _speedBuckets, 0);
    final slot = _history[_head];
    var recorded = 0;
    // Reciprocal once; a divide per particle per frame is the kind of cost
    // this loop is too hot to carry.
    const invScale = 1 / kWindSpeedScale;
    for (final p in particles) {
      if (!p.visible) continue;
      // [speed] is a square root and therefore non-negative. Saturating with
      // one branch is equivalent to clamp + min without two generic helpers
      // for every visible particle.
      final scaledSpeed = p.speed * invScale;
      final bi = scaledSpeed >= 1 || scaledSpeed.isNaN
          ? _speedBuckets - 1
          : (scaledSpeed * _speedBuckets).floor();
      final i = counts[bi];
      if (i * 2 + 1 < _bucketCapacity) {
        counts[bi] = i + 1;
        final b = points[bi];
        b[i * 2] = p.sx;
        b[i * 2 + 1] = p.sy;
      }
      if (recorded * 2 + 1 < _bucketCapacity) {
        slot[recorded * 2] = p.sx;
        slot[recorded * 2 + 1] = p.sy;
        recorded++;
      }
    }
    _historyCounts[_head] = recorded;
    _head = (_head + 1) % historyFrames;
    if (_filled < historyFrames) _filled++;

    for (var i = 0; i < _speedBuckets; i++) {
      final count = counts[i];
      if (count == 0) continue;
      // The bucket's midpoint on the web ramp, prebuilt once rather than
      // allocating sixteen colours on every frame.
      paint.color = _headColors[i];
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.sublistView(points[i], 0, count * 2),
        paint,
      );
    }
  }
}

/// Draws the streaks over the map.
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
    trails.paint(canvas, sim.particles);
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
