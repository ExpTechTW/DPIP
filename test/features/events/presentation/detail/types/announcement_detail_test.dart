/// An announcement's `addition` carries only an internal code, so its detail
/// adds nothing to the shared page, whatever the `addition` holds.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/detail/types/announcement_detail.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _detail = AnnouncementDetail();

/// The announcement fixture, with every report's `addition` replaced by
/// [addition] when given.
EventCardDetail _announcement({Object? Function()? addition}) {
  final body = jsonDecode(
    File('test/fixtures/events_v2/announcement_detail.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  if (addition != null) {
    for (final card
        in (body['cards'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      card['addition'] = addition();
    }
  }
  return EventCardDetail.fromJson(body);
}

/// Builds the summary and every report body of [detail] in a pumped app.
Future<({Widget? summary, List<Widget?> bodies})> _build(
  WidgetTester tester,
  EventCardDetail detail,
) async {
  Widget? summary;
  final bodies = <Widget?>[];
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            summary = _detail.summary(context, detail);
            bodies
              ..clear()
              ..addAll([
                for (final report in detail.reports)
                  _detail.reportBody(context, report),
              ]);
            return ListView(children: [?summary, ...bodies.nonNulls]);
          },
        ),
      ),
    ),
  );
  return (summary: summary, bodies: bodies);
}

void main() {
  testWidgets('the fixture has no summary and no report body', (tester) async {
    final detail = _announcement();
    final built = await _build(tester, detail);

    expect(detail.reports, hasLength(2));
    expect(built.summary, isNull);
    expect(built.bodies, [null, null]);
  });

  testWidgets('any addition, malformed or not, adds nothing and never throws', (
    tester,
  ) async {
    final additions = <Object? Function()>[
      () => null,
      () => <String, dynamic>{},
      () => 'not an object',
      () => {'code': 42},
      () => {'code': 'drill', 'url': 'https://example.com'},
    ];
    for (final (index, addition) in additions.indexed) {
      final built = await _build(tester, _announcement(addition: addition));
      expect(built.summary, isNull, reason: 'case $index');
      expect(built.bodies, [null, null], reason: 'case $index');
      expect(tester.takeException(), isNull, reason: 'case $index');
    }
  });
}
