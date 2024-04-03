import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

extension IntensityColor on ColorScheme {
  static const intensity1 = Color(0xff003264);
  static const intensity2 = Color(0xff0064c8);
  static const intensity3 = Color(0xff1e9632);
  static const intensity4 = Color(0xffffc800);
  static const intensity5 = Color(0xffff9600);
  static const intensity6 = Color(0xffff6400);
  static const intensity7 = Color(0xffff0000);
  static const intensity8 = Color(0xffc00000);
  static const intensity9 = Color(0xff9600c8);

  Color intensity(int intensity) {
    switch (intensity) {
      case 1:
        return IntensityColor.intensity1.harmonizeWith(primary);
      case 2:
        return IntensityColor.intensity2.harmonizeWith(primary);
      case 3:
        return IntensityColor.intensity3.harmonizeWith(primary);
      case 4:
        return IntensityColor.intensity4.harmonizeWith(primary);
      case 5:
        return IntensityColor.intensity5.harmonizeWith(primary);
      case 6:
        return IntensityColor.intensity6.harmonizeWith(primary);
      case 7:
        return IntensityColor.intensity7.harmonizeWith(primary);
      case 8:
        return IntensityColor.intensity8.harmonizeWith(primary);
      case 9:
        return IntensityColor.intensity9.harmonizeWith(primary);
      default:
        throw "Intensity index out of range. Range: 0..9, Received: $intensity";
    }
  }

  Color onIntensity(int intensity) {
    switch (intensity) {
      case 4:
      case 5:
        return Colors.black;
      default:
        return Colors.white;
    }
  }
}
