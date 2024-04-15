import 'package:flutter/material.dart';

extension MagnitudeColorExtension on double {
  Color getMagnitudeColor() {
    if (this > 6.0) {
      return Colors.red;
    } else if (this >= 5.0 && this < 6.0) {
      return Colors.orange;
    } else if (this >= 4.0 && this < 5.0) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  Color getMagColor() {
    if (this >= 4.0) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }
}
