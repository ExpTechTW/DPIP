import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RainShaderBackground extends StatefulWidget {
  final Widget? child;

  final bool animated;

  final String imagePath;

  const RainShaderBackground({
    super.key,
    this.child,
    this.animated = true,
    this.imagePath = 'assets/wallpaper/night/city_rooftop_stars.jpg',
  });

  @override
  State<RainShaderBackground> createState() => _RainShaderBackgroundState();
}

class _RainShaderBackgroundState extends State<RainShaderBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  ui.Image? _image;
  late final AnimationController _controller;
  int _startTime = 0;

  double get _elapsedTime =>
      (DateTime.now().millisecondsSinceEpoch - _startTime) / 1000;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
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
        ui.FragmentProgram.fromAsset('shaders/rain.frag'),
        _loadImage(widget.imagePath),
      ]);

      if (mounted) {
        setState(() {
          _shader = (results[0] as ui.FragmentProgram).fragmentShader();
          _image = results[1] as ui.Image;
        });
      }
    } catch (e) {
      debugPrint('Failed to load rain shader: $e');
    }
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void didUpdateWidget(RainShaderBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated != oldWidget.animated) {
      widget.animated ? _controller.repeat() : _controller.stop();
    }
    if (widget.imagePath != oldWidget.imagePath) {
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
    _startTime = DateTime.now().millisecondsSinceEpoch;

    if (_shader == null || _image == null) {
      return Container(
        color: const Color(0xFF1a1a2e),
        child: widget.child,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        _shader!
          ..setFloat(1, size.width)
          ..setFloat(2, size.height);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            _shader!
              ..setFloat(0, _elapsedTime)
              ..setImageSampler(0, _image!);

            return CustomPaint(
              size: size,
              painter: _ShaderPainter(_shader!, _image!, size),
              child: widget.child,
            );
          },
        );
      },
    );
  }
}

class _ShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image image;
  final Size viewSize;

  _ShaderPainter(this.shader, this.image, this.viewSize);

  @override
  void paint(Canvas canvas, Size size) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    final imageAspect = imageWidth / imageHeight;
    final viewAspect = viewSize.width / viewSize.height;

    double srcX, srcY, srcW, srcH;

    if (imageAspect > viewAspect) {
      srcH = imageHeight;
      srcW = imageHeight * viewAspect;
      srcX = (imageWidth - srcW) / 2;
      srcY = 0;
    } else {
      srcW = imageWidth;
      srcH = imageWidth / viewAspect;
      srcX = 0;
      srcY = (imageHeight - srcH) / 2;
    }

    final recorder = ui.PictureRecorder();
    final tempCanvas = Canvas(recorder);

    tempCanvas.save();
    tempCanvas.translate(0, viewSize.height);
    tempCanvas.scale(1, -1);
    tempCanvas.drawImageRect(
      image,
      Rect.fromLTWH(srcX, srcY, srcW, srcH),
      Rect.fromLTWH(0, 0, viewSize.width, viewSize.height),
      Paint(),
    );
    tempCanvas.restore();

    final picture = recorder.endRecording();
    final croppedImage = picture.toImageSync(
      viewSize.width.toInt(),
      viewSize.height.toInt(),
    );

    shader.setImageSampler(0, croppedImage);

    canvas
      ..translate(size.width, size.height)
      ..rotate(math.pi)
      ..drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..shader = shader,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
