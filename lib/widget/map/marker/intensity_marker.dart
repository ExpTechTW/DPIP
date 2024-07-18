import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/extension/int.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:flutter/material.dart';

class IntensityMarker extends StatelessWidget {
  final double size;
  final int intensity;

  const IntensityMarker({
    super.key,
    this.size = 20,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        border: Border.all(
          color: context.colors.onSurface,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
        color: IntensityColor.intensity(intensity),
      ),
      child: Center(
        child: Text(
          intensity.asIntensityDisplayLabel,
          style: TextStyle(
            color: IntensityColor.onIntensity(intensity),
            height: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
