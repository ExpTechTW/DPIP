/// Verifies the home header's weather-readout gating: readings (and the
/// "view on map" link + station data time) show only while they belong to the
/// *selected* area. The controller holds a previous area's observation while
/// the new fetch runs — this is what must never appear as the new area's.
library;

import 'dart:async';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet_header.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const _directory = TownDirectory(<String, Town>{
  '100': Town(
    code: '100',
    city: '臺北市',
    town: '北區',
    lat: 25.0,
    lng: 121.5,
    cityLevel: '市',
    townLevel: '區',
  ),
  '200': Town(
    code: '200',
    city: '高雄市',
    town: '南區',
    lat: 24.0,
    lng: 120.5,
    cityLevel: '市',
    townLevel: '區',
  ),
});

/// A [MeteorWeatherRepository] whose `realtime` results are completed by hand,
/// so a test can hold a fetch in flight while the area switches underneath it.
class _GatedWeatherRepository implements MeteorWeatherRepository {
  final Map<String, Completer<Result<WeatherRealtime?>>> _gates = {};

  /// Resolves the realtime fetch for the township centred at ([lat], [lng]).
  void complete(double lat, double lng, WeatherRealtime value) {
    _gates.remove('$lat,$lng')?.complete(Ok(value));
  }

  @override
  Future<Result<WeatherRealtime?>> realtime(double lat, double lng) {
    final gate = Completer<Result<WeatherRealtime?>>();
    _gates['$lat,$lng'] = gate;
    return gate.future;
  }

  @override
  Future<Result<WeatherForecast>> forecast(String code) async =>
      Ok(WeatherForecast(updateTime: 0, forecast: const []));

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeHourTrendRepository implements RainHourTrendRepository {
  @override
  Future<Result<RainHourTrend>> hourTrend(String code) async =>
      Ok(RainHourTrend(startSecond: 0, mm: List.filled(60, 0)));
}

/// Built through `fromJson` so the 5-char realtime id exercises the same
/// directory-key padding the live API payload goes through.
WeatherRealtime _realtime(String station, double temp) =>
    WeatherRealtime.fromJson({
      'id': 'C0X16',
      'station': {
        'name': station,
        'lat': 25.0,
        'lon': 121.5,
        'altitude': 10,
        'distance': 1.0,
      },
      'time': 0,
      'data': {
        'weather': '晴',
        'weatherCode': 100,
        'temperature': temp,
        'humidity': 50,
        'rain': 0,
        'wind': {'speed': 0.0, 'beaufort': 0},
        'gust': {'speed': -99, 'beaufort': -99},
      },
    });

Future<RegionStore> _store() async {
  return RegionStore(
    SettingsStore.inMemory({
      'home.savedRegionCodes': ['100', '200'],
    }),
  );
}

/// Pumps the header with a router (the view-on-map link navigates by name) and
/// the home weather providers it reads. The controller is built over [repo],
/// whose realtime results the test completes by hand. [gpsFix] is optional —
/// a test that wants a slow/hung GPS read injects it here.
Widget _wrap(
  RegionStore store,
  _GatedWeatherRepository repo,
  MapStationHandoff handoff, {
  Future<({double lat, double lng})?> Function()? gpsFix,
  bool expanded = false,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => MultiProvider(
          providers: [
            ChangeNotifierProvider<RegionStore>.value(value: store),
            Provider<TownDirectory>.value(value: _directory),
            ChangeNotifierProvider<MapStationHandoff>.value(value: handoff),
            ChangeNotifierProvider<HomeWeatherController>(
              create: (_) => HomeWeatherController(
                repo,
                _FakeHourTrendRepository(),
                store,
                _directory,
                gpsFix: gpsFix,
              ),
            ),
          ],
          child: Scaffold(
            body: SingleChildScrollView(
              child: HomeSheetHeader(expanded: expanded),
            ),
          ),
        ),
      ),
      // The view-on-map link lands here; the stub exists so `goNamed` resolves.
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (_, _) => const Scaffold(body: SizedBox()),
      ),
    ],
  );
  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh', 'TW'),
    routerConfig: router,
  );
}

void main() {
  testWidgets('collapsed: station data time shows, view-on-map link does not', (
    tester,
  ) async {
    final store = await _store()
      ..select(2); // the '100' saved township
    final repo = _GatedWeatherRepository();
    final handoff = MapStationHandoff();
    await tester.pumpWidget(_wrap(store, repo, handoff));

    repo.complete(25.0, 121.5, _realtime('信義', 28.7));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('zh', 'TW'));
    expect(find.textContaining('信義'), findsOneWidget);
    expect(find.text(l10n.homeViewOnMap), findsNothing);
  });

  testWidgets(
    'switching area hides the previous area reading until the new one lands',
    (tester) async {
      final store = await _store()
        ..select(2); // '100'
      final repo = _GatedWeatherRepository();
      final handoff = MapStationHandoff();
      await tester.pumpWidget(_wrap(store, repo, handoff));

      repo.complete(25.0, 121.5, _realtime('信義', 28.7));
      await tester.pumpAndSettle();

      // Switch to '200' while its fetch is still in flight: the header must not
      // show the previous area's station — dashes until the new reading arrives.
      store.next();
      await tester.pump();

      expect(find.textContaining('信義'), findsNothing);

      repo.complete(24.0, 120.5, _realtime('鳳山', 31.2));
      await tester.pumpAndSettle();

      expect(find.textContaining('鳳山'), findsOneWidget);
    },
  );

  testWidgets(
    'expanded: view-on-map shows below the metrics and queues a hand-off',
    (tester) async {
      final store = await _store()
        ..select(2); // '100'
      final repo = _GatedWeatherRepository();
      final handoff = MapStationHandoff();
      await tester.pumpWidget(_wrap(store, repo, handoff, expanded: true));

      repo.complete(25.0, 121.5, _realtime('信義', 28.7));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('zh', 'TW'),
      );
      expect(find.text(l10n.homeViewOnMap), findsOneWidget);

      await tester.tap(find.text(l10n.homeViewOnMap));
      await tester.pump();

      final pending = handoff.takePending();
      expect(pending, isNotNull);
      expect(pending!.layerId, 'temperature');
      // The 5-char realtime id is padded to the directory's 6-char key on
      // decode — this is the id the map layer's station sheet can resolve.
      expect(pending.stationId, 'C0X160');
    },
  );

  testWidgets('a GPS fix that never resolves does not hold up the reading', (
    tester,
  ) async {
    final store = await _store()
      ..select(2); // '100'
    final repo = _GatedWeatherRepository();
    final handoff = MapStationHandoff();
    // A hung GPS read (the live fix can sit in its 10s timeout window) is a
    // debug-log-only dependency and must never block the sheet's data.
    final hungFix = Completer<({double lat, double lng})?>();
    await tester.pumpWidget(
      _wrap(store, repo, handoff, gpsFix: () => hungFix.future),
    );

    // Real data resolves instantly; the hung GPS fix is still outstanding.
    repo.complete(25.0, 121.5, _realtime('信義', 28.7));
    await tester.pumpAndSettle();

    expect(find.textContaining('信義'), findsOneWidget);
  });
}
