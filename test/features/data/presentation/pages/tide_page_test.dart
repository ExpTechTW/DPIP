/// The tide page is the astronomical forcing for the selected township. With
/// no directory it must not invent a place, and with one it must name that
/// place and both a high and a low turning point.
library;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/data/presentation/pages/tide_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> _pump(WidgetTester tester, TownDirectory directory) async {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<TownDirectory>.value(value: directory),
        ChangeNotifierProvider(
          create: (_) => RegionStore(SettingsStore.inMemory()),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TidePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty directory shows the title and nothing else', (
    tester,
  ) async {
    await _pump(tester, const TownDirectory({}));
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.tideTitle), findsOneWidget);
    expect(find.text(l10n.tideDisclaimer), findsNothing);
  });

  testWidgets('a known township shows phase, distance, and turning points', (
    tester,
  ) async {
    await _pump(
      tester,
      TownDirectory({
        '6300100': const Town(
          code: '6300100',
          city: '臺北',
          town: '中正',
          lat: 25.03,
          lng: 121.56,
          cityLevel: '市',
          townLevel: '區',
        ),
      }),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.tideDisclaimer), findsOneWidget);
    expect(find.text('臺北市 中正區'), findsOneWidget);
    expect(find.text(l10n.tideHigh), findsWidgets);
    expect(find.text(l10n.tideLow), findsWidgets);
    expect(find.textContaining('×'), findsOneWidget);
  });
}
