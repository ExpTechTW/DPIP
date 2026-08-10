import 'package:dpip/core/settings/map_layer_order_controller.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_layer_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal [MapLayer] for switcher tests — identity + label only.
class _FakeLayer implements MapLayer {
  _FakeLayer(this.id, this._label);

  @override
  final String id;
  final String _label;

  @override
  String label(BuildContext context) => _label;

  @override
  IconData get icon => Icons.layers_outlined;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final radar = _FakeLayer('radar', 'Radar echo');
  final qpesums = _FakeLayer('qpesums', 'Precip');
  final satellite = _FakeLayer('satellite', 'Satellite IR');
  final rain = _FakeLayer('rain', 'Rain');
  final typhoon = _FakeLayer('typhoon', 'Typhoon path');
  final layers = [radar, qpesums, satellite, rain, typhoon];

  Future<MapLayerOrderController> pumpSwitcher(
    WidgetTester tester,
    Map<String, Object> initial, {
    MapLayer? active,
  }) async {
    // Tall viewport so every category block is laid out inside the initial
    // sheet height — a short screen would lazily skip the bottom group.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(initial);
    final controller = MapLayerOrderController(
      Prefs(await SharedPreferences.getInstance()),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<MapLayerOrderController>.value(
        value: controller,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: MapLayerSwitcher(
                layers: layers,
                active: active ?? radar,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    return controller;
  }

  double topOf(WidgetTester tester, String text) {
    // The picker chip and a sheet tile can share a label; prefer the row inside
    // the (reorderable) sheet's list.
    final reorder = find.byType(ReorderableListView);
    final tile = reorder.evaluate().isNotEmpty
        ? find.descendant(of: reorder, matching: find.text(text))
        : find.descendant(
            of: find.byType(ListView).last,
            matching: find.text(text),
          );
    return tester.getTopLeft(tile).dy;
  }

  /// Horizontal centre of [finder] — for asserting a title is truly centred
  /// over the sheet, regardless of asymmetric header actions.
  double centreX(WidgetTester tester, Finder finder) =>
      tester.getCenter(finder).dx;

  double screenWidth(WidgetTester tester) =>
      tester.view.physicalSize.width / tester.view.devicePixelRatio;

  testWidgets('the picker groups layers by category, ordered within', (
    tester,
  ) async {
    await pumpSwitcher(tester, {
      'map.layerOrder': ['rain', 'typhoon', 'radar', 'qpesums', 'satellite'],
    });
    await tester.tap(find.text('Radar echo'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(MapLayerSwitcher)),
    );
    // Header title is centred even with the trailing reorder button.
    expect(
      centreX(tester, find.text(l10n.mapLayers)),
      closeTo(screenWidth(tester) / 2, 1),
    );
    // Group order: typhoon → weather → satellite → radar; the two radar-group
    // layers keep their saved relative order (radar echo before precip).
    expect(
      topOf(tester, l10n.mapLayerCategoryTyphoon),
      lessThan(topOf(tester, l10n.mapLayerCategoryWeather)),
    );
    expect(
      topOf(tester, l10n.mapLayerCategoryWeather),
      lessThan(topOf(tester, l10n.mapLayerCategorySatellite)),
    );
    expect(
      topOf(tester, l10n.mapLayerCategorySatellite),
      lessThan(topOf(tester, l10n.mapLayerCategoryRadar)),
    );
    expect(topOf(tester, 'Radar echo'), lessThan(topOf(tester, 'Precip')));
  });

  testWidgets(
    'the picker puts a layer added after the saved order at the bottom of '
    'its category',
    (tester) async {
      await pumpSwitcher(tester, {
        'map.layerOrder': ['typhoon'],
      });
      await tester.tap(find.text('Radar echo'));
      await tester.pumpAndSettle();

      // Unsaved layers keep the declared order within their groups: Rain
      // (weather) above Satellite above Radar group (radar echo, precip).
      expect(topOf(tester, 'Rain'), lessThan(topOf(tester, 'Satellite IR')));
      expect(
        topOf(tester, 'Satellite IR'),
        lessThan(topOf(tester, 'Radar echo')),
      );
      expect(topOf(tester, 'Radar echo'), lessThan(topOf(tester, 'Precip')));
    },
  );

  testWidgets('the reorder button opens the order editor', (tester) async {
    await pumpSwitcher(tester, {});
    await tester.tap(find.text('Radar echo'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(MapLayerSwitcher)),
    );
    // Editor title is centred over the reset + close actions.
    expect(
      centreX(tester, find.text(l10n.mapLayerOrderTitle)),
      closeTo(screenWidth(tester) / 2, 1),
    );
    // One drag handle per layer row *and* per non-empty category header (the
    // picker behind also shows headers — scope to the editor's own list).
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(9));
    Finder inEditor(String text) => find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.text(text),
    );
    expect(inEditor(l10n.mapLayerCategoryTyphoon), findsOneWidget);
    expect(inEditor(l10n.mapLayerCategoryWeather), findsOneWidget);
    expect(inEditor(l10n.mapLayerCategorySatellite), findsOneWidget);
    expect(inEditor(l10n.mapLayerCategoryRadar), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('dragging a layer clamps to its category', (tester) async {
    final controller = await pumpSwitcher(tester, {});
    await tester.tap(find.text('Radar echo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    // Precip sits in the bottom (radar) group. Drag its handle far up — past
    // the typhoon block — and it must land back next to radar, not escape the
    // group.
    final handles = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.byIcon(Icons.drag_handle),
    );
    await tester.drag(handles.last, const Offset(0, -700));
    await tester.pumpAndSettle();

    // Precip stays inside the radar group — dragged up it clamps to the
    // group's head, above radar echo but below the radar header, never
    // escaping into another category.
    final l10n = AppLocalizations.of(
      tester.element(find.byType(MapLayerSwitcher)),
    );
    expect(
      topOf(tester, l10n.mapLayerCategoryRadar),
      lessThan(topOf(tester, 'Precip')),
    );
    expect(topOf(tester, 'Precip'), lessThan(topOf(tester, 'Radar echo')));
    // The persisted order is the grouped snapshot — precip flipped above radar
    // within the radar group, nothing escaped to another category.
    expect(controller.order, [
      'typhoon',
      'rain',
      'satellite',
      'qpesums',
      'radar',
    ]);
  });

  testWidgets('dragging a category header moves its whole block', (
    tester,
  ) async {
    final controller = await pumpSwitcher(tester, {});
    await tester.tap(find.text('Radar echo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(MapLayerSwitcher)),
    );
    // Typhoon is the top block. Drag its header down past the radar block so
    // the whole group (header + its layer) lands at the bottom.
    final handles = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.byIcon(Icons.drag_handle),
    );
    final start = tester.getCenter(handles.first);
    final end = tester.getCenter(handles.last);
    await tester.drag(handles.first, end - start + const Offset(0, 30));
    await tester.pumpAndSettle();

    // The typhoon block now sits below radar echo, header above its layer.
    expect(
      topOf(tester, 'Radar echo'),
      lessThan(topOf(tester, l10n.mapLayerCategoryTyphoon)),
    );
    expect(
      topOf(tester, l10n.mapLayerCategoryTyphoon),
      lessThan(topOf(tester, 'Typhoon path')),
    );
    // Both persisted orders reflect the move: radar group first, typhoon last.
    expect(controller.categoryOrder, [
      'weather',
      'satellite',
      'radar',
      'typhoon',
    ]);
    expect(controller.order, [
      'rain',
      'satellite',
      'radar',
      'qpesums',
      'typhoon',
    ]);
  });

  testWidgets('reset restores the grouped default and clears the preference', (
    tester,
  ) async {
    // A saved order that flips the radar pair and moves a category — a
    // grouped-default order would disable the reset button (nothing to restore).
    final controller = await pumpSwitcher(tester, {
      'map.layerOrder': ['qpesums', 'satellite', 'rain', 'typhoon', 'radar'],
      'map.layerCategoryOrder': ['radar', 'typhoon'],
    });
    await tester.tap(find.text('Radar echo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(MapLayerSwitcher)),
    );
    await tester.tap(find.text(l10n.mapLayerOrderReset));
    await tester.pumpAndSettle();

    // The editor's own list falls back to the grouped default — radar echo
    // before precip within the bottom group…
    expect(topOf(tester, 'Radar echo'), lessThan(topOf(tester, 'Precip')));
    // …and both preferences are cleared.
    expect(controller.order, isEmpty);
    expect(controller.categoryOrder, isEmpty);
  });
}
