/// A missing-station card's detail lists its latest report's stations in the
/// server's order, by name and place, and stays empty rather than throwing
/// when the addition is missing or malformed.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/detail/event_detail_blocks.dart';
import 'package:dpip/features/events/presentation/detail/types/station_missing_detail.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _fixtureName =
    'test/fixtures/events_v2/earthquake_station_missing_detail';

Map<String, dynamic> _fixtureJson() =>
    jsonDecode(File('$_fixtureName.json').readAsStringSync())
        as Map<String, dynamic>;

EventCardDetail _fixture() => EventCardDetail.fromJson(_fixtureJson());

/// The fixture with its report's `addition` replaced by [addition], or
/// removed when [drop].
EventCardDetail _withAddition(Object? addition, {bool drop = false}) {
  final json = _fixtureJson();
  for (final card in json['cards'] as List<Object?>) {
    final report = card! as Map<String, dynamic>;
    if (drop) {
      report.remove('addition');
    } else {
      report['addition'] = addition;
    }
  }
  return EventCardDetail.fromJson(json);
}

/// The fixture with its report's `addition.stations` replaced.
EventCardDetail _withStations(Object? stations) {
  final report = (_fixtureJson()['cards'] as List<Object?>).first! as Map;
  return _withAddition({
    ...(report['addition'] as Map<String, dynamic>),
    'stations': stations,
  });
}

Widget _app(Widget Function(BuildContext) build) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(child: Builder(builder: build)),
  ),
);

/// Pumps [StationMissingDetail.summary] of [detail] and returns what it gave.
Future<Widget?> _pumpSummary(
  WidgetTester tester,
  EventCardDetail detail,
) async {
  Widget? summary;
  await tester.pumpWidget(
    _app((context) {
      summary = const StationMissingDetail().summary(context, detail);
      return summary ?? const SizedBox.shrink();
    }),
  );
  return summary;
}

/// Pumps [StationMissingDetail.reportBody] of [report] and returns what it
/// gave.
Future<Widget?> _pumpBody(WidgetTester tester, EventReport report) async {
  Widget? body;
  await tester.pumpWidget(
    _app((context) {
      body = const StationMissingDetail().reportBody(context, report);
      return body ?? const SizedBox.shrink();
    }),
  );
  return body;
}

void main() {
  group('summary', () {
    testWidgets('lists each station by name and place, in server order', (
      tester,
    ) async {
      final summary = await _pumpSummary(tester, _fixture());

      expect(summary, isNotNull);
      expect(find.text('Stations not reporting'), findsOneWidget);
      expect(find.text('蘭嶼氣象站'), findsOneWidget);
      expect(find.text('臺東縣 蘭嶼鄉'), findsOneWidget);
      expect(find.text('綠島國小'), findsOneWidget);
      expect(find.text('臺東縣 綠島鄉'), findsOneWidget);
      expect(find.text('滿州國小'), findsOneWidget);
      expect(find.text('屏東縣 滿州鄉'), findsOneWidget);

      final tops = [
        for (final name in ['蘭嶼氣象站', '綠島國小', '滿州國小'])
          tester.getTopLeft(find.text(name)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
    });

    testWidgets('does not show the station intensity', (tester) async {
      await _pumpSummary(tester, _fixture());

      expect(find.textContaining('5強'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(EventDetailRows),
          matching: find.text('2'),
        ),
        findsNothing,
      );
    });

    testWidgets('falls back to the station code', (tester) async {
      await _pumpSummary(
        tester,
        _withStations([
          {'code': 'LAY', 'name': '蘭嶼氣象站'},
          {'code': 'LDU', 'county': '臺東縣', 'town': '綠島鄉'},
          {'code': 'SMS', 'name': '  ', 'county': '屏東縣', 'town': 5},
        ]),
      );

      // A name without a place is valued by its code.
      expect(find.text('蘭嶼氣象站'), findsOneWidget);
      expect(find.text('LAY'), findsOneWidget);
      // No name: the code is the label.
      expect(find.text('LDU'), findsOneWidget);
      expect(find.text('臺東縣 綠島鄉'), findsOneWidget);
      // A blank name and a mistyped township.
      expect(find.text('SMS'), findsOneWidget);
      expect(find.text('屏東縣'), findsOneWidget);
    });

    testWidgets('leaves out stations it cannot name', (tester) async {
      await _pumpSummary(
        tester,
        _withStations([
          'LAY',
          null,
          {'county': '臺東縣', 'town': '蘭嶼鄉'},
          {'name': 7, 'code': false},
          {'name': '滿州國小', 'county': '屏東縣', 'town': '滿州鄉'},
        ]),
      );

      expect(find.text('滿州國小'), findsOneWidget);
      expect(find.text('臺東縣 蘭嶼鄉'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(EventDetailRows),
          matching: find.byType(Row),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a missing, empty or malformed addition gives no summary', (
      tester,
    ) async {
      final cases = <String, EventCardDetail>{
        'no addition': _withAddition(null, drop: true),
        'empty addition': _withAddition(<String, dynamic>{}),
        'stations not a list': _withStations({'code': 'LAY'}),
        'no stations': _withStations(<Object?>[]),
        'no usable station': _withStations([1, 'LAY', <String, dynamic>{}]),
      };
      for (final MapEntry(key: name, value: detail) in cases.entries) {
        final summary = await _pumpSummary(tester, detail);
        expect(summary, isNull, reason: name);
        expect(tester.takeException(), isNull, reason: name);
      }
    });
  });

  group('reportBody', () {
    testWidgets('keeps the headline facts of the report', (tester) async {
      final body = await _pumpBody(tester, _fixture().latest);

      expect(body, isA<EventFactsWrap>());
      expect(find.textContaining('M 5.2', findRichText: true), findsOneWidget);
      expect(find.textContaining('15 km', findRichText: true), findsOneWidget);
    });

    testWidgets('is empty without an addition', (tester) async {
      final report = _withAddition(null, drop: true).latest;

      expect(await _pumpBody(tester, report), isNull);
    });
  });
}
