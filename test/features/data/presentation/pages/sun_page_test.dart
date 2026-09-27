/// The Sun page: that the day's times belong to a *named* place, that the year's
/// solar-term table is complete, and that the terms keep their own names.
///
/// The place is the load-bearing part. Every time on this page is a statement
/// about a location, so a page that silently computes for a fallback — or shows
/// the numbers with no place attached — is worse than one that says it has no
/// answer. The 中氣 count is the other half: the lunisolar calendar is anchored
/// by exactly twelve of the twenty-four, and a table that quietly lost one
/// would still render.
library;

import 'package:dpip/core/astro/solar_terms.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/data/presentation/pages/sun_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

final _directory = TownDirectory.fromJson({
  '100': {
    'city': '臺北',
    'town': '中正',
    'lat': 25.03,
    'lng': 121.52,
    'cityLevel': '市',
    'townLevel': '區',
  },
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
  tester.view.physicalSize = const Size(900, 3200);
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
        home: SunPage(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the day is named for the township it was computed for', (
    tester,
  ) async {
    await _pump(
      tester,
      regions: await _regions(code: '970'),
      directory: _directory,
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.sunTitle), findsOneWidget);
    expect(find.text('花蓮縣 花蓮市'), findsOneWidget);
  });

  testWidgets('every daylight row has a real time, not a missing marker', (
    tester,
  ) async {
    await _pump(
      tester,
      regions: await _regions(code: '100'),
      directory: _directory,
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    for (final label in [
      l10n.sunRise,
      l10n.sunNoon,
      l10n.sunSet,
      l10n.sunDayLength,
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    // With a township known, a `—` anywhere here means the place never reached
    // the ephemeris — the one failure that renders as a plausible page.
    expect(find.text(l10n.moonNoEvent), findsNothing);
  });

  testWidgets('with no place at all it says so instead of guessing', (
    tester,
  ) async {
    await _pump(
      tester,
      regions: await _regions(),
      directory: const TownDirectory(<String, Town>{}),
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // Taipei City Hall is 25.03/121.52; an empty directory has nothing to
    // resolve it to, so the page has to admit it has no place rather than
    // compute for a coordinate it cannot name.
    expect(find.text('臺北市 中正區'), findsNothing);
    expect(find.text(l10n.moonNoEvent), findsWidgets);
  });

  testWidgets('the year lists all twenty-four terms, each under its own name', (
    tester,
  ) async {
    await _pump(
      tester,
      regions: await _regions(code: '100'),
      directory: _directory,
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final terms = SolarTerms.ofYear(
      DateTime.now().toUtc().add(const Duration(hours: 8)).year,
      offset: const Duration(hours: 8),
    );

    expect(terms, hasLength(24));
    for (final (term, _) in terms) {
      expect(
        find.text(solarTermName(l10n, term)),
        findsOneWidget,
        reason: '$term is missing from the table',
      );
    }
  });

  testWidgets('exactly twelve of the terms are 中氣', (tester) async {
    await _pump(
      tester,
      regions: await _regions(code: '100'),
      directory: _directory,
    );

    // The dot is drawn only for a major term. Twelve is not a coincidence —
    // the lunisolar calendar's month numbering is anchored on them, so a table
    // with eleven or thirteen would be a leap-month bug waiting to happen.
    expect(find.byIcon(Icons.circle), findsNWidgets(12));
  });

  test('every term has its own non-empty name', () {
    final l10n = AppLocalizations.delegate.load(const Locale('en'));
    return l10n.then((value) {
      final names = {
        for (final term in SolarTerm.values) solarTermName(value, term),
      };
      expect(names, everyElement(isNotEmpty));
      expect(names, hasLength(SolarTerm.values.length));
    });
  });
}
