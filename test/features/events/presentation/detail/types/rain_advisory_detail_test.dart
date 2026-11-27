/// A rain advisory's detail lists the townships its latest report covers,
/// grouped by city, and stays empty rather than throwing when the directory,
/// the area or the addition is missing or malformed.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/detail/types/rain_advisory_detail.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

const _fixtureDir = 'test/fixtures/events_v2';

Map<String, dynamic> _fixtureJson(String name) =>
    jsonDecode(File('$_fixtureDir/$name.json').readAsStringSync())
        as Map<String, dynamic>;

EventCardDetail _fixture(String name) =>
    EventCardDetail.fromJson(_fixtureJson(name));

/// [name]'s detail with every report's `area` and `addition` replaced.
EventCardDetail _patched(
  String name, {
  Object? area = const <Object?>[],
  Object? addition,
  bool dropAddition = false,
}) {
  final json = _fixtureJson(name);
  for (final card in json['cards'] as List<Object?>) {
    final report = card! as Map<String, dynamic>;
    report['area'] = area;
    if (dropAddition) {
      report.remove('addition');
    } else {
      report['addition'] = addition;
    }
  }
  return EventCardDetail.fromJson(json);
}

TownDirectory _directory() => TownDirectory.fromJson({
  for (final (code, city, town) in [
    ('100', '臺北', '中正'),
    ('103', '臺北', '大同'),
    ('106', '臺北', '大安'),
    ('200', '基隆', '仁愛'),
  ])
    code: {
      'city': city,
      'town': town,
      'lat': 25.0,
      'lng': 121.5,
      'cityLevel': '市',
      'townLevel': '區',
    },
});

/// Pumps whatever [build] returns, under a localized app and, unless
/// [directory] is null, a [TownDirectory]. Returns what [build] returned.
Future<Widget?> _pump(
  WidgetTester tester,
  Widget? Function(BuildContext context) build, {
  TownDirectory? directory,
  Locale locale = const Locale('en'),
}) async {
  Widget? built;
  final app = MaterialApp(
    locale: locale,
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) {
          built = build(context);
          return ListView(children: [?built]);
        },
      ),
    ),
  );
  await tester.pumpWidget(
    directory == null
        ? app
        : Provider<TownDirectory>.value(value: directory, child: app),
  );
  return built;
}

void main() {
  const detail = RainAdvisoryDetail();

  group('summary', () {
    for (final (name, city, town) in [
      ('heavy-rain_detail', '臺北市', '中正區'),
      ('extremely-heavy-rain_detail', '臺北市', '中正區'),
      ('torrential-rain_detail', '基隆市', '仁愛區'),
      ('extremely-torrential-rain_detail', '臺北市', '中正區'),
    ]) {
      testWidgets('$name lists the latest report\'s townships', (tester) async {
        final card = _fixture(name);
        final built = await _pump(
          tester,
          (context) => detail.summary(context, card),
          directory: _directory(),
        );
        expect(built, isNotNull);
        expect(find.text('Affected areas'), findsOneWidget);
        expect(find.text(city), findsOneWidget);
        expect(find.text(town), findsOneWidget);
      });
    }

    testWidgets('one row per city, in first-appearance order, deduplicated', (
      tester,
    ) async {
      final card = _patched(
        'heavy-rain_detail',
        area: [200, 100, 106, 100, 103],
        addition: {'issueTime': 1717213800000},
      );
      await _pump(
        tester,
        (context) => detail.summary(context, card),
        directory: _directory(),
      );
      expect(find.text('基隆市'), findsOneWidget);
      expect(find.text('仁愛區'), findsOneWidget);
      expect(find.text('臺北市'), findsOneWidget);
      expect(find.text('中正區, 大安區, 大同區'), findsOneWidget);
      final keelung = tester.getTopLeft(find.text('基隆市'));
      final taipei = tester.getTopLeft(find.text('臺北市'));
      expect(keelung.dy, lessThan(taipei.dy));
    });

    testWidgets('Chinese joins townships with the ideographic comma', (
      tester,
    ) async {
      final card = _patched('heavy-rain_detail', area: [100, 106]);
      await _pump(
        tester,
        (context) => detail.summary(context, card),
        directory: _directory(),
        locale: const Locale('zh'),
      );
      expect(find.text('中正區、大安區'), findsOneWidget);
    });

    testWidgets('a code the directory does not know is left out', (
      tester,
    ) async {
      final card = _patched('heavy-rain_detail', area: [999, 100]);
      await _pump(
        tester,
        (context) => detail.summary(context, card),
        directory: _directory(),
      );
      expect(find.text('臺北市'), findsOneWidget);
      expect(find.text('中正區'), findsOneWidget);
    });

    testWidgets('null when no code resolves', (tester) async {
      final card = _patched('heavy-rain_detail', area: [999, 12345]);
      final built = await _pump(
        tester,
        (context) => detail.summary(context, card),
        directory: _directory(),
      );
      expect(built, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('null when the latest report covers no township', (
      tester,
    ) async {
      // The level ended by an upgrade: its last report has `area: []`.
      final card = _fixture('heavy-rain_upgrade-detail');
      expect(card.latest.area, isEmpty);
      final built = await _pump(
        tester,
        (context) => detail.summary(context, card),
        directory: _directory(),
      );
      expect(built, isNull);
    });

    testWidgets('null when no TownDirectory is provided', (tester) async {
      final card = _fixture('heavy-rain_detail');
      final built = await _pump(
        tester,
        (context) => detail.summary(context, card),
      );
      expect(built, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a malformed area keeps only its integer codes', (
      tester,
    ) async {
      final card = _patched('heavy-rain_detail', area: ['100', 100, null]);
      await _pump(
        tester,
        (context) => detail.summary(context, card),
        directory: _directory(),
      );
      expect(find.text('中正區'), findsOneWidget);
    });

    testWidgets('a non-list area gives null', (tester) async {
      final card = _patched('heavy-rain_detail', area: 'oops');
      final built = await _pump(
        tester,
        (context) => detail.summary(context, card),
        directory: _directory(),
      );
      expect(built, isNull);
    });

    for (final (label, addition, drop) in <(String, Object?, bool)>[
      ('absent', null, true),
      ('null', null, false),
      ('empty', <String, Object?>{}, false),
      ('not an object', 'oops', false),
      (
        'mistyped fields',
        {'issueTime': 'x', 'released': 'y', 'changed': 1, 'end': []},
        false,
      ),
    ]) {
      testWidgets('an $label addition does not affect the areas', (
        tester,
      ) async {
        final card = _patched(
          'heavy-rain_detail',
          area: [100],
          addition: addition,
          dropAddition: drop,
        );
        await _pump(
          tester,
          (context) => detail.summary(context, card),
          directory: _directory(),
        );
        expect(find.text('中正區'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('reportBody', () {
    for (final name in [
      'heavy-rain_detail',
      'heavy-rain_upgrade-detail',
      'extremely-heavy-rain_detail',
      'torrential-rain_detail',
      'extremely-torrential-rain_detail',
    ]) {
      testWidgets('$name keeps the default, which is empty', (tester) async {
        final card = _fixture(name);
        for (final report in card.reports) {
          final built = await _pump(
            tester,
            (context) => detail.reportBody(context, report),
          );
          expect(built, isNull, reason: 'serial ${report.serial}');
        }
      });
    }

    testWidgets('a malformed addition gives no body and no error', (
      tester,
    ) async {
      final card = _patched(
        'heavy-rain_detail',
        addition: {'issueTime': 'x', 'released': 'y'},
      );
      final built = await _pump(
        tester,
        (context) => detail.reportBody(context, card.latest),
      );
      expect(built, isNull);
      expect(tester.takeException(), isNull);
    });
  });
}
