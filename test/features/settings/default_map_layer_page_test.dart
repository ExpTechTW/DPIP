/// The default-map page is the only place the Map tab's opening overlay is
/// chosen. A tap that does not move the check, or a category that drops a
/// layer, would open the map on the wrong product.
library;

import 'package:dpip/core/settings/default_map_layer.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/settings/presentation/pages/default_map_layer_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/default_map_layer_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const Size _tall = Size(400, 4000);

Future<DefaultMapLayerController> _pump(WidgetTester tester) async {
  tester.view.physicalSize = _tall;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = DefaultMapLayerController(SettingsStore.inMemory());
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DefaultMapLayerPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('radar starts checked and every layer is listed', (tester) async {
    final controller = await _pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(l10n.defaultMapLayerSettings), findsOneWidget);
    expect(find.text(l10n.defaultMapLayerSubtitle), findsOneWidget);
    expect(controller.layer, DefaultMapLayer.radar);
    for (final layer in DefaultMapLayer.values) {
      expect(find.text(layer.label(l10n)), findsWidgets);
    }
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('tapping typhoon persists that layer', (tester) async {
    final controller = await _pump(tester);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    final typhoon = find.widgetWithText(
      ListTile,
      DefaultMapLayer.typhoon.label(l10n),
    );
    await tester.tap(typhoon);
    await tester.pumpAndSettle();
    expect(controller.layer, DefaultMapLayer.typhoon);

    await tester.tap(typhoon);
    await tester.pumpAndSettle();
    expect(controller.layer, DefaultMapLayer.typhoon);
  });
}
