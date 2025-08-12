import 'dart:ui';

const depth0 = Color(0xFF000000);
const depth1 = Color(0xFFFF0000);
const depth2 = Color(0xFFFF6400);
const depth3 = Color(0xFFFFC800);
const depth4 = Color(0xFF00C800);
const depth5 = Color(0xFF00C8C8);
const depth6 = Color(0xFF0000C8);

Color depth(double depth) {
  final depthList = [5, 15, 30, 50, 100, 150];
  final colorList = [depth1, depth2, depth3, depth4, depth5, depth6];

  if (depth <= depthList.first) return colorList.first;

  if (depth >= depthList.last) return colorList.last;

  for (int i = 0; i < depthList.length - 1; i++) {
    if (depth >= depthList[i] && depth < depthList[i + 1]) {
      final double localT = (depth - depthList[i]) / (depthList[i + 1] - depthList[i]);
      return Color.lerp(colorList[i], colorList[i + 1], localT)!;
    }
  }
  return depth0;
}
