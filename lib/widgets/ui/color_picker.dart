import 'dart:math';
import 'dart:ui';

import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/number.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension ColorExtension on Color {
  String toHexString([bool includeAlpha = false]) {
    final hex = toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0');

    return includeAlpha ? hex.substring(0, 8) : hex.substring(2, 8);
  }
}

class ColorPickerBackgroundPainter extends CustomPainter {
  final double value;

  const ColorPickerBackgroundPainter({this.value = 1})
    : assert(value >= 0 && value <= 1, 'Value must be between 0 and 1');

  @override
  void paint(Canvas canvas, Size size) {
    final colors = List.generate(
      360,
      (index) => HSVColor.fromAHSV(1, index.asDouble, 1, value).toColor(),
    );

    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: colors,
        transform: GradientRotation(-pi / 2),
      ).createShader(rect);

    canvas.drawCircle(center, radius, sweepPaint);

    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          HSVColor.fromAHSV(1, 0, 0, value).toColor(),
          HSVColor.fromAHSV(0, 0, 0, value).toColor(),
        ],
      ).createShader(rect);

    canvas.drawCircle(center, radius, radialPaint);
  }

  @override
  bool shouldRepaint(covariant ColorPickerBackgroundPainter oldDelegate) =>
      value != oldDelegate.value;
}

class ColorPicker extends StatefulWidget {
  final HSVColor color;
  final Size thumbSize;
  final void Function(HSVColor color)? onChanged;

  const ColorPicker({
    super.key,
    this.color = const .fromAHSV(1, 0, 0, 1),
    this.thumbSize = const Size(24, 24),
    this.onChanged,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  final _h = TextEditingController();
  final _s = TextEditingController();
  final _v = TextEditingController();
  final _hex = TextEditingController();

  HSVColor get hsv => widget.color;

  Color _ColorFromAHSV(num alpha, num hue, num saturation, num value) =>
      HSVColor.fromAHSV(
        alpha.asDouble,
        hue.asDouble,
        saturation.asDouble,
        value.asDouble,
      ).toColor();

  Offset _calculatePositionFromColor(HSVColor color, Size size) {
    final center = size.center(.zero);
    final radius = min(size.width, size.height) / 2;

    final angle = (color.hue - 90) * pi / 180;

    final r = color.saturation * radius;

    final dx = r * cos(angle);
    final dy = r * sin(angle);

    return Offset(center.dx + dx, center.dy + dy);
  }

  void _updateFromPosition(Offset position, Size size) {
    final center = size.center(.zero);
    final radius = min(size.width, size.height) / 2;

    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    final clampedDistance = distance > radius ? radius : distance;

    double hue = (atan2(dy, dx) * 180 / pi + 90) % 360;
    if (hue < 0) hue += 360;

    final saturation = clampedDistance / radius;

    _update(hue: hue, saturation: saturation);
  }

  void _update({num? alpha, num? hue, num? saturation, num? value}) {
    final onChanged = this.widget.onChanged;
    if (onChanged == null) return;

    final a = switch (alpha) {
      null => hsv.alpha,
      double v => v,
      num v => v.asDouble,
    };

    final h = switch (hue) {
      null => hsv.hue,
      double v => v,
      num v => v.asDouble,
    };

    final s = switch (saturation) {
      null => hsv.saturation,
      double v => v,
      num v => v.asDouble,
    };

    final v = switch (value) {
      null => hsv.value,
      double v => v,
      num v => v.asDouble,
    };

    final newColor = HSVColor.fromAHSV(a, h, s, v);

    if (newColor == hsv) return;

    onChanged(newColor);
  }

  _updateTextControllers(HSVColor color) {
    _h.value = _h.value.replaced(
      TextRange(start: 0, end: _h.value.text.length),
      color.hue.precisionString(2),
    );
    _s.value = _s.value.replaced(
      TextRange(start: 0, end: _s.value.text.length),
      color.saturation.precisionString(2),
    );
    _v.value = _v.value.replaced(
      TextRange(start: 0, end: _v.value.text.length),
      color.value.precisionString(2),
    );
    _hex.value = _hex.value.replaced(
      TextRange(start: 0, end: _hex.value.text.length),
      color.toColor().toHexString(),
    );
  }

  @override
  void initState() {
    super.initState();
    _updateTextControllers(hsv);
  }

  @override
  void didUpdateWidget(covariant ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.color != hsv) {
      _updateTextControllers(hsv);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: 8,
      children: [
        ClipOval(
          child: Padding(
            padding: const .fromLTRB(24, 24, 24, 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final radius = min(constraints.maxWidth, constraints.maxHeight);
                final size = Size.square(radius);

                final thumbPosition = _calculatePositionFromColor(
                  hsv,
                  size,
                );

                return SizedBox.fromSize(
                  size: size,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      clipBehavior: .none,
                      children: [
                        GestureDetector(
                          behavior: .opaque,
                          onPanDown: (details) =>
                              _updateFromPosition(details.localPosition, size),
                          onPanUpdate: (details) =>
                              _updateFromPosition(details.localPosition, size),
                          child: CustomPaint(
                            size: size,
                            painter: ColorPickerBackgroundPainter(
                              value: hsv.value,
                            ),
                          ),
                        ),
                        Positioned(
                          left: thumbPosition.dx - widget.thumbSize.width / 2,
                          top: thumbPosition.dy - widget.thumbSize.height / 2,
                          child: Container(
                            height: widget.thumbSize.height,
                            width: widget.thumbSize.width,
                            decoration: BoxDecoration(
                              shape: .circle,
                              color: hsv.toColor(),
                              border: .all(color: Colors.white, width: 3),
                              boxShadow: kElevationToShadow[2],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Hue Slider
        Stack(
          alignment: .center,
          children: [
            Positioned(
              height: 16,
              left: 24,
              right: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: .circular(8),
                  gradient: LinearGradient(
                    colors: List.generate(
                      360,
                      (index) => _ColorFromAHSV(1, index, 1, 1),
                    ),
                  ),
                ),
              ),
            ),
            Slider(
              min: 0,
              max: 1,
              value: hsv.hue / 360,
              label: '${hsv.hue.asInt}°',
              inactiveColor: Colors.transparent,
              activeColor: Colors.transparent,
              thumbColor: context.colors.primary,
              onChanged: (value) => _update(hue: value * 360),
            ),
          ],
        ),
        // Saturation Slider
        Stack(
          alignment: .center,
          children: [
            Positioned(
              height: 16,
              left: 24,
              right: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: .circular(8),
                  gradient: LinearGradient(
                    colors: [
                      _ColorFromAHSV(1, hsv.hue, 0, hsv.value),
                      _ColorFromAHSV(1, hsv.hue, 1, hsv.value),
                    ],
                  ),
                ),
              ),
            ),
            Slider(
              min: 0,
              max: 1,
              value: hsv.saturation,
              label: '${hsv.saturation.asPercentage}%',
              inactiveColor: Colors.transparent,
              activeColor: Colors.transparent,
              thumbColor: context.colors.primary,
              onChanged: (value) => _update(saturation: value),
            ),
          ],
        ),
        // Value Slider
        Stack(
          alignment: .center,
          children: [
            Positioned(
              height: 16,
              left: 24,
              right: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: .circular(8),
                  gradient: LinearGradient(
                    colors: [
                      _ColorFromAHSV(1, hsv.hue, hsv.saturation, 0),
                      _ColorFromAHSV(1, hsv.hue, hsv.saturation, 1),
                    ],
                  ),
                ),
              ),
            ),
            Slider(
              min: 0,
              max: 1,
              value: hsv.value,
              label: '${hsv.value.asPercentage}%',
              inactiveColor: Colors.transparent,
              activeColor: Colors.transparent,
              thumbColor: context.colors.primary,
              onChanged: (value) => _update(value: value),
            ),
          ],
        ),
        // Hue Input
        Padding(
          padding: const .symmetric(horizontal: 24),
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _h,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: .circular(8)),
                    visualDensity: .compact,
                    labelText: '色相'.i18n,
                    suffixText: '°',
                  ),
                  keyboardType: .numberWithOptions(decimal: true),
                  inputFormatters: [
                    ClampedTextInputFormatter(min: 0, max: 360),
                  ],
                  onChanged: (value) => _update(hue: .tryParse(value)),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _s,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: .circular(8)),
                    visualDensity: .compact,
                    labelText: '彩度'.i18n,
                  ),
                  keyboardType: .numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[0-9.]+$')),
                    ClampedTextInputFormatter(min: 0, max: 1),
                  ],
                  onChanged: (value) => _update(saturation: .tryParse(value)),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _v,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: .circular(8)),
                    visualDensity: .compact,
                    labelText: '明度'.i18n,
                  ),
                  keyboardType: .numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[0-9.]+$')),
                    ClampedTextInputFormatter(min: 0, max: 1),
                  ],
                  onChanged: (value) => _update(value: .tryParse(value)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const .symmetric(horizontal: 24, vertical: 8),
          child: TextFormField(
            controller: _hex,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: .circular(8)),
              visualDensity: .compact,
              labelText: '十六進位值'.i18n,
              prefixText: '#',
            ),
            keyboardType: .visiblePassword,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^[0-9A-Fa-f]+$')),
            ],
            onChanged: (value) {
              if (value.isEmpty) return;
              if (value.length != 6) return;

              final hex = int.parse(value, radix: 16);
              if (hex < 0 || hex > 0xffffff) return;

              widget.onChanged?.call(
                HSVColor.fromColor(
                  Color(.parse('FF$value', radix: 16)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ClampedTextInputFormatter extends TextInputFormatter {
  final double min;
  final double max;

  const ClampedTextInputFormatter({this.min = 0, this.max = 1});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return oldValue;
    if (newValue.text.asDouble == oldValue.text.asDouble) return newValue;

    return newValue.copyWith(
      text: clampDouble(
        newValue.text.asDouble,
        min,
        max,
      ).precision(2).toString(),
    );
  }
}
