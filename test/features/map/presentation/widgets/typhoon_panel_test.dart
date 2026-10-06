/// The typhoon sheet is the only place a warning, a storm's English name, and
/// a tapped forecast fix are read together. An empty season has to say so,
/// and a second storm has to be selectable without mixing the two bulletins.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_storm_band.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_weather_overlay.dart';
import 'package:dpip/features/map/presentation/widgets/typhoon_panel.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:dpip/features/typhoon/domain/storm_circle.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/features/typhoon/domain/typhoon_kind.dart';
import 'package:dpip/features/typhoon/domain/typhoon_potential.dart';
import 'package:dpip/features/typhoon/domain/typhoon_probability.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:dpip/features/typhoon/domain/typhoon_warning.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

class _Cam extends RecordingMapController {
  @override
  Future<bool?> animateCamera(
    CameraUpdate cameraUpdate, {
    Duration? duration,
  }) async => true;
}

const _circle = StormCircle(avg: 180, ne: 200, se: 220, sw: 160, nw: 140);

TrackForecast _forecast(int tau, {double lat = 24, double lon = 122}) =>
    TrackForecast(
      tau: tau,
      time: 1700000000 + tau * 3600,
      latitude: lat,
      longitude: lon,
      wind: 35,
      gust: 45,
      pressure: 960,
      speed: 18,
      direction: 'WNW',
      r15: 200,
      state: const ['減弱', 'weakening'],
    );

TyphoonTrack _haishen() => TyphoonTrack(
  name: 'HAISHEN',
  cwaName: '海神',
  year: 2026,
  tdNo: '1',
  tyNo: '14',
  analysis: const [
    TrackFix(
      time: 1700000000 - 6 * 3600,
      latitude: 22.4,
      longitude: 124.2,
      wind: 38,
      pressure: 965,
    ),
    TrackFix(
      time: 1700000000,
      latitude: 23.2,
      longitude: 123.1,
      wind: 40,
      gust: 52,
      pressure: 960,
    ),
  ],
  now: const TrackNow(
    speed: 22,
    direction: 'WNW',
    c15: _circle,
    c25: StormCircle(avg: 80, ne: 90, se: 100, sw: 70, nw: 60),
  ),
  forecast: [
    _forecast(12, lat: 24.1, lon: 121.4),
    _forecast(24, lat: 25.0, lon: 120.2),
    _forecast(36, lat: 26.2, lon: 119.0),
  ],
);

TyphoonTrack _depression() => const TyphoonTrack(
  name: '',
  year: 2026,
  tdNo: '19',
  analysis: [
    TrackFix(time: 1700000000, latitude: 10, longitude: 140, wind: 12),
  ],
  forecast: [],
);

class _Repo implements MeteorTyphoonRepository {
  /// When false, the nearest storm is chosen from the track, not the index.
  bool withIndex = true;

  @override
  Future<Result<CycloneIndex>> cyclones() async => Ok(
    CycloneIndex(
      updated: 1700000000,
      cyclones: withIndex
          ? const [
              TyphoonCyclone(
                name: 'HAISHEN',
                cwaName: '海神',
                year: 2026,
                tdNo: '1',
                tyNo: '14',
                time: 1700000000,
                latitude: 23.2,
                longitude: 123.1,
                wind: 40,
                pressure: 960,
                speed: 22,
                direction: 'WNW',
              ),
              TyphoonCyclone(
                name: '',
                year: 2026,
                tdNo: '19',
                time: 1700000000,
                latitude: 10,
                longitude: 140,
              ),
            ]
          : const [],
    ),
  );

  @override
  Future<Result<TrackPayload>> track() async => Ok(
    TrackPayload(updated: 1700000000, cyclones: [_haishen(), _depression()]),
  );

  @override
  Future<Result<PotentialPayload>> potential() async =>
      const Ok(PotentialPayload(updated: 1, cyclones: []));

  @override
  Future<Result<TyphoonProbability>> probability() async =>
      const Ok(TyphoonProbability(updated: 1, cyclones: []));

  @override
  Future<Result<WarningPayload>> warning() async => Ok(
    WarningPayload(
      updated: 1700000000,
      cyclones: [
        TyphoonWarning(
          tdNo: '1',
          active: true,
          id: 'w1',
          sent: 1700000000,
          status: 'Actual',
          msgType: 'Alert',
          scope: 'Public',
          event: 'Sea warning',
          urgency: 'Immediate',
          severity: 'Severe',
          certainty: 'Observed',
          effective: 1700000000,
          onset: 1700000000,
          expires: 1700003600,
          headline: 'Sea warning',
          senderName: 'CWA',
          typhoon: const WarningTyphoon(
            name: 'HAISHEN',
            cwaName: '海神',
            no: '14',
            analysis: WarningFix(
              time: 1700000000,
              latitude: 23.2,
              longitude: 123.1,
              wind: 40,
              pressure: 960,
            ),
          ),
          sections: const [
            WarningSection(title: 'Wind', text: 'Gale force near the centre.'),
            WarningSection(title: 'Sea', text: 'Very rough.'),
            WarningSection(title: 'Rain', text: 'Heavy along the east coast.'),
            WarningSection(title: 'Extra', text: 'Not shown.'),
          ],
          areas: const [
            WarningArea(name: 'Hualien', code: '10015'),
            WarningArea(name: 'Taitung', code: '10014'),
          ],
        ),
      ],
    ),
  );

  @override
  Future<Result<List<int>>> history(TyphoonKind kind) async => const Ok([]);

  @override
  Future<Result<TrackPayload>> trackAt(int second) async =>
      const Ok(TrackPayload(updated: 0, cyclones: []));

  @override
  Future<Result<PotentialPayload>> potentialAt(int second) async =>
      const Ok(PotentialPayload(updated: 0, cyclones: []));

  @override
  Future<Result<TyphoonProbability>> probabilityAt(int second) async =>
      const Ok(TyphoonProbability(updated: 0, cyclones: []));

  @override
  Future<Result<WarningPayload>> warningAt(int second) async =>
      const Ok(WarningPayload(updated: 0, cyclones: []));
}

class _Radar extends FakeRasterFrameSource implements RadarRepository {
  _Radar([super.frames = const []]);

  @override
  String tileUrl(String frame) => 'https://example.invalid/{z}/{x}/{y}';
}

class _Sat extends FakeRasterFrameSource implements SatelliteRepository {
  _Sat([super.frames = const []]);

  @override
  String tileUrl(String frame) => 'https://example.invalid/{z}/{x}/{y}';

  @override
  void setStyle(String? style) {}
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: home),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the sheet title prefers a named typhoon, then a depression number',
    () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(
        cycloneSheetTitle(l10n, name: 'HAISHEN', cwaName: '海神', tyNo: '14'),
        '海神 TY 14',
      );
      expect(cycloneSheetTitle(l10n, tdNo: '19'), 'Tropical depression TD 19');
      expect(cycloneSheetTitle(l10n, name: 'INVEST'), 'INVEST');
    },
  );

  testWidgets('nothing active says so', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final layer = TyphoonMapLayer(_Repo(), radar: _Radar(), satellite: _Sat());
    await tester.pumpWidget(_app(TyphoonPanel(layer: layer)));
    await tester.pump();
    expect(find.text(l10n.typhoonNoActive), findsOneWidget);
  });

  testWidgets('a summary with no track still names the storm', (tester) async {
    final layer = TyphoonMapLayer(_Repo(), radar: _Radar(), satellite: _Sat());
    layer.summary.value = const TyphoonCyclone(
      name: 'HAISHEN',
      cwaName: '海神',
      year: 2026,
      tdNo: '1',
      tyNo: '14',
      time: 1700000000,
      latitude: 23.2,
      longitude: 123.1,
      wind: 40,
      pressure: 960,
      speed: 12,
      direction: '停滯',
    );
    await tester.pumpWidget(_app(TyphoonPanel(layer: layer)));
    await tester.pump();
    expect(find.text('海神'), findsOneWidget);
    expect(find.text('HAISHEN'), findsOneWidget);
    expect(find.text('停滯'), findsOneWidget);
  });

  testWidgets(
    'a bulletin shows the warning, and a forecast tap can be closed',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final layer = TyphoonMapLayer(
        _Repo(),
        radar: _Radar(),
        satellite: _Sat(),
      );
      await layer.render(_Cam());
      await tester.pumpWidget(_app(TyphoonPanel(layer: layer)));
      await tester.pump();
      await tester.pump();

      expect(find.text('海神'), findsWidgets);
      expect(find.text('HAISHEN'), findsOneWidget);
      expect(find.text('TY 14'), findsOneWidget);
      expect(find.text('west-northwest'), findsWidgets);
      expect(layer.matchedWarning, isNotNull);
      await tester.scrollUntilVisible(find.text(l10n.typhoonWarningTitle), 200);
      expect(find.text('Sea warning'), findsOneWidget);
      expect(find.text('Wind'), findsOneWidget);
      expect(find.text('Rain'), findsOneWidget);
      expect(find.text('Extra'), findsNothing);
      expect(
        find.text(l10n.typhoonWarningAreas('Hualien, Taitung')),
        findsOneWidget,
      );

      // The warning sits below the picker, so revealing it scrolls the pills
      // above the sheet. Jump back before tapping one.
      tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .jumpTo(0);
      await tester.pump();
      await tester.tap(find.text('TD 19'));
      await tester.pump();
      expect(find.text(l10n.typhoonIntensityTd), findsWidgets);

      await tester.ensureVisible(find.text('海神'));
      await tester.tap(find.text('海神').first);
      await tester.pump();

      layer.tapped.value = '+12h';
      layer.tapRevision.value++;
      await tester.pump();
      await tester.scrollUntilVisible(find.text('+12h'), 200);
      expect(find.text('+12h'), findsOneWidget);
      expect(find.text(l10n.typhoonForecastLead('12')), findsOneWidget);
      expect(find.text('weakening'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      expect(find.text(l10n.typhoonForecastLead('12')), findsNothing);
    },
  );

  testWidgets(
    'overlay toggles, a tap, and the legend follow a rendered storm',
    (tester) async {
      final layer = TyphoonMapLayer(
        _Repo()..withIndex = false,
        radar: _Radar(const ['1699990000', '1700000000']),
        satellite: _Sat(const ['1699990000', '1700000000']),
      );
      final map = _Cam();
      await layer.render(map);
      expect(layer.selectedFocusBounds(), isNotNull);

      layer.setShowProbability(false);
      layer.setShowProbability(true);
      layer.setShowForecastCallouts(true);
      layer.setShowForecastCallouts(false);
      layer.setShowWarningAreas(false);
      layer.setShowWarningAreas(true);
      layer.setStormBand(TyphoonStormBand.level7);
      layer.setStormBand(TyphoonStormBand.level10);
      layer.setWeatherOverlay(TyphoonWeatherOverlay.radar);
      layer.setWeatherOverlay(TyphoonWeatherOverlay.none);
      layer.setWeatherOverlay(TyphoonWeatherOverlay.satellite);
      layer.setShowScanRange(true);
      layer.setShowScanRange(false);
      layer.setShowCountyOutline(true);
      layer.setShowCountyOutline(false);
      layer.setShowTownOutline(true);
      layer.setShowTownOutline(false);

      await tester.pumpWidget(
        _app(Builder(builder: (context) => layer.buildLegend(context))),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _app(Builder(builder: (context) => layer.buildSheet(context))),
      );
      await tester.pump();
      await tester.pumpWidget(
        _app(Builder(builder: (context) => layer.buildMapOverlay(context))),
      );
      await tester.pump();
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => layer.buildTopTrailingChrome(
              context,
              showTownLabels: ValueNotifier(true),
              onShowTownLabelsChanged: (_) {},
              showTerrain: ValueNotifier(true),
              onShowTerrainChanged: (_) {},
              onReloadActive: () async {},
            ),
          ),
        ),
      );
      await tester.pump();

      await layer.onMapTap(const LatLng(23.2, 123.1), map);
      await layer.onMapTap(const LatLng(0, 0), map);
      layer.onMapGestureStart();
      layer.onMapGestureEnd();
      layer.clearForecastSelection();
      layer.onStyleReset();
      await layer.clear(map);
      expect(layer.tapped.value, isNull);
    },
  );
}
