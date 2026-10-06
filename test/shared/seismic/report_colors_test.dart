import 'package:dpip/shared/seismic/report_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('magnitude and depth clamp, then blend between stops', () {
    expect(MagnitudeColors.of(1), MagnitudeColors.of(2.5));
    expect(MagnitudeColors.of(9), MagnitudeColors.of(7));
    final mid = MagnitudeColors.of(3);
    expect(mid, isNot(MagnitudeColors.of(2.5)));
    expect(mid, isNot(MagnitudeColors.of(3.5)));

    expect(DepthColors.of(0), DepthColors.of(5));
    expect(DepthColors.of(400), DepthColors.of(150));
    expect(DepthColors.of(10), isNot(DepthColors.of(5)));
    expect(ReportColors.numberedMagnitude, isA<Color>());
  });
}
