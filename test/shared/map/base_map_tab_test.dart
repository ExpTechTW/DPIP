import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:maplibre_gl_platform_interface/maplibre_gl_platform_interface.dart';

/// A fake platform that completes the map lifecycle (`buildView` →
/// `onPlatformViewCreated` → controller) and records every
/// [MapLibrePlatform.setRenderPaused] call. Everything else a real controller
/// might touch is absorbed by `noSuchMethod` — these tests only exercise the
/// visibility↔render state machine.
class _FakePlatform extends MapLibrePlatform {
  final paused = <bool>[];

  @override
  Future<void> initPlatform(int id) async {}

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    onPlatformViewCreated(0);
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
    await tester.pumpWidget(MaterialApp(home: child));
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

  testWidgets('no tabIndex means the map never pauses', (tester) async {
    final visibleTab = VisibleTab(0);
    await pump(
      tester,
      VisibleTabScope(visibleTab: visibleTab, child: const BaseMap()),
    );
    visibleTab.value = 2;
    await tester.pump();
    expect(platform.paused, isEmpty);
  });

  testWidgets('no VisibleTabScope (outside the shell) means never paused', (
    tester,
  ) async {
    await pump(tester, const BaseMap(tabIndex: 2));
    expect(platform.paused, isEmpty);
  });
}
