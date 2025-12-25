import 'dart:ui';

const kDepthColor0 = Color(0xFF000000);
const kDepthColor1 = Color(0xFFFF0000);
const kDepthColor2 = Color(0xFFFF6400);
const kDepthColor3 = Color(0xFFFFC800);
const kDepthColor4 = Color(0xFF00C800);
const kDepthColor5 = Color(0xFF00C8C8);
const kDepthColor6 = Color(0xFF0000C8);

Color getDepthColor(double depth) {
  final depthList = [5, 15, 30, 50, 100, 150];
  final colorList = [
    kDepthColor1,
    kDepthColor2,
    kDepthColor3,
    kDepthColor4,
    kDepthColor5,
    kDepthColor6,
  ];

  if (depth <= depthList.first) return colorList.first;

  if (depth >= depthList.last) return colorList.last;

  for (int i = 0; i < depthList.length - 1; i++) {
    if (depth >= depthList[i] && depth < depthList[i + 1]) {
      final double localT =
          (depth - depthList[i]) / (depthList[i + 1] - depthList[i]);
      return Color.lerp(colorList[i], colorList[i + 1], localT)!;
    }
  }
  return kDepthColor0;
}
