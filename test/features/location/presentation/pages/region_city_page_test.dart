import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/location/presentation/pages/region_city_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Widget _wrap(RegionStore store) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  home: MultiProvider(
    providers: [
      ChangeNotifierProvider<RegionStore>.value(value: store),
      Provider<TownDirectory>.value(value: _directory),
    ],
    child: const RegionCityPage(city: '臺北市'),
  ),
);

Future<RegionStore> _store([List<String>? saved]) async {
  SharedPreferences.setMockInitialValues(
    saved == null ? {} : {'home.savedRegionCodes': saved},
  );
  return RegionStore(Prefs(await SharedPreferences.getInstance()));
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
    await tester.pump();

    expect(store.savedCodes, ['103', '104', '105']); // unchanged
    expect(find.text('最多只能選擇 3 個地區'), findsOneWidget);
  });
}
