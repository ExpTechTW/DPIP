/// Township names and terrain relief are base-map settings, so every layer
/// menu has to offer the same rows. A row that does not call back leaves the
/// map unchanged while the checkbox looks flipped.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_terrain_toggle.dart';
import 'package:dpip/shared/map/map_town_labels.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the terrain row flips through its callback', (tester) async {
    final shown = ValueNotifier(true);
    addTearDown(shown.dispose);
    var next = true;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MenuAnchor(
            menuChildren: [
              MapTerrainRow(
                showTerrain: shown,
                onShowTerrainChanged: (value) => next = value,
              ),
            ],
            builder: (context, controller, _) => TextButton(
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(MapTerrainRow)),
    );
    await tester.tap(find.text(l10n.mapTerrainRelief));
    await tester.pump();
    expect(next, isFalse);

    shown.value = false;
    await tester.pump();
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
  });

  testWidgets('the basemap menu opens both rows and reports a non-default', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final labels = ValueNotifier(false);
    final terrain = ValueNotifier(true);
    addTearDown(labels.dispose);
    addTearDown(terrain.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: MapBasemapMenu(
              showTownLabels: labels,
              onShowTownLabelsChanged: (value) => labels.value = value,
              showTerrain: terrain,
              onShowTerrainChanged: (value) => terrain.value = value,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isTrue,
    );

    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(MapBasemapMenu)),
    );
    expect(find.text(l10n.mapTownLabels), findsWidgets);
    expect(find.text(l10n.mapTerrainRelief), findsOneWidget);

    await tester.tap(find.text(l10n.mapTerrainRelief));
    await tester.pumpAndSettle();
    expect(terrain.value, isFalse);
  });

  testWidgets('the shared section lists map controls in a stable order', (
    tester,
  ) async {
    final labels = ValueNotifier(true);
    final terrain = ValueNotifier(true);
    addTearDown(labels.dispose);
    addTearDown(terrain.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MenuAnchor(
            menuChildren: [
              MapBasemapControlRows(
                showTownLabels: labels,
                onShowTownLabelsChanged: (value) => labels.value = value,
                showTerrain: terrain,
                onShowTerrainChanged: (_) {},
              ),
            ],
            builder: (context, controller, _) => TextButton(
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.mapOverlaySectionMap), findsOneWidget);
    await tester.ensureVisible(find.text(l10n.mapTownLabels));
    await tester.tap(find.text(l10n.mapTownLabels));
    await tester.pump();
    expect(labels.value, isFalse);
  });
}
