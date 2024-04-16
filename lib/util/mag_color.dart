import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

extension MagnitudeColorExtension on ColorScheme {
  Color magnitude(double mag) {
    if (mag > 6.0) {
      return Colors.red.harmonizeWith(primary);
    } else if (mag >= 5.0 && mag < 6.0) {
      return Colors.orange.harmonizeWith(primary);
    } else if (mag >= 4.0 && mag < 5.0) {
      return Colors.yellow.harmonizeWith(primary);
    } else {
      return Colors.green.harmonizeWith(primary);
    }
  }

  Color onMagnitude(double mag) {
    if (mag >= 4.0) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }
}
