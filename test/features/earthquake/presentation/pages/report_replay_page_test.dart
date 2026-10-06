/// The report replay: a 強震監視器 frozen at a historical instant, polling the
/// RTS and EEW archives on its own clock rather than the live feeds.
///
/// The page starts those polls in `initState` and keeps a 16 ms wavefront
/// ticker while it is on screen, so every test tears the route down — a
/// leftover timer fails the suite. What the reader sees (the alert card, the
/// "replaying" word when the shaking archive is gone, the spoken intensity)
/// is decided here, not in the archive clients.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_paths.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/realtime_service.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:dpip/core/settings/eew_cwa_only_settings.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/eew_spoken_announcement_settings.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/speech/speech_service.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_town_levels.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/earthquake/presentation/pages/report_replay_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_circle_renderer.dart';
import 'package:dpip/shared/seismic/intensity_icon_renderer.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

/// 2026-03-10 14:00 Taipei — the replayed origin.
final _origin = DateTime.utc(2026, 3, 10, 6);

class _FixedClock implements Clock {
  @override
  DateTime now() => _origin;
}

class _ZeroElapsed implements Elapsed {
  @override
  Duration get elapsed => Duration.zero;
}

class _FixedSource implements ServerTimeSource {
  @override
  Future<Result<int>> serverTimeMs() async =>
      Ok(_origin.millisecondsSinceEpoch);
}

class _MapPlatform extends MapLibrePlatform {
  final calls = <String>[];
  final geojson = <String, Map<String, dynamic>>{};
  bool failNextBox = false;
  bool failNextBlink = false;
  var holdEew = true;
  int moves = 0;

  /// The map state completes a one-shot future the first time the platform
  /// view is created. A later rebuild of the same map must not call it again.
  bool _viewCreated = false;

  @override
  Future<void> initPlatform(int id) async {
    onMapStyleLoadedPlatform(null);
  }

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    if (!_viewCreated) {
      _viewCreated = true;
      onPlatformViewCreated(0);
    }
    return const SizedBox.shrink();
  }

  @override
  Future<void> setRenderPaused(bool paused) async {}

  @override
  Future<void> addSource(String sourceId, SourceProperties properties) async {
    calls.add('addSource:$sourceId');
  }

  @override
  Future<void> addImage(
    String name,
    Uint8List bytes, [
    bool sdf = false,
  ]) async {}

  @override
  Future<void> setGeoJsonSource(
    String sourceId,
    Map<String, dynamic> geojson,
  ) async {
    if (failNextBox && sourceId.contains('box')) {
      failNextBox = false;
      throw StateError('box');
    }
    this.geojson[sourceId] = geojson;
    if (holdEew && sourceId.contains('eew')) {
      holdEew = false;
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  @override
  Future<void> setLayerVisibility(String layerId, bool visible) async {
    calls.add('visibility:$layerId:$visible');
    if (failNextBlink && layerId.contains('box')) {
      failNextBlink = false;
      throw StateError('blink');
    }
  }

  @override
  Future<void> setLayerProperties(
    String layerId,
    Map<String, dynamic> properties,
  ) async {
    calls.add('props:$layerId');
  }

  @override
  Future<bool?> moveCamera(CameraUpdate cameraUpdate) async {
    moves++;
    return true;
  }

  void lookEast() {
    onCameraMovePlatform(
      const CameraPosition(target: LatLng(23.7, 121), zoom: 6, bearing: 40),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<dynamic>.value(null);
}

class _Archive extends ApiClient {
  _Archive(RegionSelection regions) : super(Dio(), regions);

  bool rtsMissing = false;
  bool rtsDown = false;
  List<Map<String, dynamic>> eews = [];
  Map<String, dynamic> stations = {};
  final polls = <String>[];

  @override
  Future<dynamic> get(
    ApiTier tier,
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    polls.add(path);
    if (path.contains(ApiPaths.rtsArchive)) {
      if (rtsMissing) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 404,
          ),
        );
      }
      if (rtsDown) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
        );
      }
      return {'ts': _origin.millisecondsSinceEpoch, 'stations': stations};
    }
    if (path.contains(ApiPaths.eew)) return eews;
    throw StateError(path);
  }
}

class _Stations implements TremStationRepository {
  _Stations(this.directory);

  final Map<String, SeismicStation> directory;
  bool savedNull = false;
  var delaySaved = false;

  @override
  Future<Map<String, SeismicStation>?> saved() async {
    if (delaySaved) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    if (savedNull) return null;
    return directory;
  }

  @override
  Future<Result<Map<String, SeismicStation>>> refresh() async =>
      savedNull ? const Err(NetworkFailure('down')) : Ok(directory);
}

class _Speech implements SpeechService {
  final phrases = <String>[];
  var throwNext = false;
  var stops = 0;

  @override
  Future<void> speak(String text, {required String languageTag}) async {
    if (throwNext) {
      throwNext = false;
      throw StateError('tts');
    }
    phrases.add('$languageTag:$text');
  }

  @override
  Future<void> stop() async => stops++;

  @override
  void dispose() {}
}

class _Model implements MlIntensityEstimator {
  final prepareGate = Completer<bool>();
  var modelReady = false;
  Map<String, int>? levels;

  @override
  bool get ready => modelReady;

  @override
  Future<bool> prepare() async {
    final ok = await prepareGate.future;
    modelReady = ok;
    return ok;
  }

  @override
  Future<Map<String, int>?> townLevels(EewInfo info) async => levels;
}

Map<String, dynamic> _eew({
  required String agency,
  required String id,
  required int serial,
  required String location,
  required int timeMs,
  int max = 5,
}) => {
  'author': agency,
  'id': id,
  'serial': serial,
  'status': 1,
  'final': 0,
  'eq': {
    'time': timeMs,
    'lon': 121.6,
    'lat': 23.98,
    'depth': 10,
    'mag': 6.2,
    'loc': location,
    'max': max,
  },
};

/// A square around [lat]/[lng], with [first] as the corner the coverage
/// check inspects before the rest.
List<List<double>> _ring({
  required List<double> first,
  required double west,
  required double south,
  required double east,
  required double north,
}) => [
  first,
  [west, south],
  [east, south],
  [east, north],
  first,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MapPlatform platform;

  setUpAll(() async {
    final clock = ServerClock(_FixedClock(), _ZeroElapsed(), _FixedSource());
    await clock.sync();
    AppTime.install(clock);
    // The replay map bakes station badges and the epicentre cross through
    // Picture.toImage, which does not finish inside a widget test's fake
    // async. Doing it here leaves both caches hot for every case below.
    await IntensityIconRenderer.renderAll();
    await IntensityCircleRenderer.renderAll();
  });

  setUp(() {
    platform = _MapPlatform();
    final previous = MapLibrePlatform.createInstance;
    addTearDown(() => MapLibrePlatform.createInstance = previous);
    MapLibrePlatform.createInstance = () => platform;
  });

  Future<void> icons(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
  }

  void useSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('plays the archive, speaks, and follows the sheet chrome', (
    tester,
  ) async {
    final settings = SettingsStore.inMemory();
    final regions = RegionSelection(settings);
    final archive = _Archive(regions);
    final originMs = _origin.millisecondsSinceEpoch;
    archive.eews = [
      _eew(
        agency: 'cwa',
        id: 'cwa-1',
        serial: 1,
        location: '花蓮縣',
        timeMs: originMs,
      ),
      _eew(
        agency: 'cwa',
        id: 'cwa-2',
        serial: 1,
        location: '未來縣',
        timeMs: originMs + const Duration(hours: 1).inMilliseconds,
      ),
      _eew(
        agency: 'nied',
        id: 'nied-1',
        serial: 1,
        location: '臺東縣',
        timeMs: originMs,
      ),
      _eew(
        agency: 'jma',
        id: 'jma-1',
        serial: 1,
        location: '東京',
        timeMs: originMs,
      ),
    ];
    archive.stations = {
      'aa': {'i': 4.5, 'pga': 1.2, 'alert': 1},
      'bb': {'i': 0.2, 'pga': 0.1, 'alert': 1},
      'cc': {'i': 0.1, 'alert': 0},
      'dd': {'i': 1.0, 'alert': 0},
    };
    final directory = {
      'aa': const SeismicStation(
        id: 'aa',
        latitude: 23.98,
        longitude: 121.6,
        townCode: '1001501',
      ),
      'bb': const SeismicStation(
        id: 'bb',
        latitude: 23.99,
        longitude: 122.0,
        townCode: '1001511',
      ),
      'cc': const SeismicStation(
        id: 'cc',
        latitude: 24.2,
        longitude: 121.2,
        townCode: '1001501',
      ),
    };
    final stations = _Stations(directory)..delaySaved = true;
    final towns = TownDirectory({
      '1001501': Town(
        code: '1001501',
        city: '花蓮',
        town: '花蓮',
        lat: 23.98,
        lng: 121.6,
        cityLevel: '縣',
        townLevel: '市',
      ),
      '1001511': Town(
        code: '1001511',
        city: '花蓮',
        town: '秀林',
        lat: 24.3,
        lng: 121.4,
        cityLevel: '縣',
        townLevel: '鄉',
      ),
    });
    final table = SeismicTravelTimeTable({
      10: const [
        (p: 2, r: 1, s: 2),
        (p: 2.5, r: 2, s: 4),
        (p: 100, r: 2000, s: 100),
      ],
    });
    final grid = RtsBoxGrid({
      1: _ring(
        first: const [121.4, 28.0],
        west: 121.4,
        south: 23.8,
        east: 121.8,
        north: 24.2,
      ),
      2: _ring(
        first: const [123.0, 23.98],
        west: 121.8,
        south: 23.8,
        east: 122.3,
        north: 24.2,
      ),
    });
    final speech = _Speech();
    final model = _Model();
    GpsFix? fix;
    final location = LocationService(
      towns,
      isAvailable: () async => false,
      fix: () async => fix,
      lastKnown: () async => fix,
      status: () async => LocationStatus.denied,
    );
    final cwaOnly = EewCwaOnlySettings(settings);
    final spoken = EewSpokenAnnouncementSettings(settings);
    final clock = ServerClock(_FixedClock(), _ZeroElapsed(), _FixedSource());
    final realtime = RealtimeService(clock);
    platform.failNextBox = true;

    useSurface(tester);
    final router = GoRouter(
      initialLocation: '/list/replay',
      routes: [
        GoRoute(
          path: '/list',
          builder: (_, _) => const Text('list'),
          routes: [
            GoRoute(
              path: 'replay',
              builder: (_, _) => ReportReplayPage(replayTimestamp: originMs),
            ),
          ],
        ),
      ],
    );
    try {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiClient>.value(value: archive),
            Provider<RealtimeService>.value(value: realtime),
            ChangeNotifierProvider<EewCwaOnlySettings>.value(value: cwaOnly),
            ChangeNotifierProvider<EewSpokenAnnouncementSettings>.value(
              value: spoken,
            ),
            Provider<TremStationRepository>.value(value: stations),
            Provider<Future<SeismicTravelTimeTable>>.value(
              value: Future.value(table),
            ),
            Provider<Future<RtsBoxGrid>>.value(value: Future.value(grid)),
            Provider<TownDirectory>.value(value: towns),
            Provider<SettingsStore>.value(value: settings),
            ChangeNotifierProvider<RegionStore>.value(
              value: RegionStore(settings),
            ),
            Provider<SpeechService>.value(value: speech),
            Provider<LocationService>.value(value: location),
            Provider<MlIntensityEstimator>.value(value: model),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await icons(tester);

      expect(find.text('Seismic Monitor'), findsOneWidget);
      expect(find.text('花蓮縣'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('臺東縣'), findsNothing);
      expect(find.text('東京'), findsNothing);
      expect(find.textContaining('14:00'), findsWidgets);

      await tester.tap(find.text('花蓮縣'));
      await tester.pump();
      expect(find.text('未來縣'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);

      await cwaOnly.setEnabled(false);
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();
      // The card still shows the alert it was on. NIED joins the cycle;
      // JMA never does.
      expect(find.text('東京'), findsNothing);
      expect(find.textContaining('/3'), findsOneWidget);
      await tester.tap(find.textContaining('/3'));
      await tester.pump();
      expect(find.text('臺東縣'), findsOneWidget);

      final l10n = AppLocalizations.of(
        tester.element(find.text('Seismic Monitor')),
      );
      await spoken.setEnabled(true);
      await tester.pump();
      await tester.pump();
      expect(
        speech.phrases.any(
          (phrase) => phrase.endsWith(l10n.eewSpokenMaxIntensity('five lower')),
        ),
        isTrue,
      );

      model.levels = const {};
      if (!model.prepareGate.isCompleted) model.prepareGate.complete(true);
      await tester.pump();

      // Off the epicentre: a fix on it makes the S-wave time NaN, and the
      // announcement swallows that instead of speaking a local intensity.
      fix = (lat: 25.03, lng: 121.52);
      model.levels = const {'1001501': 6};
      archive.eews = [
        _eew(
          agency: 'cwa',
          id: 'cwa-1',
          serial: 2,
          location: '花蓮縣',
          timeMs: originMs,
        ),
      ];
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();
      expect(
        speech.phrases.any((phrase) => phrase.contains('your location')),
        isTrue,
      );

      speech.throwNext = true;
      model.levels = const {'nope': 4};
      archive.eews = [
        _eew(
          agency: 'cwa',
          id: 'cwa-1',
          serial: 3,
          location: '花蓮縣',
          timeMs: originMs,
        ),
      ];
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();
      expect(speech.stops, greaterThan(0));

      model.levels = const {};
      archive.eews = [];
      platform.failNextBlink = true;
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('花蓮縣'), findsNothing);

      await tester.tap(find.byTooltip('Township names'));
      await tester.pump();
      await tester.tap(find.text('Detailed map'));
      await tester.pump();
      await tester.tap(find.text('Terrain relief'));
      await tester.pump();
      await tester.tap(find.text('Township names'));
      await tester.pump();
      await tester.tap(find.byTooltip('Township names'));
      await tester.pump();

      platform.lookEast();
      await tester.pump();
      expect(find.byTooltip('Reset north'), findsOneWidget);
      await tester.tap(find.byTooltip('Reset north'));
      await tester.pump();
      expect(find.byTooltip('Reset north'), findsNothing);
      expect(platform.moves, greaterThan(0));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump();
      expect(find.text('list'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      cwaOnly.dispose();
      spoken.dispose();
      realtime.dispose();
    }
  });

  testWidgets('a 404 shaking archive says the replay is running', (
    tester,
  ) async {
    final settings = SettingsStore.inMemory();
    final archive = _Archive(RegionSelection(settings))..rtsMissing = true;
    final stations = _Stations(const {})..savedNull = true;
    final cwaOnly = EewCwaOnlySettings(settings);
    final spoken = EewSpokenAnnouncementSettings(settings);
    final realtime = RealtimeService(
      ServerClock(_FixedClock(), _ZeroElapsed(), _FixedSource()),
    );
    useSurface(tester);
    final router = GoRouter(
      initialLocation: '/replay',
      routes: [
        GoRoute(
          path: '/replay',
          builder: (_, _) =>
              ReportReplayPage(replayTimestamp: _origin.millisecondsSinceEpoch),
        ),
      ],
    );
    try {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiClient>.value(value: archive),
            Provider<RealtimeService>.value(value: realtime),
            ChangeNotifierProvider<EewCwaOnlySettings>.value(value: cwaOnly),
            ChangeNotifierProvider<EewSpokenAnnouncementSettings>.value(
              value: spoken,
            ),
            Provider<TremStationRepository>.value(value: stations),
            Provider<Future<SeismicTravelTimeTable>>.value(
              value: Future.value(const SeismicTravelTimeTable({10: []})),
            ),
            Provider<Future<RtsBoxGrid>>.value(
              value: Future.value(const RtsBoxGrid({})),
            ),
            Provider<TownDirectory>.value(value: const TownDirectory({})),
            Provider<SettingsStore>.value(value: settings),
            ChangeNotifierProvider<RegionStore>.value(
              value: RegionStore(settings),
            ),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Replaying'), findsOneWidget);
      expect(find.text('Connection lost'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      cwaOnly.dispose();
      spoken.dispose();
      realtime.dispose();
    }
  });

  testWidgets('a hidden tab pauses the replay, and a dead feed goes stale', (
    tester,
  ) async {
    final settings = SettingsStore.inMemory();
    final archive = _Archive(RegionSelection(settings));
    final stations = _Stations(const {});
    final cwaOnly = EewCwaOnlySettings(settings);
    final spoken = EewSpokenAnnouncementSettings(settings);
    final realtime = RealtimeService(
      ServerClock(_FixedClock(), _ZeroElapsed(), _FixedSource()),
    );
    final tab = VisibleTab(0);
    useSurface(tester);
    final router = GoRouter(
      initialLocation: '/replay',
      routes: [
        GoRoute(
          path: '/replay',
          builder: (_, _) =>
              ReportReplayPage(replayTimestamp: _origin.millisecondsSinceEpoch),
        ),
      ],
    );
    try {
      await tester.pumpWidget(
        VisibleTabScope(
          visibleTab: tab,
          child: MultiProvider(
            providers: [
              Provider<ApiClient>.value(value: archive),
              Provider<RealtimeService>.value(value: realtime),
              ChangeNotifierProvider<EewCwaOnlySettings>.value(value: cwaOnly),
              ChangeNotifierProvider<EewSpokenAnnouncementSettings>.value(
                value: spoken,
              ),
              Provider<TremStationRepository>.value(value: stations),
              Provider<Future<SeismicTravelTimeTable>>.value(
                value: Future.value(const SeismicTravelTimeTable({10: []})),
              ),
              Provider<Future<RtsBoxGrid>>.value(
                value: Future.value(const RtsBoxGrid({})),
              ),
              Provider<TownDirectory>.value(value: const TownDirectory({})),
              Provider<SettingsStore>.value(value: settings),
              ChangeNotifierProvider<RegionStore>.value(
                value: RegionStore(settings),
              ),
            ],
            child: MaterialApp.router(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pump();
      final pollsWhileHidden = archive.polls.length;
      await tester.pump(const Duration(milliseconds: 1200));
      expect(archive.polls.length, pollsWhileHidden);

      tab.value = 3;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      expect(archive.polls.length, greaterThan(pollsWhileHidden));

      archive.rtsDown = true;
      // Staleness is a real stopwatch, while the poll that reads it is a
      // fake-async timer. Age the clock, then let one tick observe it.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(seconds: 4));
      });
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Data may be out of date'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
      tab.dispose();
      cwaOnly.dispose();
      spoken.dispose();
      realtime.dispose();
    }
  });
}
