/// The almanac page: the lunisolar date it derives for today, and the one thing
/// that is a statement about a place rather than about the sky — the solar
/// eclipses, which are only visible from somewhere.
///
/// The solar half is why this page has a place at all. Lunar eclipses are the
/// same instant everywhere, so they render with no township; solar ones need a
/// coordinate, and with none the page has to say so rather than fall back to
/// Taipei and label the result as the user's own. Everything here is derived
/// from today's date, so the assertions are on the derivation rather than on
/// values that a future calendar would legitimately change.
library;

import 'package:dpip/core/astro/lunisolar_calendar.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/data/presentation/pages/almanac_page.dart';
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
        home: AlmanacPage(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("today's row is the calendar's own answer, not a table", (
    tester,
  ) async {
    await _pump(
      tester,
      regions: await _regions(code: '100'),
      directory: _directory,
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final lunar = LunisolarCalendar.of(DateTime.now().toUtc());

    expect(find.text(l10n.almanacTitle), findsOneWidget);
    expect(
      find.text(
        l10n.almanacLunarDate(
          lunar.isLeapMonth ? l10n.almanacLeapPrefix : '',
          lunar.month,
          lunar.day,
        ),
      ),
      findsOneWidget,
    );
    // The sexagenary year is only ever shown with its animal beside it.
    expect(find.textContaining('${lunar.sexagenaryYear} '), findsOneWidget);
    expect(
      find.text(
        lunar.monthLength == 30
            ? l10n.almanacLongMonth
            : l10n.almanacShortMonth,
      ),
      findsOneWidget,
    );
  });

  testWidgets('lunar eclipses need no place', (tester) async {
    await _pump(
      tester,
      regions: await _regions(code: '100'),
      directory: _directory,
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // They are the same instant everywhere, so they are listed even when the
    // page has no township to compute solar ones for.
    expect(find.text(l10n.almanacSectionLunarEclipses), findsOneWidget);
    expect(find.byIcon(Icons.brightness_1_outlined), findsWidgets);
  });

  testWidgets('solar eclipses are attributed to the township', (tester) async {
    await _pump(
      tester,
      regions: await _regions(code: '970'),
      directory: _directory,
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.almanacSectionSolarEclipses), findsOneWidget);
    // The section header carries the place, so a solar eclipse is never read as
    // a fact about wherever the reader happens to be.
    expect(find.text('花蓮縣 花蓮市'), findsOneWidget);
    expect(find.text(l10n.almanacNoSolarEclipse), findsNothing);
  });

  testWidgets('with no place it declines instead of defaulting to Taipei', (
    tester,
  ) async {
    await _pump(
      tester,
      regions: await _regions(),
      directory: const TownDirectory(<String, Town>{}),
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.almanacNoSolarEclipse), findsOneWidget);
    expect(find.text('臺北市 中正區'), findsNothing);
  });
}
