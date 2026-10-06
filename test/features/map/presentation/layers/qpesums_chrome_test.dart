/// QPESUMS is a one-hour forecast raster: its timeline says so, the legend is
/// millimetres per hour, and the coverage geometry is the forecast rectangle
/// rather than the radar circles.
library;

import 'package:dpip/features/map/presentation/layers/qpesums_layer.dart';
import 'package:dpip/features/map/presentation/layers/qpesums_scan_range.dart';
import 'package:dpip/features/weather/domain/qpesums_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

class _Repo extends FakeRasterFrameSource implements QpesumsRepository {
  _Repo() : super(const []);

  @override
  String tileUrl(String frame) => 'https://example.invalid/$frame/{z}/{x}/{y}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('identity, forecast caption, and precipitation legend', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final layer = QpesumsMapLayer(_Repo(), testReferenceOutline());
    expect(layer.id, 'qpesums');
    expect(layer.icon, Icons.cloud_outlined);
    expect(layer.opacity, 0.85);
    expect(layer.framePeriod, const Duration(hours: 1));
    expect(layer.rasterBelowLayerId, townLabelLayerId);
    expect(layer.scanRangeSourceId, QpesumsScanRange.sourceId);
    expect(layer.scanRangeLayerId, QpesumsScanRange.outlineLayerId);
    expect(layer.scanRangeGeoJson['type'], 'FeatureCollection');
    expect(layer.scanRangeColor, isNotEmpty);

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
                Text(layer.timelineCaption(context)),
                layer.buildLegend(context),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text(l10n.mapLayerQpesums), findsOneWidget);
    expect(find.text(l10n.mapTimelineForecast), findsOneWidget);
    expect(find.textContaining('mm/h'), findsOneWidget);
  });
}
