/// [TyphoonKind.path] is interpolated straight into the meteor API's URL
/// (`'$_base/${kind.path}/list'` in `meteor_typhoon_api.dart`), so it has to
/// stay exactly the enum's own member name. A future refactor that gave
/// [TyphoonKind] a custom `path` per value (say, to match a renamed endpoint)
/// would silently start requesting the wrong dataset for every kind whose
/// path no longer equals its name — nothing type-checks a URL segment.
library;

import 'package:dpip/features/typhoon/domain/typhoon_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('path is exactly the member name for every kind', () {
    expect(TyphoonKind.values, hasLength(4));
    for (final kind in TyphoonKind.values) {
      expect(kind.path, kind.name, reason: kind.name);
    }
  });

  test(
    'the four documented kinds are exactly track/potential/probability/warning',
    () {
      expect(TyphoonKind.track.path, 'track');
      expect(TyphoonKind.potential.path, 'potential');
      expect(TyphoonKind.probability.path, 'probability');
      expect(TyphoonKind.warning.path, 'warning');
    },
  );
}
