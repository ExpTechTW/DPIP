/// The frosted "tune" chip beside the disaster-prevention map's layer
/// switcher: its dot is the only sign, once the dropdown is closed, that AED /
/// restroom / shelter markers or a base-map option were changed from their
/// defaults, and its rows are the only way to change them back.
///
/// The dot is driven by one OR of three independent conditions — any
/// sub-layer hidden, town labels off, or terrain off. Losing a term (or
/// turning that `||` into `&&`) fails silently in the direction that matters
/// most here: a reader who hid the AED layer to declutter the map sees an
/// unmarked chip and has no reason to reopen it, so a disaster-prevention
/// layer they meant to keep available stays hidden with no visible sign why.
///
/// Every row here — the sub-layer toggles and (via [MapBasemapControlRows])
/// the base-map ones — sets `closeOnActivate: false` deliberately: this is a
/// settings panel a reader watches the map react to while changing several
/// rows in a row, not a command menu that should vanish after one tap. Losing
/// that flag would not crash anything; it would just force a reopen after
/// every single toggle, the kind of regression no analyzer catches.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/disaster_map/domain/aed_detail.dart';
import 'package:dpip/features/disaster_map/domain/disaster_map_repository.dart';
import 'package:dpip/features/disaster_map/domain/restroom_detail.dart';
import 'package:dpip/features/disaster_map/domain/shelter_detail.dart';
import 'package:dpip/features/map/presentation/layers/disaster_map_layer.dart';
import 'package:dpip/features/map/presentation/widgets/disaster_map_overlay_menu.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The menu only reads [DisasterMapLayer.subLayers] and flips a sub-layer's
/// visibility; that in turn reaches the repository only through a live map
/// controller (prefetch, on turning one back on) or once every sub-layer is
/// hidden at once (cancel). This suite never attaches a controller and never
/// hides all three, so [cancelTilePrefetch] gets a real, harmless body and
/// everything else is left to fail loudly if a future test's reach changes.
class _FakeDisasterMapRepository implements DisasterMapRepository {
  @override
  String tileUrl(String layer) => throw UnimplementedError();

  @override
  Future<Result<AedDetail>> aedDetail(int id) => throw UnimplementedError();

  @override
  Future<Result<RestroomDetail>> restroomDetail(int id) =>
      throw UnimplementedError();

  @override
  Future<Result<ShelterDetail>> shelterDetail(int id) =>
      throw UnimplementedError();

  @override
  Future<void> prefetchTiles({
    required String layer,
    required double south,
    required double west,
    required double north,
    required double east,
    required double zoom,
  }) => throw UnimplementedError();

  @override
  void cancelTilePrefetch() {}
}

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(
    body: Align(alignment: Alignment.topRight, child: child),
  ),
);

Future<AppLocalizations> _l10n() =>
    AppLocalizations.delegate.load(const Locale('en'));

/// Opens the dropdown.
Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(MapChipButton));
  await tester.pumpAndSettle();
}

/// The menu has grown past the 800x600 default test surface; a row that lands
/// off-screen cannot be tapped, which fails as "widget cannot receive pointer
/// events" rather than as anything about the menu itself.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// The checked/unchecked [icon] inside the row titled [title] — scoped so
/// asserting on one sub-layer's box can't accidentally match the base-map
/// rows' own checkboxes above it in the same dropdown.
Finder _rowIcon(String title, IconData icon) => find.descendant(
  of: find.widgetWithText(MenuItemButton, title),
  matching: find.byIcon(icon),
);

void main() {
  testWidgets(
    'the chip starts unmarked when every layer and option is at its default',
    (tester) async {
      final layer = DisasterMapLayer(_FakeDisasterMapRepository());
      await tester.pumpWidget(
        _wrap(
          DisasterMapOverlayMenu(
            layer: layer,
            showTownLabels: ValueNotifier<bool>(true),
            onShowTownLabelsChanged: (_) {},
            showTerrain: ValueNotifier<bool>(true),
            onShowTerrainChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
        isFalse,
      );
    },
  );

  testWidgets(
    'opening it lists all three sub-layers, each checked by default',
    (tester) async {
      _useTallSurface(tester);
      final layer = DisasterMapLayer(_FakeDisasterMapRepository());
      await tester.pumpWidget(
        _wrap(
          DisasterMapOverlayMenu(
            layer: layer,
            showTownLabels: ValueNotifier<bool>(true),
            onShowTownLabelsChanged: (_) {},
            showTerrain: ValueNotifier<bool>(true),
            onShowTerrainChanged: (_) {},
          ),
        ),
      );
      await _open(tester);

      final l10n = await _l10n();
      expect(find.text(l10n.disasterMapOverlaySectionLayers), findsOneWidget);
      for (final sub in layer.subLayers) {
        final label = DisasterMapLayer.layerLabel(l10n, sub.id);
        expect(find.text(label), findsOneWidget);
        expect(_rowIcon(label, Icons.check_box), findsOneWidget);
      }
    },
  );

  testWidgets(
    'hiding a sub-layer unchecks only its own row, marks the chip, and leaves the menu open',
    (tester) async {
      _useTallSurface(tester);
      final layer = DisasterMapLayer(_FakeDisasterMapRepository());
      await tester.pumpWidget(
        _wrap(
          DisasterMapOverlayMenu(
            layer: layer,
            showTownLabels: ValueNotifier<bool>(true),
            onShowTownLabelsChanged: (_) {},
            showTerrain: ValueNotifier<bool>(true),
            onShowTerrainChanged: (_) {},
          ),
        ),
      );
      await _open(tester);

      final l10n = await _l10n();
      final aedLabel = DisasterMapLayer.layerLabel(l10n, 'aed');
      final restroomLabel = DisasterMapLayer.layerLabel(l10n, 'restroom');

      await tester.tap(find.text(aedLabel));
      await tester.pumpAndSettle();

      expect(layer.aed.visible.value, isFalse);
      expect(layer.restroom.visible.value, isTrue);
      expect(_rowIcon(aedLabel, Icons.check_box_outline_blank), findsOneWidget);
      expect(_rowIcon(restroomLabel, Icons.check_box), findsOneWidget);
      // closeOnActivate: false — the dropdown must still be showing.
      expect(find.text(l10n.disasterMapOverlaySectionLayers), findsOneWidget);
      expect(
        tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
        isTrue,
      );

      // Tapping again restores the default and clears the marker.
      await tester.tap(find.text(aedLabel));
      await tester.pumpAndSettle();

      expect(layer.aed.visible.value, isTrue);
      expect(_rowIcon(aedLabel, Icons.check_box), findsOneWidget);
      expect(
        tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
        isFalse,
      );
    },
  );

  testWidgets(
    'turning off town labels marks the chip, with every sub-layer untouched',
    (tester) async {
      _useTallSurface(tester);
      final layer = DisasterMapLayer(_FakeDisasterMapRepository());
      final showTownLabels = ValueNotifier<bool>(true);
      await tester.pumpWidget(
        _wrap(
          DisasterMapOverlayMenu(
            layer: layer,
            showTownLabels: showTownLabels,
            onShowTownLabelsChanged: (v) => showTownLabels.value = v,
            showTerrain: ValueNotifier<bool>(true),
            onShowTerrainChanged: (_) {},
          ),
        ),
      );
      await _open(tester);

      final l10n = await _l10n();
      await tester.tap(find.text(l10n.mapTownLabels));
      await tester.pumpAndSettle();

      expect(showTownLabels.value, isFalse);
      expect(layer.subLayers.every((s) => s.visible.value), isTrue);
      expect(
        tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
        isTrue,
      );
    },
  );

  testWidgets(
    'turning off terrain marks the chip, with every sub-layer untouched',
    (tester) async {
      _useTallSurface(tester);
      final layer = DisasterMapLayer(_FakeDisasterMapRepository());
      final showTerrain = ValueNotifier<bool>(true);
      await tester.pumpWidget(
        _wrap(
          DisasterMapOverlayMenu(
            layer: layer,
            showTownLabels: ValueNotifier<bool>(true),
            onShowTownLabelsChanged: (_) {},
            showTerrain: showTerrain,
            onShowTerrainChanged: (v) => showTerrain.value = v,
          ),
        ),
      );
      await _open(tester);

      final l10n = await _l10n();
      await tester.tap(find.text(l10n.mapTerrainRelief));
      await tester.pumpAndSettle();

      expect(showTerrain.value, isFalse);
      expect(layer.subLayers.every((s) => s.visible.value), isTrue);
      expect(
        tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
        isTrue,
      );
    },
  );
}
