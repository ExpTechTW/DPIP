/// The shared map surface has to keep a stale fetch from painting on the
/// wrong layer, and a timeline that failed to load has to stay visibly failed
/// until someone retries — a blank map would look like "nothing happening".
library;

import 'dart:async';
import 'dart:math' show Point;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/map_layer_order_controller.dart';
import 'package:dpip/core/settings/map_layer_visibility_controller.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_scaffold.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:dpip/shared/map/map_tile_cache.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

/// Completes the platform view and answers every other native call with an
/// already-finished future, so annotation setup during style load can finish.
class _Platform extends MapLibrePlatform {
  int moves = 0;
  int regionQueries = 0;
  final paused = <bool>[];
  Object? resumeError;

  @override
  Future<void> initPlatform(int id) async {}

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) => _PlatformView(onCreated: onPlatformViewCreated);

  @override
  Future<void> setRenderPaused(bool paused) async {
    this.paused.add(paused);
    final error = resumeError;
    if (!paused && error != null) throw error;
  }

  @override
  Future<LatLngBounds> getVisibleRegion() async {
    regionQueries++;
    return LatLngBounds(
      southwest: const LatLng(22, 120),
      northeast: const LatLng(25, 122),
    );
  }

  @override
  Future<bool?> moveCamera(CameraUpdate cameraUpdate) async {
    moves++;
    return true;
  }

  @override
  Future<CameraPosition?> updateMapOptions(
    Map<String, dynamic> optionsUpdate,
  ) async => null;

  @override
  Future<CameraPosition?> queryCameraPosition() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isAccessor) return null;
    return Future<Object?>.value();
  }
}

/// The platform view reports itself once. [MapLibreMap] calls `buildView` on
/// every rebuild; completing the controller again throws and drops the style
/// callback the scaffold is waiting on.
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

/// A layer the scaffold can drive without a real tile source.
class _Layer with MapLayerDefaults implements MapLayer {
  _Layer({
    required this.id,
    required this.name,
    this.timeline = true,
    this.withChrome = false,
  });

  @override
  final String id;
  final String name;
  final bool timeline;
  final bool withChrome;

  Result<List<MapFrame>> framesResult = const Ok([]);
  Completer<Result<List<MapFrame>>>? framesGate;
  int frameCalls = 0;
  int prepares = 0;
  int renders = 0;
  int clears = 0;
  int taps = 0;
  int memory = 0;
  int cameraIdles = 0;
  int mapIdles = 0;
  int gestureStarts = 0;
  int gestureEnds = 0;
  int scrubs = 0;
  int styleResets = 0;
  final shown = <String>[];
  final visibility = <bool>[];
  String? selected;
  bool throwOnShow = false;
  bool throwOnClear = false;

  @override
  String label(BuildContext context) => name;

  @override
  IconData get icon => Icons.layers_outlined;

  @override
  bool get usesTimeline => timeline;

  @override
  double get bottomChromeFraction => timeline ? 0 : 0.14;

  @override
  bool get overlayFollowsCamera => true;

  @override
  Future<Result<List<MapFrame>>> frames() {
    frameCalls++;
    final gate = framesGate;
    if (gate != null) return gate.future;
    return Future.value(framesResult);
  }

  @override
  Future<void> prepare(
    MapLibreMapController controller,
    List<MapFrame> frames,
  ) async {
    prepares++;
  }

  @override
  Future<void> show(
    MapLibreMapController controller,
    MapFrame frame, {
    bool scrubbing = false,
  }) async {
    if (throwOnShow) throw StateError('show failed');
    shown.add(frame.id);
  }

  @override
  Future<void> render(MapLibreMapController controller) async {
    renders++;
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    if (throwOnClear) throw StateError('clear failed');
    clears++;
  }

  @override
  Future<void> onMapTap(LatLng latLng, MapLibreMapController controller) async {
    taps++;
  }

  @override
  void selectFeature(String featureId) => selected = featureId;

  @override
  Future<void> onMemoryPressure(MapLibreMapController controller) async {
    memory++;
  }

  @override
  Future<void> onCameraIdle(MapLibreMapController controller) async {
    cameraIdles++;
  }

  @override
  void onMapIdle() => mapIdles++;

  @override
  void onMapGestureStart() => gestureStarts++;

  @override
  void onMapGestureEnd() => gestureEnds++;

  @override
  void onTimelineScrubStart() => scrubs++;

  @override
  void onSurfaceVisibility(bool visible) => visibility.add(visible);

  @override
  void onStyleReset() => styleResets++;

  @override
  Widget buildLegend(BuildContext context) => const Text('Legend mark');

  @override
  Widget? buildLegendAccessory(BuildContext context) => const Text('Rank');

  @override
  Widget buildSheet(BuildContext context) => const Text('Sheet body');

  @override
  Widget buildMapOverlay(BuildContext context) => const Text('Callout');

  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
    required ValueListenable<bool> showTerrain,
    required ValueChanged<bool> onShowTerrainChanged,
    required Future<void> Function() onReloadActive,
  }) {
    if (!withChrome) return const SizedBox.shrink();
    return TextButton(
      onPressed: () async {
        onShowTerrainChanged(true);
        onShowTerrainChanged(true);
        onShowTownLabelsChanged(false);
        onShowTownLabelsChanged(false);
        await onReloadActive();
      },
      child: const Text('Layer options'),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Platform platform;

  setUp(() {
    platform = _Platform();
    final previous = MapLibrePlatform.createInstance;
    addTearDown(() => MapLibrePlatform.createInstance = previous);
    MapLibrePlatform.createInstance = () => platform;
  });

  final past = DateTime.utc(2026, 10, 5, 12);
  List<MapFrame> twoFrames() => [
    MapFrame(id: 'older', time: past),
    MapFrame(id: 'newer', time: past.add(const Duration(hours: 1))),
  ];

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  Future<void> show(
    WidgetTester tester, {
    required SettingsStore settings,
    required MapCameraHandoff camera,
    required MapStationHandoff stations,
    required MapLayerVisibilityController visibility,
    required List<MapLayer> layers,
    String? initialLayerId,
    bool initialOsmEnabled = false,
    VisibleTab? visibleTab,
    int? tabIndex,
  }) async {
    final child = MapScaffold(
      layers: layers,
      initialLayerId: initialLayerId,
      initialOsmEnabled: initialOsmEnabled,
      tabIndex: tabIndex,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SettingsStore>.value(value: settings),
          ChangeNotifierProvider<MapCameraHandoff>.value(value: camera),
          ChangeNotifierProvider<MapStationHandoff>.value(value: stations),
          ChangeNotifierProvider<MapLayerVisibilityController>.value(
            value: visibility,
          ),
          ChangeNotifierProvider<MapLayerOrderController>.value(
            value: MapLayerOrderController(settings),
          ),
          Provider<TownDirectory>.value(
            value: TownDirectory.fromJson(const {}),
          ),
          Provider<MapTileCache?>.value(value: null),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: visibleTab == null
              ? child
              : VisibleTabScope(visibleTab: visibleTab, child: child),
        ),
      ),
    );
  }

  /// Style load is not part of the first frame: the controller has to exist
  /// before the platform reports that the style is ready.
  Future<void> loadStyle(WidgetTester tester) async {
    await tester.pump();
    platform.onMapStyleLoadedPlatform(null);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a timeline shows the present frame, and a scrub re-shows it', (
    tester,
  ) async {
    final l10n = await english();
    final echo = _Layer(id: 'echo', name: 'Echo')
      ..framesResult = Ok(twoFrames());
    await show(
      tester,
      settings: SettingsStore.inMemory(),
      camera: MapCameraHandoff(),
      stations: MapStationHandoff(),
      visibility: MapLayerVisibilityController(SettingsStore.inMemory()),
      layers: [echo],
    );
    await loadStyle(tester);

    expect(find.text('Echo'), findsWidgets);
    expect(find.text(l10n.mapTimelineObserved), findsOneWidget);
    await tester.tap(find.text(l10n.mapLegendExpand));
    await tester.pump();
    expect(find.text('Legend mark'), findsOneWidget);
    expect(find.text('Rank'), findsOneWidget);
    expect(echo.prepares, 1);
    expect(echo.shown, isNotEmpty);
    expect(echo.styleResets, greaterThan(0));

    await tester.drag(find.byType(ListView), const Offset(-120, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(echo.scrubs, greaterThan(0));
    expect(echo.shown.length, greaterThan(1));
  });

  testWidgets('a failed frame list shows the message and retry reloads', (
    tester,
  ) async {
    final l10n = await english();
    final echo = _Layer(id: 'echo', name: 'Echo')
      ..framesResult = Err(const NetworkFailure('radar offline'));
    await show(
      tester,
      settings: SettingsStore.inMemory(),
      camera: MapCameraHandoff(),
      stations: MapStationHandoff(),
      visibility: MapLayerVisibilityController(SettingsStore.inMemory()),
      layers: [echo],
    );
    await loadStyle(tester);

    expect(find.text('radar offline'), findsOneWidget);
    expect(find.text(l10n.commonRetry), findsOneWidget);

    echo.framesResult = Ok(twoFrames());
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pump();
    await tester.pump();

    expect(find.text('radar offline'), findsNothing);
    expect(find.text(l10n.mapTimelineObserved), findsOneWidget);
    expect(echo.frameCalls, greaterThan(1));
  });

  testWidgets('an empty frame list leaves the timeline blank, not failed', (
    tester,
  ) async {
    final l10n = await english();
    final echo = _Layer(id: 'echo', name: 'Echo');
    await show(
      tester,
      settings: SettingsStore.inMemory(),
      camera: MapCameraHandoff(),
      stations: MapStationHandoff(),
      visibility: MapLayerVisibilityController(SettingsStore.inMemory()),
      layers: [echo],
    );
    await loadStyle(tester);

    expect(find.text(l10n.commonRetry), findsNothing);
    expect(find.text(l10n.mapTimelineObserved), findsNothing);
    expect(echo.prepares, 0);
  });

  testWidgets('sheet taps, handoffs, hiding, and a dpm switch all land', (
    tester,
  ) async {
    final settings = SettingsStore.inMemory();
    final camera = MapCameraHandoff();
    final stations = MapStationHandoff();
    final echo = _Layer(id: 'echo', name: 'Echo')
      ..framesResult = Ok(twoFrames());
    final sheet = _Layer(id: 'stations', name: 'Stations', timeline: false);
    final dpm = _Layer(id: 'dpm', name: 'Prevention', timeline: false);
    // Queued before the surface listens, so the first style load consumes it.
    stations.request(
      layerId: 'stations',
      stationId: 'C0S730',
      latitude: 23.5,
      longitude: 121,
    );
    camera.request(
      LatLngBounds(
        southwest: const LatLng(23, 120),
        northeast: const LatLng(25, 122),
      ),
      layerId: 'stations',
    );

    await show(
      tester,
      settings: settings,
      camera: camera,
      stations: stations,
      visibility: MapLayerVisibilityController(settings),
      layers: [echo, sheet, dpm],
    );
    await loadStyle(tester);

    expect(sheet.renders, greaterThan(0));
    expect(sheet.selected, 'C0S730');
    expect(find.text('Sheet body'), findsOneWidget);

    platform.onMapClickPlatform({
      'point': const Point<double>(10, 10),
      'latLng': const LatLng(23.5, 121),
    });
    await tester.pump();
    expect(sheet.taps, 1);

    camera.request(
      LatLngBounds(
        southwest: const LatLng(22, 120),
        northeast: const LatLng(24, 122),
      ),
      layerId: 'missing',
    );
    await tester.pump();
    await tester.pump();
    expect(sheet.renders, greaterThan(0));

    camera.request(
      LatLngBounds(
        southwest: const LatLng(22, 120),
        northeast: const LatLng(24, 122),
      ),
      layerId: 'dpm',
    );
    await tester.pump();
    await tester.pump();
    expect(dpm.renders, greaterThan(0));
    expect(settings.getBool(SettingKeys.mapGsiEnabled), isTrue);

    final visibility = Provider.of<MapLayerVisibilityController>(
      tester.element(find.byType(MapScaffold)),
      listen: false,
    );
    await visibility.setHidden('dpm', hidden: true);
    await tester.pump();
    await tester.pump();
    expect(echo.frameCalls, greaterThan(0));
  });

  testWidgets(
    'layer chrome, the compass, and memory pressure reach the layer',
    (tester) async {
      final l10n = await english();
      final settings = SettingsStore.inMemory();
      final echo = _Layer(id: 'echo', name: 'Echo', withChrome: true)
        ..framesResult = Ok(twoFrames());
      await show(
        tester,
        settings: settings,
        camera: MapCameraHandoff(),
        stations: MapStationHandoff(),
        visibility: MapLayerVisibilityController(settings),
        layers: [echo],
        initialOsmEnabled: true,
      );
      await loadStyle(tester);

      await tester.tap(find.text('Layer options'));
      await tester.pump();
      await tester.pump();
      expect(settings.getBool(SettingKeys.mapShowTownLabels), isFalse);
      expect(echo.frameCalls, greaterThan(1));

      platform.onCameraMovePlatform(
        const CameraPosition(target: LatLng(23.5, 121), zoom: 7, bearing: 40),
      );
      await tester.pump();
      expect(find.byIcon(Icons.navigation), findsOneWidget);
      final movesBefore = platform.moves;
      await tester.tap(find.byTooltip(l10n.mapResetNorth));
      await tester.pump();
      expect(platform.moves, greaterThan(movesBefore));
      expect(find.byIcon(Icons.navigation), findsNothing);

      final gesture = await tester.startGesture(const Offset(20, 400));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(echo.gestureStarts, greaterThan(0));
      expect(echo.gestureEnds, greaterThan(0));

      platform.onCameraIdlePlatform(null);
      platform.onMapIdlePlatform(null);
      await tester.pump();
      expect(echo.cameraIdles, greaterThan(0));
      expect(echo.mapIdles, greaterThan(0));
      expect(platform.regionQueries, greaterThan(0));

      tester.binding.handleMemoryPressure();
      await tester.pump();
      expect(echo.memory, 1);
    },
  );

  testWidgets(
    'leaving and returning reloads a timeline; a hidden tab does not',
    (tester) async {
      final echo = _Layer(id: 'echo', name: 'Echo')
        ..framesResult = Ok(twoFrames());
      final visibleTab = VisibleTab(0);
      await show(
        tester,
        settings: SettingsStore.inMemory(),
        camera: MapCameraHandoff(),
        stations: MapStationHandoff(),
        visibility: MapLayerVisibilityController(SettingsStore.inMemory()),
        layers: [echo],
        visibleTab: visibleTab,
        tabIndex: 2,
      );
      await tester.pump();
      expect(echo.visibility, contains(false));

      visibleTab.value = 2;
      await tester.pump();
      expect(echo.frameCalls, 0, reason: 'style is not up yet');

      await loadStyle(tester);
      final loaded = echo.frameCalls;
      expect(loaded, greaterThan(0));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(echo.frameCalls, greaterThan(loaded));

      visibleTab.value = 0;
      await tester.pump();
      visibleTab.value = 2;
      await tester.pump();
      await tester.pump();
      expect(echo.frameCalls, greaterThan(loaded + 1));
    },
  );

  testWidgets(
    'a throw from show or clear is swallowed, and a late fetch is dropped',
    (tester) async {
      final gate = Completer<Result<List<MapFrame>>>();
      final echo = _Layer(id: 'echo', name: 'Echo')..framesGate = gate;
      final sheet = _Layer(id: 'stations', name: 'Stations', timeline: false)
        ..throwOnClear = true;
      final camera = MapCameraHandoff();
      await show(
        tester,
        settings: SettingsStore.inMemory(),
        camera: camera,
        stations: MapStationHandoff(),
        visibility: MapLayerVisibilityController(SettingsStore.inMemory()),
        layers: [echo, sheet],
      );
      await loadStyle(tester);

      camera.request(
        LatLngBounds(
          southwest: const LatLng(22, 120),
          northeast: const LatLng(24, 122),
        ),
        layerId: 'stations',
      );
      await tester.pump();
      gate.complete(Ok(twoFrames()));
      await tester.pump();
      await tester.pump();

      expect(echo.prepares, 0);
      expect(sheet.renders, greaterThan(0));

      echo.throwOnShow = true;
      echo.framesGate = null;
      echo.framesResult = Ok(twoFrames());
      camera.request(
        LatLngBounds(
          southwest: const LatLng(22, 120),
          northeast: const LatLng(24, 122),
        ),
        layerId: 'echo',
      );
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
