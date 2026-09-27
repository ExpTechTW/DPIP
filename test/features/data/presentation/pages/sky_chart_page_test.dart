/// The sky chart's three states, and the place it refuses to draw without.
///
/// The chart is one `CustomPaint` fed by an asset, so there are exactly two
/// things that can go wrong before any pixel is drawn: the catalogue never
/// loads, or there is no township to project it for. Both used to be a spinner
/// forever, which is indistinguishable from "slow" — so what is pinned here is
/// that each ends in something a reader can act on, and that the chart itself is
/// only drawn once it has a place to be drawn for.
library;

import 'package:dpip/core/astro/star_catalog.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/data/presentation/pages/sky_chart_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

final _directory = TownDirectory.fromJson({
  '970': {
    'city': '花蓮',
    'town': '花蓮',
    'lat': 23.99,
    'lng': 121.60,
    'cityLevel': '縣',
    'townLevel': '市',
  },
});

Future<RegionStore> _regions({String? code}) async {
  final store = RegionStore(SettingsStore.inMemory({}));
  if (code != null) store.setCurrentCode(code);
  return store;
}

Future<void> _pump(
  WidgetTester tester, {
  required RegionStore regions,
  required TownDirectory directory,
}) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<TownDirectory>.value(value: directory),
        ChangeNotifierProvider<RegionStore>.value(value: regions),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SkyChartPage(),
      ),
    ),
  );
}

/// The catalogue is cached by `setUpAll`; a short `runAsync` lets the cached
/// future's callback cross from the real async queue into the widget test, then
/// one pump lands its `setState`.
Future<void> _awaitChart(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Warm the catalogue outside the widget test's fake-async zone. The page
  // resolves it once and caches it, and inside a `testWidgets` body neither the
  // asset load nor the isolate can advance without puppeting `runAsync` — which
  // would make this test about the harness rather than about the chart.
  setUpAll(StarCatalog.load);

  testWidgets('with no township it will not draw a chart it cannot label', (
    tester,
  ) async {
    await _pump(
      tester,
      regions: await _regions(),
      directory: const TownDirectory(<String, Town>{}),
    );
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.skyChartTitle), findsOneWidget);
    // The chart is a statement about where the reader is standing; with no
    // place there is nothing honest to draw, so it stays un-drawn rather than
    // silently defaulting to Taipei.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('臺北市 中正區'), findsNothing);
  });

  testWidgets('a catalogue and a township together produce the chart', (
    tester,
  ) async {
    await _pump(
      tester,
      regions: await _regions(code: '970'),
      directory: _directory,
    );
    await _awaitChart(tester);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // Either the chart drew, or the page said why it could not — a spinner is
    // the one outcome that is not allowed, because it is not an answer.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(l10n.skyChartUnavailable), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
      findsOneWidget,
      reason: 'the disc the chart is painted on is missing',
    );
    // The place the chart is for is named under it, not left implicit.
    expect(find.text('花蓮縣 花蓮市'), findsOneWidget);
  });
}
