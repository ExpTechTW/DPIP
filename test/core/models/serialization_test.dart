/// The API encodes booleans as `0`/`1`, sometimes as strings. A decoder that
/// only accepts `true` would store every flag as off.
library;

import 'package:dpip/core/models/serialization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('boolishInt accepts only the integer and string forms of 1', () {
    expect(boolishInt(1), isTrue);
    expect(boolishInt('1'), isTrue);
    expect(boolishInt(0), isFalse);
    expect(boolishInt('0'), isFalse);
    expect(boolishInt(true), isFalse);
    expect(boolishInt(null), isFalse);
  });

  test('intFromBool is the inverse used by toJson', () {
    expect(intFromBool(true), 1);
    expect(intFromBool(false), 0);
    expect(boolishInt(intFromBool(true)), isTrue);
    expect(boolishInt(intFromBool(false)), isFalse);
  });
}
