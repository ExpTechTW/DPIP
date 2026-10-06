/// The wind-forecast options chip toggles the three reference outlines. Each
/// row stays open and flips the shared outline controller.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/wind_forecast_layer.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:dpip/features/weather/domain/wind_forecast_model.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

class _WindRepo extends FakeRasterFrameSource
    implements WindForecastRepository {
  _WindRepo() : super(const []);

  @override
  String tileUrl(String frame) => 'https://example.invalid/$frame/{z}/{x}/{y}';

  @override
  Future<Result<WindField>> fetchWindField(String frame) async =>
      const Err(NetworkFailure('unused'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('each outline row flips that outline off', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final layer = WindForecastMapLayer(
      _WindRepo(),
      model: WindForecastModel.gfs,
      referenceOutline: testReferenceOutline(),
    );
    final labels = ValueNotifier(true);
    final terrain = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) => layer.buildTopTrailingChrome(
              context,
              showTownLabels: labels,
              onShowTownLabelsChanged: (value) => labels.value = value,
              showTerrain: terrain,
              onShowTerrainChanged: (value) => terrain.value = value,
              onReloadActive: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip(l10n.windForecastOverlayMenuTooltip));
    await tester.pumpAndSettle();
    Future<void> flip(String title) async {
      final row = find.ancestor(
        of: find.text(title),
        matching: find.byType(MapMenuToggleRow),
      );
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pump();
    }

    await flip(l10n.radarGlobalOutline);
    expect(layer.showGlobalOutline, isFalse);
    await flip(l10n.radarCountyOutline);
    expect(layer.showCountyOutline, isFalse);
    await flip(l10n.radarTownOutline);
    expect(layer.showTownOutline, isFalse);
  });
}
