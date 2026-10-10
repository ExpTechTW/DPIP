import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/map/presentation/layers/mesh_node_layer.dart';
import 'package:dpip/features/map/presentation/widgets/mesh_node_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/meshtastic/fake_mesh_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var clock = DateTime.utc(2026, 1, 1, 12);

  MeshNode node(
    int num, {
    double snr = 0,
    int? battery,
    String name = 'repeater',
    bool viaMqtt = false,
    int? hops,
    double? lat = 24.0,
    double? lng = 121.6,
  }) => MeshNode(
    num: num,
    displayName: name,
    batteryLevel: battery,
    lastHeard: clock,
    latitude: lat,
    longitude: lng,
    snr: snr,
    viaMqtt: viaMqtt,
    hopsAway: hops,
  );

  Future<(MeshNodeStore, FakeMeshService)> makeStore() async {
    clock = DateTime.utc(2026, 1, 1, 12);
    final service = FakeMeshService();
    final store = MeshNodeStore(
      service,
      SettingsStore.inMemory({}),
      now: () => clock,
    )..start();
    return (store, service);
  }

  Widget wrap(
    MeshNodeStore store, {
    bool connected = true,
    int cooldown = 0,
    ValueNotifier<int?>? selected,
    ValueNotifier<MeshRouteState>? route,
  }) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MeshNodeSheet(
        store: store,
        selected: selected ?? ValueNotifier(1),
        selectionRevision: ValueNotifier(0),
        routeState: route ?? ValueNotifier(const MeshRouteState.none()),
        connected: ValueNotifier(connected),
        traceCooldown: ValueNotifier(cooldown),
        onTraceRoute: (_) {},
        onClose: () {},
      ),
    ),
  );

  testWidgets('no trends until two distinct readings exist', (tester) async {
    final (store, service) = await makeStore();
    service.nodes.add(node(1, snr: -5));
    await tester.pump();

    await tester.pumpWidget(wrap(store));
    await tester.pump();

    expect(find.text('Signal trend (SNR)'), findsNothing);

    // Let the store's debounced persist fire.
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
  });

  testWidgets('renders SNR and battery trends once history builds', (
    tester,
  ) async {
    final (store, service) = await makeStore();
    service.nodes
      ..add(node(1, snr: -8, battery: 90))
      ..add(node(1, snr: -6, battery: 88));
    await tester.pump();

    await tester.pumpWidget(wrap(store));
    await tester.pump();

    expect(find.text('Signal trend (SNR)'), findsOneWidget);
    expect(find.text('Battery trend'), findsOneWidget);
    // Current-value readouts sit on the trend headers.
    expect(find.textContaining(' dB'), findsWidgets);
    expect(find.textContaining('%'), findsWidgets);

    // Let the store's debounced persist fire.
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
  });

  testWidgets('battery trend skips an externally powered node', (tester) async {
    final (store, service) = await makeStore();
    // 101 is "plugged in", not a charge — no trend to draw.
    service.nodes
      ..add(node(1, snr: -8, battery: 101))
      ..add(node(1, snr: -6, battery: 101));
    await tester.pump();

    await tester.pumpWidget(wrap(store));
    await tester.pump();

    expect(find.text('Signal trend (SNR)'), findsOneWidget);
    expect(find.text('Battery trend'), findsNothing);

    // Let the store's debounced persist fire.
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
  });

  /// `FilledButton.tonalIcon` builds a private subclass, and `byType` matches
  /// the exact runtime type — so the button is found by predicate.
  Finder traceButton() => find.byWidgetPredicate((w) => w is FilledButton);

  testWidgets('the trace button is disabled without a radio', (tester) async {
    final (store, service) = await makeStore();
    service.nodes.add(node(1, snr: -5));
    await tester.pump();

    await tester.pumpWidget(wrap(store, connected: false));
    await tester.pump();

    // A probe rides the BLE link; without it the button greys out and the row
    // says why, rather than offering an action that can only fail.
    expect(tester.widget<FilledButton>(traceButton()).onPressed, isNull);
    expect(find.text('Radio not connected'), findsOneWidget);
    // Let the store's debounced persist fire.
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
  });

  testWidgets('and enabled once the radio is attached', (tester) async {
    final (store, service) = await makeStore();
    service.nodes.add(node(1, snr: -5));
    await tester.pump();

    await tester.pumpWidget(wrap(store));
    await tester.pump();

    expect(tester.widget<FilledButton>(traceButton()).onPressed, isNotNull);
    expect(find.text('Radio not connected'), findsNothing);
    expect(find.text('Trace route'), findsOneWidget);
    // Let the store's debounced persist fire.
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
  });

  testWidgets('a cooldown counts down on the button, disabled', (tester) async {
    final (store, service) = await makeStore();
    service.nodes.add(node(1, snr: -5));
    await tester.pump();

    await tester.pumpWidget(wrap(store, cooldown: 12));
    await tester.pump();

    // The radio refuses a second probe inside 30 s, so the button waits it
    // out visibly instead of being live and answering with a refusal.
    expect(tester.widget<FilledButton>(traceButton()).onPressed, isNull);
    expect(find.text('Trace route 12'), findsOneWidget);
    expect(find.text('Radio limits this to once every 30 s'), findsOneWidget);
    // Let the store's debounced persist fire.
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
  });

  testWidgets('nothing selected asks for a tap', (tester) async {
    final (store, _) = await makeStore();
    await tester.pumpWidget(wrap(store, selected: ValueNotifier<int?>(null)));
    await tester.pump();
    expect(find.text('Tap a node for details'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
  });

  testWidgets('mqtt, hops, a nameless id, and distance all read on the sheet', (
    tester,
  ) async {
    final (store, service) = await makeStore();
    final selected = ValueNotifier<int?>(1);
    service.nodes
      ..add(node(0x1234, name: 'mine', lat: 25, lng: 121))
      ..add(node(1, name: '', viaMqtt: true, hops: 0, lat: 25.001, lng: 121));
    await tester.pump();
    await tester.pumpWidget(wrap(store, selected: selected));
    await tester.pump();

    expect(find.text('0x1'), findsWidgets);
    expect(find.text('Via MQTT (internet)'), findsOneWidget);
    expect(find.text('Direct'), findsOneWidget);
    expect(find.textContaining(' m'), findsOneWidget);

    service.nodes.add(
      node(1, name: '', viaMqtt: true, hops: 3, lat: 25.02, lng: 121),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('3 hops'), findsOneWidget);
    expect(find.textContaining('km'), findsOneWidget);

    service.nodes.add(node(1, name: '', hops: 3, lat: 26, lng: 121));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('111'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
  });

  testWidgets('a flat signal trend still draws', (tester) async {
    final (store, service) = await makeStore();
    service.nodes.add(node(1, snr: -6, battery: 80));
    clock = clock.add(const Duration(minutes: 2));
    service.nodes.add(node(1, snr: -6, battery: 79));
    await tester.pump();
    await tester.pumpWidget(wrap(store));
    await tester.pump();
    expect(find.text('Signal trend (SNR)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
  });

  testWidgets('trace results, failures, and an in-flight probe all say so', (
    tester,
  ) async {
    final (store, service) = await makeStore();
    service.nodes.add(node(1));
    await tester.pump();
    final route = ValueNotifier<MeshRouteState>(
      const MeshRouteState(
        result: MeshRoute(
          towards: [MeshRouteHop(num: 9), MeshRouteHop(num: 1)],
          back: [],
          target: 1,
        ),
      ),
    );
    await tester.pumpWidget(wrap(store, route: route));
    await tester.pump();
    expect(find.text('Direct — no relays between'), findsOneWidget);

    route.value = const MeshRouteState(
      result: MeshRoute(
        towards: [
          MeshRouteHop(num: 9),
          MeshRouteHop(num: 8),
          MeshRouteHop(num: 1),
        ],
        back: [],
        target: 1,
      ),
    );
    await tester.pump();
    expect(find.text('1 hops'), findsOneWidget);

    route.value = const MeshRouteState(failed: true);
    await tester.pump();
    expect(
      find.text('No reply — out of range or on another channel key'),
      findsOneWidget,
    );

    route.value = const MeshRouteState(failed: true, reason: 'busy');
    await tester.pump();
    expect(find.text('busy'), findsOneWidget);

    route.value = const MeshRouteState(result: MeshRoute.none());
    await tester.pump();
    expect(find.text('Unreadable reply'), findsOneWidget);

    route.value = const MeshRouteState(target: 1);
    await tester.pump();
    expect(find.text('Tracing…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
  });
}
