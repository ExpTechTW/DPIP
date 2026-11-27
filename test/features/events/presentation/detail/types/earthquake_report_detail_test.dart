/// An intensity report's detail lists its latest report's townships by
/// intensity, strongest first; earthquake reports and tsunami notes add no
/// summary; and nothing throws when the directory or the addition is missing
/// or malformed.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/detail/event_detail_blocks.dart';
import 'package:dpip/features/events/presentation/detail/types/earthquake_report_detail.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

const _fixtureDir = 'test/fixtures/events_v2';

Map<String, dynamic> _fixtureJson(String name) =>
    jsonDecode(File('$_fixtureDir/$name.json').readAsStringSync())
        as Map<String, dynamic>;

EventCardDetail _fixture(String name) =>
    EventCardDetail.fromJson(_fixtureJson(name));

/// [name]'s detail with [edit] applied to each report's JSON first.
EventCardDetail _edited(
  String name,
  void Function(Map<String, dynamic> report) edit,
) {
  final json = _fixtureJson(name);
  for (final card in json['cards'] as List<Object?>) {
    edit(card! as Map<String, dynamic>);
  }
  return EventCardDetail.fromJson(json);
}

/// The intensity detail with every report's `addition.area` replaced.
EventCardDetail _withArea(Object? area) => _edited(
  'intensity_detail',
  (report) => (report['addition'] as Map<String, dynamic>)['area'] = area,
);

TownDirectory _directory() => TownDirectory.fromJson({
  for (final (code, city, cityLevel, town, townLevel) in [
    ('100', '臺北', '市', '中正', '區'),
    ('900', '屏東', '縣', '屏東', '市'),
    ('970', '花蓮', '縣', '花蓮', '市'),
  ])
    code: {
      'city': city,
      'town': town,
      'lat': 24.0,
      'lng': 121.0,
      'cityLevel': cityLevel,
      'townLevel': townLevel,
    },
});

Widget _app(Widget Function(BuildContext) build, {TownDirectory? directory}) {
  Widget home = Scaffold(
    body: SingleChildScrollView(child: Builder(builder: build)),
  );
  if (directory != null) {
    home = Provider<TownDirectory>.value(value: directory, child: home);
  }
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

/// Pumps [EarthquakeReportDetail.summary] of [detail] and returns what it
/// gave.
Future<Widget?> _pumpSummary(
  WidgetTester tester,
  EventCardDetail detail, {
  bool withDirectory = true,
}) async {
  Widget? summary;
  await tester.pumpWidget(
    _app((context) {
      summary = const EarthquakeReportDetail().summary(context, detail);
      return summary ?? const SizedBox.shrink();
    }, directory: withDirectory ? _directory() : null),
  );
  return summary;
}

/// Pumps [EarthquakeReportDetail.reportBody] of [report] and returns what it
/// gave.
Future<Widget?> _pumpBody(WidgetTester tester, EventReport report) async {
  Widget? body;
  await tester.pumpWidget(
    _app((context) {
      body = const EarthquakeReportDetail().reportBody(context, report);
      return body ?? const SizedBox.shrink();
    }, directory: _directory()),
  );
  return body;
}

/// The y of each of [labels], to compare their order on screen.
List<double> _tops(WidgetTester tester, List<String> labels) => [
  for (final label in labels) tester.getTopLeft(find.text(label)).dy,
];

Finder _rowValue(String value) => find.descendant(
  of: find.byType(EventDetailRows),
  matching: find.text(value),
);

void main() {
  group('intensity summary', () {
    testWidgets('lists each township by intensity, strongest first', (
      tester,
    ) async {
      final summary = await _pumpSummary(tester, _fixture('intensity_detail'));

      expect(summary, isNotNull);
      expect(find.text('Intensity by area'), findsOneWidget);
      expect(find.byType(IntensityBadge), findsNWidgets(3));
      final tops = _tops(tester, ['花蓮縣 花蓮市', '臺北市 中正區', '屏東縣 屏東市']);
      expect(tops, orderedEquals([...tops]..sort()));
      // The badge and the value both read the level.
      expect(_rowValue('5⁻'), findsNWidgets(2));
      expect(_rowValue('2'), findsNWidgets(2));
      expect(_rowValue('1'), findsNWidgets(2));
    });

    testWidgets('orders townships of one intensity by name', (tester) async {
      await _pumpSummary(
        tester,
        _withArea({
          '2': [100, 900],
          '3': [970],
        }),
      );

      final tops = _tops(tester, ['花蓮縣 花蓮市', '屏東縣 屏東市', '臺北市 中正區']);
      expect(tops, orderedEquals([...tops]..sort()));
    });

    testWidgets('reads the latest report only', (tester) async {
      final detail = _edited('intensity_detail', (report) {
        (report['addition']
            as Map<String, dynamic>)['area'] = report['serial'] == 1
            ? {
                '4': [100],
              }
            : {
                '3': [970],
              };
      });
      await _pumpSummary(tester, detail);

      expect(find.text('花蓮縣 花蓮市'), findsOneWidget);
      expect(find.text('臺北市 中正區'), findsNothing);
    });

    testWidgets('a township under two levels keeps the higher one', (
      tester,
    ) async {
      await _pumpSummary(
        tester,
        _withArea({
          '2': [970],
          '6': [970],
        }),
      );

      expect(find.text('花蓮縣 花蓮市'), findsOneWidget);
      expect(_rowValue('5⁺'), findsNWidgets(2));
      expect(_rowValue('2'), findsNothing);
    });

    testWidgets('leaves out bad keys, bad codes and unknown codes', (
      tester,
    ) async {
      await _pumpSummary(
        tester,
        _withArea({
          '5弱': [100],
          '10': [100],
          '-1': [100],
          '3': '970',
          '4': ['900', 999, null, 1.5, 970.0],
        }),
      );

      expect(find.text('花蓮縣 花蓮市'), findsOneWidget);
      expect(find.text('臺北市 中正區'), findsNothing);
      expect(find.text('屏東縣 屏東市'), findsNothing);
      expect(find.byType(IntensityBadge), findsOneWidget);
    });

    testWidgets('a missing, empty or malformed addition gives no summary', (
      tester,
    ) async {
      final cases = <String, void Function(Map<String, dynamic>)>{
        'no addition': (report) => report.remove('addition'),
        'empty addition': (report) => report['addition'] = <String, dynamic>{},
        'area not an object': (report) =>
            (report['addition'] as Map<String, dynamic>)['area'] = [970],
        'empty area': (report) =>
            (report['addition'] as Map<String, dynamic>)['area'] =
                <String, dynamic>{},
        'only unknown codes': (report) =>
            (report['addition'] as Map<String, dynamic>)['area'] = {
              '5': [1, 2],
            },
      };
      for (final MapEntry(key: name, value: edit) in cases.entries) {
        final summary = await _pumpSummary(
          tester,
          _edited('intensity_detail', edit),
        );
        expect(summary, isNull, reason: name);
        expect(tester.takeException(), isNull, reason: name);
      }
    });

    testWidgets('no summary without a township directory', (tester) async {
      final summary = await _pumpSummary(
        tester,
        _fixture('intensity_detail'),
        withDirectory: false,
      );

      expect(summary, isNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('earthquake report and tsunami note', () {
    testWidgets('have no summary', (tester) async {
      for (final name in ['earthquake_detail', 'tsunami_note_detail']) {
        expect(
          await _pumpSummary(tester, _fixture(name)),
          isNull,
          reason: name,
        );
      }
    });

    testWidgets('have no summary with a malformed addition either', (
      tester,
    ) async {
      for (final addition in <Object?>[null, <String, dynamic>{}, 'x']) {
        final summary = await _pumpSummary(
          tester,
          _edited('earthquake_detail', (report) {
            report['addition'] = addition;
          }),
        );
        expect(summary, isNull, reason: '$addition');
        expect(tester.takeException(), isNull, reason: '$addition');
      }
    });
  });

  group('reportBody', () {
    testWidgets('keeps the intensity report facts', (tester) async {
      final body = await _pumpBody(tester, _fixture('intensity_detail').latest);

      expect(body, isA<EventFactsWrap>());
      expect(find.textContaining('5⁻', findRichText: true), findsOneWidget);
      expect(find.textContaining('#2', findRichText: true), findsOneWidget);
    });

    testWidgets('is empty for an earthquake report', (tester) async {
      expect(
        await _pumpBody(tester, _fixture('earthquake_detail').latest),
        isNull,
      );
    });
  });
}
