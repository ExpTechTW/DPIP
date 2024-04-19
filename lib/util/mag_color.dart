import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

extension MagnitudeColorExtension on ColorScheme {
  Color magnitude(double mag) {
    if (this.brightness == Brightness.light) {
      if (mag > 6.0) {
        return Colors.red[800]!;
      } else if (mag >= 5.0 && mag < 6.0) {
        return Colors.orange[800]!;
      } else if (mag >= 4.0 && mag < 5.0) {
        return Colors.yellow[800]!;
      } else {
        return Colors.green[800]!;
      }
    } else {
      if (mag > 6.0) {
        return Colors.red[400]!;
      } else if (mag >= 5.0 && mag < 6.0) {
        return Colors.orange[400]!;
      } else if (mag >= 4.0 && mag < 5.0) {
        return Colors.yellow[400]!;
      } else {
        return Colors.green[400]!;
      }
    }
  }
}
