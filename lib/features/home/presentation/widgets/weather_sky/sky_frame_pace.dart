import 'dart:async';

import 'package:dpip/features/home/presentation/widgets/weather_sky/weather_sky_painter.dart';
import 'package:flutter/scheduler.dart';

/// How early a paced wake asks for the next frame, so the vsync lands near
/// the due time. A 120 Hz frame is about 8 ms; waking 6 ms ahead skips the
/// vsync that would still be early and catches the one that is due.
const Duration kSkyPaceLead = Duration(milliseconds: 6);

/// Repaint budget shared by rain and a lightning strike.
const Duration kSkyRainInterval = Duration(milliseconds: 16);

/// Minimum time between painted sky frames for this scene.
///
/// Clouds, stars and the sun drift slowly enough that a full-screen picture
/// on every vsync is wasted. Rain and a lightning strike do not: a near drop
/// falls a few percent of the screen in one frame, and a bolt is a flash.
/// Snow sits between them. Rain and a strike share the fast budget and are
/// checked first, so either one outranks snow — a rain-snow mix, or a bolt
/// over snow, stays on the rain clock.
///
/// The gates are the painter's own ([skyPrecipitationOn] and
/// [LightningFrame.isActive]). [kSkyRainInterval] and 33 ms are both under
/// the backdrop's 1/20 s particle clamp, so a paced rain or snow step is
/// not shortened and the flakes are not slowed. The calm budget can reach
/// that clamp; nothing on that path integrates `dt`.
Duration skyFrameInterval({
  required double rain,
  required double snow,
  required LightningFrame lightning,
}) {
  if (skyPrecipitationOn(rain) || lightning.isActive) {
    return kSkyRainInterval;
  }
  if (skyPrecipitationOn(snow)) {
    return const Duration(milliseconds: 33);
  }
  return const Duration(milliseconds: 66);
}

/// One wake shared by the sky animations.
///
/// Callbacks registered before the pending timer fires run in that one
/// fire, so the frames they ask for land on the same vsync. A shorter wait
/// replaces the timer; a longer one joins the callbacks already waiting.
final class SkyFramePulse {
  SkyFramePulse._();

  static final SkyFramePulse shared = SkyFramePulse._();

  final Set<VoidCallback> _waiting = {};
  Timer? _timer;
  Duration _wait = Duration.zero;

  /// Adds [callback] to the pending fire, arming or bringing the timer
  /// forward when [wait] is sooner than whatever is already scheduled.
  void wake(Duration wait, VoidCallback callback) {
    _waiting.add(callback);
    if (_timer == null || wait < _wait) {
      _timer?.cancel();
      _wait = wait;
      _timer = Timer(wait, _fire);
    }
  }

  /// Drops [callback]. The timer goes with the last one.
  void cancel(VoidCallback callback) {
    _waiting.remove(callback);
    if (_waiting.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _fire() {
    _timer = null;
    final due = _waiting.toList(growable: false);
    _waiting.clear();
    for (final callback in due) {
      callback();
    }
  }
}

/// A ticker that asks for one frame per [interval] instead of one per vsync.
///
/// After each frame the inner ticker stops, and [SkyFramePulse] starts it
/// again [kSkyPaceLead] before [interval] is up. The elapsed time passed to
/// the callback runs from [start] across those pauses: the inner ticker's
/// own elapsed is zero on every frame, because starting it resets its
/// clock. The inner ticker comes from the [TickerProvider], so a disabled
/// ticker mode mutes it. A muted ticker does not tick and therefore does
/// not arm the pulse; enabling the mode lets it tick again.
final class SkyPacedTicker {
  SkyPacedTicker(
    TickerProvider vsync,
    this._onTick, {
    this.interval = kSkyRainInterval,
  }) {
    _inner = vsync.createTicker(_tick);
  }

  final TickerCallback _onTick;
  final Duration interval;

  late final Ticker _inner;
  bool _running = false;

  /// Frame time of the first tick since [start]. Later ticks subtract it,
  /// so the elapsed value keeps growing while the inner ticker is stopped.
  Duration? _origin;

  bool get isActive => _running;

  /// Starts a new run. A ticker that is already running stays on its clock.
  void start() {
    if (_running) return;
    _running = true;
    _origin = null;
    _inner.start();
  }

  /// Stops the run and drops any wake already registered for it.
  void stop() {
    _running = false;
    SkyFramePulse.shared.cancel(_wake);
    _inner.stop();
  }

  /// Stops the run and releases the inner ticker.
  void dispose() {
    stop();
    _inner.dispose();
  }

  void _tick(Duration _) {
    final now = SchedulerBinding.instance.currentFrameTimeStamp;
    _origin ??= now;
    _onTick(now - _origin!);
    if (!_running) return;
    _inner.stop();
    SkyFramePulse.shared.wake(interval - kSkyPaceLead, _wake);
  }

  void _wake() {
    if (_running && !_inner.isActive) {
      _inner.start();
    }
  }
}
