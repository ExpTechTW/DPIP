/// The planets page: that every planet appears under its own name, that each one
/// carries a visibility verdict rather than only a magnitude, and that an
/// altitude is shown only when there is an observer to have one.
///
/// The verdict is the point of the page. A magnitude answers "how bright", never
/// "is it there to be seen", so a planet that has set or is lost in twilight has
/// to say so — and a page that rendered seven rows and seven magnitudes would
/// look complete while being useless. Altitude is the mirror of it: with no
/// township there is no horizon to measure against, so the row has to omit the
/// reading rather than print one for a coordinate nobody named.
library;

import 'package:dpip/core/astro/planet_ephemeris.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/data/presentation/pages/planets_page.dart';
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
  tester.view.physicalSize = const Size(900, 4000);
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
        home: PlanetsPage(),
      ),
    ),
  );
  await tester.pump();
}

Future<int> _countOf(WidgetTester tester, Iterable<String> texts) async {
  var total = 0;
  for (final text in texts) {
    total += tester.widgetList(find.text(text)).length;
  }
  return total;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every planet is listed, under its own name', (tester) async {
    await _pump(
      tester,
      regions: await _regions(code: '970'),
      directory: _directory,
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.planetsTitle), findsOneWidget);
    for (final planet in Planet.values) {
      expect(
        find.text(planetName(l10n, planet)),
        findsOneWidget,
        reason: '$planet is missing',
      );
    }
  });

  testWidgets('each planet carries a verdict, not just a magnitude', (
    tester,
  ) async {
    await _pump(
      tester,
      regions: await _regions(code: '970'),
      directory: _directory,
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      find.text(l10n.planetMagnitude),
      findsNWidgets(Planet.values.length),
    );

    // One verdict per planet, and it is one of the three — a row with a
    // magnitude and no visibility is the shape this page exists to avoid.
    expect(
      await _countOf(tester, [
        l10n.planetUp,
        l10n.planetDown,
        l10n.planetInGlare,
      ]),
      Planet.values.length,
    );
  });

  testWidgets('the section names the place the horizons belong to', (
    tester,
  ) async {
    await _pump(
      tester,
      regions: await _regions(code: '970'),
      directory: _directory,
    );

    expect(find.text('花蓮縣 花蓮市'), findsOneWidget);
  });

  testWidgets('altitude appears only when an observer has one', (tester) async {
    await _pump(
      tester,
      regions: await _regions(code: '970'),
      directory: _directory,
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    final withObserver = tester
        .widgetList(find.text(l10n.planetAltitude))
        .length;
    expect(withObserver, greaterThan(0));
    expect(withObserver, lessThanOrEqualTo(Planet.values.length));
  });

  testWidgets('with no place it omits altitude instead of inventing one', (
    tester,
  ) async {
    await _pump(
      tester,
      regions: await _regions(),
      directory: const TownDirectory(<String, Town>{}),
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // Still seven planets — the sky does not need a location — but no rise,
    // transit, set or altitude, because none of those exist without a horizon.
    for (final planet in Planet.values) {
      expect(find.text(planetName(l10n, planet)), findsOneWidget);
    }
    expect(find.text(l10n.planetAltitude), findsNothing);
    expect(find.text('臺北市 中正區'), findsNothing);
    expect(
      find.text(l10n.moonNoEvent),
      findsNWidgets(Planet.values.length * 3),
    );
  });

  test('every planet has its own name', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final names = {
      for (final planet in Planet.values) planetName(l10n, planet),
    };

    expect(names, everyElement(isNotEmpty));
    expect(names, hasLength(Planet.values.length));
  });
}
