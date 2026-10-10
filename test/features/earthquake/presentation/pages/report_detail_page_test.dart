/// The report detail page: a map of the epicentre and felt towns, with a
/// sheet that stays collapsed until the reader asks for the breakdown.
///
/// A withdrawn report (404) must leave for the catalogue — a retry button
/// there can never succeed — while a network failure keeps the retry. The
/// sheet's two layouts, the county/intensity sort, and the CWA image are all
/// on this one route, so a test that only pumps the loaded report misses the
/// states a reader actually hits.
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/features/earthquake/presentation/pages/report_detail_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_icon_renderer.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// 2026-03-10 14:00 Taipei.
final _origin = DateTime.utc(2026, 3, 10, 6);

/// A 1×1 PNG. [Image.memory] needs real bytes; anything else hits the
/// card's error builder.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

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

/// Completes the map lifecycle and records the style calls the detail page
/// makes. `noSuchMethod` returns a future so `await controller.addSymbolLayer`
/// (and the annotation managers created on style load) do not throw.
class _MapPlatform extends MapLibrePlatform {
  final List<String> calls = [];
  final Map<String, Map<String, dynamic>> sources = {};
  bool failNextDetailSource = false;
  bool failNextVisibility = false;
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
    final data = properties.toJson()['data'];
    if (data is Map) {
      sources[sourceId] = Map<String, dynamic>.from(data);
    }
    if (failNextDetailSource && sourceId == 'report-detail-src') {
      failNextDetailSource = false;
      throw StateError('style');
    }
  }

  @override
  Future<void> setLayerVisibility(String layerId, bool visible) async {
    calls.add('visibility:$layerId:$visible');
    if (failNextVisibility) {
      failNextVisibility = false;
      throw StateError('labels');
    }
  }

  @override
  Future<bool?> moveCamera(CameraUpdate cameraUpdate) async {
    moves++;
    return true;
  }

  @override
  Future<void> addImage(
    String name,
    Uint8List bytes, [
    bool sdf = false,
  ]) async {
    calls.add('image:$name');
  }

  void emitStyle() => onMapStyleLoadedPlatform(null);

  void lookEast() {
    onCameraMovePlatform(
      const CameraPosition(target: LatLng(23.7, 121), zoom: 6, bearing: 40),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add('${invocation.memberName}');
    return Future<dynamic>.value(null);
  }
}

class _Reports implements ReportRepository {
  Result<EarthquakeReport>? next;
  Completer<Result<EarthquakeReport>>? pending;
  int gets = 0;

  @override
  Future<Result<EarthquakeReport>> get(String id) async {
    gets++;
    final gate = pending;
    if (gate != null) {
      pending = null;
      return gate.future;
    }
    return next!;
  }

  @override
  Future<Result<List<PartialEarthquakeReport>>> list({
    int limit = 30,
    int page = 1,
    ReportListQuery query = ReportListQuery.empty,
  }) => throw UnimplementedError();
}

class _BytesClient extends ApiClient {
  _BytesClient(RegionSelection regions) : super(Dio(), regions);

  Completer<void>? gate;
  Object? error;
  Uint8List bytes = _png;
  final urls = <String>[];

  @override
  Future<BytePayload> getBytesAbsolute(
    String url, {
    CancelToken? cancelToken,
  }) async {
    urls.add(url);
    final waiting = gate;
    if (waiting != null) await waiting.future;
    final thrown = error;
    if (thrown != null) throw thrown;
    return BytePayload(bytes: bytes);
  }
}

class _Launcher extends UrlLauncherPlatform {
  final launched = <String>[];
  bool fail = false;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    if (fail) throw StateError('no browser');
    launched.add(url);
    return true;
  }
}

Town _town({
  required String code,
  required String city,
  required String town,
  required double lat,
  required double lng,
  String cityLevel = '縣',
  String townLevel = '市',
}) => Town(
  code: code,
  city: city,
  town: town,
  lat: lat,
  lng: lng,
  cityLevel: cityLevel,
  townLevel: townLevel,
);

EarthquakeReport _report({
  String id = '115053-2026-0310-140000',
  DateTime? origin,
  String location = '花蓮縣近海 (位於花蓮市)',
  Map<String, AreaIntensity>? list,
}) {
  final when = origin ?? _origin;
  return EarthquakeReport(
    id: id,
    longitude: 121.6,
    latitude: 23.98,
    location: location,
    depth: 10,
    magnitude: 6.2,
    time: when.millisecondsSinceEpoch,
    trem: 0,
    list: list ?? _areas(),
  );
}

Map<String, AreaIntensity> _areas() => {
  '宜蘭縣': AreaIntensity(
    intensity: 6,
    town: {
      '頭城鎮': StationIntensity(longitude: 121.82, latitude: 24.86, intensity: 4),
      '礁溪鄉': StationIntensity(longitude: 121.77, latitude: 24.82, intensity: 4),
    },
  ),
  '花蓮縣': AreaIntensity(
    intensity: 4,
    town: {
      '花蓮市': StationIntensity(longitude: 121.6, latitude: 23.98, intensity: 6),
    },
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MapPlatform platform;
  late _Launcher launcher;

  setUpAll(() async {
    final clock = ServerClock(_FixedClock(), _ZeroElapsed(), _FixedSource());
    await clock.sync();
    AppTime.install(clock);
    // Picture.toImage never completes inside a widget test's fake async, and
    // the detail map waits on it before adding the epicentre source. Baking
    // the icons here, outside that zone, leaves the cache hot.
    await IntensityIconRenderer.renderAll();
  });

  setUp(() {
    platform = _MapPlatform();
    final previousMap = MapLibrePlatform.createInstance;
    addTearDown(() => MapLibrePlatform.createInstance = previousMap);
    MapLibrePlatform.createInstance = () => platform;

    launcher = _Launcher();
    final previousLaunch = UrlLauncherPlatform.instance;
    addTearDown(() => UrlLauncherPlatform.instance = previousLaunch);
    UrlLauncherPlatform.instance = launcher;
  });

  Future<void> settleStyle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      if (platform.sources.containsKey('report-detail-src') &&
          platform.moves > 0) {
        return;
      }
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
    }
  }

  void useSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.reset);
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required _Reports reports,
    required _BytesClient client,
    required SettingsStore settings,
    required RegionStore regions,
    required TownDirectory towns,
    required GoRouter router,
    ThemeData? theme,
  }) async {
    useSurface(tester);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ReportRepository>.value(value: reports),
          Provider<ApiClient>.value(value: client),
          Provider<SettingsStore>.value(value: settings),
          ChangeNotifierProvider<RegionStore>.value(value: regions),
          Provider<TownDirectory>.value(value: towns),
        ],
        child: MaterialApp.router(
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }

  GoRouter nestedRouter(_Reports reports) => GoRouter(
    initialLocation: '/earthquake/115053-2026-0310-140000',
    routes: [
      GoRoute(
        path: '/earthquake',
        name: AppRoutes.earthquake,
        builder: (_, _) => const Text('catalogue'),
        routes: [
          GoRoute(
            path: ':id',
            name: AppRoutes.earthquakeReport,
            builder: (_, state) =>
                ReportDetailPage(reportId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'replay',
                name: AppRoutes.earthquakeReplay,
                builder: (_, state) =>
                    Text('replay ${state.uri.queryParameters['t']}'),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  testWidgets('a pending report stays on the loading view', (tester) async {
    final reports = _Reports()..pending = Completer<Result<EarthquakeReport>>();
    final settings = SettingsStore.inMemory();
    await pumpPage(
      tester,
      reports: reports,
      client: _BytesClient(RegionSelection(settings)),
      settings: settings,
      regions: RegionStore(settings),
      towns: const TownDirectory({}),
      router: nestedRouter(reports),
    );
    expect(find.byType(LoadingView), findsOneWidget);
    expect(reports.gets, 1);
  });

  testWidgets('a network failure retries into the loaded report', (
    tester,
  ) async {
    final reports = _Reports()..next = const Err(NetworkFailure('offline'));
    final settings = SettingsStore.inMemory();
    await pumpPage(
      tester,
      reports: reports,
      client: _BytesClient(RegionSelection(settings)),
      settings: settings,
      regions: RegionStore(settings),
      towns: const TownDirectory({}),
      router: nestedRouter(reports),
    );
    await tester.pump();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text("Couldn't load data. Please try again."), findsOneWidget);

    reports.next = Ok(_report());
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(find.text('花蓮市'), findsWidgets);
    expect(reports.gets, 2);
  });

  testWidgets('a missing report pops back to the list and says so', (
    tester,
  ) async {
    final reports = _Reports()..next = const Err(NotFoundFailure('gone'));
    final settings = SettingsStore.inMemory();
    await pumpPage(
      tester,
      reports: reports,
      client: _BytesClient(RegionSelection(settings)),
      settings: settings,
      regions: RegionStore(settings),
      towns: const TownDirectory({}),
      router: nestedRouter(reports),
    );
    await tester.pump();
    await tester.pump();
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .toList();
    expect(texts, contains('catalogue'), reason: texts.join(' | '));
    expect(
      find.text('That earthquake report is no longer available'),
      findsOneWidget,
    );
  });

  testWidgets('a missing report with nothing under it opens the catalogue', (
    tester,
  ) async {
    final reports = _Reports()..next = const Err(NotFoundFailure('gone'));
    final settings = SettingsStore.inMemory();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const ReportDetailPage(reportId: '115053-2026-0310-140000'),
        ),
        GoRoute(
          path: '/earthquake',
          name: AppRoutes.earthquake,
          builder: (_, _) => const Text('catalogue-root'),
        ),
      ],
    );
    await pumpPage(
      tester,
      reports: reports,
      client: _BytesClient(RegionSelection(settings)),
      settings: settings,
      regions: RegionStore(settings),
      towns: const TownDirectory({}),
      router: router,
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    final shown = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .join(' | ');
    expect(
      find.text('catalogue-root'),
      findsOneWidget,
      reason: '${router.state.uri} [$shown]',
    );
    expect(
      find.text('That earthquake report is no longer available'),
      findsOneWidget,
    );
  });

  testWidgets('the loaded sheet sorts, opens links, and frames the map', (
    tester,
  ) async {
    final report = _report();
    final reports = _Reports()..next = Ok(report);
    final settings = SettingsStore.inMemory();
    final regions = RegionStore(settings);
    regions.setCurrentCode('1001501');
    regions.addSaved('1001511');
    regions.addSaved('6300500');
    regions.addSaved('9999999');
    final towns = TownDirectory({
      '1001501': _town(
        code: '1001501',
        city: '花蓮',
        town: '花蓮',
        lat: 23.98,
        lng: 121.6,
      ),
      '1001511': _town(
        code: '1001511',
        city: '花蓮',
        town: '秀林',
        lat: 24.3,
        lng: 121.4,
        townLevel: '鄉',
      ),
      '6300500': _town(
        code: '6300500',
        city: '臺北',
        town: '中正',
        lat: 25.03,
        lng: 121.52,
        cityLevel: '市',
        townLevel: '區',
      ),
    });
    final client = _BytesClient(RegionSelection(settings))
      ..gate = Completer<void>();
    await pumpPage(
      tester,
      reports: reports,
      client: client,
      settings: settings,
      regions: regions,
      towns: towns,
      router: nestedRouter(reports),
    );
    await tester.pump();

    expect(find.text('No. 115053 Significant Earthquake'), findsWidgets);
    expect(find.text('花蓮市'), findsWidgets);
    expect(find.text('2026/03/10 14:00:00'), findsWidgets);
    expect(find.text('M6.2'), findsWidgets);
    expect(find.text('10.0 km'), findsWidgets);
    expect(find.text('23.98°N・121.60°E'), findsWidgets);
    expect(find.text('花蓮縣 花蓮市'), findsOneWidget);
    expect(find.text('花蓮縣 秀林鄉'), findsOneWidget);
    expect(find.text('臺北市 中正區'), findsOneWidget);
    expect(find.text('No intensity data'), findsNWidgets(2));
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byIcon(Icons.push_pin_outlined), findsNWidgets(2));
    expect(find.text('Intensity by area'), findsOneWidget);
    expect(find.byType(InlineLoading), findsOneWidget);

    // Intensity bands follow the town reading (花蓮 6 above 宜蘭 4). County
    // sort follows the area's own intensity, which is the other way around.
    expect(
      tester.getTopLeft(find.text('花蓮縣').first).dy,
      lessThan(tester.getTopLeft(find.text('宜蘭縣').first).dy),
    );

    client.gate!.complete();
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(client.urls.single, contains('scweb.cwa.gov.tw'));

    // Settle, never a bare pump: the menu opens on an animation, so one frame
    // leaves every row mid-flight and a tap lands wherever it was passing.
    await tester.tap(find.byTooltip('Township names'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terrain relief'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detailed map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terrain relief'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Township names'));
    await tester.pumpAndSettle();
    // The menu stays open over the compass; close it before tapping the needle.
    await tester.tap(find.byTooltip('Township names'));
    await tester.pumpAndSettle();

    platform.failNextDetailSource = true;
    platform.failNextVisibility = true;
    platform.emitStyle();
    await settleStyle(tester);
    expect(platform.sources.containsKey('report-detail-src'), isTrue);
    expect(platform.moves, greaterThan(0));
    expect(
      platform.calls.any((call) => call.contains('addSymbolLayer')),
      isTrue,
    );

    platform.lookEast();
    await tester.pump();
    expect(find.byTooltip('Reset north'), findsOneWidget);
    await tester.tap(find.byTooltip('Reset north'));
    await tester.pump();
    expect(find.byTooltip('Reset north'), findsNothing);

    // The sheet widget fills the screen; its centre is the map. Drag the peek.
    await _expandSheet(tester);
    expect(find.text('Earthquake Report'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Earthquake Report'), findsNothing);

    await _expandSheet(tester);
    await tester.scrollUntilVisible(find.byTooltip('Sort by county'), 400);
    await tester.tap(find.byTooltip('Sort by county'));
    await tester.pump();
    expect(find.byTooltip('Sort by intensity'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('宜蘭縣').first).dy,
      lessThan(tester.getTopLeft(find.text('花蓮縣').first).dy),
    );
    // Same intensity, so the name order is a row of chips, not a column.
    expect(
      tester.getTopLeft(find.text('礁溪鄉')).dx,
      lessThan(tester.getTopLeft(find.text('頭城鎮')).dx),
    );

    await tester.tap(find.text('Report page'));
    await tester.pump();
    expect(launcher.launched.single, contains('scweb.cwa.gov.tw'));

    launcher.fail = true;
    await tester.tap(find.text('Report page'));
    await tester.pump();

    final replayAt = report.originTimeUtc.millisecondsSinceEpoch - 2000;
    await tester.tap(find.text('Replay'));
    await tester.pump();
    await tester.pump();
    expect(find.text('replay $replayAt'), findsOneWidget);
  });

  testWidgets(
    'a pre-2020 local-felt report with no towns hides the area list',
    (tester) async {
      final reports = _Reports()
        ..next = Ok(
          _report(
            id: '115000-2019-0101-000000',
            origin: DateTime.utc(2019, 1, 1),
            location: '花蓮縣東方',
            list: const {},
          ),
        );
      final settings = SettingsStore.inMemory();
      final client = _BytesClient(RegionSelection(settings))
        ..error = StateError('no image');
      await pumpPage(
        tester,
        reports: reports,
        client: client,
        settings: settings,
        regions: RegionStore(settings),
        towns: const TownDirectory({}),
        router: GoRouter(
          initialLocation: '/earthquake/115000-2019-0101-000000',
          routes: [
            GoRoute(
              path: '/earthquake',
              name: AppRoutes.earthquake,
              builder: (_, _) => const Text('catalogue'),
              routes: [
                GoRoute(
                  path: ':id',
                  name: AppRoutes.earthquakeReport,
                  builder: (_, state) =>
                      ReportDetailPage(reportId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Local Felt Earthquake'), findsWidgets);
      expect(find.text('花蓮縣東方'), findsWidgets);
      expect(find.text('Intensity by area'), findsNothing);
      expect(find.text('Intensity at your locations'), findsNothing);
      expect(find.text('Report image not available'), findsOneWidget);
      expect(find.text('5⁻'), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump();
      expect(find.text('catalogue'), findsOneWidget);
    },
  );

  testWidgets('a dark map uses the light icon suffix, and bad bytes fail', (
    tester,
  ) async {
    final reports = _Reports()
      ..next = Ok(
        _report(
          origin: DateTime.utc(2019, 6, 1),
          list: {
            '花蓮縣': AreaIntensity(
              intensity: 6,
              town: {
                '花蓮市': StationIntensity(
                  longitude: 121.6,
                  latitude: 23.98,
                  intensity: 5,
                ),
              },
            ),
          },
        ),
      );
    final settings = SettingsStore.inMemory();
    final client = _BytesClient(RegionSelection(settings))
      ..bytes = Uint8List.fromList(const [1, 2, 3, 4]);
    await pumpPage(
      tester,
      reports: reports,
      client: client,
      settings: settings,
      regions: RegionStore(settings),
      towns: const TownDirectory({}),
      router: nestedRouter(reports),
      theme: ThemeData.dark(),
    );
    await tester.pump();
    expect(find.text('5'), findsWidgets);
    expect(find.text('5⁻'), findsNothing);
    await settleStyle(tester);
    final features =
        platform.sources['report-detail-src']?['features'] as List<dynamic>?;
    expect(features, isNotNull);
    final icons = [
      for (final feature in features!)
        (feature as Map)['properties']['icon'] as String,
    ];
    expect(icons, contains('cross'));
    expect(icons.any((icon) => icon.contains('-dark')), isFalse);
    expect(icons.any((icon) => icon.contains('-old')), isTrue);

    // The bytes sit below the fold, and the image does not decode until it
    // is scrolled into view. The codec itself is real async.
    await _expandSheet(tester);
    await tester.scrollUntilVisible(find.byType(Image), 400);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(find.text('Report image not available'), findsOneWidget);
  });
}

/// Drags the peek, not the sheet's full-screen centre (that is the map).
Future<void> _expandSheet(WidgetTester tester) async {
  final from =
      tester.getBottomLeft(find.byType(DraggableScrollableSheet)) +
      const Offset(120, -40);
  await tester.dragFrom(from, const Offset(0, -1400));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
