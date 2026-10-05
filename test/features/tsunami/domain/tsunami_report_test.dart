/// The `data.area` tuples CWA sends, the wave-height scale both the map and the
/// sheet colour by, and the event grouping behind the sheet's 第N報 picker.
///
/// Both tuple shapes matter because they decode without complaint under the
/// wrong branch — a prediction read as an observation would take its name from
/// a coast description and its reading from a predicted height, and the only
/// thing visibly wrong would be the panel. The fixtures are the real
/// 2024-04-03 花蓮 event's payloads (`…300301-…` 第1報 `predict`; `…300302-…`
/// 第2報 `predict`; `…300303-…` 第3報 `observe`), including the 臺中港 entry
/// whose coordinates are `null` — the one row `tsunamiGeoJson` has to skip.
library;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/features/map/presentation/layers/tsunami_layer.dart';
import 'package:dpip/features/tsunami/domain/tsunami_report.dart';
import 'package:flutter_test/flutter_test.dart';

const Map<String, dynamic> _predict = {
  'id': 'CWA-TSU11300301-2024-0403-081100',
  'sent': 1712103060000,
  'msgType': 'Issue',
  'no': 113003,
  'rep': '第1報',
  'type': '海嘯警報',
  'content': '…',
  'eq': {
    't': 1712102280000,
    'lon': 121.67,
    'lat': 23.77,
    'loc': '臺灣東部海域',
    'dep': 15.5,
    'mag': 7.3,
  },
  'data': {
    'type': 'predict',
    'area': [
      ['東部沿海地區', '宜蘭縣南澳鄉至臺東縣長濱鄉沿岸', '<1', 1712102340000, '黃色'],
      ['海峽沿海地區', '桃園市至嘉義縣沿岸', '<1', 1712109480000, '黃色'],
    ],
  },
};

const Map<String, dynamic> _observe = {
  'id': 'CWA-TSU11300303-2024-0403-111000',
  'sent': 1712113800000,
  'msgType': 'Cancel',
  'no': 113003,
  'rep': '第3報',
  'type': '海嘯警報解除',
  'content': '…',
  'eq': {
    't': 1712102280000,
    'lon': 121.67,
    'lat': 23.77,
    'loc': '臺灣',
    'dep': 15.5,
    'mag': 7.2,
  },
  'data': {
    'type': 'observe',
    'area': [
      ['HL', '花蓮', '27公分', 1712104200000, 121.62, 23.98],
      ['CK', '台東成功', '54公分', 1712105520000, 121.38, 23.09],
      ['TO', '宜蘭烏石', '82公分', 1712106720000, 121.84, 24.87],
      ['臺中港臺中港', '臺中港臺中港', '27公分', 1712108160000, null, null],
    ],
  },
};

void main() {
  group('TsunamiReport.decode', () {
    test('a predict bulletin decodes its five-field area tuples', () {
      final report = TsunamiReport.decode(_predict);

      expect(report.report, '第1報');
      expect(report.msgType, 'Issue');
      expect(report.type, '海嘯警報');
      // `eq` is a plain object on the wire, so it goes through the generated
      // `fromJson` — the one place a `@JsonKey` typo would silently null a
      // field instead of throwing.
      expect(report.earthquake.location, '臺灣東部海域');
      expect(report.earthquake.magnitude, 7.3);
      expect(report.earthquake.depth, 15.5);
      expect(report.earthquake.longitude, 121.67);
      expect(
        report.earthquake.time,
        1712102280000,
        reason: 'earthquake origin time is a @JsonKey rename of `t`',
      );
      expect(report.observations, isEmpty);
      expect(report.predictions, hasLength(2));
      final first = report.predictions.first;
      expect(first.area, '東部沿海地區');
      expect(first.coast, '宜蘭縣南澳鄉至臺東縣長濱鄉沿岸');
      expect(first.height, '<1');
      expect(first.arrivalTime, 1712102340000);
    });

    test('an observe bulletin decodes its six-field area tuples', () {
      final report = TsunamiReport.decode(_observe);

      expect(report.predictions, isEmpty);
      expect(report.observations, hasLength(4));
      final first = report.observations.first;
      expect(first.name, '花蓮');
      expect(first.height, '27公分');
      expect(first.time, 1712104200000);
      expect(first.longitude, 121.62);
      expect(first.latitude, 23.98);
    });

    test('a station that reported no position keeps a null one', () {
      final station = TsunamiReport.decode(_observe).observations.last;
      expect(station.name, '臺中港臺中港');
      expect(station.longitude, isNull);
      expect(station.latitude, isNull);
    });

    test('a bulletin whose data block is empty decodes to neither list', () {
      final report = TsunamiReport.decode({
        ..._predict,
        'data': const {'type': 'predict'},
      });
      expect(report.predictions, isEmpty);
      expect(report.observations, isEmpty);
    });
  });

  group('predicted coast', () {
    Map<String, dynamic> predictBulletin(List<List<Object?>> rows) => {
      ..._predict,
      'data': {'type': 'predict', 'area': rows},
    };

    test('a prediction keeps CWA\'s own warning colour', () {
      final first = TsunamiReport.decode(_predict).predictions.first;
      expect(first.color, '黃色');
    });

    test('a four-field tuple has no colour rather than failing', () {
      final report = TsunamiReport.decode(
        predictBulletin([
          ['東部沿海地區', '宜蘭縣南澳鄉至臺東縣長濱鄉沿岸', '<1', 1712102340000],
        ]),
      );
      expect(report.predictions.single.color, isNull);
    });

    test('CWA colours map to the legacy steps, and nothing is invented', () {
      expect(TsunamiWaveBand.ofWarningColor('黃色'), TsunamiWaveBand.from30cm);
      expect(TsunamiWaveBand.ofWarningColor('紅色'), TsunamiWaveBand.from1m);
      expect(TsunamiWaveBand.ofWarningColor('紫色'), TsunamiWaveBand.over3m);
      // An unknown colour must not be defaulted to the quiet blue.
      expect(TsunamiWaveBand.ofWarningColor('綠色'), isNull);
      expect(TsunamiWaveBand.ofWarningColor(null), isNull);
    });

    test('each region is banded by its own colour', () {
      final bands = tsunamiAreaBands(TsunamiReport.decode(_predict));
      expect(bands, {
        '東部沿海地區': TsunamiWaveBand.from30cm,
        '海峽沿海地區': TsunamiWaveBand.from30cm,
      });
    });

    test('a region listed twice keeps its higher band', () {
      final bands = tsunamiAreaBands(
        TsunamiReport.decode(
          predictBulletin([
            ['東部沿海地區', 'a', '<1', 1, '紅色'],
            ['東部沿海地區', 'b', '<1', 1, '黃色'],
          ]),
        ),
      );
      expect(bands, {'東部沿海地區': TsunamiWaveBand.from1m});
    });

    test('an observe bulletin paints no coast', () {
      expect(tsunamiAreaBands(TsunamiReport.decode(_observe)), isEmpty);
    });
  });

  group('TsunamiBulletin', () {
    test('fromJson reads no/rep, toJson restores the wire keys', () {
      final json = <String, dynamic>{
        'id': 'CWA-TSU11300303-2024-0403-111000',
        'no': 113003,
        'rep': '第3報',
        'type': '海嘯警報解除',
        'sent': 1712113800000,
      };

      final bulletin = TsunamiBulletin.fromJson(json);

      expect(bulletin.number, 113003);
      expect(bulletin.report, '第3報');
      expect(bulletin.type, '海嘯警報解除');
      expect(bulletin.sent, 1712113800000);
      expect(bulletin.toJson(), json);
    });

    Map<String, dynamic> row(String id, int no, String rep, int sent) => {
      'id': id,
      'no': no,
      'rep': rep,
      'type': '海嘯警報',
      'sent': sent,
    };

    test('newestEvent keeps the newest event\'s reports, newest first', () {
      final bulletins = TsunamiBulletin.newestEvent([
        row('b-3', 113004, '第1報', 300),
        row('a-3', 113003, '第3報', 200),
        row('a-2', 113003, '第2報', 100),
        row('a-1', 113003, '第1報', 50),
      ]);

      // 113004 is this year's event and 113003 last year's: the picker must
      // offer this year's three reports and never the older event's, or a
      // reader reopening the layer during a quiet season would be shown a
      // bulletin from the previous year as though it were current.
      expect([for (final b in bulletins) b.id], ['b-3']);
    });

    test('newestEvent keeps every report of one event, in index order', () {
      final bulletins = TsunamiBulletin.newestEvent([
        row('a-3', 113003, '第3報', 200),
        row('a-2', 113003, '第2報', 100),
        row('a-1', 113003, '第1報', 50),
      ]);

      expect([for (final b in bulletins) b.report], ['第3報', '第2報', '第1報']);
    });

    test('newestEvent over an empty index is empty, not an error', () {
      expect(TsunamiBulletin.newestEvent(const []), isEmpty);
    });
  });

  group('wave-height scale', () {
    test('a reading lands in the band CWA defines', () {
      // CWA's boundaries, and both sides of each: 30 cm, 100 cm, 300 cm.
      expect(TsunamiWaveBand.of(0), TsunamiWaveBand.under30cm);
      expect(TsunamiWaveBand.of(29), TsunamiWaveBand.under30cm);
      expect(TsunamiWaveBand.of(30), TsunamiWaveBand.from30cm);
      expect(TsunamiWaveBand.of(99), TsunamiWaveBand.from30cm);
      expect(TsunamiWaveBand.of(100), TsunamiWaveBand.from1m);
      expect(TsunamiWaveBand.of(299), TsunamiWaveBand.from1m);
      expect(TsunamiWaveBand.of(300), TsunamiWaveBand.over3m);
      expect(TsunamiWaveBand.of(1000), TsunamiWaveBand.over3m);
    });

    test('the observed text becomes centimetres', () {
      expect(parseObservedCentimeters('27公分'), 27);
      expect(parseObservedCentimeters('82公分'), 82);
      expect(parseObservedCentimeters('1.5 公尺'), 150);
      expect(
        parseObservedCentimeters('不明'),
        isNull,
        reason: 'no number is not a zero-centimetre wave',
      );
    });

    test('the four band colours are the legacy palette', () {
      // Pinned because the map, the legend and the chips all read them: a
      // changed hex here silently repaints a safety scale.
      expect(
        TsunamiMapLayer.bandColor(TsunamiWaveBand.over3m),
        '#E543FF'.vision,
      );
      expect(
        TsunamiMapLayer.bandColor(TsunamiWaveBand.from1m),
        '#C90000'.vision,
      );
      expect(
        TsunamiMapLayer.bandColor(TsunamiWaveBand.from30cm),
        '#FFC900'.vision,
      );
      expect(
        TsunamiMapLayer.bandColor(TsunamiWaveBand.under30cm),
        '#00AAFF'.vision,
      );
    });
  });

  group('map geometry', () {
    test('the map skips an observation with no coordinates', () {
      final features =
          tsunamiGeoJson(TsunamiReport.decode(_observe))['features'] as List;

      // Epicentre + three positioned stations; 臺中港 is dropped. A station with
      // no position is not "somewhere off the coast" — putting `null` into a
      // Point is a crash, not a marker.
      expect(features, hasLength(4));
      expect((features.first as Map)['properties'], {'kind': 'epicenter'});
      expect((features.first as Map)['geometry'], {
        'type': 'Point',
        'coordinates': [121.67, 23.77],
      });
      expect(features[1], {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [121.62, 23.98],
        },
        'properties': {
          'kind': 'observation',
          'band': 'under30cm',
          'label': '花蓮\n27公分',
        },
      });
    });

    test('each reading carries its band, not a colour', () {
      final features =
          tsunamiGeoJson(TsunamiReport.decode(_observe))['features'] as List;
      final bands = [
        for (final feature in features.skip(1))
          (feature as Map)['properties']['band'],
      ];
      // 27 cm and 54 cm read quiet on the scale, 82 cm reaches 0.3-1 m — the
      // heights the legacy palette was chosen for.
      expect(bands, ['under30cm', 'from30cm', 'from30cm']);
    });
  });
}
