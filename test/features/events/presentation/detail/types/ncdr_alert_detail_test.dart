/// An NCDR alert's detail adds only what its title, text and facts do not
/// already say: a work and school closure's townships by city. Every other
/// type has no summary, and none of them throws on a missing or malformed
/// area or addition.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/detail/types/ncdr_alert_detail.dart';
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
    ('300', '新竹', '北'),
    ('600', '嘉義', '東'),
    ('601', '嘉義', '西'),
    ('709', '臺南', '安南'),
  ])
    code: {
      'city': city,
      'town': town,
      'lat': 24.0,
      'lng': 121.0,
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
}) async {
  Widget? built;
  final app = MaterialApp(
    locale: const Locale('en'),
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

const _fixtures = [
  'thunderstorm_detail',
  'thunderstorm_tornado-detail',
  'seawave_detail',
  'workSchlClos_detail',
  'debrisFlowLandSlide_detail',
  'roadClose_detail',
  'floodSensor_detail',
  'barrierLake_detail',
];

void main() {
  const detail = NcdrAlertDetail();

  group('summary', () {
    testWidgets('workSchlClos lists its townships by city', (tester) async {
      final card = _fixture('workSchlClos_detail');
      final built = await _pump(
        tester,
        (context) => detail.summary(context, card),
        directory: _directory(),
      );
      expect(built, isNotNull);
      expect(find.text('Affected areas'), findsOneWidget);
      expect(find.text('新竹市'), findsOneWidget);
      expect(find.text('北區'), findsOneWidget);
      expect(find.text('嘉義市'), findsOneWidget);
      // `area` is [300, 601, 600]: the townships keep that order.
      expect(find.text('西區, 東區'), findsOneWidget);
      final hsinchu = tester.getTopLeft(find.text('新竹市'));
      final chiayi = tester.getTopLeft(find.text('嘉義市'));
      expect(hsinchu.dy, lessThan(chiayi.dy));
    });

    testWidgets('workSchlClos without a TownDirectory gives null', (
      tester,
    ) async {
      final card = _fixture('workSchlClos_detail');
      final built = await _pump(
        tester,
        (context) => detail.summary(context, card),
      );
      expect(built, isNull);
      expect(tester.takeException(), isNull);
    });

    for (final (label, area) in <(String, Object?)>[
      ('no', const <Object?>[]),
      ('an unknown', [999]),
      ('a non-list', 'oops'),
      ('a null', null),
    ]) {
      testWidgets('workSchlClos with $label area gives null', (tester) async {
        final card = _patched('workSchlClos_detail', area: area);
        final built = await _pump(
          tester,
          (context) => detail.summary(context, card),
          directory: _directory(),
        );
        expect(built, isNull);
        expect(tester.takeException(), isNull);
      });
    }

    for (final name in _fixtures.where((n) => n != 'workSchlClos_detail')) {
      testWidgets('$name has no summary', (tester) async {
        final card = _fixture(name);
        final built = await _pump(
          tester,
          (context) => detail.summary(context, card),
          directory: _directory(),
        );
        expect(built, isNull);
      });
    }

    for (final name in _fixtures) {
      for (final (label, addition, drop) in <(String, Object?, bool)>[
        ('absent', null, true),
        ('empty', <String, Object?>{}, false),
        ('not an object', 'oops', false),
        ('mistyped', {'light': 1, 'roadName': [], 'areaDesc': 2}, false),
      ]) {
        testWidgets('$name with an $label addition does not throw', (
          tester,
        ) async {
          final card = _patched(
            name,
            area: [709, 'x'],
            addition: addition,
            dropAddition: drop,
          );
          await _pump(
            tester,
            (context) => detail.summary(context, card),
            directory: _directory(),
          );
          expect(tester.takeException(), isNull);
          expect(
            find.text('Affected areas'),
            name == 'workSchlClos_detail' ? findsOneWidget : findsNothing,
          );
        });
      }
    }
  });

  group('reportBody', () {
    testWidgets('roadClose keeps the road and the place as facts', (
      tester,
    ) async {
      final card = _fixture('roadClose_detail');
      final built = await _pump(
        tester,
        (context) => detail.reportBody(context, card.latest),
      );
      expect(built, isNotNull);
      expect(find.text('Road 台灣大道線', findRichText: true), findsOneWidget);
      expect(find.text('Location 中清路口', findRichText: true), findsOneWidget);
    });

    testWidgets('floodSensor keeps its place and skips the empty station', (
      tester,
    ) async {
      final card = _fixture('floodSensor_detail');
      final built = await _pump(
        tester,
        (context) => detail.reportBody(context, card.latest),
      );
      expect(built, isNotNull);
      expect(find.text('Location 臺南市安南區', findRichText: true), findsOneWidget);
      expect(find.textContaining('Station', findRichText: true), findsNothing);
    });

    for (final name in [
      'thunderstorm_detail',
      'thunderstorm_tornado-detail',
      'seawave_detail',
      'workSchlClos_detail',
      'debrisFlowLandSlide_detail',
      'barrierLake_detail',
    ]) {
      testWidgets('$name has no body', (tester) async {
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

    testWidgets('a mistyped roadClose addition gives no body, no error', (
      tester,
    ) async {
      final card = _patched(
        'roadClose_detail',
        addition: {'roadName': 1, 'location': <Object?>[]},
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
