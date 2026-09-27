/// The region/tier vocabulary [ApiClient.hostsFor] switches on.
///
/// `isRedundant` and the region `code`s are read by nothing but a switch
/// statement today, which is exactly the kind of getter a refactor silently
/// breaks: flip `coreExclusiveApi` to redundant and [ApiClient] would still
/// compile, still run, and only fail over into a host `hostsFor` never
/// actually returns for that tier. Pinning the code/label/redundancy of every
/// member here means that mistake shows up as a red test, not as a status
/// page cell for a host that was never really tried.
library;

import 'package:dpip/core/network/api_region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LbRegion', () {
    test('carries the host code and a human label', () {
      expect(LbRegion.tpe1.code, 'tpe1');
      expect(LbRegion.tpe1.label, 'Taipei');
      expect(LbRegion.khh1.code, 'khh1');
      expect(LbRegion.khh1.label, 'Kaohsiung');
    });

    test('has exactly the two Taiwan edge regions', () {
      expect(LbRegion.values, [LbRegion.tpe1, LbRegion.khh1]);
    });
  });

  group('CoreRegion', () {
    test('carries the host code and a human label', () {
      expect(CoreRegion.tnn1.code, 'tnn1');
      expect(CoreRegion.tnn1.label, 'Tainan');
      expect(CoreRegion.tyo1.code, 'tyo1');
      expect(CoreRegion.tyo1.label, 'Tokyo');
    });

    test('has exactly the two core regions', () {
      expect(CoreRegion.values, [CoreRegion.tnn1, CoreRegion.tyo1]);
    });
  });

  group('ApiTier.isRedundant', () {
    test('is true for every multi-active tier', () {
      expect(ApiTier.lbApi.isRedundant, isTrue);
      expect(ApiTier.lbStatic.isRedundant, isTrue);
      expect(ApiTier.coreApi.isRedundant, isTrue);
      expect(ApiTier.coreStatic.isRedundant, isTrue);
    });

    test('is false for every single-host tier', () {
      // These are exactly the tiers `ApiClient.hostsFor` answers with a
      // single, fixed host — a true value here would be a promise of
      // failover that `hostsFor` cannot keep.
      expect(ApiTier.coreExclusiveApi.isRedundant, isFalse);
      expect(ApiTier.coreStaticExclusive.isRedundant, isFalse);
      expect(ApiTier.legacyApi.isRedundant, isFalse);
    });

    test('classifies every tier — nothing falls through the switch', () {
      for (final tier in ApiTier.values) {
        // A getter, not a switch with a default: if a new tier is added and
        // forgotten here, this loop still calls it — the interesting
        // assertion is just that it doesn't throw.
        expect(() => tier.isRedundant, returnsNormally);
      }
    });
  });
}
