/// A meteor card is one round of station observations. Its summary must list
/// every station with a reading, most severe first, and leave out a reading
/// the source marks as missing (`-99`) instead of showing it; malformed data
/// drops a row or the whole summary, never throws.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/detail/event_detail_blocks.dart';
import 'package:dpip/features/events/presentation/detail/types/meteor_detail.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../event_card_fixtures.dart';

EventCardDetail _fixture(String name) => EventCardDetail.fromJson(
  jsonDecode(
    File('test/fixtures/events_v2/${name}_detail.json').readAsStringSync(),
  ),
);

EventCardDetail _card(String type, Map<String, dynamic>? addition) =>
    EventCardDetail(
      lang: 'en',
      reports: [
        eventReport(
          serial: 1,
          kind: EventReportKind.issue,
          type: type,
          send: DateTime.utc(2026, 11, 18, 4),
          addition: addition,
        ),
      ],
    );

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

/// Pumps the summary of [detail] and returns it.
Future<Widget?> _pumpSummary(
  WidgetTester tester,
  EventCardDetail detail,
) async {
  Widget? summary;
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) {
          summary = const MeteorDetail().summary(context, detail);
          return summary ?? const SizedBox.shrink();
        },
      ),
    ),
  );
  return summary;
}

/// Pumps the body of [report] and returns it.
Future<Widget?> _pumpReportBody(WidgetTester tester, EventReport report) async {
  Widget? body;
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) {
          body = const MeteorDetail().reportBody(context, report);
          return body ?? const SizedBox.shrink();
        },
      ),
    ),
  );
  return body;
}

double _top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  group('summary from the api.md examples', () {
    testWidgets('heavy_rain.short lists the one-hour rainfall', (tester) async {
      expect(
        await _pumpSummary(tester, _fixture('heavy_rain_short')),
        isA<EventDetailSection>(),
      );
      expect(find.text('Stations'), findsOneWidget);
      expect(find.text('臺北市信義區 測試站'), findsOneWidget);
      expect(find.text('50.5 mm'), findsOneWidget);
    });

    testWidgets('heavy_rain.short_extreme lists the one-hour rainfall', (
      tester,
    ) async {
      await _pumpSummary(tester, _fixture('heavy_rain_short_extreme'));
      expect(find.text('臺北市信義區 測試站'), findsOneWidget);
      expect(find.text('85 mm'), findsOneWidget);
    });

    testWidgets('wind.strong names the mean wind when it beats the gust', (
      tester,
    ) async {
      await _pumpSummary(tester, _fixture('wind_strong'));
      expect(find.text('臺北市信義區 信義'), findsOneWidget);
      expect(find.text('Wind speed 21 m/s'), findsOneWidget);
    });

    testWidgets('wind.damaging puts the strongest station first', (
      tester,
    ) async {
      await _pumpSummary(tester, _fixture('wind_damaging'));
      expect(find.text('Gust 42 m/s'), findsOneWidget);
      expect(find.text('Wind speed 33 m/s'), findsOneWidget);
      expect(_top(tester, '臺東縣蘭嶼鄉 蘭嶼'), lessThan(_top(tester, '臺中市梧棲區 梧棲')));
    });

    testWidgets('thunderstorm.lightning lists clusters by strikes', (
      tester,
    ) async {
      await _pumpSummary(tester, _fixture('thunderstorm_lightning'));
      expect(find.text('160'), findsOneWidget);
      expect(find.text('20'), findsNWidgets(2));
      final first = _top(tester, '25.030, 122.491');
      final second = _top(tester, '25.030, 121.500');
      final third = _top(tester, '25.032, 121.004');
      expect(first, lessThan(second));
      expect(second, lessThan(third));
    });

    testWidgets('river_rise.watch reads the level-2 line', (tester) async {
      await _pumpSummary(tester, _fixture('river_rise_watch'));
      expect(find.text('大甲溪零級'), findsOneWidget);
      expect(find.text('7 m / 6 m'), findsOneWidget);
    });

    testWidgets('river_rise.warning reads the level-1 line', (tester) async {
      await _pumpSummary(tester, _fixture('river_rise_warning'));
      expect(find.text('4.5 m / 4 m'), findsOneWidget);
      expect(find.text('2.6 m / -1 m'), findsOneWidget);
      expect(_top(tester, '高屏溪里嶺'), lessThan(_top(tester, '負一級站')));
    });

    testWidgets('fog.visibility shows the source bound, not its stand-in', (
      tester,
    ) async {
      await _pumpSummary(tester, _fixture('fog_visibility'));
      expect(find.text('臺北市北投區 鞍部'), findsOneWidget);
      expect(find.text('連江縣南竿鄉 東引'), findsOneWidget);
      expect(find.text('< 1 km'), findsNWidgets(2));
      expect(find.text('0.5 km'), findsNothing);
    });
  });

  group('ordering and missing readings', () {
    testWidgets('rain: highest first, -99 left out, id for a missing name', (
      tester,
    ) async {
      await _pumpSummary(
        tester,
        _card('heavy_rain.short', {
          'stations': [
            {
              'stationName': 'A',
              'rain': {'1h': 45},
            },
            {
              'stationName': 'B',
              'rain': {'1h': -99},
            },
            {
              'stationId': 'C0A001',
              'rain': {'1h': 90.26},
            },
          ],
        }),
      );
      expect(find.text('B'), findsNothing);
      expect(find.text('90.3 mm'), findsOneWidget);
      expect(_top(tester, 'C0A001'), lessThan(_top(tester, 'A')));
    });

    testWidgets('wind: -99 gust falls back to the mean wind', (tester) async {
      await _pumpSummary(
        tester,
        _card('wind.strong', {
          'stations': [
            {
              'stationName': 'A',
              'wind': {'speed': 25.3},
              'gust': {'speed': -99},
            },
            {
              'stationName': 'B',
              'wind': {'speed': -99},
              'gust': {'speed': -99},
            },
            {
              'stationName': 'C',
              'wind': {'speed': 20},
              'gust': {'speed': 30},
            },
          ],
        }),
      );
      expect(find.text('Wind speed 25.3 m/s'), findsOneWidget);
      expect(find.text('Gust 30 m/s'), findsOneWidget);
      expect(find.text('B'), findsNothing);
      expect(_top(tester, 'C'), lessThan(_top(tester, 'A')));
    });

    testWidgets('lightning: a cluster without a centre or count is left out', (
      tester,
    ) async {
      await _pumpSummary(
        tester,
        _card('thunderstorm.lightning', {
          'stations': [
            {'count': 9},
            {
              'center': {'lat': 23.5, 'lng': 121},
              'count': -99,
            },
            {
              'center': {'lat': 22.1, 'lng': 120.7},
              'count': 4.0,
            },
          ],
        }),
      );
      expect(find.text('22.100, 120.700'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('9'), findsNothing);
      expect(find.text('23.500, 121.000'), findsNothing);
    });

    testWidgets('river: level 1 before level 2, a missing line shows the '
        'level alone', (tester) async {
      await _pumpSummary(
        tester,
        _card('river_rise.watch', {
          'stations': [
            {
              'stationName': 'Watch',
              'stage': 'l2up',
              'waterLevel': 3.2,
              'warningLevel2': 3.0,
              'warningLevel1': null,
            },
            {
              'stationName': 'Gone',
              'stage': 'l1',
              'waterLevel': -99,
              'warningLevel1': 1,
            },
            {
              'stationName': 'Warn',
              'stage': 'l1',
              'waterLevel': 5.55,
              'warningLevel1': null,
            },
          ],
        }),
      );
      expect(find.text('3.2 m / 3 m'), findsOneWidget);
      expect(find.text('5.55 m'), findsOneWidget);
      expect(find.text('Gone'), findsNothing);
      expect(_top(tester, 'Warn'), lessThan(_top(tester, 'Watch')));
    });

    testWidgets('fog: lowest first, full-width bound normalised', (
      tester,
    ) async {
      await _pumpSummary(
        tester,
        _card('fog.visibility', {
          'stations': [
            {'stationName': 'A', 'visibility': 0.8},
            {'stationName': 'B', 'visibility': 0.5, 'visibilityText': '＜1'},
            {'stationName': 'C', 'visibility': -99, 'visibilityText': '<1'},
          ],
        }),
      );
      expect(find.text('0.8 km'), findsOneWidget);
      expect(find.text('< 1 km'), findsOneWidget);
      expect(find.text('C'), findsNothing);
      expect(_top(tester, 'B'), lessThan(_top(tester, 'A')));
    });
  });

  group('malformed addition', () {
    final cases = <String, Map<String, dynamic>?>{
      'null': null,
      'empty': {},
      'stations not a list': {'stations': 'x'},
      'stations of the wrong type': {
        'stations': [1, 'x', null],
      },
      'reading of the wrong type': {
        'stations': [
          {
            'stationName': 'A',
            'rain': {'1h': '50'},
            'wind': '25',
            'gust': {'speed': true},
            'center': [25, 121],
            'count': '9',
            'waterLevel': '3',
            'visibility': '0.5',
          },
        ],
      },
      'no label': {
        'stations': [
          {
            'stationName': ' ',
            'rain': {'1h': 50},
          },
        ],
      },
    };
    const types = [
      'heavy_rain.short',
      'heavy_rain.short_extreme',
      'wind.strong',
      'wind.damaging',
      'thunderstorm.lightning',
      'river_rise.watch',
      'river_rise.warning',
      'fog.visibility',
    ];
    for (final MapEntry(key: name, value: addition) in cases.entries) {
      testWidgets('$name gives no summary', (tester) async {
        for (final type in types) {
          expect(
            await _pumpSummary(tester, _card(type, addition)),
            isNull,
            reason: type,
          );
          expect(tester.takeException(), isNull, reason: type);
        }
      });
    }

    testWidgets('a type outside the family gives no summary', (tester) async {
      expect(
        await _pumpSummary(
          tester,
          _card('heavy-rain', {
            'stations': [
              {
                'stationName': 'A',
                'rain': {'1h': 50},
              },
            ],
          }),
        ),
        isNull,
      );
    });

    testWidgets('one bad station drops only its row', (tester) async {
      await _pumpSummary(
        tester,
        _card('heavy_rain.short', {
          'stations': [
            'x',
            {
              'stationName': 'A',
              'rain': {'1h': 'x'},
            },
            {
              'stationName': 'B',
              'rain': {'1h': 41},
            },
          ],
        }),
      );
      expect(find.text('A'), findsNothing);
      expect(find.text('41 mm'), findsOneWidget);
    });
  });

  group('reportBody', () {
    testWidgets('keeps the headline facts', (tester) async {
      final detail = _fixture('wind_damaging');
      expect(
        await _pumpReportBody(tester, detail.latest),
        isA<EventFactsWrap>(),
      );
      expect(
        find.text('Wind speed 33 m/s', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Gust 42 m/s', findRichText: true), findsOneWidget);
    });

    testWidgets('is empty without an addition', (tester) async {
      final report = _card('fog.visibility', null).latest;
      expect(await _pumpReportBody(tester, report), isNull);
    });
  });
}
