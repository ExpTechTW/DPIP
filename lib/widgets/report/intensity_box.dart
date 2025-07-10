import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/int.dart';
import 'package:dpip/utils/intensity_color.dart';
import 'package:flutter/material.dart';

class IntensityBox extends StatelessWidget {
  final int intensity;
  final double size;
  final double borderRadius;
  final bool border;

  const IntensityBox({super.key, required this.intensity, this.size = 64, this.borderRadius = 16, this.border = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration:
          border
              ? BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: IntensityColor.intensity(intensity), width: 3.0),
              )
              : BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                color: IntensityColor.intensity(intensity),
              ),
      child: Center(
        child: Text(
          intensity.asIntensityDisplayLabel,
          style: TextStyle(
            color: border ? context.colors.onSurface : IntensityColor.onIntensity(intensity),
            fontSize: size / 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
