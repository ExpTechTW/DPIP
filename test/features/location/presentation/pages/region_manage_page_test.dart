/// The manage page is the only review of saved townships. Hiding Add before
/// the cap, or leaving a deleted row on screen, would either overflow the
/// saved list or make a removal look like it failed.
library;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/location/presentation/pages/region_manage_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Town _town(String code) => Town(
  code: code,
  city: '臺北',
  town: '區$code',
  lat: 25,
  lng: 121,
  cityLevel: '市',
  townLevel: '區',
);

Future<RegionStore> _pump(
  WidgetTester tester, {
  List<String> saved = const [],
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final store = RegionStore(SettingsStore.inMemory());
  for (final code in saved) {
    store.addSaved(code);
  }
  final directory = TownDirectory({
    for (final code in ['6300100', '6300200', '6300300', '6300400'])
      code: _town(code),
  });
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const RegionManagePage()),
      GoRoute(
        name: AppRoutes.regionSelect,
        path: '/select',
        builder: (_, _) => const Scaffold(body: Text('picker')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        Provider<TownDirectory>.value(value: directory),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('an empty list offers add and no rows', (tester) async {
    await _pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.regionEmpty), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('picker'), findsOneWidget);
  });

  testWidgets('a saved town can be removed and the cap hides add', (
    tester,
  ) async {
    final store = await _pump(
      tester,
      saved: const ['6300100', '6300200', '6300300'],
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('區6300100區'), findsOneWidget);
    expect(find.text('臺北市'), findsNWidgets(3));

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(store.savedCodes, ['6300200', '6300300']);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
