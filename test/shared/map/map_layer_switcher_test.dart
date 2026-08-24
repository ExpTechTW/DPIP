import 'package:dpip/core/settings/map_layer_order_controller.dart';
import 'package:dpip/core/settings/map_layer_visibility_controller.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_layer_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Minimal [MapLayer] for switcher tests — identity + label (+ optional
/// subtitle) only.
class _FakeLayer implements MapLayer {
  _FakeLayer(this.id, this._label, [this._subtitle]);

  @override
  final String id;
  final String _label;
  final String? _subtitle;

  @override
  String label(BuildContext context) => _label;

  @override
  String? subtitle(BuildContext context) => _subtitle;

  @override
  IconData get icon => Icons.layers_outlined;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final radar = _FakeLayer('radar', 'Radar echo');
  final qpesums = _FakeLayer('qpesums', 'Precip');
  final ecmwf = _FakeLayer('wind-ecmwf', 'ECMWF', '0.25° · 3 h');
  final gfs = _FakeLayer('wind-gfs', 'GFS', '0.25° · 1 h');
  final satellite = _FakeLayer('satellite', 'Satellite IR', 'B13 · 10.4 µm');
  final rain = _FakeLayer('rain', 'Rain');
  final typhoon = _FakeLayer('typhoon', 'Typhoon path');
  final layers = [radar, qpesums, ecmwf, gfs, satellite, rain, typhoon];

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
    final settings = SettingsStore.inMemory(initial);
    final controller = MapLayerOrderController(settings);
    final visibility = MapLayerVisibilityController(settings);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MapLayerOrderController>.value(
            value: controller,
          ),
          ChangeNotifierProvider<MapLayerVisibilityController>.value(
            value: visibility,
          ),
        ],
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
    // Group order: radar → forecast → typhoon → weather → satellite. The
    // numerical-forecast group (QPESUMS, then the unsaved wind models appended
    // in declared order) sits right under radar.
    expect(
      topOf(tester, l10n.mapLayerCategoryRadar),
      lessThan(topOf(tester, l10n.mapLayerCategoryForecast)),
    );
    expect(
      topOf(tester, l10n.mapLayerCategoryForecast),
      lessThan(topOf(tester, l10n.mapLayerCategoryTyphoon)),
    );
    expect(
      topOf(tester, l10n.mapLayerCategoryTyphoon),
      lessThan(topOf(tester, l10n.mapLayerCategoryWeather)),
    );
    expect(
      topOf(tester, l10n.mapLayerCategoryWeather),
      lessThan(topOf(tester, l10n.mapLayerCategorySatellite)),
    );
    // Within the forecast group the saved precip keeps its place above the
    // wind models, which follow the declared order (ECMWF before GFS).
    expect(topOf(tester, 'Precip'), lessThan(topOf(tester, 'ECMWF')));
    expect(topOf(tester, 'ECMWF'), lessThan(topOf(tester, 'GFS')));
    // A layer's subtitle sits under its label in the same tile.
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('B13 · 10.4 µm'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('0.25° · 3 h'),
      ),
      findsOneWidget,
    );
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

      // Unsaved layers keep the declared order within their groups: Radar
      // group (radar echo) at the top, then forecast (precip, ECMWF, GFS)
      // above weather (rain) and satellite (satellite IR).
      expect(topOf(tester, 'Radar echo'), lessThan(topOf(tester, 'Rain')));
      expect(topOf(tester, 'Rain'), lessThan(topOf(tester, 'Satellite IR')));
      expect(topOf(tester, 'Precip'), lessThan(topOf(tester, 'GFS')));
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
    // rows. Every category shows a chevron — single-layer ones too, since
    // the visibility eyes live on level 2.
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(5));
    Finder inEditor(String text) => find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.text(text),
    );
    expect(inEditor(l10n.mapLayerCategoryRadar), findsOneWidget);
    expect(inEditor(l10n.mapLayerCategoryForecast), findsOneWidget);
    expect(inEditor(l10n.mapLayerCategoryTyphoon), findsOneWidget);
    expect(inEditor(l10n.mapLayerCategoryWeather), findsOneWidget);
    expect(inEditor(l10n.mapLayerCategorySatellite), findsOneWidget);
    // The picker behind still shows the active layer's tile — the editor's
    // level-1 list must not.
    expect(inEditor('Radar echo'), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(5));
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('a single-layer category opens and hides its only layer', (
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
    await tester.tap(
      find.descendant(
        of: find.byType(ReorderableListView),
        matching: find.text(l10n.mapLayerCategoryRadar),
      ),
    );
    await tester.pumpAndSettle();

    // The radar row is reachable on level 2 with a working eye — hiding it
    // must not be blocked by the category holding just one layer. Scoped to
    // the reorder list: the "show all" / "hide all" row above it has its own
    // visibility icons.
    final rows = find.byType(ReorderableListView);
    expect(
      find.descendant(of: rows, matching: find.byIcon(Icons.visibility)),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: rows, matching: find.byIcon(Icons.visibility)),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: rows, matching: find.byIcon(Icons.visibility_off)),
      findsOneWidget,
    );

    // Back to level 1, close the editor, then look at the picker.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Back on the picker: hiding drops the tile entirely, not just dims it —
    // and radar's now-empty category (nothing else belongs to it) drops out
    // of the list too. The editor's eye remains the only way back.
    final sheet = find.byType(DraggableScrollableSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Radar echo')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.text(l10n.mapLayerCategoryRadar),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Rain')),
      findsOneWidget,
    );
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
    final forecastCategory = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.text(l10n.mapLayerCategoryForecast),
    );
    await tester.tap(forecastCategory);
    await tester.pumpAndSettle();

    // Level 2 shows just the forecast-group layers, each with a drag handle.
    expect(editorText('Precip'), findsOneWidget);
    expect(editorText('ECMWF'), findsOneWidget);
    expect(editorText('GFS'), findsOneWidget);
    expect(editorText('Rain'), findsNothing);
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
    // The back affordance appears only on level 2.
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(editorText('Precip'), findsNothing);
    expect(editorText(l10n.mapLayerCategoryRadar), findsOneWidget);
  });

  testWidgets('a hidden layer is left out of the picker', (tester) async {
    await pumpSwitcher(tester, {
      'map.layerHiddenIds': ['qpesums'],
    });
    await tester.tap(find.text('Radar echo'));
    await tester.pumpAndSettle();

    // The hidden layer drops out of the list entirely — nothing dims it,
    // nothing marks it. Its still-visible category siblings are unaffected.
    expect(find.text('Precip'), findsNothing);
    expect(find.byIcon(Icons.visibility_off), findsNothing);
    expect(find.text('ECMWF'), findsOneWidget);
    expect(find.text('Rain'), findsOneWidget);
  });

  testWidgets('the editor eye toggle hides a layer live', (tester) async {
    await pumpSwitcher(tester, {});
    await tester.tap(find.text('Radar echo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(ReorderableListView),
        matching: find.text(
          AppLocalizations.of(tester.element(find.byType(MapLayerSwitcher)))
              .mapLayerCategoryForecast,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Three visible layers, three eyes. Scoped to the reorder list: the
    // "show all" / "hide all" row above it has its own visibility icons.
    // Hide the first row's layer.
    final rows = find.byType(ReorderableListView);
    Finder rowIcon(IconData icon) =>
        find.descendant(of: rows, matching: find.byIcon(icon));
    expect(rowIcon(Icons.visibility), findsNWidgets(3));
    await tester.tap(rowIcon(Icons.visibility).first);
    await tester.pumpAndSettle();
    expect(rowIcon(Icons.visibility), findsNWidgets(2));
    expect(rowIcon(Icons.visibility_off), findsOneWidget);

    // Back to level 1, close the editor: back on the picker the hidden
    // layer is gone — the order editor's eye is the only way to offer it
    // again.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.text('Precip'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byIcon(Icons.visibility_off),
      ),
      findsNothing,
    );
  });

  testWidgets('show all / hide all toggle every layer in the open category', (
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
    await tester.tap(
      find.descendant(
        of: find.byType(ReorderableListView),
        matching: find.text(l10n.mapLayerCategoryForecast),
      ),
    );
    await tester.pumpAndSettle();

    final rows = find.byType(ReorderableListView);
    Finder rowIcon(IconData icon) =>
        find.descendant(of: rows, matching: find.byIcon(icon));

    expect(rowIcon(Icons.visibility), findsNWidgets(3));
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.mapLayerHideAll));
    await tester.pumpAndSettle();
    expect(rowIcon(Icons.visibility_off), findsNWidgets(3));

    await tester.tap(find.widgetWithText(OutlinedButton, l10n.mapLayerShowAll));
    await tester.pumpAndSettle();
    expect(rowIcon(Icons.visibility), findsNWidgets(3));
  });

  testWidgets(
    "hide all keeps the surface's last visible layer even inside the open "
    'category',
    (tester) async {
      // Every other category already hidden — the open one (forecast) holds
      // the only layers left on screen.
      await pumpSwitcher(tester, {
        'map.layerHiddenIds': ['radar', 'typhoon', 'rain', 'satellite'],
      });
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
          matching: find.text(l10n.mapLayerCategoryForecast),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(OutlinedButton, l10n.mapLayerHideAll),
      );
      await tester.pumpAndSettle();

      // "Hide all" can't take the surface's last layer — one row stays
      // visible instead of all three going dark.
      final rows = find.byType(ReorderableListView);
      expect(
        find.descendant(of: rows, matching: find.byIcon(Icons.visibility)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: rows, matching: find.byIcon(Icons.visibility_off)),
        findsNWidgets(2),
      );
    },
  );

  testWidgets('dragging a category reorders the categories', (tester) async {
    final controller = await pumpSwitcher(tester, {});
    await tester.tap(find.text('Radar echo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    // Satellite is the bottom category. Drag its handle far up to the top.
    final handles = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.byIcon(Icons.drag_handle),
    );
    await tester.drag(handles.last, const Offset(0, -600));
    await tester.pumpAndSettle();

    // Category order moved satellite to the top; the layer snapshot follows
    // the block order (satellite group, then the rest in declared order).
    expect(controller.categoryOrder, [
      'satellite',
      'radar',
      'forecast',
      'typhoon',
      'weather',
    ]);
    expect(controller.order, [
      'satellite',
      'radar',
      'qpesums',
      'wind-ecmwf',
      'wind-gfs',
      'typhoon',
      'rain',
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
        matching: find.text(l10n.mapLayerCategoryForecast),
      ),
    );
    await tester.pumpAndSettle();

    // GFS sits below ECMWF. Drag its handle far up to flip them.
    final handles = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.byIcon(Icons.drag_handle),
    );
    await tester.drag(handles.last, const Offset(0, -300));
    await tester.pumpAndSettle();

    // Only the layer ids changed — GFS now first in the forecast group; the
    // category order is untouched (declared order, so the flattened snapshot
    // leads with the radar block).
    expect(controller.order, [
      'radar',
      'wind-gfs',
      'qpesums',
      'wind-ecmwf',
      'typhoon',
      'rain',
      'satellite',
    ]);
    expect(controller.categoryOrder, isEmpty);
  });

  testWidgets(
    'reset restores the grouped default and clears both preferences',
    (tester) async {
      // A saved order that flips the forecast pair and moves a category — a
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
        matching: find.text(l10n.mapLayerCategoryForecast),
      );
      await tester.tap(inEditor);
      await tester.pumpAndSettle();
      // …and precip is back before the wind models within the forecast group.
      expect(topOf(tester, 'Precip'), lessThan(topOf(tester, 'ECMWF')));
      expect(topOf(tester, 'ECMWF'), lessThan(topOf(tester, 'GFS')));
      // Both preferences are cleared.
      expect(controller.order, isEmpty);
      expect(controller.categoryOrder, isEmpty);
    },
  );
}
