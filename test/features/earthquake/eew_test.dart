import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Map<String, dynamic> wire = {
    'author': 'cwa',
    'id': '113000',
    'serial': 3,
    'status': 1,
    'final': 1,
    'eq': <String, dynamic>{
      'time': 1700000000000,
      'lon': 121.5,
      'lat': 24.0,
      'depth': 10.0,
      'mag': 5.2,
      'loc': '花蓮縣',
      'max': 4,
    },
  };

  group('Eew.fromJson', () {
    test('maps wire field names and coerces the boolish int', () {
      final eew = Eew.fromJson(wire);
      expect(eew.agency, 'cwa'); // author -> agency
      expect(eew.serial, 3);
      expect(eew.isFinal, isTrue); // final: 1 -> true
      expect(eew.info.magnitude, 5.2); // eq.mag -> info.magnitude
      expect(eew.info.location, '花蓮縣');
      expect(eew.info.latlng, const LatLng(24.0, 121.5));
    });

    test('round-trips symmetrically through toJson', () {
      final eew = Eew.fromJson(wire);
      expect(Eew.fromJson(eew.toJson()), eew);
    });
  });

  group('Eew.isCwa', () {
    Eew withAgency(String agency) => Eew.fromJson({...wire, 'author': agency});

    test('matches the lowercase wire value', () {
      expect(withAgency('cwa').isCwa, isTrue);
    });

    test('matches case-insensitively — a differently-cased agency must not '
        'silently slip past the filter', () {
      expect(withAgency('CWA').isCwa, isTrue);
      expect(withAgency('Cwa').isCwa, isTrue);
    });

    test('rejects every other publishing agency', () {
      expect(withAgency('jma').isCwa, isFalse);
      expect(withAgency('nied').isCwa, isFalse);
      expect(withAgency('').isCwa, isFalse);
    });
  });

  group('Eew.isJma', () {
    Eew withAgency(String agency) => Eew.fromJson({...wire, 'author': agency});

    test('matches the lowercase wire value, case-insensitively', () {
      expect(withAgency('jma').isJma, isTrue);
      expect(withAgency('JMA').isJma, isTrue);
    });

    test('rejects every other publishing agency', () {
      expect(withAgency('cwa').isJma, isFalse);
      expect(withAgency('nied').isJma, isFalse);
      expect(withAgency('').isJma, isFalse);
    });
  });
}
