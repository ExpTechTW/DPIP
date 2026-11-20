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
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/platform/image_saver.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/clock.dart';
import 'package:dpip/core/realtime/elapsed.dart';
import 'package:dpip/core/realtime/server_clock.dart';
import 'package:dpip/core/realtime/server_time_source.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/partial_earthquake_report.dart';
import 'package:dpip/features/earthquake/domain/report_list_query.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/features/earthquake/presentation/pages/report_detail_page.dart';
import 'package:dpip/features/earthquake/presentation/widgets/earthquake_share_card.dart';
import 'package:dpip/features/earthquake/presentation/widgets/earthquake_share_dialog.dart';
import 'package:dpip/features/earthquake/presentation/widgets/earthquake_share_story_card.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/l10n/gen/app_localizations_en.dart';
import 'package:dpip/shared/seismic/intensity_icon_renderer.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show RenderParagraph, RenderRepaintBoundary;
import 'package:flutter/services.dart';
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
  Future<CameraPosition?> updateMapOptions(
    Map<String, dynamic> optionsUpdate,
  ) async {
    if (!optionsUpdate.containsKey('styleString')) return null;
    // A new style does not retain runtime images or sources.
    calls.clear();
    sources.clear();
    emitStyle();
    return null;
  }

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

  void useSurface(WidgetTester tester, {Size size = const Size(900, 1600)}) {
    tester.view.physicalSize = size;
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
    Size size = const Size(900, 1600),
  }) async {
    useSurface(tester, size: size);
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

  GoRouter nestedRouter(_Reports reports, {ImageSaver? imageSaver}) => GoRouter(
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
            builder: (_, state) => ReportDetailPage(
              reportId: state.pathParameters['id']!,
              imageSaver: imageSaver,
            ),
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

  testWidgets('switching map themes restores intensity and epicentre icons', (
    tester,
  ) async {
    final reports = _Reports()..next = Ok(_report());
    final settings = SettingsStore.inMemory();
    final regions = RegionStore(settings);
    final client = _BytesClient(RegionSelection(settings));
    final router = nestedRouter(reports);

    Future<void> applyTheme(ThemeData theme) => pumpPage(
      tester,
      reports: reports,
      client: client,
      settings: settings,
      regions: regions,
      towns: const TownDirectory({}),
      router: router,
      theme: theme,
    );

    await applyTheme(ThemeData.light());
    await settleStyle(tester);
    final map = find.byType(MapLibreMap);
    final lightStyle = tester.widget<MapLibreMap>(map).styleString;
    expect(platform.calls, contains('image:intensity-4-dark'));

    await applyTheme(ThemeData.dark());
    await tester.pumpAndSettle();
    expect(tester.widget<MapLibreMap>(map).styleString, isNot(lightStyle));
    await settleStyle(tester);

    expect(platform.calls, containsAll(['image:intensity-4', 'image:cross']));
    final source = platform.sources['report-detail-src']!;
    final features = source['features'] as List<Map<String, dynamic>>;
    expect(features.map((feature) => (feature['properties'] as Map)['icon']), [
      'intensity-4',
      'intensity-4',
      'intensity-6',
      'cross',
    ]);
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
    await tester.tap(find.byTooltip('Map settings panel'));
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
    await tester.tap(find.byTooltip('Map settings panel'));
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

    await Scrollable.ensureVisible(
      tester.element(find.text('Report page')),
      alignment: 0.5,
    );
    await tester.pump();
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

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('fixed artwork fits localized report data in $locale', (
      tester,
    ) async {
      useSurface(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final report = _report(
        location:
            '花蓮縣政府東北方 115.6 公里，位於臺灣東部海域，鄰近宜蘭縣南澳鄉及花蓮縣秀林鄉 (位於花蓮縣近海至宜蘭縣外海一帶)',
      );
      final post = GlobalKey();
      final story = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  key: post,
                  child: SizedBox(
                    width: 360,
                    height: 450,
                    child: EarthquakeShareCard(report: report),
                  ),
                ),
                SizedBox(
                  width: 360,
                  height: 640,
                  child: EarthquakeShareStoryCard(
                    report: report,
                    compositionKey: story,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final cardContext = tester.element(find.byType(EarthquakeShareCard));
      await tester.runAsync(
        () => precacheImage(EarthquakeShareCard.brandImage, cardContext),
      );
      await tester.pump();
      final l10n = AppLocalizations.of(cardContext);
      for (final value in [
        l10n.reportDetailSharePreview,
        l10n.reportDetailImageSave,
        l10n.reportDetailImageSavePermissionDenied,
        l10n.reportDetailImageSaveSettingsRequired,
        l10n.reportDetailImageSaveUnavailable,
        l10n.reportDetailImageSaveRestricted,
        l10n.reportDetailImageSaveSettingsFailed,
        l10n.reportDetailStoryLegendCount,
        l10n.reportDetailStoryLegendIntensity,
      ]) {
        expect(value.trim(), isNotEmpty);
        expect(value, isNot(contains('{')));
      }
      expect(find.text(report.location), findsOneWidget);
      expect(find.text(report.shortLocation), findsExactly(2));
      expect(find.text(l10n.reportDetailShareRichterScale), findsOneWidget);
      expect(
        find.text(l10n.reportDetailShareObservedIntensity),
        findsOneWidget,
      );
      expect(find.text(l10n.reportDetailShareSource), findsOneWidget);
      final attribution = l10n.reportDetailStoryAttribution(
        l10n.reportDetailShareSource,
      );
      expect(attribution, contains('ExpTech Studio'));
      expect(attribution, contains(l10n.reportDetailShareSource));
      expect(find.text(attribution), findsOneWidget);

      Future<Uint8List> capture(GlobalKey key, int width, int height) async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        return (await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 3);
          try {
            expect((image.width, image.height), (width, height));
            final png = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
          } finally {
            image.dispose();
          }
        }))!;
      }

      final maxTextPngs = <(GlobalKey, int, int), Uint8List>{};
      for (final (key, width, height) in [
        (post, 1080, 1350),
        (story, 1080, 1920),
      ]) {
        final artwork = find.byKey(key);
        final canvas = tester.getRect(artwork);
        final text = find.descendant(
          of: artwork,
          matching: find.byType(RichText),
        );
        for (final paragraph in tester.renderObjectList<RenderParagraph>(
          text,
        )) {
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: paragraph.text.toPlainText(),
          );
          final topLeft = paragraph.localToGlobal(Offset.zero);
          final bottomRight = paragraph.localToGlobal(
            paragraph.size.bottomRight(Offset.zero),
          );
          expect(
            (canvas.inflate(0.01)).contains(topLeft) &&
                (canvas.inflate(0.01)).contains(bottomRight),
            isTrue,
            reason: paragraph.text.toPlainText(),
          );
        }
        maxTextPngs[(key, width, height)] = await capture(key, width, height);
      }

      tester.platformDispatcher.textScaleFactorTestValue = 1;
      await tester.pump();
      for (final entry in maxTextPngs.entries) {
        final (key, width, height) = entry.key;
        expect(await capture(key, width, height), orderedEquals(entry.value));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'both artworks preserve the historical and split intensity labels',
    (tester) async {
      useSurface(tester);
      for (final (year, value, label) in [
        (2018, 5, '5'),
        (2018, 6, '6'),
        (2018, 9, '7'),
        (2026, 5, '5⁻'),
        (2026, 6, '5⁺'),
        (2026, 7, '6⁻'),
        (2026, 8, '6⁺'),
      ]) {
        final report = _report(
          origin: DateTime.utc(year),
          list: {
            '花蓮縣': AreaIntensity(
              intensity: value,
              town: {
                '花蓮市': StationIntensity(
                  longitude: 121.6,
                  latitude: 23.98,
                  intensity: value,
                ),
              },
            ),
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh', 'TW'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Row(
              children: [
                SizedBox(
                  width: 360,
                  height: 450,
                  child: EarthquakeShareCard(report: report),
                ),
                SizedBox(
                  width: 360,
                  height: 640,
                  child: EarthquakeShareStoryCard(report: report),
                ),
              ],
            ),
          ),
        );
        expect(
          tester
              .widgetList<IntensityBadge>(find.byType(IntensityBadge))
              .map((badge) => badge.label),
          [label, label],
        );
      }
    },
  );

  group('Story sharing', () {
    const snapshotChannel = MethodChannel('com.exptech.dpip/map_snapshot');
    const imageChannel = MethodChannel('com.exptech.dpip/image_saver');
    final save = find.widgetWithText(FilledButton, 'Save image');
    final retry = find.widgetWithText(TextButton, 'Retry');
    final captureError = find.text("Couldn't load data. Please try again.");
    final card = find.byType(EarthquakeShareStoryCard);
    late _RecordingSaver saver;
    late List<_SnapshotCall> captures;

    Future<void> mountReport(
      WidgetTester tester, {
      ImageSaver? imageSaver,
      Size size = const Size(900, 1600),
    }) async {
      captures = [];
      saver = _RecordingSaver();
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(snapshotChannel, (call) {
        expect(call.method, 'captureWithProjection');
        final capture = _SnapshotCall(call);
        captures.add(capture);
        return capture.response.future;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(snapshotChannel, null);
        messenger.setMockMethodCallHandler(imageChannel, null);
      });

      final reports = _Reports()..next = Ok(_report());
      final settings = SettingsStore.inMemory();
      await pumpPage(
        tester,
        reports: reports,
        client: _BytesClient(RegionSelection(settings)),
        settings: settings,
        regions: RegionStore(settings),
        towns: const TownDirectory({}),
        router: nestedRouter(reports, imageSaver: imageSaver ?? saver),
        size: size,
      );
      await tester.pump();
      await tester.pump();
      final sheet = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet),
      );
      sheet.controller!.jumpTo(sheet.maxChildSize);
      await tester.pump();
    }

    Future<void> select(WidgetTester tester, String format) async {
      await tester.tap(find.text(format));
      await tester.pump();
      await tester.pump();
    }

    Future<void> open(WidgetTester tester) async {
      final preview = find.widgetWithText(OutlinedButton, 'Preview share card');
      await Scrollable.ensureVisible(tester.element(preview), alignment: 0.5);
      await tester.pump();
      await tester.tap(preview);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    void close(WidgetTester tester) =>
        Navigator.of(tester.element(find.byType(Dialog))).pop();

    bool enabled(WidgetTester tester) =>
        tester.widget<FilledButton>(save).onPressed != null;

    Future<void> pumpUntil(
      WidgetTester tester,
      bool Function() condition,
    ) async {
      for (var frame = 0; frame < 100; frame++) {
        await tester.pump();
        if (condition()) return;
        // The engine decodes, rasterizes and encodes outside the fake clock.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      expect(condition(), isTrue);
    }

    Future<void> waitForReady(WidgetTester tester) =>
        pumpUntil(tester, () => enabled(tester));

    Future<void> openWithBrandBundle(
      WidgetTester tester,
      _ShareBrandBundle bundle,
    ) async {
      unawaited(
        showDialog<void>(
          context: tester.element(find.byType(ReportDetailPage)),
          builder: (_) => DefaultAssetBundle(
            bundle: bundle,
            child: EarthquakeShareDialog(
              report: _report(),
              saver: saver,
              isReportCurrent: () => true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await pumpUntil(tester, () => bundle.loads.isNotEmpty);
    }

    void expectFailure(WidgetTester tester) {
      expect(captureError, findsOneWidget);
      expect(retry, findsOneWidget);
      expect(enabled(tester), isFalse);
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsNothing,
      );
      expect(saver.saved, isEmpty);
    }

    testWidgets('the report opens share preview without a diagnostic entry', (
      tester,
    ) async {
      await mountReport(tester);
      expect(find.textContaining('MapLibre Snapshot'), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await open(tester);
      expect(find.text('4:5'), findsOneWidget);
      expect(find.text('9:16'), findsOneWidget);
      expect(find.textContaining('Snapshot'), findsNothing);

      await select(tester, '9:16');
      expect(captures, hasLength(1));
      expect(
        tester.widget<EarthquakeShareStoryCard>(card).showSafeAreaGuides,
        isFalse,
      );
    });

    testWidgets('slow capture and composition gate Save, with 4:5 preserved', (
      tester,
    ) async {
      await mountReport(tester);
      await open(tester);
      expect(find.byType(EarthquakeShareCard), findsOneWidget);
      expect(save, findsOneWidget);
      expect(captures, isEmpty);

      await select(tester, '9:16');
      expect(captures, hasLength(1));
      expect(enabled(tester), isFalse);
      await tester.tap(save);
      await tester.pump(const Duration(seconds: 5));
      expect(saver.saved, isEmpty);

      captures.single.succeed();
      await tester.pump();
      expect(enabled(tester), isFalse);
      await waitForReady(tester);
      expect(saver.saved, isEmpty);

      await select(tester, '4:5');
      expect(find.byType(EarthquakeShareCard), findsOneWidget);
      expect(card, findsNothing);
      await waitForReady(tester);
    });

    testWidgets('default 4:5 saves the opaque artwork at fixed 3x', (
      tester,
    ) async {
      await mountReport(tester, size: const Size(320, 568));
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(640, 1136);
      await open(tester);
      await waitForReady(tester);
      await tester.tap(save);
      await tester.pump();
      final write = saver.saved.single;
      expect(write.fileName, 'dpip-card-115053-2026-0310-140000.png');
      expect(captures, isEmpty);

      final dispatcher = tester.platformDispatcher;
      dispatcher.textScaleFactorTestValue = 3;
      addTearDown(dispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      final close = find.byTooltip('Close');
      await tester.ensureVisible(close);
      await tester.pump();
      expect(close.hitTestable(), findsOneWidget);
      final postSelector = find.text('4:5');
      await tester.ensureVisible(postSelector);
      await tester.pump();
      expect(postSelector.hitTestable(), findsOneWidget);
      expect(save.hitTestable(), findsOneWidget);
      expect(MediaQuery.textScalerOf(tester.element(save)).scale(14), 42);
      final preview = find.byType(EarthquakeShareCard);
      final credit = find.descendant(
        of: preview,
        matching: find.text('Prepared by DPIP'),
      );
      expect(credit, findsOneWidget);
      expect(MediaQuery.textScalerOf(tester.element(credit)).scale(14), 14);
      await tester.tap(save);
      await tester.pump();
      expect(saver.saved.last.bytes, same(write.bytes));

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find
            .ancestor(of: preview, matching: find.byType(RepaintBoundary))
            .first,
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 3);
        try {
          expect((image.width, image.height), (1080, 1350));
          final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          expect(write.bytes, orderedEquals(png.buffer.asUint8List()));
          final rgba = (await image.toByteData())!.buffer.asUint8List();
          var opaque = true;
          for (var index = 3; index < rgba.length; index += 4) {
            opaque = opaque && rgba[index] == 255;
          }
          expect(opaque, isTrue);
        } finally {
          image.dispose();
        }
      });
    });

    testWidgets('stale Story cannot replace a cached and reselected 4:5', (
      tester,
    ) async {
      await mountReport(tester);
      await open(tester);
      await waitForReady(tester);
      final postSave = tester.widget<FilledButton>(save).onPressed!;
      await tester.tap(save);
      await tester.pump();
      final post = saver.saved.single.bytes;

      await select(tester, '9:16');
      postSave();
      expect(saver.saved, hasLength(1));
      captures.first.succeed(green: true);
      await waitForReady(tester);
      final storySave = tester.widget<FilledButton>(save).onPressed!;
      await tester.tap(save);
      await tester.pump();
      await _expectExport(tester, saver.saved.last.bytes, green: true);

      for (var i = 0; i < 3; i++) {
        await select(tester, '4:5');
        await select(tester, '9:16');
      }
      await select(tester, '4:5');
      storySave();
      for (final obsolete in captures.skip(1)) {
        obsolete.succeed();
      }
      await tester.pump();
      expect(saver.saved, hasLength(2));
      expect(enabled(tester), isTrue);
      await tester.tap(save);
      await tester.pump();
      expect(saver.saved, hasLength(3));
      expect(saver.saved.last.bytes, same(post));
    });

    testWidgets('late 4:5 asset cannot enable Save for a pending Story', (
      tester,
    ) async {
      await mountReport(tester);
      final bundle = _ShareBrandBundle(
        (await tester.runAsync(() => rootBundle.load('assets/DPIP.png')))!,
      );
      await openWithBrandBundle(tester, bundle);
      expect(enabled(tester), isFalse);
      await select(tester, '9:16');
      bundle.succeed();
      await tester.pump();
      expect(enabled(tester), isFalse);
      expect(saver.saved, isEmpty);
      captures.single.succeed(green: true);
      await waitForReady(tester);
      await tester.tap(save);
      await tester.pump();
      await _expectExport(tester, saver.saved.single.bytes, green: true);
    });

    testWidgets('4:5 decode failure and close require a fresh attempt', (
      tester,
    ) async {
      await mountReport(tester);
      final bytes = (await tester.runAsync(
        () => rootBundle.load('assets/DPIP.png'),
      ))!;
      final bundle = _ShareBrandBundle(bytes);
      await openWithBrandBundle(tester, bundle);
      bundle.loads.single.completeError(StateError('Missing QA brand image'));
      await pumpUntil(tester, () => captureError.evaluate().isNotEmpty);
      expectFailure(tester);

      await tester.tap(retry);
      await pumpUntil(tester, () => bundle.loads.length == 2);
      expect(enabled(tester), isFalse);
      bundle.succeed();
      await waitForReady(tester);
      close(tester);
      await tester.pumpAndSettle();

      final pending = _ShareBrandBundle(bytes);
      await openWithBrandBundle(tester, pending);
      close(tester);
      pending.succeed();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(saver.saved, isEmpty);

      await open(tester);
      await waitForReady(tester);
      expect(captures, isEmpty);
    });

    testWidgets('large text keeps share controls and the same Story PNG', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await mountReport(tester, size: const Size(320, 568));
        await open(tester);
        await select(tester, '9:16');
        final loading = find.bySemanticsLabel('Loading…');
        expect(loading, findsOneWidget);
        expect(
          tester
              .getSemantics(loading)
              .getSemanticsData()
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
        expect(
          tester
              .getSemantics(find.text('9:16'))
              .getSemanticsData()
              .flagsCollection
              .isSelected,
          ui.Tristate.isTrue,
        );
        expect(
          tester
              .getSemantics(find.text('4:5'))
              .getSemanticsData()
              .flagsCollection
              .isSelected,
          ui.Tristate.isFalse,
        );
        captures.single.succeed();
        await waitForReady(tester);
        expect(find.bySemanticsLabel('Epicenter'), findsOneWidget);
        final candidate = tester
            .widget<EarthquakeShareStoryCard>(card)
            .useD75Compact;
        expect(candidate, const bool.fromEnvironment('DPIP_STORY_D75_COMPACT'));
        expect(
          find.text('Badge: observation count'),
          candidate ? findsOneWidget : findsNothing,
        );
        expect(
          find.bySemanticsLabel(
            candidate
                ? '2 observations, group maximum intensity 4, '
                      'representative observation location 宜蘭縣頭城鎮'
                : '2 observations, group maximum intensity five upper, '
                      'representative observation location 花蓮縣花蓮市',
          ),
          findsOneWidget,
        );
        if (candidate) {
          expect(
            find.bySemanticsLabel(
              '花蓮縣花蓮市, intensity five upper, one observation',
            ),
            findsOneWidget,
          );
        }
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pump();
        final original = saver.saved.single.bytes;

        tester.platformDispatcher.textScaleFactorTestValue = 3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pump();
        await tester.pump();
        expect(captures, hasLength(1));
        expect(enabled(tester), isTrue);
        expect(save.hitTestable(), findsOneWidget);
        final pinnedSave = tester.getRect(save);
        await tester.tap(save);
        await tester.pump();
        expect(saver.saved.last.bytes, same(original));

        final details = find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Details'),
        );
        await tester.ensureVisible(details);
        await tester.tap(details);
        await tester.pump(const Duration(milliseconds: 300));
        final location = find.descendant(
          of: find.byType(Dialog),
          matching: find.text(_report().location),
        );
        await tester.ensureVisible(location);
        await tester.pump();
        final viewport = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(Scrollable),
        );
        expect(
          tester.getRect(viewport).contains(tester.getCenter(location)),
          isTrue,
        );
        final context = tester.element(location);
        expect(MediaQuery.textScalerOf(context).scale(14), 42);
        expect(tester.getRect(save), pinnedSave);
        final closeButton = find.byTooltip('Close');
        await tester.ensureVisible(closeButton);
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('an unplaceable legend invalidates the Story before Save', (
      tester,
    ) async {
      await mountReport(tester);
      unawaited(
        showDialog<void>(
          context: tester.element(find.byType(ReportDetailPage)),
          builder: (context) => Localizations.override(
            context: context,
            delegates: const [_OversizeStoryLegendDelegate()],
            child: EarthquakeShareDialog(
              report: _report(),
              saver: saver,
              isReportCurrent: () => true,
              useD75Compact: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await select(tester, '9:16');
      expect(captures, hasLength(1));
      expect(enabled(tester), isFalse);
      captures.single.succeed();
      final unavailable = find.text(
        'This report cannot fit in a Story. Choose 4:5 or open Details.',
      );
      for (var frame = 0; frame < 100; frame++) {
        await tester.pump();
        expect(enabled(tester), isFalse);
        if (unavailable.evaluate().isNotEmpty) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      expect(unavailable, findsOneWidget);
      expect(card, findsNothing);
      expect(retry, findsNothing);
      expect(captures, hasLength(1));
      expect(saver.saved, isEmpty);
      await select(tester, '4:5');
      expect(find.byType(EarthquakeShareCard), findsOneWidget);
      expect(captures, hasLength(1));
    });

    testWidgets('an unfittable Story offers Details, 4:5 and Close', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await mountReport(tester, size: const Size(320, 568));
      await open(tester);
      await select(tester, '9:16');
      final current = tester.widget<EarthquakeShareStoryCard>(card);
      current.onMapLayout!((mapRegion: Rect.zero, anchorRegion: Rect.zero));
      await tester.pump();
      expect(
        find.text(
          'This report cannot fit in a Story. Choose 4:5 or open Details.',
        ),
        findsOneWidget,
      );
      expect(enabled(tester), isFalse);
      expect(retry, findsNothing);
      expect(card, findsNothing);
      final close = find.byTooltip('Close');
      await tester.ensureVisible(close);
      await tester.pumpAndSettle();
      expect(close.hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.text('4:5'));
      await tester.pump();
      await select(tester, '4:5');
      expect(find.byType(EarthquakeShareCard), findsOneWidget);
      expect(saver.saved, isEmpty);
    });

    testWidgets('capture error stays out of UI, Retry creates a fresh export', (
      tester,
    ) async {
      await mountReport(tester);
      await open(tester);
      await select(tester, '9:16');
      captures.single.fail('native_error');
      await tester.pump();
      expectFailure(tester);
      expect(find.textContaining('native_error'), findsNothing);
      await tester.tap(save);
      expect(saver.saved, isEmpty);

      await tester.tap(retry);
      await tester.pump();
      await tester.pump();
      expect(captures, hasLength(2));
      expect(captureError, findsNothing);
      expect(enabled(tester), isFalse);

      captures.last.succeed();
      await waitForReady(tester);
      await tester.tap(save);
      await tester.pump();
      expect(
        saver.saved.single.fileName,
        'dpip-story-115053-2026-0310-140000.png',
      );
      expect(find.text('Saved to your photos'), findsOneWidget);
      await _expectExport(tester, saver.saved.single.bytes, green: false);
    });

    testWidgets('4:5 → 9:16 → 4:5 → 9:16 discards a failed capture', (
      tester,
    ) async {
      await mountReport(tester);
      await open(tester);
      await select(tester, '9:16');
      captures.single.fail();
      await tester.pump();
      expectFailure(tester);
      await select(tester, '4:5');
      await select(tester, '9:16');
      expect(captures, hasLength(2));
      expect(captureError, findsNothing);
      expect(enabled(tester), isFalse);
      captures.last.succeed(green: true);
      await waitForReady(tester);
    });

    for (final lateFailure in [false, true]) {
      testWidgets(
        'late ${lateFailure ? 'failure' : 'image'} cannot supersede a ready Story',
        (tester) async {
          await mountReport(tester);
          await open(tester);
          await select(tester, '9:16');
          await select(tester, '4:5');
          await select(tester, '9:16');
          expect(captures, hasLength(2));

          captures[1].succeed(green: true);
          await waitForReady(tester);
          final ready = tester.widget<EarthquakeShareStoryCard>(card);
          final obsolete = captures[0];
          if (lateFailure) {
            obsolete.fail();
          } else {
            obsolete.succeed();
          }
          await tester.pump();

          final visible = tester.widget<EarthquakeShareStoryCard>(card);
          expect(visible.mapPng, same(ready.mapPng));
          expect(visible.mapPng, orderedEquals(_greenStoryMap));
          expect(visible.epicenterPosition, const Offset(230, 150));
          expect(visible.stationMarkers.first.position, const Offset(230, 207));
          expect(captureError, findsNothing);
          expect(saver.saved, isEmpty);
          await tester.tap(save);
          await tester.pump();
          await _expectExport(tester, saver.saved.single.bytes, green: true);
        },
      );
    }

    testWidgets('close invalidates capture before its exit animation ends', (
      tester,
    ) async {
      await mountReport(tester);
      await open(tester);
      await select(tester, '9:16');
      close(tester);
      captures.first.succeed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Dialog), findsNothing);
      expect(saver.saved, isEmpty);
      expect(find.text('Saved to your photos'), findsNothing);

      await open(tester);
      await select(tester, '9:16');
      expect(captures, hasLength(2));
      expect(tester.widget<EarthquakeShareStoryCard>(card).mapPng, isNull);
      captures.last.succeed(green: true);
      await waitForReady(tester);
    });

    testWidgets('double Save is single-flight and saving keeps format locked', (
      tester,
    ) async {
      await mountReport(tester);
      await open(tester);
      await select(tester, '9:16');
      captures.single.succeed();
      await waitForReady(tester);

      final write = saver.pending = Completer<Result<void>>();
      await tester.tap(save);
      await tester.tap(save); // The old button callback is still on screen.
      await tester.pump();
      expect(saver.saved, hasLength(1));
      expect(enabled(tester), isFalse);
      await select(tester, '4:5');
      expect(card, findsOneWidget);
      expect(find.text('Saved to your photos'), findsNothing);

      write.complete(const Ok(null));
      await tester.pump();
      expect(enabled(tester), isTrue);
      expect(saver.saved, hasLength(1));
    });

    for (final story in [false, true]) {
      testWidgets(
        '${story ? '9:16' : '4:5'} gallery errors retry the same PNG',
        (tester) async {
          await mountReport(tester);
          await open(tester);
          if (story) {
            await select(tester, '9:16');
            captures.single.succeed();
          }
          await waitForReady(tester);

          for (final (reason, text) in [
            (ImageSaveFailureReason.failed, "Couldn't save the image"),
            (
              ImageSaveFailureReason.permissionDenied,
              'Allow photo access to save the image',
            ),
          ]) {
            saver.result = Err(ImageSaveFailure(reason, 'internal failure'));
            await tester.tap(save);
            await tester.pump();
            expect(find.text(text), findsOneWidget);
            expect(find.textContaining('internal failure'), findsNothing);
            expect(find.text('Saved to your photos'), findsNothing);
            expect(retry, findsNothing);
            expect(enabled(tester), isTrue);
          }

          final pending = saver.pending = Completer<Result<void>>();
          await tester.tap(save);
          await tester.tap(save);
          await tester.pump();
          expect(enabled(tester), isFalse);
          pending.complete(const Ok(null));
          await tester.pump();
          expect(captures, hasLength(story ? 1 : 0));
          expect(saver.saved, hasLength(3));
          expect(
            saver.saved.map((write) => write.bytes),
            everyElement(same(saver.saved.first.bytes)),
          );
          expect(find.text("Couldn't save the image"), findsNothing);
          expect(
            find.text('Allow photo access to save the image'),
            findsNothing,
          );
          expect(find.text('Saved to your photos'), findsOneWidget);
        },
      );
    }

    testWidgets(
      'settings recovery keeps Save reachable at large text and reuses PNG',
      (tester) async {
        const settingsChannel = MethodChannel(
          'flutter.baseflow.com/permissions/methods',
        );
        var settingsOpened = false;
        var settingsCalls = 0;
        final messenger = tester.binding.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(settingsChannel, (call) async {
          expect(call.method, 'openAppSettings');
          settingsCalls++;
          return settingsOpened;
        });
        addTearDown(
          () => messenger.setMockMethodCallHandler(settingsChannel, null),
        );

        await mountReport(tester, size: const Size(320, 568));
        await open(tester);
        await select(tester, '9:16');
        captures.single.succeed();
        await waitForReady(tester);
        tester.platformDispatcher.textScaleFactorTestValue = 3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pump();

        saver.result = const Err(
          ImageSaveFailure(
            ImageSaveFailureReason.permissionSettingsRequired,
            'private',
          ),
        );
        await tester.tap(save);
        await tester.pump();
        final settings = find.widgetWithText(TextButton, 'Open Settings');
        expect(
          find.text('Allow photo access in Settings, then try saving again.'),
          findsOneWidget,
        );
        expect(find.text('Saved to your photos'), findsNothing);
        expect(retry, findsNothing);
        expect(save.hitTestable(), findsOneWidget);
        await tester.ensureVisible(settings);
        await tester.tap(settings);
        await tester.pump();
        expect(settingsCalls, 1);
        expect(find.textContaining('Could not open Settings.'), findsOneWidget);

        settingsOpened = true;
        await tester.ensureVisible(settings);
        await tester.tap(settings);
        await tester.pump();
        expect(settingsCalls, 2);
        expect(find.textContaining('Could not open Settings.'), findsNothing);
        expect(
          saver.saved,
          hasLength(1),
          reason: 'Returning from Settings must not save automatically',
        );

        saver.result = const Ok(null);
        await tester.tap(save);
        await tester.pump();
        expect(captures, hasLength(1));
        expect(saver.saved, hasLength(2));
        expect(saver.saved.last.bytes, same(saver.saved.first.bytes));
        expect(settings, findsNothing);
        expect(find.text('Saved to your photos'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    for (final (reason, message) in [
      (
        ImageSaveFailureReason.unavailable,
        'Saving to photos is unavailable on this device.',
      ),
      (
        ImageSaveFailureReason.permissionRestricted,
        'Your device restricts access to photos.',
      ),
    ]) {
      testWidgets('${reason.name} has no futile gallery recovery action', (
        tester,
      ) async {
        await mountReport(tester);
        await open(tester);
        await select(tester, '9:16');
        captures.single.succeed();
        await waitForReady(tester);
        saver.result = Err(ImageSaveFailure(reason, 'internal'));
        await tester.tap(save);
        await tester.pump();

        expect(find.text(message), findsOneWidget);
        expect(enabled(tester), isFalse);
        expect(find.text('Open Settings'), findsNothing);
        expect(find.text('Saved to your photos'), findsNothing);
        expect(saver.saved, hasLength(1));
      });
    }

    testWidgets('timeout is recoverable and ignores the late PNG', (
      tester,
    ) async {
      await mountReport(tester);
      await open(tester);
      await select(tester, '9:16');
      await tester.pump(const Duration(seconds: 19));
      expect(enabled(tester), isFalse);
      expect(retry, findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expectFailure(tester);

      await tester.tap(retry);
      await tester.pump();
      await tester.pump();
      expect(captures, hasLength(2));
      captures.first.succeed();
      await tester.pump();
      expect(tester.widget<EarthquakeShareStoryCard>(card).mapPng, isNull);
      expect(enabled(tester), isFalse);

      captures.last.succeed(green: true);
      await waitForReady(tester);
    });

    for (final corrupt in [false, true]) {
      testWidgets(
        corrupt
            ? 'PNG header alone does not enable Save'
            : 'PNG/projection mismatch cannot export',
        (tester) async {
          await mountReport(tester);
          await open(tester);
          await select(tester, '9:16');
          final response = captures.single.makeResponse();
          if (corrupt) {
            response['png'] = Uint8List.sublistView(_blueStoryMap, 0, 24);
          } else {
            (response['points']! as Map).remove('epicenter');
          }
          captures.single.response.complete(response);
          for (
            var frame = 0;
            frame < 100 && retry.evaluate().isEmpty;
            frame++
          ) {
            await tester.pump();
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
          }
          expectFailure(tester);
          await tester.tap(save);
          expect(saver.saved, isEmpty);
        },
      );
    }

    testWidgets(
      'rapid raster input updates keep the active PNG and markers together',
      (tester) async {
        await mountReport(tester);
        await open(tester);
        await select(tester, '9:16');
        final dispatcher = tester.platformDispatcher;
        addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
        for (final bold in [true, false]) {
          dispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
            boldText: bold,
          );
          await tester.pump();
          await tester.pump();
        }
        expect(captures, hasLength(3));

        captures.last.succeed(green: true);
        await waitForReady(tester);
        captures.first.succeed();
        captures[1].succeed();
        await tester.pump();

        final visible = tester.widget<EarthquakeShareStoryCard>(card);
        expect(visible.mapPng, orderedEquals(_greenStoryMap));
        expect(visible.epicenterPosition, const Offset(230, 150));
        expect(visible.stationMarkers.first.position, const Offset(230, 207));
        final oldSave = tester.widget<FilledButton>(save).onPressed!;
        dispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(boldText: true);
        await tester.pump();
        await tester.pump();
        expect(captures, hasLength(4));
        oldSave();
        expect(enabled(tester), isFalse);
        expect(tester.widget<EarthquakeShareStoryCard>(card).mapPng, isNull);
        expect(saver.saved, isEmpty);

        captures.last.succeed();
        await waitForReady(tester);
        await tester.tap(save);
        await tester.pump();
        await _expectExport(tester, saver.saved.single.bytes, green: false);
      },
    );

    for (final closeAfterWrite in [false, true]) {
      testWidgets(
        closeAfterWrite
            ? 'close after native write starts ignores its result'
            : 'close during native permission cannot dispatch a write',
        (tester) async {
          final gate = Completer<String?>();
          var requests = 0;
          var writes = 0;
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            imageChannel,
            (call) {
              switch (call.method) {
                case 'status':
                  return Future.value(
                    closeAfterWrite ? 'granted' : 'notDetermined',
                  );
                case 'request':
                  requests++;
                  return gate.future;
                case 'save':
                  writes++;
                  return gate.future;
                default:
                  fail('Unexpected call ${call.method}');
              }
            },
          );
          await mountReport(
            tester,
            imageSaver: IosImageSaver(
              channel: imageChannel,
              isSupportedPlatform: true,
            ),
          );
          await open(tester);
          await select(tester, '9:16');
          captures.single.succeed();
          await waitForReady(tester);
          await tester.tap(save);
          await tester.pump();
          expect(writes, closeAfterWrite ? 1 : 0);
          expect(requests, closeAfterWrite ? 0 : 1);

          close(tester);
          gate.complete(closeAfterWrite ? null : 'granted');
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(writes, closeAfterWrite ? 1 : 0);
          expect(find.text('Saved to your photos'), findsNothing);
          expect(find.byType(Dialog), findsNothing);
        },
      );
    }
  });

  testWidgets('the report image saves to the photo library', (tester) async {
    final reports = _Reports()..next = Ok(_report());
    final settings = SettingsStore.inMemory();
    final saver = _RecordingSaver();
    await pumpPage(
      tester,
      reports: reports,
      client: _BytesClient(RegionSelection(settings)),
      settings: settings,
      regions: RegionStore(settings),
      towns: const TownDirectory({}),
      router: nestedRouter(reports, imageSaver: saver),
    );
    await tester.pump();
    await tester.pump();

    await _expandSheet(tester);
    await tester.scrollUntilVisible(find.byType(Image), 400);
    // Image.memory decodes off the fake clock; let the real codec finish.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.ensureVisible(find.byTooltip('Save image'));

    await tester.tap(find.byTooltip('Save image'));
    await tester.pump();

    expect(saver.saved, hasLength(1));
    expect(
      saver.saved.single.fileName,
      'dpip-earthquake-115053-2026-0310-140000.png',
    );
    expect(find.text('Saved to your photos'), findsOneWidget);

    // A refusal must say so in its own words, and offer the only way out:
    // Settings, not another tap.
    saver.result = const Err(
      ImageSaveFailure(
        ImageSaveFailureReason.permissionSettingsRequired,
        'refused',
      ),
    );
    await tester.tap(find.byTooltip('Save image'));
    await tester.pump();

    expect(
      find.text('Allow photo access in Settings, then try saving again.'),
      findsOneWidget,
    );
    expect(find.text('Open Settings'), findsOneWidget);
  });
}

class _OversizeStoryLegendDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _OversizeStoryLegendDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(_OversizeStoryLegend());

  @override
  bool shouldReload(_OversizeStoryLegendDelegate old) => false;
}

class _OversizeStoryLegend extends AppLocalizationsEn {
  @override
  String get reportDetailStoryLegendCount =>
      super.reportDetailStoryLegendCount * 25;
}

const _fixtures = 'test/features/earthquake/presentation/fixtures';
final _blueStoryMap = File('$_fixtures/story_map_blue.png').readAsBytesSync();
final _greenStoryMap = File('$_fixtures/story_map_green.png').readAsBytesSync();

class _SnapshotCall {
  _SnapshotCall(this.call);

  final MethodCall call;
  final response = Completer<Object?>();

  Map<String, Object> makeResponse({bool green = false}) {
    final queries = (call.arguments as Map)['points'] as List;
    final x = green ? 230.0 : 120.0;
    final stations = queries.skip(1).indexed;
    return {
      'png': green ? _greenStoryMap : _blueStoryMap,
      'pngWidth': 720,
      'pngHeight': 1280,
      'logicalWidth': 360.0,
      'logicalHeight': 640.0,
      'points': {
        'epicenter': [x, 150.0],
        for (final (i, point) in stations)
          (point as Map)['id']: [x, 207.0 + 36 * i],
      },
    };
  }

  void succeed({bool green = false}) =>
      response.complete(makeResponse(green: green));

  void fail([String code = 'snapshot_failed']) =>
      response.completeError(PlatformException(code: code));
}

Future<void> _expectExport(
  WidgetTester tester,
  Uint8List png, {
  required bool green,
}) async {
  await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(png);
    try {
      final image = (await codec.getNextFrame()).image;
      try {
        expect(image.width, 1080);
        expect(image.height, 1920);
        final data = (await image.toByteData())!;
        int pixel(int x, int y) => data.getUint32((y * image.width + x) * 4);
        final background = green ? 0x10ac58ff : 0x1880e0ff;
        expect(pixel(12, 12), background);
        expect(pixel(12, 56 * 3), background); // Guide excluded.
        expect(pixel((green ? 230 : 120) * 3, 150 * 3), isNot(background));
        expect(pixel((green ? 120 : 230) * 3, 150 * 3), background);
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  });
}

/// Holds the artwork asset at a controlled point in composition.
class _ShareBrandBundle extends CachingAssetBundle {
  _ShareBrandBundle(this.bytes);

  final ByteData bytes;
  final loads = <Completer<ByteData>>[];

  @override
  Future<ByteData> load(String key) {
    if (key != 'assets/DPIP.png') return rootBundle.load(key);
    final load = Completer<ByteData>();
    loads.add(load);
    return load.future;
  }

  void succeed() => loads.last.complete(bytes);
}

/// Records what the save button hands over, and answers with [result].
///
/// The permission gate itself is covered by `image_saver_test.dart`; here it
/// simply agrees, so the widget path is what is under test.
class _RecordingSaver implements ImageSaver {
  final saved = <({Uint8List bytes, String fileName})>[];
  Result<void> result = const Ok(null);
  Completer<Result<void>>? pending;

  @override
  Future<Result<void>> ensurePermission() async => const Ok(null);

  @override
  Future<Result<void>> saveToGallery({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'image/png',
  }) async {
    saved.add((bytes: bytes, fileName: fileName));
    return pending?.future ?? result;
  }
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
