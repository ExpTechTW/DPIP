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

  final radar = _FakeLayer('radar', 'Radar');
  final rain = _FakeLayer('rain', 'Rain');
  final typhoon = _FakeLayer('typhoon', 'Typhoon');
  final layers = [radar, rain, typhoon];

  Future<MapLayerOrderController> pumpSwitcher(
    WidgetTester tester,
    Map<String, Object> initial, {
    MapLayer? active,
  }) async {
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

  testWidgets('the picker lists layers in the saved order', (tester) async {
    await pumpSwitcher(tester, {
      'map.layerOrder': ['rain', 'typhoon', 'radar'],
    });
    await tester.tap(find.text('Radar'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(MapLayerSwitcher)),
    );
    // Header title is centred even with the trailing reorder button.
    expect(
      centreX(tester, find.text(l10n.mapLayers)),
      closeTo(screenWidth(tester) / 2, 1),
    );
    expect(topOf(tester, 'Rain'), lessThan(topOf(tester, 'Typhoon')));
    expect(topOf(tester, 'Typhoon'), lessThan(topOf(tester, 'Radar')));
  });

  testWidgets(
    'the picker puts a layer added after the saved order at the bottom',
    (tester) async {
      await pumpSwitcher(tester, {
        'map.layerOrder': ['typhoon'],
      });
      await tester.tap(find.text('Radar'));
      await tester.pumpAndSettle();

      expect(topOf(tester, 'Typhoon'), lessThan(topOf(tester, 'Radar')));
      expect(topOf(tester, 'Radar'), lessThan(topOf(tester, 'Rain')));
    },
  );

  testWidgets('the reorder button opens the order editor', (tester) async {
    await pumpSwitcher(tester, {});
    await tester.tap(find.text('Radar'));
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
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('reset restores the declared order and clears the preference', (
    tester,
  ) async {
    final controller = await pumpSwitcher(tester, {
      'map.layerOrder': ['rain', 'typhoon', 'radar'],
    });
    await tester.tap(find.text('Radar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(MapLayerSwitcher)),
    );
    await tester.tap(find.text(l10n.mapLayerOrderReset));
    await tester.pumpAndSettle();

    // The editor's own list falls back to the declared order…
    expect(topOf(tester, 'Radar'), lessThan(topOf(tester, 'Rain')));
    expect(topOf(tester, 'Rain'), lessThan(topOf(tester, 'Typhoon')));
    // …and the preference is cleared.
    expect(controller.order, isEmpty);
  });
}
