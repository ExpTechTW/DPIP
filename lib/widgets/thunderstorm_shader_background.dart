import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThunderstormShaderBackground extends StatefulWidget {
  final Widget? child;
  final bool animated;
  final String imagePath;
  final double lightningIntensity;
  final double rainAmount;

  const ThunderstormShaderBackground({
    super.key,
    this.child,
    this.animated = true,
    this.imagePath = 'assets/wallpaper/dusk/vending_machine.jpg',
    this.lightningIntensity = 1,
    this.rainAmount = 0.3,
  });

  @override
  State<ThunderstormShaderBackground> createState() =>
      _ThunderstormShaderBackgroundState();
}

class _ThunderstormShaderBackgroundState
    extends State<ThunderstormShaderBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  ui.Image? _image;
  late final AnimationController _controller;
  int _startTime = 0;

  double get _elapsedTime =>
      (DateTime.now().millisecondsSinceEpoch - _startTime) / 1000.0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().millisecondsSinceEpoch;

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    if (widget.animated) {
      _controller.repeat();
    }

    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final results = await Future.wait([
        ui.FragmentProgram.fromAsset('shaders/thunderstorm.frag'),
        _loadImage(widget.imagePath),
      ]);

      if (mounted) {
        setState(() {
          _shader = (results[0] as ui.FragmentProgram).fragmentShader();
          _image = results[1] as ui.Image;
        });
      }
    } catch (e) {
      debugPrint('Failed to load thunderstorm shader: $e');
    }
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void didUpdateWidget(ThunderstormShaderBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.animated != oldWidget.animated) {
      widget.animated ? _controller.repeat() : _controller.stop();
    }

    if (widget.imagePath != oldWidget.imagePath) {
      _image?.dispose();
      _image = null;
      _loadAssets();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shader?.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null || _image == null) {
      return Container(
        color: const Color(0xFF1a1a2e),
        child: widget.child,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: size,
              painter: _ThunderstormShaderPainter(
                shader: _shader!,
                image: _image!,
                time: _elapsedTime,
                lightningIntensity: widget.lightningIntensity,
                rainAmount: widget.rainAmount,
              ),
              child: widget.child,
            );
          },
        );
      },
    );
  }
}

class _ThunderstormShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image image;
  final double time;
  final double lightningIntensity;
  final double rainAmount;

  _ThunderstormShaderPainter({
    required this.shader,
    required this.image,
    required this.time,
    required this.lightningIntensity,
    required this.rainAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int idx = 0;
    shader.setFloat(idx++, time);
    shader.setFloat(idx++, size.width);
    shader.setFloat(idx++, size.height);
    shader.setFloat(idx++, lightningIntensity);
    shader.setFloat(idx++, rainAmount);
    shader.setImageSampler(0, image);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ThunderstormShaderPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.lightningIntensity != lightningIntensity ||
        oldDelegate.rainAmount != rainAmount ||
        oldDelegate.image != image;
  }
}
