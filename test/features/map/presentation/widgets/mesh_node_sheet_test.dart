import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/features/map/presentation/widgets/mesh_node_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/meshtastic/fake_mesh_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var clock = DateTime.utc(2026, 1, 1, 12);

  MeshNode node(int num, {double snr = 0, int? battery}) => MeshNode(
    num: num,
    displayName: 'repeater',
    isOnline: true,
    batteryLevel: battery,
    lastHeard: clock,
    latitude: 24.0,
    longitude: 121.6,
    snr: snr,
  );

  Future<(MeshNodeStore, FakeMeshService)> makeStore() async {
    clock = DateTime.utc(2026, 1, 1, 12);
    SharedPreferences.setMockInitialValues({});
    final service = FakeMeshService();
    final store = MeshNodeStore(
      service,
      Prefs(await SharedPreferences.getInstance()),
      now: () => clock,
    )..start();
    return (store, service);
  }

  Widget wrap(MeshNodeStore store) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MeshNodeSheet(
        store: store,
        selected: ValueNotifier(1),
        selectionRevision: ValueNotifier(0),
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
}
