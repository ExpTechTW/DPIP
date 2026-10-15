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

  group('Eew.kind reads the wire status', () {
    Eew withStatus(int status, {String author = 'cwa'}) =>
        Eew.fromJson({...wire, 'status': status, 'author': author});

    test('0 is an ordinary 預警 report', () {
      expect(withStatus(0).kind, EewReportKind.forecast);
      expect(withStatus(0).isCancelled, isFalse);
      expect(withStatus(0).isWarning, isFalse);
    });

    test('1 is the agency\'s public 警報', () {
      expect(withStatus(1).kind, EewReportKind.warning);
      expect(withStatus(1).isWarning, isTrue);
      expect(withStatus(1).isCancelled, isFalse);
    });

    test('3 is a CWA cancel and 2 the event server\'s cancel code', () {
      expect(withStatus(3).isCancelled, isTrue);
      expect(withStatus(2, author: 'nied').isCancelled, isTrue);
      expect(withStatus(2).kind, EewReportKind.cancelled);
    });

    test('an unknown code never reads as a cancel — a misread code must '
        'leave an alert up, not hide one', () {
      for (final status in [-1, 4, 9, 255]) {
        expect(withStatus(status).kind, EewReportKind.forecast);
        expect(withStatus(status).isCancelled, isFalse);
      }
    });

    test('a final report is not a cancel', () {
      final last = Eew.fromJson({...wire, 'status': 0, 'final': 1});
      expect(last.isFinal, isTrue);
      expect(last.isCancelled, isFalse);
    });
  });

  group('Eew.eventKey', () {
    test('is one key per agency event, across serials and spellings', () {
      final a = Eew.fromJson({...wire, 'serial': 1});
      final b = Eew.fromJson({...wire, 'serial': 5, 'author': 'CWA'});
      expect(a.eventKey, b.eventKey);
    });

    test('keeps two agencies\' same-numbered events apart', () {
      final cwa = Eew.fromJson(wire);
      final nied = Eew.fromJson({...wire, 'author': 'nied'});
      expect(cwa.eventKey, isNot(nied.eventKey));
    });
  });

  group('cancel filter', () {
    final live = Eew.fromJson({...wire, 'id': 'live', 'status': 0});
    final cancelled = Eew.fromJson({...wire, 'id': 'gone', 'status': 3});

    test('uncancelled keeps order and drops only the cancelled', () {
      expect([cancelled, live].uncancelled, [live]);
      expect([live, cancelled, live].uncancelled, [live, live]);
    });

    test('hasUncancelled is false for a set of only cancelled alerts', () {
      expect([cancelled].hasUncancelled, isFalse);
      expect([cancelled, live].hasUncancelled, isTrue);
      expect(const <Eew>[].hasUncancelled, isFalse);
    });
  });
}
