import 'package:dpip/features/events/domain/event_addition.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every type family and the headline facts read `addition` through these.
/// The source's JSON is untyped, so each reader takes a wrong type as missing
/// and never throws.
void main() {
  test('objects and lists of objects', () {
    expect(additionMap({'a': 1}), {'a': 1});
    expect(additionMap([1]), isNull);
    expect(additionMap(null), isNull);
    expect(
      additionMaps([
        {'a': 1},
        'x',
        null,
        {'b': 2},
      ]),
      [
        {'a': 1},
        {'b': 2},
      ],
    );
    expect(additionMaps({'a': 1}), isEmpty);
  });

  test('text is trimmed and blank is missing', () {
    expect(additionText('  花蓮縣 '), '花蓮縣');
    expect(additionText('   '), isNull);
    expect(additionText(3), isNull);
  });

  test('a whole number may be written as a double, never beyond exact', () {
    expect(additionInt(4), 4);
    expect(additionInt(4.0), 4);
    expect(additionInt(4.5), isNull);
    expect(additionInt(double.nan), isNull);
    expect(additionInt(1e300), isNull);
    expect(additionInt('4'), isNull);
  });

  test('amounts drop -99 and negatives; stages keep levels above -99', () {
    expect(additionAmount(12), 12.0);
    expect(additionAmount(0), 0.0);
    expect(additionAmount(-99), isNull);
    expect(additionAmount(-0.1), isNull);
    expect(additionAmount(double.infinity), isNull);
    expect(additionStage(-1.2), -1.2);
    expect(additionStage(-99), isNull);
  });

  test('a time must be positive and one DateTime can hold', () {
    expect(additionEpochMs(1785000000000), 1785000000000);
    expect(additionEpochMs(1785000000000.0), 1785000000000);
    expect(additionEpochMs(0), isNull);
    expect(additionEpochMs(-5), isNull);
    expect(additionEpochMs(8640000000000001), isNull);
  });

  test('visibility text maps full-width bounds to ASCII', () {
    expect(additionVisibilityText('＜1'), '< 1');
    expect(additionVisibilityText('> 10'), '> 10');
    expect(additionVisibilityText('0.8'), '0.8');
    expect(additionVisibilityText('＜'), isNull);
  });

  test('decimals drop trailing zeros; the clock is Taipei time', () {
    expect(eventDecimal(50.5, 1), '50.5');
    expect(eventDecimal(21, 1), '21');
    expect(eventDecimal(4.50, 2), '4.5');
    expect(eventDecimal(-0.01, 1), '0');
    // 12:36:31 UTC is 20:36 in Taipei.
    expect(
      eventClock(DateTime.utc(2026, 8, 27, 12, 36, 31).millisecondsSinceEpoch),
      '20:36',
    );
  });
}
