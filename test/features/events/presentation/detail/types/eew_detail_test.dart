/// An EEW card's detail shows the latest estimate beside its
/// maximum intensity badge and how the estimate moved between reports, and
/// stays empty rather than throwing when the addition is missing or
/// malformed.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/detail/event_detail_blocks.dart';
import 'package:dpip/features/events/presentation/detail/types/eew_detail.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _fixtureDir = 'test/fixtures/events_v2';

Map<String, dynamic> _fixtureJson(String name) =>
    jsonDecode(File('$_fixtureDir/$name.json').readAsStringSync())
        as Map<String, dynamic>;

EventCardDetail _fixture(String name) =>
    EventCardDetail.fromJson(_fixtureJson(name));

/// [name]'s detail with [edit] applied to each report's JSON first.
EventCardDetail _edited(
  String name,
  void Function(Map<String, dynamic> report) edit, {
  int? keep,
}) {
  final json = _fixtureJson(name);
  final cards = json['cards'] as List<Object?>;
  if (keep != null) cards.removeRange(keep, cards.length);
  for (final card in cards) {
    edit(card! as Map<String, dynamic>);
  }
  return EventCardDetail.fromJson(json);
}

Widget _app(Widget Function(BuildContext) build) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(child: Builder(builder: build)),
  ),
);

/// Pumps [EewDetail.summary] of [detail] and returns what it gave.
Future<Widget?> _pumpSummary(
  WidgetTester tester,
  EventCardDetail detail,
) async {
  Widget? summary;
  await tester.pumpWidget(
    _app((context) {
      summary = const EewDetail().summary(context, detail);
      return summary ?? const SizedBox.shrink();
    }),
  );
  return summary;
}

/// Pumps [EewDetail.reportBody] of [report] and returns what it gave.
Future<Widget?> _pumpBody(WidgetTester tester, EventReport report) async {
  Widget? body;
  await tester.pumpWidget(
    _app((context) {
      body = const EewDetail().reportBody(context, report);
      return body ?? const SizedBox.shrink();
    }),
  );
  return body;
}

Finder _badge(String label) => find.descendant(
  of: find.byType(IntensityBadge),
  matching: find.text(label),
);

void main() {
  group('summary', () {
    testWidgets('an EEW shows the latest estimate and every report', (
      tester,
    ) async {
      final summary = await _pumpSummary(
        tester,
        _fixture('earthquake_eew_detail'),
      );

      expect(summary, isNotNull);
      expect(find.text('Latest estimate'), findsOneWidget);
      expect(_badge('4'), findsOneWidget);
      expect(find.text('Magnitude'), findsOneWidget);
      expect(find.text('M 4.5'), findsOneWidget);
      expect(find.text('Depth'), findsOneWidget);
      expect(find.text('10 km'), findsOneWidget);
      expect(find.text('Epicenter'), findsOneWidget);
      expect(find.text('連江縣南竿鄉'), findsOneWidget);
      // 1785069391000 is 2026-07-26 20:36:31 in Taipei.
      expect(find.text('Origin time'), findsOneWidget);
      expect(find.text('20:36'), findsOneWidget);
      expect(find.text('Report 1'), findsOneWidget);
      expect(find.text('Report 2'), findsOneWidget);
      expect(find.text('M 4.5 · 4'), findsNWidgets(2));
    });

    testWidgets('the facts are in the order magnitude, depth, epicentre, '
        'origin time', (tester) async {
      await _pumpSummary(tester, _fixture('earthquake_eew_detail'));

      final labels = [
        'Magnitude',
        'Depth',
        'Epicenter',
        'Origin time',
      ].map((label) => tester.getTopLeft(find.text(label)).dy).toList();
      expect(labels, orderedEquals([...labels]..sort()));
    });

    testWidgets('an upgraded EEW shows the alert report as the latest', (
      tester,
    ) async {
      await _pumpSummary(tester, _fixture('earthquake_eew_alert_detail'));

      expect(find.text('M 5.0'), findsOneWidget);
      expect(find.text('M 4.5'), findsNothing);
      expect(_badge('4'), findsOneWidget);

      final first = tester.getTopLeft(find.text('Report 1')).dy;
      final second = tester.getTopLeft(find.text('Report 2')).dy;
      expect(first, lessThan(second));
      expect(find.text('M 4.5 · 4'), findsOneWidget);
      expect(find.text('M 5.0 · 4'), findsOneWidget);
    });

    testWidgets('an estimate without an intensity has no badge', (
      tester,
    ) async {
      final detail = _edited('earthquake_eew_detail', (report) {
        (report['addition'] as Map<String, dynamic>)['eq'] = {
          'time': 1785069391000,
          'mag': 4.5,
        };
      }, keep: 1);
      await _pumpSummary(tester, detail);

      expect(find.byType(IntensityBadge), findsNothing);
      expect(find.text('M 4.5'), findsOneWidget);
      expect(find.text('20:36'), findsOneWidget);
      expect(find.text('Depth'), findsNothing);
    });

    testWidgets('a missing, empty or malformed addition gives no summary', (
      tester,
    ) async {
      final cases = <String, void Function(Map<String, dynamic>)>{
        'no addition': (report) => report.remove('addition'),
        'empty addition': (report) => report['addition'] = <String, dynamic>{},
        'eq not an object': (report) =>
            (report['addition'] as Map<String, dynamic>)['eq'] = 'M 4.5',
        'eq of the wrong types': (report) =>
            (report['addition'] as Map<String, dynamic>)['eq'] = {
              'time': '20:36',
              'mag': '4.5',
              'depth': -99,
              'loc': 12,
              'max': 'four',
            },
      };
      for (final MapEntry(key: name, value: edit) in cases.entries) {
        final summary = await _pumpSummary(
          tester,
          _edited('earthquake_eew_detail', edit),
        );
        expect(summary, isNull, reason: name);
        expect(tester.takeException(), isNull, reason: name);
      }
    });

    testWidgets('an unusable origin time drops only the origin time', (
      tester,
    ) async {
      for (final time in <Object?>[
        null,
        '1785069391000',
        -1,
        0,
        1.5,
        double.maxFinite,
        9007199254740993,
      ]) {
        final detail = _edited('earthquake_eew_detail', (report) {
          final eq =
              (report['addition'] as Map<String, dynamic>)['eq']
                  as Map<String, dynamic>;
          eq['time'] = time;
        });
        final summary = await _pumpSummary(tester, detail);

        expect(summary, isNotNull, reason: '$time');
        expect(find.text('Origin time'), findsNothing, reason: '$time');
        expect(find.text('M 4.5'), findsOneWidget, reason: '$time');
        expect(tester.takeException(), isNull, reason: '$time');
      }
    });
  });

  group('reportBody', () {
    testWidgets('keeps the headline facts of the report', (tester) async {
      final report = _fixture('earthquake_eew_detail').latest;
      final body = await _pumpBody(tester, report);

      expect(body, isA<EventFactsWrap>());
      expect(find.textContaining('M 4.5', findRichText: true), findsOneWidget);
      expect(find.textContaining('10 km', findRichText: true), findsOneWidget);
    });

    testWidgets('is empty for a cancelled detection', (tester) async {
      final report = _fixture('earthquake_detection_detail').latest;

      expect(await _pumpBody(tester, report), isNull);
    });
  });
}
