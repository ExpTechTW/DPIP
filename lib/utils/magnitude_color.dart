import 'dart:ui';

class MagnitudeColor {
  MagnitudeColor._();

  static const magnitude0 = Color(0xFF000000);
  static const magnitude1 = Color(0xFF00C8C8);
  static const magnitude2 = Color(0xFF00C800);
  static const magnitude3 = Color(0xFFFFC800);
  static const magnitude4 = Color(0xFFFF0000);
  static const magnitude5 = Color(0xFF9600FF);

  static Color magnitude(double mag) {
    final magnitudeList = [2.5, 3.5, 4.5, 6.0, 7.0];
    final colorList = [
      magnitude1,
      magnitude2,
      magnitude3,
      magnitude4,
      magnitude5,
    ];

    if (mag <= magnitudeList.first) {
      return colorList.first;
    }

    if (mag >= magnitudeList.last) {
      return colorList.last;
    }

    for (int i = 0; i < magnitudeList.length - 1; i++) {
      if (mag >= magnitudeList[i] && mag < magnitudeList[i + 1]) {
        final double localT =
            (mag - magnitudeList[i]) /
            (magnitudeList[i + 1] - magnitudeList[i]);
        return Color.lerp(colorList[i], colorList[i + 1], localT)!;
      }
    }

    return magnitude0;
  }
}
