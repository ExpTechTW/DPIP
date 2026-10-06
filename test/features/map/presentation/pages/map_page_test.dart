/// The map tab has to open on the layer the user asked for, and fall back
/// when that one is hidden — opening on a layer they just turned off would
/// put them back in the menu they were trying to leave.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_channel.dart';
import 'package:dpip/core/realtime/realtime_config.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/ticker.dart';
import 'package:dpip/core/settings/default_map_layer.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/map_layer_visibility_controller.dart';
import 'package:dpip/core/settings/map_reference_outline_controller.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/disaster_map/domain/disaster_map_repository.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_town_levels.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/rts_live_demand.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/map/presentation/pages/map_page.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:dpip/features/weather/domain/meteor_lightning_repository.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/qpesums_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/features/weather/domain/wind_forecast_model.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

import '../../raster_timeline_harness.dart';

class _Platform extends MapLibrePlatform {
  @override
  Future<void> initPlatform(int id) async {}

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) => _PlatformView(onCreated: onPlatformViewCreated);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isAccessor) return null;
    return Future<Object?>.value();
  }
}

class _Frames extends FakeRasterFrameSource
    implements
        RadarRepository,
        QpesumsRepository,
        SatelliteRepository,
        WindForecastRepository {
  _Frames() : super(const []);

  @override
  String tileUrl(String frame) => 'https://example.invalid/{z}/{x}/{y}';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Silent {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isAccessor) return null;
    return Future<Object?>.value();
  }
}

class _TyphoonRepo extends _Silent implements MeteorTyphoonRepository {}

class _DisasterRepo extends _Silent implements DisasterMapRepository {
  @override
  String tileUrl(String layer) => 'https://example.invalid/$layer/{z}/{x}/{y}';

  @override
  void cancelTilePrefetch() {}
}

class _TremRepo extends _Silent implements TremStationRepository {}

class _RainRepo extends _Silent implements MeteorRainRepository {}

class _PlatformView extends StatefulWidget {
  const _PlatformView({required this.onCreated});

  final OnPlatformViewCreatedCallback onCreated;

  @override
  State<_PlatformView> createState() => _PlatformViewState();
}

class _PlatformViewState extends State<_PlatformView> {
  @override
  void initState() {
    super.initState();
    widget.onCreated(1);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _Dead<T> extends RealtimeSource<T> {
  @override
  Future<Result<T>> fetch() async => Err(const UnexpectedFailure('unused'));

  @override
  DateTime? timestampOf(T value) => null;
}

class _Ml implements MlIntensityEstimator {
  @override
  bool get ready => false;

  @override
  Future<bool> prepare() async => false;

  @override
  Future<Map<String, int>?> townLevels(EewInfo info) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final previous = MapLibrePlatform.createInstance;
    addTearDown(() => MapLibrePlatform.createInstance = previous);
    MapLibrePlatform.createInstance = _Platform.new;
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    DefaultMapLayer preferred = DefaultMapLayer.radar,
    Set<String> hidden = const {},
  }) async {
    final settings = SettingsStore.inMemory();
    final defaults = DefaultMapLayerController(settings)..setLayer(preferred);
    final visibility = MapLayerVisibilityController(settings);
    if (hidden.isNotEmpty) {
      await visibility.setManyHidden(hidden, hidden: true);
    }
    final frames = _Frames();
    final rts = RealtimeNotifier<Rts>(
      RealtimeChannel(
        source: _Dead<Rts>(),
        clock: SystemClock(),
        elapsed: SystemElapsed(),
        ticker: SystemTicker(),
        config: RealtimeConfig.rts,
      ),
    );
    final eew = RealtimeNotifier<List<Eew>>(
      RealtimeChannel(
        source: _Dead<List<Eew>>(),
        clock: SystemClock(),
        elapsed: SystemElapsed(),
        ticker: SystemTicker(),
        config: RealtimeConfig.eew,
      ),
    );
    addTearDown(rts.dispose);
    addTearDown(eew.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SettingsStore>.value(value: settings),
          ChangeNotifierProvider<DefaultMapLayerController>.value(
            value: defaults,
          ),
          ChangeNotifierProvider<MapLayerVisibilityController>.value(
            value: visibility,
          ),
          ChangeNotifierProvider<MapReferenceOutlineController>.value(
            value: MapReferenceOutlineController(settings),
          ),
          Provider<RadarRepository>.value(value: frames),
          Provider<QpesumsRepository>.value(value: frames),
          Provider<SatelliteRepository>.value(value: frames),
          Provider<Map<WindForecastModel, WindForecastRepository>>.value(
            value: {
              for (final model in WindForecastModel.values) model: frames,
            },
          ),
          Provider<Map<SatelliteChannel, SatelliteRepository>>.value(
            value: {
              for (final channel in SatelliteChannel.values) channel: frames,
            },
          ),
          Provider<MeteorLightningRepository>.value(
            value: EmptyLightningRepository(),
          ),
          Provider<MeteorWeatherRepository>.value(
            value: EmptyWeatherRepository(),
          ),
          Provider<MeteorRainRepository>.value(value: _RainRepo()),
          Provider<MeteorTyphoonRepository>.value(value: _TyphoonRepo()),
          Provider<DisasterMapRepository>.value(value: _DisasterRepo()),
          Provider<TremStationRepository>.value(value: _TremRepo()),
          ChangeNotifierProvider<RealtimeNotifier<Rts>>.value(value: rts),
          ChangeNotifierProvider<RealtimeNotifier<List<Eew>>>.value(value: eew),
          Provider<Future<SeismicTravelTimeTable>>.value(
            value: Future.value(
              const SeismicTravelTimeTable({
                10: [(p: 5, r: 20, s: 10), (p: 20, r: 80, s: 40)],
              }),
            ),
          ),
          Provider<Future<RtsBoxGrid>>.value(
            value: Future.value(const RtsBoxGrid(<int, List<List<double>>>{})),
          ),
          Provider<TownDirectory>.value(
            value: TownDirectory.fromJson(const {}),
          ),
          Provider<RtsLiveDemand>.value(value: RtsLiveDemand()),
          Provider<MlIntensityEstimator>.value(value: _Ml()),
          ChangeNotifierProvider<MeshNodeStore>.value(
            value: MeshNodeStore(FakeMeshPageService(), settings),
          ),
          Provider<MeshtasticService>.value(value: FakeMeshPageService()),
          ChangeNotifierProvider<MapCameraHandoff>.value(
            value: MapCameraHandoff(),
          ),
          ChangeNotifierProvider<MapStationHandoff>.value(
            value: MapStationHandoff(),
          ),
          Provider<MapTileCache?>.value(value: null),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MapPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the preferred layer is what the switcher names', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpPage(tester);
    expect(find.text(l10n.mapLayerRadar), findsWidgets);
  });

  testWidgets('a hidden preference opens the next visible layer', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpPage(tester, hidden: {'radar'});
    expect(find.text(l10n.mapLayerQpesums), findsWidgets);
    expect(find.text(l10n.mapLayerRadar), findsNothing);
  });

  testWidgets('hiding every layer still opens the first one', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpPage(
      tester,
      hidden: {
        'radar',
        'qpesums',
        for (final model in WindForecastModel.values) 'wind-${model.key}',
        for (final channel in SatelliteChannel.values)
          channel == SatelliteChannel.irClean
              ? 'satellite'
              : 'satellite-${channel.key}',
        'lightning',
        'typhoon',
        'monitor',
        'temperature',
        'humidity',
        'pressure',
        'wind',
        'rain',
        'dpm',
        'meshtastic',
      },
    );
    expect(find.text(l10n.mapLayerRadar), findsWidgets);
  });

  testWidgets('the disaster map is the layer that starts on streets', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await pumpPage(tester, preferred: DefaultMapLayer.dpm);
    expect(find.text(l10n.mapLayerDisasterMap), findsWidgets);
  });
}

/// Mesh store only needs a service instance at construction; the page does
/// not start the radio.
class FakeMeshPageService implements MeshtasticService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isAccessor) return null;
    return Future<Object?>.value();
  }
}
