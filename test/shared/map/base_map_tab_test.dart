import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

/// A fake platform that completes the map lifecycle (`buildView` →
/// `onPlatformViewCreated` → controller) and records every
/// [MapLibrePlatform.setRenderPaused] call. Everything else a real controller
/// might touch is absorbed by `noSuchMethod` — these tests only exercise the
/// visibility↔render state machine.
class _FakePlatform extends MapLibrePlatform {
  final paused = <bool>[];
  int buildCount = 0;

  @override
  Future<void> initPlatform(int id) async {}

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    onPlatformViewCreated(buildCount++);
    return const SizedBox.shrink();
  }

  @override
  Future<void> setRenderPaused(bool paused) async {
    this.paused.add(paused);
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePlatform platform;

  setUp(() {
    platform = _FakePlatform();
    final previous = MapLibrePlatform.createInstance;
    addTearDown(() => MapLibrePlatform.createInstance = previous);
    MapLibrePlatform.createInstance = () => platform;
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<TownDirectory>.value(
          // The style string needs a (empty) directory for its town labels —
          // a real one is the app bootstrap's job.
          value: TownDirectory.fromJson(const {}),
          child: child,
        ),
      ),
    );
    // Let the platform view callback run and the controller report in.
    await tester.pump();
  }

  testWidgets('a map owned by another tab pauses once the controller is up', (
    tester,
  ) async {
    final visibleTab = VisibleTab(0);
    await pump(
      tester,
      VisibleTabScope(
        visibleTab: visibleTab,
        child: const BaseMap(tabIndex: 2),
      ),
    );
    expect(platform.paused, [
      true,
    ], reason: 'hidden at birth → paused on ready');
  });

  testWidgets('returning to the owning tab resumes rendering', (tester) async {
    final visibleTab = VisibleTab(0);
    await pump(
      tester,
      VisibleTabScope(
        visibleTab: visibleTab,
        child: const BaseMap(tabIndex: 2),
      ),
    );
    visibleTab.value = 2;
    await tester.pump();
    expect(platform.paused, [true, false]);
  });

  testWidgets('iOS leaves the retained native render loop under MapLibre', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final visibleTab = VisibleTab(2);
      await pump(
        tester,
        VisibleTabScope(
          visibleTab: visibleTab,
          child: const BaseMap(tabIndex: 2),
        ),
      );

      visibleTab.value = 0;
      await tester.pump();
      visibleTab.value = 2;
      await tester.pump();

      expect(platform.paused, isEmpty);
      expect(platform.buildCount, 1);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iOS opt-in recreates the native view on return', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final visibleTab = VisibleTab(2);
      final created = <MapLibreMapController>[];
      final invalidated = <MapLibreMapController>[];
      await pump(
        tester,
        VisibleTabScope(
          visibleTab: visibleTab,
          child: BaseMap(
            tabIndex: 2,
            recreateOnReturn: true,
            onMapCreated: created.add,
            onMapInvalidated: invalidated.add,
          ),
        ),
      );

      visibleTab.value = 0;
      await tester.pump();
      expect(platform.buildCount, 1, reason: 'hiding retains the current view');

      visibleTab.value = 2;
      await tester.pump();
      await tester.pump();

      expect(platform.paused, isEmpty);
      expect(platform.buildCount, 2);
      expect(created, hasLength(2));
      expect(invalidated, [created.first]);
      expect(created.last, isNot(same(created.first)));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android keeps pause-resume when recreation is requested', (
    tester,
  ) async {
    final visibleTab = VisibleTab(2);
    await pump(
      tester,
      VisibleTabScope(
        visibleTab: visibleTab,
        child: const BaseMap(tabIndex: 2, recreateOnReturn: true),
      ),
    );

    visibleTab.value = 0;
    await tester.pump();
    visibleTab.value = 2;
    await tester.pump();

    expect(platform.buildCount, 1);
    expect(platform.paused, [true, false]);
  });

  testWidgets('flapping between tabs pauses exactly once per transition', (
    tester,
  ) async {
    final visibleTab = VisibleTab(0);
    await pump(
      tester,
      VisibleTabScope(
        visibleTab: visibleTab,
        child: const BaseMap(tabIndex: 2),
      ),
    );
    visibleTab.value = 2;
    await tester.pump();
    visibleTab.value = 2; // Same value — no transition.
    await tester.pump();
    visibleTab.value = 5;
    await tester.pump();
    expect(platform.paused, [true, false, true]);
  });

  testWidgets('no tabIndex means no tab can hide the map', (tester) async {
    final visibleTab = VisibleTab(0);
    await pump(
      tester,
      VisibleTabScope(visibleTab: visibleTab, child: const BaseMap()),
    );
    visibleTab.value = 2;
    await tester.pump();
    expect(platform.paused, isEmpty);
  });

  testWidgets('no VisibleTabScope (outside the shell) means no tab test', (
    tester,
  ) async {
    await pump(tester, const BaseMap(tabIndex: 2));
    expect(platform.paused, isEmpty);
  });

  testWidgets('a page pushed over the shell pauses the visible tab', (
    tester,
  ) async {
    final visibleTab = VisibleTab(2);
    await pump(
      tester,
      VisibleTabScope(
        visibleTab: visibleTab,
        child: const BaseMap(tabIndex: 2),
      ),
    );
    expect(platform.paused, isEmpty, reason: 'on screen at birth');

    // What a full-screen route does: the branch index never moves, so only the
    // shell flag can tell this map it is no longer being looked at.
    visibleTab.shellOnTop = false;
    await tester.pump();
    expect(platform.paused, [true]);

    visibleTab.shellOnTop = true;
    await tester.pump();
    expect(platform.paused, [true, false], reason: 'popped back to the map');
  });

  testWidgets('a covered map stays paused across a tab switch', (tester) async {
    final visibleTab = VisibleTab(2);
    await pump(
      tester,
      VisibleTabScope(
        visibleTab: visibleTab,
        child: const BaseMap(tabIndex: 2),
      ),
    );
    visibleTab.shellOnTop = false;
    await tester.pump();
    visibleTab.value = 0; // hidden two ways over; still just the one pause
    await tester.pump();
    expect(platform.paused, [true]);
  });

  testWidgets('backgrounding pauses a map the shell cannot reach', (
    tester,
  ) async {
    // No scope at all: the native render loop is the whole reason this matters,
    // since it keeps drawing after Flutter stops producing frames.
    await pump(tester, const BaseMap());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(platform.paused, [true]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(platform.paused, [true, false]);
  });

  testWidgets('inactive keeps rendering — the map is still on screen', (
    tester,
  ) async {
    await pump(tester, const BaseMap());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(platform.paused, isEmpty);
  });

  testWidgets('a backgrounded hidden tab does not resume on foreground', (
    tester,
  ) async {
    final visibleTab = VisibleTab(0);
    await pump(
      tester,
      VisibleTabScope(
        visibleTab: visibleTab,
        child: const BaseMap(tabIndex: 2),
      ),
    );
    expect(platform.paused, [true], reason: 'hidden tab');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(platform.paused, [true], reason: 'still the wrong tab to draw');
  });
}
