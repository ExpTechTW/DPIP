import 'package:dpip/shared/map/admin_outline.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_weather_overlay.dart';
import 'package:dpip/features/map/presentation/widgets/typhoon_overlay_menu.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'raster_timeline_harness.dart';

/// The menu never touches the repositories — it only reads and flips notifiers.
class _FakeTyphoonRepository implements MeteorTyphoonRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeRadarRepository extends FakeRasterFrameSource
    implements RadarRepository {
  _FakeRadarRepository() : super(const []);

  @override
  String tileUrl(String frame) => 'https://host/$frame/{z}/{x}/{y}.webp';
}

class _FakeSatelliteRepository extends FakeRasterFrameSource
    implements SatelliteRepository {
  _FakeSatelliteRepository() : super(const []);

  @override
  String tileUrl(String frame) => 'https://host/sat/$frame/{z}/{x}/{y}.png';

  @override
  void setStyle(String? style) {}
}

TyphoonMapLayer _layer() => TyphoonMapLayer(
  _FakeTyphoonRepository(),
  radar: _FakeRadarRepository(),
  satellite: _FakeSatelliteRepository(),
);

Widget _wrap(TyphoonMapLayer layer) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topRight,
      child: TyphoonOverlayMenu(
        layer: layer,
        showTownLabels: ValueNotifier<bool>(true),
        onShowTownLabelsChanged: (_) {},
      ),
    ),
  ),
);

Future<AppLocalizations> _l10n() =>
    AppLocalizations.delegate.load(const Locale('en'));

/// Opens the dropdown.
Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(MapChipButton));
  await tester.pumpAndSettle();
}

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
  test('every radar overlay defaults on', () {
    final layer = _layer();
    expect(layer.showScanRange.value, isTrue);
    expect(layer.showCountyOutline.value, isTrue);
    expect(layer.showTownOutline.value, isTrue);
    // And radar is already the underlay, so they are live on first open.
    expect(layer.weatherOverlay.value, TyphoonWeatherOverlay.radar);
  });

  testWidgets('the radar chrome rows show while radar is the underlay', (
    tester,
  ) async {
    _useTallSurface(tester);
    final layer = _layer();
    await tester.pumpWidget(_wrap(layer));
    await _open(tester);

    final l10n = await _l10n();
    expect(find.text(l10n.radarScanRange), findsOneWidget);
    expect(find.text(l10n.radarCountyOutline), findsOneWidget);
    expect(find.text(l10n.radarTownOutline), findsOneWidget);
  });

  testWidgets('they disappear when the underlay is satellite', (tester) async {
    _useTallSurface(tester);
    final layer = _layer();
    await tester.pumpWidget(_wrap(layer));

    layer.setWeatherOverlay(TyphoonWeatherOverlay.satellite);
    await tester.pumpAndSettle();
    await _open(tester);

    final l10n = await _l10n();
    // The radar chrome toggles exist only while the radar underlay does — a
    // coverage boundary over Himawari IR would bound an instrument that is not
    // on screen, and the base style's borders only disappear under the echo.
    expect(find.text(l10n.radarScanRange), findsNothing);
    expect(find.text(l10n.radarCountyOutline), findsNothing);
    expect(find.text(l10n.radarTownOutline), findsNothing);
  });

  testWidgets('they disappear when there is no underlay at all', (
    tester,
  ) async {
    _useTallSurface(tester);
    final layer = _layer();
    await tester.pumpWidget(_wrap(layer));

    layer.setWeatherOverlay(TyphoonWeatherOverlay.none);
    await tester.pumpAndSettle();
    await _open(tester);

    final l10n = await _l10n();
    expect(find.text(l10n.radarScanRange), findsNothing);
    expect(find.text(l10n.radarCountyOutline), findsNothing);
    expect(find.text(l10n.radarTownOutline), findsNothing);
  });

  testWidgets('tapping a row flips only its own flag', (tester) async {
    _useTallSurface(tester);
    final layer = _layer();
    await tester.pumpWidget(_wrap(layer));
    await _open(tester);

    final l10n = await _l10n();
    await tester.tap(find.text(l10n.radarScanRange));
    await tester.pumpAndSettle();

    expect(layer.showScanRange.value, isFalse);
    expect(layer.showCountyOutline.value, isTrue);
    expect(layer.showTownOutline.value, isTrue);
  });

  testWidgets('switching away from radar does not reset the toggles', (
    tester,
  ) async {
    _useTallSurface(tester);
    final layer = _layer();
    await tester.pumpWidget(_wrap(layer));
    layer.setShowCountyOutline(false);

    layer.setWeatherOverlay(TyphoonWeatherOverlay.satellite);
    layer.setWeatherOverlay(TyphoonWeatherOverlay.radar);
    await tester.pumpAndSettle();
    await _open(tester);

    // The choice is the reader's; a round trip through another underlay must
    // not silently hand it back.
    expect(layer.showCountyOutline.value, isFalse);
    // Exactly one box is clear: the county one. Everything else is still on.
    expect(find.byIcon(Icons.check_box_outline_blank), findsNWidgets(3));
  });

  testWidgets('the chip is marked whenever an underlay is showing', (
    tester,
  ) async {
    _useTallSurface(tester);
    final layer = _layer();
    await tester.pumpWidget(_wrap(layer));

    // Radar is the default underlay, and any underlay is itself a deviation
    // from the bare track — so the chip starts marked.
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isTrue,
    );

    layer.setWeatherOverlay(TyphoonWeatherOverlay.none);
    await tester.pumpAndSettle();

    // With no underlay the radar chrome is not drawn either, so nothing on
    // screen differs from the defaults and the marker clears.
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isFalse,
    );

    layer.setShowScanRange(false);
    await tester.pumpAndSettle();

    // A radar-only toggle must not light the marker while radar is off — it
    // would be pointing at a line that is not on the map.
    expect(
      tester.widget<MapChipButton>(find.byType(MapChipButton)).active,
      isFalse,
    );
  });

  testWidgets(
    'the legend carries the satellite frame while satellite is the underlay',
    (tester) async {
      _useTallSurface(tester);
      final layer = _layer();
      layer.setWeatherOverlay(TyphoonWeatherOverlay.satellite);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(builder: (context) => layer.buildLegend(context)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = await _l10n();
      // The fully-opaque IR underlay buries the base style, so the bright-yellow
      // country/county frame and the dark-yellow township mesh are keyed — but
      // the radar scan range has no instrument on screen and is not.
      expect(find.text(l10n.mapLayerSatelliteGlobalOutline), findsOneWidget);
      expect(find.text(l10n.radarCountyOutline), findsOneWidget);
      expect(find.text(l10n.radarTownOutline), findsOneWidget);
      expect(find.text(l10n.radarScanRange), findsNothing);
    },
  );

  test('the county border can be anchored under the typhoon vectors', () async {
    final controller = RecordingMapController();
    await AdminOutline.add(
      controller,
      AdminBoundary.county,
      belowLayerId: 'typhoon-probability',
    );

    // On the radar surface these go on top; over a typhoon track they must not
    // cross the thing being read, so the anchor has to reach the layer call.
    expect(
      controller.belowOf(AdminBoundary.county.lineLayerId),
      'typhoon-probability',
    );
    expect(
      controller.belowOf(AdminBoundary.county.casingLayerId),
      'typhoon-probability',
    );
  });

  test(
    'the default border core is white; satellite passes bright yellow',
    () async {
      final controller = RecordingMapController();
      await AdminOutline.add(controller, AdminBoundary.county);
      expect(
        controller.lineColorOf(AdminBoundary.county.lineLayerId),
        '#FFFFFF',
      );
      expect(
        controller.lineColorOf(AdminBoundary.county.casingLayerId),
        '#000000',
      );

      final satelliteController = RecordingMapController();
      await AdminOutline.add(
        satelliteController,
        AdminBoundary.town,
        lineColor: satelliteOutlineColor,
      );
      expect(
        satelliteController.lineColorOf(AdminBoundary.town.lineLayerId),
        '#FFD400',
      );
    },
  );

  test('omitting the anchor keeps the borders on top', () async {
    final controller = RecordingMapController();
    await AdminOutline.add(controller, AdminBoundary.county);
    expect(controller.belowOf(AdminBoundary.county.lineLayerId), isNull);
  });
}
