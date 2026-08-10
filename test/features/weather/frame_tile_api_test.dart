import 'package:dpip/features/weather/data/frame_tile_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FrameTileApi.framesFromList', () {
    test('decodes delta-seconds and returns them newest first', () {
      // [baseSec, +600, +600] → 1783360200, 1783360800, 1783361400 (10-min steps)
      expect(FrameTileApi.framesFromList([1783360200, 600, 600]), [
        '1783361400',
        '1783360800',
        '1783360200',
      ]);
    });

    test('decodes delta-millis (QPESUMS) the same way', () {
      // [baseMs, +600000, +600000] → 1786208400000, 1786209000000,
      // 1786209600000 (10-min steps)
      expect(FrameTileApi.framesFromList([1786208400000, 600000, 600000]), [
        '1786209600000',
        '1786209000000',
        '1786208400000',
      ]);
    });

    test('an empty list yields no frames', () {
      expect(FrameTileApi.framesFromList(const []), isEmpty);
    });

    test('a single-frame list is just the base timestamp', () {
      expect(FrameTileApi.framesFromList([1783360200]), ['1783360200']);
    });

    test('frame ids keep their digit width, usable straight in a tile URL', () {
      final seconds = FrameTileApi.framesFromList([1783360200, 600]);
      expect(seconds.first.length, 10);
      final millis = FrameTileApi.framesFromList([1786208400000, 600000]);
      expect(millis.first.length, 13);
    });
  });
}
