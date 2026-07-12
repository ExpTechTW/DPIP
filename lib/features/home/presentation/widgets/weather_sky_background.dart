import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/settings/domain/weather_mode.dart';
import 'package:flutter/material.dart';

/// GPU-accelerated procedural sky backdrop.
///
/// Ported from the `feat/new-home` design: a fragment shader
/// (`shaders/weather_sky.frag`) draws a time-of-day sky with drifting clouds
/// and rain — no image sampling, so it stays cheap to animate. [mode] forces a
/// look (or [WeatherMode.auto] for defaults until a weather feed is wired up);
/// [active] pauses the animation when the backdrop is off-screen (e.g. while the
/// home sheet is collapsed) to save GPU.
class WeatherSkyBackground extends StatefulWidget {
  /// Which weather look to render.
  final WeatherMode mode;

  /// Whether the animation should run. When `false` the shader holds its last
  /// frame instead of ticking.
  final bool active;

  const WeatherSkyBackground({
    super.key,
    this.mode = WeatherMode.auto,
    this.active = true,
  });

  @override
  State<WeatherSkyBackground> createState() => _WeatherSkyBackgroundState();
}

class _WeatherSkyBackgroundState extends State<WeatherSkyBackground>
    with SingleTickerProviderStateMixin {
  final Stopwatch _clock = Stopwatch();
  late final AnimationController _ticker = AnimationController(
    duration: const Duration(seconds: 60),
    vsync: this,
  );
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _syncRunning();
    _load();
  }

  Future<void> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/weather_sky.frag',
      );
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'Failed to load weather_sky shader');
    }
  }

  /// Runs the clock + ticker only while [WeatherSkyBackground.active].
  void _syncRunning() {
    if (widget.active) {
      if (!_clock.isRunning) _clock.start();
      _ticker.repeat();
    } else {
      _clock.stop();
      _ticker.stop();
    }
  }

  @override
  void didUpdateWidget(WeatherSkyBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncRunning();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    _clock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light ? 1.0 : 0.0;
    final weather = _weightsFor(widget.mode);
    final shader = _shader;
    if (shader == null) {
      return ColoredBox(
        color: _fallbackColor(_skyScene(DateTime.now().hour), light),
      );
    }
    return AnimatedBuilder(
      animation: _ticker,
      builder: (context, _) {
        final now = DateTime.now();
        final time = _clock.elapsedMilliseconds / 1000;
        return CustomPaint(
          size: Size.infinite,
          painter: _SkyShaderPainter(
            shader: shader,
            scene: _skyScene(now.hour),
            cloud: weather.cloud,
            rain: weather.rain,
            wind: weather.wind,
            fog: weather.fog,
            sunPhase: _sunPhase(now),
            light: light,
            time: time,
            lightning: widget.mode == WeatherMode.thunderstorm
                ? _lightningAt(time)
                : 0.0,
          ),
        );
      },
    );
  }
}

typedef _Weights = ({double cloud, double rain, double wind, double fog});

/// Maps a [WeatherMode] onto the shader's cloud/rain/wind/fog weights.
///
/// Until a realtime feed drives [WeatherMode.auto], it renders a calm, lightly
/// clouded sky.
_Weights _weightsFor(WeatherMode mode) => switch (mode) {
  WeatherMode.auto => (cloud: 0.30, rain: 0.0, wind: 0.4, fog: 0.0),
  WeatherMode.clear => (cloud: 0.10, rain: 0.0, wind: 0.25, fog: 0.0),
  WeatherMode.rain => (cloud: 0.85, rain: 0.7, wind: 0.6, fog: 0.1),
  WeatherMode.fog => (cloud: 0.45, rain: 0.0, wind: 0.15, fog: 0.9),
  WeatherMode.thunderstorm => (cloud: 0.9, rain: 0.85, wind: 0.8, fog: 0.15),
};

/// Spatially-uniform lightning flash at [time] (seconds): quantise into windows,
/// hash-gate which fire, then a double-flash exponential-impulse envelope,
/// clamped below 1 for photosensitivity. Fed to the shader's `iLightning`.
double _lightningAt(double time) {
  const period = 3.6;
  final window = (time / period).floorToDouble();
  if (_hash01(window) > 0.45) return 0.0;
  final x = time - window * period;
  final env = _expImpulse(x, 9.0) + 0.6 * _expImpulse(x - 0.12, 12.0);
  return (env * (0.7 + 0.3 * _hash01(window + 7.0))).clamp(0.0, 0.9);
}

double _expImpulse(double t, double k) {
  if (t < 0) return 0.0;
  final h = k * t;
  return h * math.exp(1.0 - h);
}

double _hash01(double n) {
  final x = math.sin(n * 127.1) * 43758.5453;
  return x - x.floorToDouble();
}

/// Time-of-day scene index: `0` day, `1` night, `2` dawn, `3` sunset.
int _skyScene(int hour) {
  if (hour < 5 || hour >= 19) return 1;
  if (hour < 7) return 2;
  if (hour >= 17) return 3;
  return 0;
}

/// Solar phase in `[0, 1]` across the 5am–7pm daylight window.
double _sunPhase(DateTime now) {
  final h = now.hour + now.minute / 60.0;
  return ((h - 5.0) / 14.0).clamp(0.0, 1.0);
}

/// Solid colour shown before the shader loads (and as a permanent fallback).
Color _fallbackColor(int scene, double light) {
  if (scene == 0 && light > 0.5) return const Color(0xFFAFD4F0);
  return switch (scene) {
    1 => const Color(0xFF0A1220),
    2 => const Color(0xFF5E2455),
    3 => const Color(0xFFA0331E),
    _ => const Color(0xFF1E6FC4),
  };
}

/// Feeds the sky parameters to the shader and fills the canvas.
class _SkyShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final int scene;
  final double cloud;
  final double rain;
  final double wind;
  final double fog;
  final double sunPhase;
  final double light;
  final double time;
  final double lightning;

  const _SkyShaderPainter({
    required this.shader,
    required this.scene,
    required this.cloud,
    required this.rain,
    required this.wind,
    required this.fog,
    required this.sunPhase,
    required this.light,
    required this.time,
    required this.lightning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, time)
      ..setFloat(1, size.width)
      ..setFloat(2, size.height)
      ..setFloat(3, scene.toDouble())
      ..setFloat(4, 0) // iScroll — parallax disabled for now
      ..setFloat(5, cloud)
      ..setFloat(6, rain)
      ..setFloat(7, wind)
      ..setFloat(8, sunPhase)
      ..setFloat(9, light)
      ..setFloat(10, fog)
      ..setFloat(11, lightning);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_SkyShaderPainter old) =>
      old.time != time ||
      old.scene != scene ||
      old.cloud != cloud ||
      old.rain != rain ||
      old.wind != wind ||
      old.fog != fog ||
      old.sunPhase != sunPhase ||
      old.light != light ||
      old.lightning != lightning;
}
