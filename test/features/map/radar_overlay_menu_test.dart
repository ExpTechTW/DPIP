import 'package:dpip/features/map/presentation/layers/radar_layer.dart';
import 'package:dpip/features/map/presentation/widgets/radar_overlay_menu.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'raster_timeline_harness.dart';

class _FakeRadarRepository extends FakeRasterFrameSource
    implements RadarRepository {
  _FakeRadarRepository() : super(const ['1700000000']);

  @override
  String tileUrl(String frame) => 'https://host/$frame/{z}/{x}/{y}.webp';
}

Widget _wrap(
  RadarMapLayer layer, {
  ValueListenable<bool>? showTownLabels,
  ValueChanged<bool>? onShowTownLabelsChanged,
  ValueListenable<bool>? showTerrain,
  ValueChanged<bool>? onShowTerrainChanged,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  // Top-right of the map, where the scaffold mounts it beside the switcher.
  home: Scaffold(
    body: Align(
      alignment: Alignment.topRight,
      child: RadarOverlayMenu(
        layer: layer,
        showTownLabels: showTownLabels ?? ValueNotifier<bool>(true),
        onShowTownLabelsChanged: onShowTownLabelsChanged ?? (_) {},
        showTerrain: showTerrain ?? ValueNotifier<bool>(true),
        onShowTerrainChanged: onShowTerrainChanged ?? (_) {},
      ),
    ),
  ),
);

Future<AppLocalizations> _l10n() =>
    AppLocalizations.delegate.load(const Locale('en'));

/// The menus have grown past the 800x600 default test surface; a dropdown row
/// that lands off-screen cannot be tapped, which fails as a "widget cannot
/// receive pointer events" rather than as anything about the menu.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('the chip opens a menu carrying all eight overlay toggles', (
    tester,
  ) async {
    _useTallSurface(tester);
    final layer = testRadarLayer(_FakeRadarRepository());
    await tester.pumpWidget(_wrap(layer));

    final l10n = await _l10n();
    // Closed: neither row is on screen — this is a dropdown, not a panel.
    expect(find.text(l10n.radarScanRange), findsNothing);

    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.radarGlobalOutline), findsOneWidget);
    expect(find.text(l10n.radarScanRange), findsOneWidget);
    expect(find.text(l10n.radarCountyOutline), findsOneWidget);
    expect(find.text(l10n.radarTownOutline), findsOneWidget);
    expect(find.text(l10n.mapTownLabels), findsOneWidget);
    expect(find.text(l10n.mapTerrainRelief), findsOneWidget);
    expect(find.text(l10n.radarLightningOverlay), findsOneWidget);
    expect(find.text(l10n.radarWindOverlay), findsOneWidget);
    // The menu is sectioned like the typhoon one: the raster's reference
    // chrome first, then the base-map settings.
    expect(find.text(l10n.mapOverlaySectionReference), findsOneWidget);
    expect(find.text(l10n.mapOverlaySectionMap), findsOneWidget);
    expect(find.text(l10n.mapOverlaySectionData), findsOneWidget);
    // Reference chrome (scan range, county, town, 國界) and the name and
    // relief toggles all ship on. The two data rows are the ones that ship
    // off: they draw extra data over the echo, not chrome, so they are opt-in
    // — and only ever one at a time.
    expect(find.byIcon(Icons.check_box), findsNWidgets(6));
    expect(find.byIcon(Icons.check_box_outline_blank), findsNWidgets(2));
  });

  testWidgets('the lightning row toggles the overlay and its chip dot', (
    tester,
  ) async {
    _useTallSurface(tester);
    final layer = testRadarLayer(_FakeRadarRepository());
    await tester.pumpWidget(_wrap(layer));

    final l10n = await _l10n();
    expect(layer.showLightning.value, isFalse);
    // Everything else ships at its default, so the chip is undotted until
    // lightning is switched on.
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isFalse,
    );

    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.radarLightningOverlay));
    await tester.pumpAndSettle();

    expect(layer.showLightning.value, isTrue);
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isTrue,
    );
  });

  testWidgets('the wind row toggles the overlay and its chip dot', (
    tester,
  ) async {
    _useTallSurface(tester);
    final layer = testRadarLayer(_FakeRadarRepository());
    await tester.pumpWidget(_wrap(layer));

    final l10n = await _l10n();
    expect(layer.showWind.value, isFalse);
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isFalse,
    );

    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.radarWindOverlay));
    await tester.pumpAndSettle();

    expect(layer.showWind.value, isTrue);
    // The dot means "this echo carries something extra", whichever of the two
    // data overlays supplied it.
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isTrue,
    );
  });

  testWidgets('the two data rows read as a three-way choice', (tester) async {
    _useTallSurface(tester);
    final layer = testRadarLayer(_FakeRadarRepository());
    await tester.pumpWidget(_wrap(layer));

    final l10n = await _l10n();
    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.radarLightningOverlay));
    await tester.pumpAndSettle();

    // Seven ticks and one blank, whichever data row is the ticked one: the
    // pair is a three-way choice, so both ticked is a state the menu never
    // shows. Asserted in the open menu, which is where the reader sees it.
    expect(find.byIcon(Icons.check_box), findsNWidgets(7));
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);

    // Tapped from the menu as it stands, with lightning on — the row is live
    // rather than greyed out, which is the whole point of the choice.
    await tester.tap(find.text(l10n.radarWindOverlay));
    await tester.pumpAndSettle();

    expect(layer.showWind.value, isTrue);
    expect(
      layer.showLightning.value,
      isFalse,
      reason:
          'the wind row is tappable while lightning is on precisely so the '
          'reader can swap in one tap — and the swap must turn the other off',
    );
    expect(find.byIcon(Icons.check_box), findsNWidgets(7));
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
  });

  testWidgets('a row leaves the menu open; the chip closes it', (tester) async {
    _useTallSurface(tester);
    final layer = testRadarLayer(_FakeRadarRepository());
    await tester.pumpWidget(_wrap(layer));

    final l10n = await _l10n();
    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.radarCountyOutline));
    await tester.pumpAndSettle();

    // The map behind the menu has already changed; a reader comparing two or
    // three toggles against it must not have to reopen the menu each time.
    expect(layer.showCountyOutline, isFalse);
    expect(find.text(l10n.radarCountyOutline), findsOneWidget);

    // A second toggle, from the menu still standing open.
    await tester.tap(find.text(l10n.radarTownOutline));
    await tester.pumpAndSettle();
    expect(layer.showTownOutline, isFalse);
    expect(find.text(l10n.radarTownOutline), findsOneWidget);

    // The chip is what closes it — the same tap that opened it.
    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.radarCountyOutline), findsNothing);
  });

  testWidgets('tapping the terrain-relief row reports the flip upward', (
    tester,
  ) async {
    _useTallSurface(tester);
    final layer = testRadarLayer(_FakeRadarRepository());
    final terrain = ValueNotifier<bool>(true);
    final flipped = <bool>[];
    await tester.pumpWidget(
      _wrap(layer, showTerrain: terrain, onShowTerrainChanged: flipped.add),
    );

    final l10n = await _l10n();
    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.mapTerrainRelief));
    await tester.pumpAndSettle();

    // Same contract as the name toggle: the value lives on the scaffold.
    expect(flipped, [false]);
  });

  testWidgets('tapping the national-border row turns it off', (tester) async {
    _useTallSurface(tester);
    final layer = testRadarLayer(_FakeRadarRepository());
    await tester.pumpWidget(_wrap(layer));

    final l10n = await _l10n();
    expect(layer.showGlobalOutline, isTrue);
    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.radarGlobalOutline));
    await tester.pumpAndSettle();

    expect(layer.showGlobalOutline, isFalse);
    // Independent controls: one must not drag the others with it.
    expect(layer.showCountyOutline, isTrue);
    expect(layer.showTownOutline, isTrue);
  });

  testWidgets('tapping the coverage row turns it off', (tester) async {
    _useTallSurface(tester);
    final layer = testRadarLayer(_FakeRadarRepository());
    await tester.pumpWidget(_wrap(layer));

    final l10n = await _l10n();
    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.radarScanRange));
    await tester.pumpAndSettle();

    expect(layer.showScanRange, isFalse);
    // Independent controls: one must not drag the others with it.
    expect(layer.showCountyOutline, isTrue);
    expect(layer.showTownOutline, isTrue);
  });

  testWidgets('tapping the county row turns it off', (tester) async {
    _useTallSurface(tester);
    final layer = testRadarLayer(_FakeRadarRepository());
    await tester.pumpWidget(_wrap(layer));

    final l10n = await _l10n();
    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.radarCountyOutline));
    await tester.pumpAndSettle();

    expect(layer.showCountyOutline, isFalse);
    expect(layer.showScanRange, isTrue);
    expect(layer.showTownOutline, isTrue);
  });

  testWidgets('tapping the township row turns only it off', (tester) async {
    _useTallSurface(tester);
    final layer = testRadarLayer(_FakeRadarRepository());
    await tester.pumpWidget(_wrap(layer));

    final l10n = await _l10n();
    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.radarTownOutline));
    await tester.pumpAndSettle();

    expect(layer.showTownOutline, isFalse);
    expect(layer.showCountyOutline, isTrue);
  });

  testWidgets('tapping the township-label row reports the flip upward', (
    tester,
  ) async {
    _useTallSurface(tester);
    final layer = testRadarLayer(_FakeRadarRepository());
    final labels = ValueNotifier<bool>(true);
    final flipped = <bool>[];
    await tester.pumpWidget(
      _wrap(
        layer,
        showTownLabels: labels,
        onShowTownLabelsChanged: flipped.add,
      ),
    );

    final l10n = await _l10n();
    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.mapTownLabels));
    await tester.pumpAndSettle();

    // The toggle lives on the scaffold, not the layer — the row hands the
    // new value back up instead of flipping layer state.
    expect(flipped, [false]);
  });

  testWidgets('the chip marks itself active once a default is switched off', (
    tester,
  ) async {
    _useTallSurface(tester);
    final layer = testRadarLayer(_FakeRadarRepository());
    await tester.pumpWidget(_wrap(layer));

    // Both overlays ship on, so at rest the chip is unmarked.
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isFalse,
    );

    layer.setShowCountyOutline(false);
    await tester.pumpAndSettle();

    // The dot is the only cue that this layer is no longer showing everything
    // it would by default, while the menu is closed.
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isTrue,
    );
  });
}
