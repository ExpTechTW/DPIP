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

  testWidgets('the reorder button opens the category editor', (tester) async {
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
    // Level 1 is the category list: one drag handle per category, no layer
    // rows, no chevron on a single-layer category (typhoon).
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(4));
    Finder inEditor(String text) => find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.text(text),
    );
    expect(inEditor(l10n.mapLayerCategoryTyphoon), findsOneWidget);
    expect(inEditor(l10n.mapLayerCategoryWeather), findsOneWidget);
    expect(inEditor(l10n.mapLayerCategorySatellite), findsOneWidget);
    expect(inEditor(l10n.mapLayerCategoryRadar), findsOneWidget);
    // The picker behind still shows the active layer's tile — the editor's
    // level-1 list must not. Only radar holds more than one layer, so just one
    // category is drill-in-able.
    expect(inEditor('Radar echo'), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('tapping a category opens its layer list and back returns', (
    tester,
  ) async {
    await pumpSwitcher(tester, {});
    await tester.tap(find.text('Radar echo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(MapLayerSwitcher)),
    );
    Finder editorText(String text) => find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.text(text),
    );
    final radarCategory = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.text(l10n.mapLayerCategoryRadar),
    );
    await tester.tap(radarCategory);
    await tester.pumpAndSettle();

    // Level 2 shows just the radar-group layers, each with a drag handle.
    expect(editorText('Radar echo'), findsOneWidget);
    expect(editorText('Precip'), findsOneWidget);
    expect(editorText('Rain'), findsNothing);
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));
    // The back affordance appears only on level 2.
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(editorText('Radar echo'), findsNothing);
    expect(editorText(l10n.mapLayerCategoryTyphoon), findsOneWidget);
  });

  testWidgets('dragging a category reorders the categories', (tester) async {
    final controller = await pumpSwitcher(tester, {});
    await tester.tap(find.text('Radar echo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    // Radar is the bottom category. Drag its handle far up to the top.
    final handles = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.byIcon(Icons.drag_handle),
    );
    await tester.drag(handles.last, const Offset(0, -600));
    await tester.pumpAndSettle();

    // Category order moved radar to the top; the layer snapshot follows the
    // block order (radar group, then the rest in declared order).
    expect(controller.categoryOrder, [
      'radar',
      'typhoon',
      'weather',
      'satellite',
    ]);
    expect(controller.order, [
      'radar',
      'qpesums',
      'typhoon',
      'rain',
      'satellite',
    ]);
  });

  testWidgets('dragging a layer reorders within its category', (tester) async {
    final controller = await pumpSwitcher(tester, {});
    await tester.tap(find.text('Radar echo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(MapLayerSwitcher)),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(ReorderableListView),
        matching: find.text(l10n.mapLayerCategoryRadar),
      ),
    );
    await tester.pumpAndSettle();

    // Precip sits below radar echo. Drag its handle far up to flip them.
    final handles = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.byIcon(Icons.drag_handle),
    );
    await tester.drag(handles.last, const Offset(0, -300));
    await tester.pumpAndSettle();

    // Only the layer ids changed — precip now before radar echo within the
    // radar group; the category order is untouched (declared order, so the
    // flattened snapshot leads with the typhoon block).
    expect(controller.order, [
      'typhoon',
      'rain',
      'satellite',
      'qpesums',
      'radar',
    ]);
    expect(controller.categoryOrder, isEmpty);
  });

  testWidgets('reset restores the grouped default and clears both preferences', (
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

    // The category list falls back to the grouped default…
    final inEditor = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.text(l10n.mapLayerCategoryRadar),
    );
    await tester.tap(inEditor);
    await tester.pumpAndSettle();
    // …and radar echo is back before precip within the radar group.
    expect(topOf(tester, 'Radar echo'), lessThan(topOf(tester, 'Precip')));
    // Both preferences are cleared.
    expect(controller.order, isEmpty);
    expect(controller.categoryOrder, isEmpty);
  });
}
