/// A wind-forecast layer names its model, caps the camera at the published
/// grid, and draws the shared speed legend. A gesture flags the particle
/// field as interacting for the whole finger-down.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/wind_forecast_layer.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:dpip/features/weather/domain/wind_forecast_model.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart';
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

  for (final model in WindForecastModel.values) {
    testWidgets('${model.key} identity, zoom cap, legend, and gesture flag', (
      tester,
    ) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final layer = WindForecastMapLayer(
        _WindRepo(),
        model: model,
        referenceOutline: testReferenceOutline(),
      );
      expect(layer.id, 'wind-${model.key}');
      expect(layer.opacity, 1);
      expect(layer.mapMinZoom, 3);
      expect(layer.mapMaxZoom, 7);
      expect(layer.rasterBelowLayerId, townLabelLayerId);
      expect(layer.overlayFollowsCamera, isFalse);
      expect(layer.field.value, isNull);
      expect(layer.interacting.value, isFalse);
      layer.onMapGestureStart();
      expect(layer.interacting.value, isTrue);
      layer.onMapGestureEnd();
      expect(layer.interacting.value, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  Text(layer.label(context)),
                  Text(layer.subtitle(context)!),
                  Text(layer.timelineCaption(context)),
                  layer.buildLegend(context),
                  layer.buildMapOverlay(context),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text(l10n.mapTimelineForecast), findsOneWidget);
      expect(find.text(model.subtitle), findsOneWidget);
      expect(find.textContaining('m/s'), findsOneWidget);
      expect(
        find.text(
          model == WindForecastModel.ecmwf
              ? l10n.mapLayerWindForecastEcmwf
              : l10n.mapLayerWindForecastGfs,
        ),
        findsOneWidget,
      );
    });
  }
}
