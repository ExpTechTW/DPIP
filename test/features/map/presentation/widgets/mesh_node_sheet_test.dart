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

  MeshNode node(int num, {double snr = 0, int? battery}) => MeshNode(
    num: num,
    displayName: 'repeater',
    batteryLevel: battery,
    lastHeard: clock,
    latitude: 24.0,
    longitude: 121.6,
    snr: snr,
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

  Widget wrap(MeshNodeStore store, {bool connected = true, int cooldown = 0}) =>
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MeshNodeSheet(
            store: store,
            selected: ValueNotifier(1),
            selectionRevision: ValueNotifier(0),
            routeState: ValueNotifier(const MeshRouteState.none()),
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
}
