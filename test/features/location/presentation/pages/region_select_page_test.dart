/// [RegionSelectPage]: the city level of the region picker — a search field
/// over [TownDirectory.cities] (already deduplicated to ~20 names), a count
/// header, a star on every city that holds a saved township, and a tap that
/// drills into `RegionCityPage` by pushing [AppRoutes.regionSelectCity].
///
/// The one behaviour worth pinning precisely is where `replaceCode` and
/// `returnToMore` come from: the constructor when the page was pushed
/// directly, but the *route's own* query parameters when it was not (a deep
/// link, or any caller that reaches this page without threading the
/// constructor through) — [RegionSelectPage.build] falls back to
/// `GoRouterState.of(context).uri.queryParameters` for exactly that reason,
/// and both paths must forward identically onto the next push.
library;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/location/presentation/pages/region_select_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Town _town(String code, String city, String cityLevel, String town) => Town(
  code: code,
  city: city,
  town: town,
  lat: 25,
  lng: 121,
  cityLevel: cityLevel,
  townLevel: '區',
);

/// Three cities, one of them (臺北市) with more than one township, so the
/// city list has to collapse townships rather than just echo the map.
final _directory = TownDirectory({
  '100': _town('100', '臺北', '市', '中正'),
  '103': _town('103', '臺北', '市', '大同'),
  '801': _town('801', '高雄', '市', '新興'),
  '973': _town('973', '花蓮', '縣', '吉安'),
  '220': _town('220', '新北', '市', '板橋'),
});

Widget _wrap(
  RegionStore store, {
  String? replaceCode,
  bool? returnToMore,
  String initialLocation = '/',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => MultiProvider(
          providers: [
            ChangeNotifierProvider<RegionStore>.value(value: store),
            Provider<TownDirectory>.value(value: _directory),
          ],
          child: RegionSelectPage(
            replaceCode: replaceCode,
            returnToMore: returnToMore,
          ),
        ),
        routes: [
          // Stands in for RegionCityPage: renders exactly what it was pushed
          // with, so a test can read the push's parameters off the screen
          // instead of instrumenting the router.
          GoRoute(
            name: AppRoutes.regionSelectCity,
            path: AppRoutes.regionSelectCityPath,
            builder: (context, state) => Text(
              'city:${state.pathParameters['city']}|'
              'replace:${state.uri.queryParameters['replace'] ?? '-'}|'
              'returnToMore:${state.uri.queryParameters['returnToMore'] ?? '-'}',
            ),
          ),
        ],
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

  testWidgets('lists every city once, not once per township', (tester) async {
    await tester.pumpWidget(_wrap(await _store()));

    expect(find.text('臺北市'), findsOneWidget);
    expect(find.text('高雄市'), findsOneWidget);
    expect(find.text('花蓮縣'), findsOneWidget);
    expect(find.text('新北市'), findsOneWidget);
  });

  testWidgets('typing in the search field narrows the city list', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(await _store()));

    await tester.enterText(find.byType(TextField), '高雄');
    await tester.pump();

    expect(find.text('高雄市'), findsOneWidget);
    expect(find.text('臺北市'), findsNothing);
    expect(find.text('花蓮縣'), findsNothing);
  });

  testWidgets('no match empties the list and shows the empty view', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(await _store()));
    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    await tester.enterText(find.byType(TextField), '東京');
    await tester.pump();

    expect(find.text(l10n.regionSearchEmpty), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets(
    'the clear button appears only once there is a query, and resets the filter',
    (tester) async {
      await tester.pumpWidget(_wrap(await _store()));
      expect(find.byIcon(Icons.clear), findsNothing);

      await tester.enterText(find.byType(TextField), '高雄');
      await tester.pump();
      expect(find.byIcon(Icons.clear), findsOneWidget);
      expect(find.text('臺北市'), findsNothing);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsNothing);
      expect(find.text('臺北市'), findsOneWidget);
      expect(find.text('高雄市'), findsOneWidget);
      expect(find.text('花蓮縣'), findsOneWidget);
    },
  );

  testWidgets('the section header shows the saved count against the cap', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(await _store(['100'])));
    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(
      find.text(l10n.regionSelectCount(1, RegionStore.maxSaved)),
      findsOneWidget,
    );
  });

  testWidgets('only a city with a saved township shows a star', (tester) async {
    await tester.pumpWidget(_wrap(await _store(['100']))); // 臺北市 中正區

    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, '臺北市'),
        matching: find.byIcon(Icons.star),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, '高雄市'),
        matching: find.byIcon(Icons.star),
      ),
      findsNothing,
    );
  });

  testWidgets('tapping a city pushes the city page with just its name', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(await _store()));

    await tester.tap(find.text('臺北市'));
    await tester.pumpAndSettle();

    expect(find.text('city:臺北市|replace:-|returnToMore:-'), findsOneWidget);
  });

  testWidgets('台北 finds the directory\'s 臺北市', (tester) async {
    await tester.pumpWidget(_wrap(await _store()));

    await tester.enterText(find.byType(TextField), ' 台北 ');
    await tester.pump();

    expect(find.text('臺北市'), findsOneWidget);
    expect(find.text('高雄市'), findsNothing);
    // A city query is answered by the city; its districts are one tap away.
    expect(find.text('臺北市 中正區'), findsNothing);
  });

  testWidgets('a township is found on the first page and saves on tap', (
    tester,
  ) async {
    final store = await _store();
    await tester.pumpWidget(_wrap(store));
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

    await tester.enterText(find.byType(TextField), '板橋');
    await tester.pump();

    expect(find.text(l10n.regionSearchEmpty), findsNothing);
    expect(find.text(l10n.regionSearchTownsHeader), findsOneWidget);
    // Titled with its city: two cities can share a township name.
    expect(find.text('新北市 板橋區'), findsOneWidget);

    await tester.tap(find.text('新北市 板橋區'));
    await tester.pump();

    expect(store.savedCodes, ['220']);
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, '新北市 板橋區'),
        matching: find.byIcon(Icons.star),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a township hit honours replace and returns to More', (
    tester,
  ) async {
    final store = await _store(['100']);
    final router = GoRouter(
      initialLocation: '/?replace=100&returnToMore=1',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MultiProvider(
            providers: [
              ChangeNotifierProvider<RegionStore>.value(value: store),
              Provider<TownDirectory>.value(value: _directory),
            ],
            child: const RegionSelectPage(),
          ),
        ),
        GoRoute(
          name: AppRoutes.more,
          path: '/more',
          builder: (_, _) => const Text('more'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh', 'TW'),
        routerConfig: router,
      ),
    );

    await tester.enterText(find.byType(TextField), '吉安');
    await tester.pump();
    await tester.tap(find.text('花蓮縣 吉安區'));
    await tester.pumpAndSettle();

    expect(store.savedCodes, ['973']);
    expect(find.text('more'), findsOneWidget);
  });

  testWidgets(
    'forwards the constructor replaceCode and returnToMore as query parameters',
    (tester) async {
      await tester.pumpWidget(
        _wrap(await _store(), replaceCode: '801', returnToMore: true),
      );

      await tester.tap(find.text('高雄市'));
      await tester.pumpAndSettle();

      expect(find.text('city:高雄市|replace:801|returnToMore:1'), findsOneWidget);
    },
  );

  testWidgets(
    "replaceCode and returnToMore fall back to the route's own query parameters",
    (tester) async {
      await tester.pumpWidget(
        _wrap(await _store(), initialLocation: '/?replace=973&returnToMore=1'),
      );

      await tester.tap(find.text('花蓮縣'));
      await tester.pumpAndSettle();

      expect(find.text('city:花蓮縣|replace:973|returnToMore:1'), findsOneWidget);
    },
  );
}
