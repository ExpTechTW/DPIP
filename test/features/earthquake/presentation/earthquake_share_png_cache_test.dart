import 'dart:typed_data';

import 'package:dpip/features/earthquake/presentation/widgets/earthquake_share_png_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'retains at most fourteen images and evicts the least recently used',
    () {
      final cache = EarthquakeSharePngCache<int>();
      for (var key = 0; key < 14; key++) {
        cache.store(key, Uint8List(1));
      }
      expect(cache.lookup(0), isNotNull);
      cache.store(14, Uint8List(1));
      expect(cache.lookup(1), isNull);
      expect(cache.lookup(0), isNotNull);
      expect(cache.lookup(14), isNotNull);
    },
  );

  test(
    'counts compressed bytes across entries and rejects oversized images',
    () {
      final cache = EarthquakeSharePngCache<String>();
      const mib = 1024 * 1024;
      final a = Uint8List(3 * mib);
      final b = Uint8List(5 * mib);
      cache.store('a', a);
      cache.store('b', b);
      expect(cache.lookup('a'), same(a));
      cache.store('c', Uint8List(mib));
      expect(cache.lookup('b'), isNull);
      expect(cache.lookup('a'), same(a));
      cache.store('large', Uint8List(8 * mib + 1));
      expect(cache.lookup('large'), isNull);
      expect(cache.lookup('c'), isNotNull);
      cache.clear();
      expect(cache.lookup('a'), isNull);
      expect(cache.lookup('c'), isNull);
    },
  );
}
