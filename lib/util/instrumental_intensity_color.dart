import 'package:flutter/material.dart';

class InstrumentalIntensityColor {
  static const intensity_3 = Color(0xff0005d0);
  static const intensity_2 = Color(0xff004bf8);
  static const intensity_1 = Color(0xff009EF8);
  static const intensity0 = Color(0xff79E5FD);
  static const intensity1 = Color(0xff49E9AD);
  static const intensity2 = Color(0xff44fa34);
  static const intensity3 = Color(0xffbeff0c);
  static const intensity4 = Color(0xfffff000);
  static const intensity5 = Color(0xffff9300);
  static const intensity6 = Color(0xfffc5235);
  static const intensity7 = Color(0xffb720e9);

  static Color intensity(int intensity) {
    switch (intensity) {
      case -3:
        return intensity_3;
      case -2:
        return intensity_2;
      case -1:
        return intensity_1;
      case 0:
        return intensity0;
      case 1:
        return intensity1;
      case 2:
        return intensity2;
      case 3:
        return intensity3;
      case 4:
        return intensity4;
      case 5:
        return intensity5;
      case 6:
        return intensity6;
      case 7:
        return intensity7;
      default:
        throw "Intensity index out of range. Range: 0..9, Received: $intensity";
    }
  }

  static Color i(double? intensity) {
    if (intensity == null) {
      return Colors.transparent;
    }

    final ceil = intensity.ceil();
    final ceilColor = InstrumentalIntensityColor.intensity(ceil);
    final floor = intensity.floor();
    final floorColor = InstrumentalIntensityColor.intensity(floor);
    final tween = ColorTween(begin: floorColor, end: ceilColor);
    return tween.lerp(intensity - floor)!;
  }
}
