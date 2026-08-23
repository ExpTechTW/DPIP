/// Regression test for channels bleeding into each other while disconnected.
///
/// The page used to skip filtering when the radio hadn't reported its channel
/// table — so with no link, every channel's messages appeared in one list.
/// Channels are separate conversations; interleaving them is wrong however
/// little else is known about the radio.
library;

import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/domain/meshtastic_service.dart';
import 'package:dpip/core/meshtastic/mesh_alerts.dart';
import 'package:dpip/core/meshtastic/mesh_link.dart';
import 'package:dpip/core/meshtastic/mesh_node_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/meshtastic/presentation/mesh_chat_controller.dart';
import 'package:dpip/features/meshtastic/presentation/pages/meshtastic_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../core/meshtastic/fake_mesh_service.dart';
import '../../core/storage/memory_db.dart';

void main() {
  MeshStoredMessage stored(String text, int channel, int seconds) =>
      MeshStoredMessage(
        from: 1,
        channel: channel,
        text: text,
        timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: seconds)),
        outgoing: false,
      );

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late MeshChatController controller;
    late MeshNodeStore nodes;
    late MeshLink link;
    late MeshAlerts alerts;
    late FakeMeshService service;
    // Real I/O: SQLite runs off the test's fake-async zone, so anything that
    // touches it must happen inside `runAsync` or its futures never complete
    // and the test simply hangs.
    await tester.runAsync(() async {
      final settings = SettingsStore.inMemory({});
      final db = openMemoryDb();
      addTearDown(db.close);
      await MeshStore.createSchema(db);
      final store = MeshStore(db);
      await store.addMessage(stored('on the primary', 0, 2));
      await store.addMessage(stored('on the secondary', 3, 1));
      // Pre-read both conversations: opening the page advances the read
      // position, and that write — a real sqflite isolate call — must not be
      // scheduled from the widget test's fake-async zone.
      await store.writeLastRead(
        0,
        stored('x', 0, 2).timestamp.millisecondsSinceEpoch,
      );
      await store.writeLastRead(
        3,
        stored('x', 3, 1).timestamp.millisecondsSinceEpoch,
      );

      // Disconnected on purpose: no channel table, the case that broke.
      service = FakeMeshService();
      link = MeshLink(service, settings);
      alerts = MeshAlerts(service, settings, post: (_) async {});
      nodes = MeshNodeStore(service, settings)..start();
      controller = MeshChatController(service, link, store);
      // Let the controller's initial load land before the first frame.
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<MeshtasticService>.value(value: service),
          ChangeNotifierProvider<MeshLink>.value(value: link),
          ChangeNotifierProvider<MeshAlerts>.value(value: alerts),
          ChangeNotifierProvider<MeshChatController>.value(value: controller),
          // The page badges node counts straight off the store now.
          ChangeNotifierProvider<MeshNodeStore>.value(value: nodes),
        ],
        child: const MaterialApp(
          locale: Locale('zh', 'TW'),
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MeshtasticPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows one channel at a time while disconnected', (tester) async {
    await pumpPage(tester);

    expect(find.text('on the primary'), findsOneWidget);
    expect(find.text('on the secondary'), findsNothing);
  });

  testWidgets('still offers the channels the log knows about', (tester) async {
    await pumpPage(tester);

    // The radio has told us nothing, but the stored log has: two channels.
    await tester.tap(find.text('CH0'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('CH3').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('on the secondary'), findsOneWidget);
    expect(find.text('on the primary'), findsNothing);
  });
}
