import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

extension magColor on ColorScheme {
  static const mag1 = Color(0xff003264);
  static const mag2 = Color(0xff0064c8);
  static const mag3 = Color(0xff1e9632);
  static const mag4 = Color(0xffffc800);
  static const mag5 = Color(0xffff9600);
  static const mag6 = Color(0xffff6400);
  static const mag7 = Color(0xffff0000);
  static const mag8 = Color(0xffc00000);
  static const mag9 = Color(0xff9600c8);

  Color mag(int mag) {
    switch (mag) {
      case 1:
        return magColor.mag1.harmonizeWith(primary);
      case 2:
        return magColor.mag2.harmonizeWith(primary);
      case 3:
        return magColor.mag3.harmonizeWith(primary);
      case 4:
        return magColor.mag4.harmonizeWith(primary);
      case 5:
        return magColor.mag5.harmonizeWith(primary);
      case 6:
        return magColor.mag6.harmonizeWith(primary);
      case 7:
        return magColor.mag7.harmonizeWith(primary);
      case 8:
        return magColor.mag8.harmonizeWith(primary);
      case 9:
        return magColor.mag9.harmonizeWith(primary);
      default:
        throw "Intensity index out of range. Range: 0..9, Received: $mag";
    }
  }

  Color onmag(int mag) {
    switch (mag) {
      case 4:
      case 5:
        return Colors.black;
      default:
        return Colors.white;
    }
  }
}
