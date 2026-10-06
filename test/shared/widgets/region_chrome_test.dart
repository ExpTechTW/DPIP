/// The region bar, the pager, and the swipe area are three views of one
/// [RegionStore]. A swipe that does not move the store, or a badge that
/// shows a code instead of the town name, leaves Home and Events naming
/// different places.
library;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/region_bar.dart';
import 'package:dpip/shared/widgets/region_label.dart';
import 'package:dpip/shared/widgets/region_pager.dart';
import 'package:dpip/shared/widgets/region_swipe_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _directory = TownDirectory({
  '6300100': Town(
    code: '6300100',
    city: '臺北',
    town: '中正',
    lat: 25,
    lng: 121,
    cityLevel: '市',
    townLevel: '區',
  ),
});

Widget _app(RegionStore store, Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: store),
      Provider<TownDirectory>.value(value: _directory),
    ],
    child: Scaffold(body: child),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('labels come from the directory, not from a stored name', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      regionAreaLabel(l10n, _directory, const NationwideArea()),
      l10n.regionNationwide,
    );
    expect(
      regionAreaLabel(l10n, _directory, const CurrentArea(null)),
      l10n.regionCurrent,
    );
    expect(
      regionAreaLabel(l10n, _directory, const SavedArea('6300100')),
      '中正區',
    );
    expect(
      regionAreaLabel(l10n, _directory, const SavedArea('missing')),
      'missing',
    );
  });

  testWidgets('a fast horizontal fling changes area; a slow one does not', (
    tester,
  ) async {
    final store = RegionStore(SettingsStore.inMemory())..addSaved('6300100');
    await tester.pumpWidget(
      _app(store, const RegionSwipeArea(child: SizedBox.expand())),
    );
    // Launch selects 所在地, the slot after 全國.
    expect(store.selectedIndex, 1);

    await tester.fling(
      find.byType(RegionSwipeArea),
      const Offset(-400, 0),
      800,
    );
    expect(store.selectedIndex, 2);

    await tester.fling(find.byType(RegionSwipeArea), const Offset(20, 0), 50);
    expect(store.selectedIndex, 2);

    await tester.fling(find.byType(RegionSwipeArea), const Offset(400, 0), 800);
    expect(store.selectedIndex, 1);
  });

  testWidgets('the pager builds the selected area and follows the store', (
    tester,
  ) async {
    final store = RegionStore(SettingsStore.inMemory())..addSaved('6300100');
    await tester.pumpWidget(
      _app(
        store,
        RegionPager(itemBuilder: (context, index) => Text('area $index')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('area 1'), findsOneWidget);

    store.select(2);
    await tester.pumpAndSettle();
    expect(find.text('area 2'), findsOneWidget);
  });

  testWidgets('the bar names each area and a tap selects it', (tester) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = RegionStore(SettingsStore.inMemory())..addSaved('6300100');
    await tester.pumpWidget(
      _app(store, const RegionBar(blend: 0.4, dismiss: 0, skyIsLight: false)),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(RegionBar)));
    expect(find.text(l10n.regionNationwide), findsWidgets);
    expect(find.text('中正區'), findsWidgets);

    await tester.tap(find.text('中正區'));
    await tester.pumpAndSettle();
    expect(store.selectedIndex, 2);

    await tester.pumpWidget(
      _app(store, const RegionBar(blend: 1, dismiss: 0.8, skyIsLight: true)),
    );
    await tester.pumpAndSettle();
    final ignored = tester.widget<IgnorePointer>(
      find
          .descendant(
            of: find.byType(RegionBar),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(ignored.ignoring, isTrue);
  });
}
