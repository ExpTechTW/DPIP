import 'package:dpip/util/extension/int.dart';
import 'package:dpip/util/intensity_color.dart';
import 'package:flutter/material.dart';

class IntensityBox extends StatelessWidget {
  final int intensity;
  final double size;
  final double borderRadius;

  const IntensityBox({super.key, required this.intensity, this.size = 64, this.borderRadius = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: IntensityColor.intensity(intensity),
      ),
      child: Center(
        child: Text(
          intensity.asIntensityLabel,
          style: TextStyle(
            color: IntensityColor.onIntensity(intensity),
            fontSize: size / 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
