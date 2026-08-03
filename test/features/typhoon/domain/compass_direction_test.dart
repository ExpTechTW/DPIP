import 'package:dpip/features/typhoon/domain/compass_direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps CWA 16-point codes', () {
    expect(compassDirection('WNW')?.zh, '西北西');
    expect(compassDirection('wnw')?.en, 'west-northwest');
    expect(compassDirection('N')?.zh, '北');
    expect(compassDirection(null), isNull);
    expect(compassDirection('XYZ'), isNull);
  });
}
