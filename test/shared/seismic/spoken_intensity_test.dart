/// Tests speech-safe labels for the split CWA intensity scale.
library;

import 'package:dpip/shared/seismic/spoken_intensity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Traditional Chinese speaks weak and strong words', () {
    expect(spokenIntensityLabel(5, 'zh-TW'), '五弱等級');
    expect(spokenIntensityLabel(6, 'zh-TW'), '五強等級');
    expect(spokenIntensityLabel(7, 'zh-TW'), '六弱等級');
    expect(spokenIntensityLabel(8, 'zh-TW'), '六強等級');
  });

  test('out-of-range values are clamped', () {
    expect(spokenIntensityLabel(-1, 'en'), 'zero');
    expect(spokenIntensityLabel(10, 'en'), 'seven');
  });
}
