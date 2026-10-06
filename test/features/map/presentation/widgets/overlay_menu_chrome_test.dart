/// Forecast and scan-range menus are the same chip. A toggle that closes the
/// menu, or a chip dot that ignores an extra radar row, makes the next change
/// a second tap.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/wind_forecast_layer.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/map/presentation/widgets/forecast_overlay_menu.dart';
import 'package:dpip/features/map/presentation/widgets/scan_range_overlay_menu.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:dpip/features/weather/domain/wind_forecast_model.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

class _Wind extends FakeRasterFrameSource implements WindForecastRepository {
  _Wind() : super(const []);

  @override
  String tileUrl(String frame) => 'https://example.invalid/$frame/{z}/{x}/{y}';

  @override
  Future<Result<WindField>> fetchWindField(String frame) async =>
      const Err(NetworkFailure('unused'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('forecast rows flip the shared outlines and the chip dot', (
    tester,
  ) async {
    tall(tester);
    final layer = WindForecastMapLayer(
      _Wind(),
      model: WindForecastModel.gfs,
      referenceOutline: testReferenceOutline(),
    );
    final labels = ValueNotifier(true);
    final terrain = ValueNotifier(true);
    addTearDown(labels.dispose);
    addTearDown(terrain.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: ForecastOverlayMenu(
              layer: layer,
              showTownLabels: labels,
              onShowTownLabelsChanged: (value) => labels.value = value,
              showTerrain: terrain,
              onShowTerrainChanged: (value) => terrain.value = value,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isFalse,
    );
    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ForecastOverlayMenu)),
    );
    await _flip(tester, l10n.radarGlobalOutline);
    expect(layer.showGlobalOutline, isFalse);
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isTrue,
    );
    await _flip(tester, l10n.mapTownLabels);
    expect(labels.value, isFalse);
  });

  testWidgets('scan-range rows include extras and flip the coverage outline', (
    tester,
  ) async {
    tall(tester);
    final layer = testRadarLayer(_Radar());
    final labels = ValueNotifier(true);
    final terrain = ValueNotifier(true);
    addTearDown(labels.dispose);
    addTearDown(terrain.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: ScanRangeOverlayMenu(
              layer: layer,
              tooltip: 'Radar options',
              showTownLabels: labels,
              onShowTownLabelsChanged: (value) => labels.value = value,
              showTerrain: terrain,
              onShowTerrainChanged: (value) => terrain.value = value,
              extraActive: true,
              extraSections: const [Text('Lightning row')],
            ),
          ),
        ),
      ),
    );
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isTrue,
    );
    await tester.tap(find.byType(MapChipButton));
    await tester.pumpAndSettle();
    expect(find.text('Lightning row'), findsOneWidget);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ScanRangeOverlayMenu)),
    );
    await _flip(tester, l10n.radarScanRange);
    expect(layer.showScanRange, isFalse);
    await _flip(tester, l10n.radarTownOutline);
    expect(layer.showTownOutline, isFalse);
  });
}

Future<void> _flip(WidgetTester tester, String title) async {
  final row = find.ancestor(
    of: find.text(title),
    matching: find.byType(MapMenuToggleRow),
  );
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pump();
  await tester.pumpAndSettle();
}

class _Radar extends FakeRasterFrameSource implements RadarRepository {
  _Radar() : super(const ['1700000000']);

  @override
  String tileUrl(String frame) => 'https://example.invalid/$frame.png';
}
