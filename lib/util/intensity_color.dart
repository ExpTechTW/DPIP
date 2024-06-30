import 'package:flutter/material.dart';

class IntensityColor {
  static const intensity0 = Colors.grey;
  static const intensity1 = Color(0xff003264);
  static const intensity2 = Color(0xff0064c8);
  static const intensity3 = Color(0xff1e9632);
  static const intensity4 = Color(0xffffc800);
  static const intensity5 = Color(0xffff9600);
  static const intensity6 = Color(0xffff6400);
  static const intensity7 = Color(0xffff0000);
  static const intensity8 = Color(0xffc00000);
  static const intensity9 = Color(0xff9600c8);

  static Color intensity(int intensity) {
    switch (intensity) {
      case 0:
        return IntensityColor.intensity0;
      case 1:
        return IntensityColor.intensity1;
      case 2:
        return IntensityColor.intensity2;
      case 3:
        return IntensityColor.intensity3;
      case 4:
        return IntensityColor.intensity4;
      case 5:
        return IntensityColor.intensity5;
      case 6:
        return IntensityColor.intensity6;
      case 7:
        return IntensityColor.intensity7;
      case 8:
        return IntensityColor.intensity8;
      case 9:
        return IntensityColor.intensity9;
      default:
        throw "Intensity index out of range. Range: 0..9, Received: $intensity";
    }
  }

  static Color onIntensity(int intensity) {
    switch (intensity) {
      case 4:
      case 5:
        return Colors.black;
      default:
        return Colors.white;
    }
  }
}
