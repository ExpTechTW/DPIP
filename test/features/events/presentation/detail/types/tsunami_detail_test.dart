/// A tsunami warning's detail must list where the waves are expected and
/// when, earliest first, stop showing those estimates once the warning is
/// lifted, and list what the tide stations observed. Malformed data drops a
/// row or the summary, never the page.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/detail/event_detail_blocks.dart';
import 'package:dpip/features/events/presentation/detail/types/tsunami_detail.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _detail = TsunamiDetail();

Map<String, dynamic> _fixture(String name) => jsonDecode(
  File('test/fixtures/events_v2/${name}_detail.json').readAsStringSync(),
) as Map<String, dynamic>;

/// The tsunami.warning fixture's reports up to serial [upTo], with the last
/// one's `addition` replaced by [addition] when given.
EventCardDetail _warning({int upTo = 5, Object? Function()? addition}) {
  final body = _fixture('tsunami_warning');
  final cards = [
    for (final card
        in (body['cards'] as List<dynamic>).cast<Map<String, dynamic>>())
      if ((card['serial'] as int) <= upTo) card,
  ];
  if (addition != null) cards.last['addition'] = addition();
  return EventCardDetail.fromJson({'lang': body['lang'], 'cards': cards});
}

/// A copy of report 2's estimate `addition`, for editing.
Map<String, dynamic> _estimateAddition() {
  final body = _fixture('tsunami_warning');
  final card = (body['cards'] as List<dynamic>).cast<Map<String, dynamic>>()[1];
  return card['addition'] as Map<String, dynamic>;
}

/// Pumps whatever [build] returns and gives it back.
Future<Widget?> _pump(
  WidgetTester tester,
  Widget? Function(BuildContext context) build,
) async {
  Widget? built;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            built = build(context);
            return ListView(children: [?built]);
          },
        ),
      ),
    ),
  );
  return built;
}

Future<Widget?> _summary(WidgetTester tester, EventCardDetail detail) =>
    _pump(tester, (context) => _detail.summary(context, detail));

/// The row values in the order drawn.
List<String> _values(WidgetTester tester) => [
  for (final row
      in tester.widget<EventDetailRows>(find.byType(EventDetailRows)).rows)
    row.value,
];

void main() {
  group('tsunami.warning', () {
    testWidgets('an active warning lists each area, earliest arrival first', (
      tester,
    ) async {
      final summary = await _summary(tester, _warning(upTo: 2));

      expect(summary, isA<EventDetailSection>());
      expect(find.text('Forecast by area'), findsOneWidget);
      expect(find.text('Observed'), findsNothing);
      expect(find.text('臺灣東部沿海地區'), findsOneWidget);
      expect(find.text('1.0 m · 20:56'), findsOneWidget);
      expect(find.text('臺灣北部沿海地區'), findsOneWidget);
      expect(find.text('0.5 m · 21:16'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('臺灣東部沿海地區')).dy,
        lessThan(tester.getTopLeft(find.text('臺灣北部沿海地區')).dy),
      );
    });

    testWidgets('rows run by arrival time, not by the order sent', (
      tester,
    ) async {
      await _summary(
        tester,
        _warning(
          upTo: 2,
          addition: () {
            final addition = _estimateAddition();
            final info = addition['info'] as Map<String, dynamic>;
            info['data'] = [
              {
                'area': 'Late',
                'arrival_time': 1785071791000,
                'wave_height': 50,
              },
              {'area': 'No time', 'wave_height': 120},
              {
                'area': 'Early',
                'arrival_time': 1785070591000,
                'wave_height': 300,
              },
            ];
            return addition;
          },
        ),
      );

      expect(_values(tester), ['3.0 m · 20:56', '0.5 m · 21:16', '1.2 m']);
      expect(
        [
          for (final row
              in tester
                  .widget<EventDetailRows>(find.byType(EventDetailRows))
                  .rows)
            row.label,
        ],
        ['Early', 'Late', 'No time'],
      );
    });

    testWidgets('a lifted warning shows its observations, not estimates', (
      tester,
    ) async {
      final summary = await _summary(tester, _warning());

      expect(summary, isA<EventDetailSection>());
      expect(find.text('Observed'), findsOneWidget);
      expect(find.text('Forecast by area'), findsNothing);
      expect(find.text('臺灣東部沿海地區'), findsNothing);
      expect(find.text('花蓮'), findsOneWidget);
      expect(_values(tester), [
        '0.25 m · 20:41',
        '0.12 m · 20:44',
        '0.08 m · 20:48',
        '0.05 m · 20:51',
      ]);
    });

    testWidgets('a lifted warning with only estimates has no summary', (
      tester,
    ) async {
      expect(await _summary(tester, _warning(upTo: 4)), isNull);
      expect(find.byType(EventDetailSection), findsNothing);
    });

    testWidgets('lifted written as 2.0 or "2" also hides the estimates', (
      tester,
    ) async {
      for (final status in <Object>[2.0, '2']) {
        final detail = _warning(
          upTo: 2,
          addition: () => _estimateAddition()..['status'] = status,
        );
        expect(await _summary(tester, detail), isNull, reason: '$status');
      }
    });

    testWidgets('an unknown info type has no summary', (tester) async {
      expect(await _summary(tester, _warning(upTo: 3)), isNull);
    });

    testWidgets('a malformed addition never throws', (tester) async {
      final malformed = <Object? Function()>[
        () => null,
        () => <String, dynamic>{},
        () => 'not an object',
        () => {'status': 1, 'info': 'estimate'},
        () => {'status': 1, 'info': <String, dynamic>{}},
        () => {
          'status': 1,
          'info': {'type': 'estimate', 'data': 'rows'},
        },
        () => {
          'status': 1,
          'info': {'type': 'estimate', 'data': <Object?>[]},
        },
        () => {
          'status': 1,
          'info': {
            'type': 'estimate',
            'data': [
              null,
              7,
              'row',
              {'area': 3, 'arrival_time': 1785070591000, 'wave_height': 100},
              {'area': '  ', 'arrival_time': 1785070591000, 'wave_height': 100},
              {'area': 'A', 'arrival_time': '20:56', 'wave_height': '100'},
              {'area': 'B', 'arrival_time': -1, 'wave_height': -99},
              {'area': 'C', 'arrival_time': 1e300, 'wave_height': double.nan},
            ],
          },
        },
      ];
      for (final (index, addition) in malformed.indexed) {
        final summary = await _summary(
          tester,
          _warning(upTo: 2, addition: addition),
        );
        expect(summary, isNull, reason: 'case $index');
        expect(tester.takeException(), isNull, reason: 'case $index');
      }
    });

    testWidgets('a malformed field drops only its own part of a row', (
      tester,
    ) async {
      await _summary(
        tester,
        _warning(
          upTo: 2,
          addition: () => {
            'status': 1,
            'info': {
              'type': 'estimate',
              'data': [
                'row',
                {
                  'area': 'Height only',
                  'arrival_time': 'soon',
                  'wave_height': 80,
                },
                {
                  'area': 'Time only',
                  'arrival_time': 1785070591000,
                  'wave_height': null,
                },
                {'arrival_time': 1785070591000, 'wave_height': 80},
              ],
            },
          },
        ),
      );

      expect(_values(tester), ['20:56', '0.8 m']);
    });

    testWidgets('a station with a null reading keeps its arrival time', (
      tester,
    ) async {
      await _summary(
        tester,
        _warning(
          addition: () => {
            'status': 2,
            'info': {
              'type': 'actual',
              'data': [
                {
                  'name': '花蓮',
                  'wave_height': null,
                  'arrival_time': 1785069691000,
                },
                {'name': '成功', 'wave_height': 12},
              ],
            },
          },
        ),
      );

      expect(find.text('Observed'), findsOneWidget);
      expect(_values(tester), ['20:41', '0.12 m']);
    });

    testWidgets('each report keeps its default facts', (tester) async {
      final detail = _warning(upTo: 2);
      final body = await _pump(
        tester,
        (context) => _detail.reportBody(context, detail.latest),
      );

      expect(body, isA<EventFactsWrap>());
      expect(find.textContaining('M 7.2'), findsOneWidget);
      expect(find.textContaining('100 cm'), findsOneWidget);
    });
  });

  group('tsunami.info', () {
    EventCardDetail info() =>
        EventCardDetail.fromJson(_fixture('tsunami_info'));

    testWidgets('names no area, so there is no summary', (tester) async {
      expect(await _summary(tester, info()), isNull);
    });

    testWidgets('each report keeps its default facts', (tester) async {
      final detail = info();
      final body = await _pump(
        tester,
        (context) => _detail.reportBody(context, detail.latest),
      );

      expect(body, isA<EventFactsWrap>());
      expect(find.textContaining('11:50'), findsOneWidget);
    });
  });
}
