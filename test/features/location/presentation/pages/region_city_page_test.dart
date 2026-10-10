import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/location/presentation/pages/region_city_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Town _town(String code, String town) => Town(
  code: code,
  city: '臺北',
  town: town,
  lat: 25,
  lng: 121,
  cityLevel: '市',
  townLevel: '區',
);

final _directory = TownDirectory({
  '100': _town('100', '中正'),
  '103': _town('103', '大同'),
  '104': _town('104', '中山'),
  '105': _town('105', '松山'),
});

Widget _wrap(RegionStore store) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => MultiProvider(
          providers: [
            ChangeNotifierProvider<RegionStore>.value(value: store),
            Provider<TownDirectory>.value(value: _directory),
          ],
          child: const RegionCityPage(city: '臺北市'),
        ),
      ),
    ],
  );
  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh', 'TW'),
    routerConfig: router,
  );
}

Future<RegionStore> _store([List<String>? saved]) async {
  return RegionStore(
    SettingsStore.inMemory(
      saved == null ? {} : {'home.savedRegionCodes': saved},
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('lists the townships of the city', (tester) async {
    await tester.pumpWidget(_wrap(await _store()));
    expect(find.text('中正區'), findsOneWidget);
    expect(find.text('松山區'), findsOneWidget);
  });

  testWidgets('tapping a township saves it (filled star)', (tester) async {
    final store = await _store();
    await tester.pumpWidget(_wrap(store));

    await tester.tap(find.text('中正區'));
    await tester.pump();

    expect(store.savedCodes, ['100']);
    expect(find.byIcon(Icons.star), findsOneWidget); // only the saved row
  });

  testWidgets('tapping a saved township removes it', (tester) async {
    final store = await _store(['100']);
    await tester.pumpWidget(_wrap(store));

    await tester.tap(find.text('中正區'));
    await tester.pump();

    expect(store.savedCodes, isEmpty);
  });

  testWidgets('adding beyond the cap explains the limit and saves nothing', (
    tester,
  ) async {
    final store = await _store(['103', '104', '105']); // full (3)
    await tester.pumpWidget(_wrap(store));

    await tester.tap(find.text('中正區'));
    await tester.pumpAndSettle();

    expect(store.savedCodes, ['103', '104', '105']); // unchanged
    expect(find.text('最多只能選擇 3 個地區'), findsOneWidget);
  });

  testWidgets('search filters townships and the clear button restores them', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('zh', 'TW'));
    await tester.pumpWidget(_wrap(await _store()));

    await tester.enterText(find.byType(TextField), '松山');
    await tester.pump();
    expect(find.text('松山區'), findsOneWidget);
    expect(find.text('中正區'), findsNothing);

    await tester.tap(find.byTooltip(l10n.commonClose));
    await tester.pump();
    expect(find.text('中正區'), findsOneWidget);
    expect(find.text('松山區'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '沒有這個區');
    await tester.pump();
    expect(find.text(l10n.regionSearchTownEmpty), findsOneWidget);
  });

  testWidgets('replace swaps the named township and can return to More', (
    tester,
  ) async {
    final store = await _store(['100', '103']);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MultiProvider(
            providers: [
              ChangeNotifierProvider<RegionStore>.value(value: store),
              Provider<TownDirectory>.value(value: _directory),
            ],
            child: const RegionCityPage(city: '臺北市', replaceCode: '100'),
          ),
        ),
        GoRoute(
          path: '/more',
          name: AppRoutes.more,
          builder: (_, _) => const Scaffold(body: Text('more-page')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh', 'TW'),
        routerConfig: router,
      ),
    );

    // Already saved, and not the township being replaced: the row is inert.
    final kept = tester.widget<ListTile>(find.widgetWithText(ListTile, '大同區'));
    expect(kept.enabled, isFalse);
    expect(kept.onTap, isNull);

    await tester.tap(find.text('中山區'));
    await tester.pump();
    expect(store.savedCodes, ['104', '103']);
  });

  testWidgets('a successful pick returns to More when asked', (tester) async {
    final store = await _store();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MultiProvider(
            providers: [
              ChangeNotifierProvider<RegionStore>.value(value: store),
              Provider<TownDirectory>.value(value: _directory),
            ],
            child: const RegionCityPage(city: '臺北市', returnToMore: true),
          ),
        ),
        GoRoute(
          path: '/more',
          name: AppRoutes.more,
          builder: (_, _) => const Scaffold(body: Text('more-page')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh', 'TW'),
        routerConfig: router,
      ),
    );

    await tester.tap(find.text('中正區'));
    await tester.pumpAndSettle();
    expect(store.savedCodes, ['100']);
    expect(find.text('more-page'), findsOneWidget);
  });

  testWidgets('a new city on the same page rescans its townships', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('zh', 'TW'));
    final city = ValueNotifier('臺北市');
    addTearDown(city.dispose);
    final store = await _store();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => ValueListenableBuilder<String>(
            valueListenable: city,
            builder: (_, name, _) => MultiProvider(
              providers: [
                ChangeNotifierProvider<RegionStore>.value(value: store),
                Provider<TownDirectory>.value(value: _directory),
              ],
              child: RegionCityPage(city: name),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh', 'TW'),
        routerConfig: router,
      ),
    );
    expect(find.text('中正區'), findsOneWidget);

    city.value = '高雄市';
    await tester.pump();
    expect(find.text('中正區'), findsNothing);
    expect(find.text(l10n.regionSearchTownEmpty), findsOneWidget);
  });
}
