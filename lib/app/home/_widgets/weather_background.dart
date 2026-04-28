/// GPU-accelerated weather sky background driven by a fragment shader.
library;

import 'dart:ui';

import 'package:dpip/app/home/_models/home_model.dart';
import 'package:dpip/app/home/_models/weather_params.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef _BgParams = ({
  int scene,
  double cloud,
  double rain,
  double wind,
  double sunPhase,
});

/// Full-screen procedurally-generated sky background.
///
/// Selects a time-of-day scene and continuous cloud, rain, and wind weights
/// from [HomeModel], then feeds them to a fragment shader. The [scrollOffset]
/// drives a layered parallax effect: distant elements drift slowly while
/// foreground elements drift more.
class WeatherBackground extends StatefulWidget {
  /// Current scroll offset of the home page list.
  final ValueListenable<double> scrollOffset;

  /// Creates a [WeatherBackground] driven by [scrollOffset].
  const WeatherBackground({required this.scrollOffset, super.key});

  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground> with SingleTickerProviderStateMixin {
  FragmentShader? _shader;
  late final AnimationController _ticker = AnimationController(
    duration: const Duration(seconds: 60),
    vsync: this,
  )..repeat();
  final _epoch = DateTime.now().millisecondsSinceEpoch;

  double get _elapsed => (DateTime.now().millisecondsSinceEpoch - _epoch) / 1000.0;

  Future<void> _loadShader() async {
    try {
      final program = await FragmentProgram.fromAsset('shaders/weather_sky.frag');
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (e) {
      debugPrint('Failed to load weather_sky shader: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  @override
  Widget build(BuildContext context) {
    final light = context.theme.brightness == .light ? 1.0 : 0.0;

    return Selector<HomeModel, _BgParams>(
      selector: (_, m) {
        final d = m.weather?.data;
        final now = DateTime.now();

        return (
          scene: resolveSkyScene(now.hour),
          cloud: cloudWeight(d),
          rain: rainWeight(d),
          wind: windWeight(d),
          sunPhase: sunPhase(now),
        );
      },
      builder: (context, params, _) {
        if (_shader == null) {
          return ColoredBox(
            color: _fallbackColor(params.scene, light),
          );
        }

        return AnimatedBuilder(
          animation: .merge([_ticker, widget.scrollOffset]),
          builder: (context, _) {
            return CustomPaint(
              painter: _SkyShaderPainter(
                shader: _shader!,
                scene: params.scene,
                cloud: params.cloud,
                rain: params.rain,
                wind: params.wind,
                sunPhase: params.sunPhase,
                light: light,
                time: _elapsed,
                scroll: widget.scrollOffset.value,
              ),
              size: .infinite,
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    super.dispose();
  }
}

Color _fallbackColor(int scene, double light) {
  if (scene == 0 && light > 0.5) return const Color(0xFFAFD4F0);

  return switch (scene) {
    1 => const Color(0xFF0A1220),
    2 => const Color(0xFF5E2455),
    3 => const Color(0xFFA0331E),
    _ => const Color(0xFF1E6FC4),
  };
}

class _SkyShaderPainter extends CustomPainter {
  final double cloud;
  final double light;
  final double rain;
  final int scene;
  final double scroll;
  final FragmentShader shader;
  final double sunPhase;
  final double time;
  final double wind;

  const _SkyShaderPainter({
    required this.shader,
    required this.scene,
    required this.cloud,
    required this.rain,
    required this.wind,
    required this.sunPhase,
    required this.light,
    required this.time,
    required this.scroll,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, time)
      ..setFloat(1, size.width)
      ..setFloat(2, size.height)
      ..setFloat(3, scene.toDouble())
      ..setFloat(4, scroll)
      ..setFloat(5, cloud)
      ..setFloat(6, rain)
      ..setFloat(7, wind)
      ..setFloat(8, sunPhase)
      ..setFloat(9, light);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_SkyShaderPainter old) =>
      old.scene != scene ||
      old.time != time ||
      old.scroll != scroll ||
      old.cloud != cloud ||
      old.rain != rain ||
      old.wind != wind ||
      old.sunPhase != sunPhase ||
      old.light != light;
}
