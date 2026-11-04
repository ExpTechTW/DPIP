/// The shell is the only place the five tabs, the attention dot, and the
/// replay-close-on-leave rule meet. The branches here are stubs so the test
/// exercises that chrome without building each feature page.
library;

import 'dart:typed_data';

import 'package:dpip/app/shell/main_shell.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/location_status.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/meshtastic/mesh_unread.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/permissions/permission_health.dart';
import 'package:dpip/core/settings/default_map_layer_controller.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/changelog/domain/changelog_repository.dart';
import 'package:dpip/features/changelog/domain/release_note.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/default_map_layer_ui.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_immersive.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/navigation/refresh_on_appear.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tabs, the badge, a covering route, and leaving a replay', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final settings = SettingsStore.inMemory();
    final extent = HomeSheetExtent();
    final reset = HomeResetSignal();
    final handoff = MapCameraHandoff();
    final unread = MeshUnread(null);
    final endpoints = EndpointHealthMonitor();
    final layers = DefaultMapLayerController(settings);
    final location = LocationService(
      const TownDirectory({}),
      isAvailable: () async => false,
      status: () async => LocationStatus.denied,
    );

    final router = GoRouter(
      initialLocation: '/home',
      observers: [shellRouteObserver],
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(navigationShell: shell),
          branches: [
            _branch('/home', 'home', 'home-body'),
            _branch('/events', 'events', 'events-body'),
            _branch('/map', 'map', 'map-body'),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/data',
                  name: 'data',
                  builder: (_, _) => const Text('data-body'),
                  routes: [
                    GoRoute(
                      path: 'replay',
                      name: AppRoutes.earthquakeReplay,
                      builder: (_, _) => const Text('replay-body'),
                    ),
                  ],
                ),
              ],
            ),
            _branch('/more', 'more', 'more-body'),
          ],
        ),
        GoRoute(path: '/cover', builder: (_, _) => const Text('cover-body')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SettingsStore>.value(value: settings),
          Provider<ChangelogRepository>.value(value: _Notes()),
          ChangeNotifierProvider<HomeSheetExtent>.value(value: extent),
          ChangeNotifierProvider<HomeResetSignal>.value(value: reset),
          ChangeNotifierProvider<MapCameraHandoff>.value(value: handoff),
          ChangeNotifierProvider<DefaultMapLayerController>.value(
            value: layers,
          ),
          ChangeNotifierProvider<PermissionHealth>(
            create: (_) => PermissionHealth(
              location: location,
              notifications: NotificationService(settings),
            ),
          ),
          ChangeNotifierProvider<EndpointHealthMonitor>.value(value: endpoints),
          ChangeNotifierProvider<MeshUnread>.value(value: unread),
          ChangeNotifierProvider<MapImmersiveController>(
            create: (_) => MapImmersiveController(),
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
    expect(find.text('home-body'), findsOneWidget);
    expect(find.text(l10n.navHome), findsOneWidget);

    extent.value = 0.85;
    await tester.pump();
    extent.value = HomeSheetExtent.rest;
    await tester.pump();

    var resets = 0;
    reset.addListener(() => resets++);
    await tester.tap(find.text(l10n.navHome));
    await tester.pump();
    expect(resets, greaterThan(0));

    await tester.tap(find.text(l10n.navEvents));
    await tester.pump();
    await tester.pump();
    expect(find.text('events-body'), findsOneWidget);

    await tester.tap(find.text(layers.layer.label(l10n)));
    await tester.pump();
    await tester.pump();
    expect(find.text('map-body'), findsOneWidget);
    expect(handoff.takePending()?.layerId, layers.layer.id);

    // An immersive map owns the whole screen, so the shell's bar slides away
    // with it and comes back on exit — the map cannot reach the bar itself.
    final immersive = Provider.of<MapImmersiveController>(
      tester.element(find.byType(MainShell)),
      listen: false,
    );
    final label = find.text(layers.layer.label(l10n));
    final restingY = tester.getTopLeft(label).dy;

    immersive.enter();
    await tester.pump();
    // The first frame starts the transition without moving the bar yet; a
    // snap would already be at the bottom here.
    expect(tester.getTopLeft(label).dy, closeTo(restingY, 0.01));

    await tester.pump(const Duration(milliseconds: 110));
    final midway = tester.getTopLeft(label).dy;
    expect(midway, greaterThan(restingY));

    await tester.pump(const Duration(milliseconds: 200));
    final hiddenY = tester.getTopLeft(label).dy;
    expect(hiddenY, greaterThan(midway));
    expect(hiddenY, greaterThan(600));

    immersive.exit();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(label).dy, lessThan(600));

    unread.recordIncoming(1, 1);
    endpoints.failure(
      ApiTier.lbApi,
      'https://api.example.test',
      '/api/v2/eq/eew',
    );
    await tester.pump();
    expect(find.byType(Badge), findsWidgets);

    router.push('/cover');
    await tester.pump();
    await tester.pump();
    expect(find.text('cover-body'), findsOneWidget);
    router.pop();
    await tester.pump();
    await tester.pump();

    router.goNamed(AppRoutes.earthquakeReplay);
    await tester.pump();
    await tester.pump();
    expect(find.text('replay-body'), findsOneWidget);

    // The replay is nested under the data branch; its immersive mode must
    // retract the shell's bar even though the map branch is not selected.
    immersive.enter();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(label).dy, greaterThan(600));
    immersive.exit();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(label).dy, lessThan(600));

    await tester.tap(find.text(l10n.navHome));
    await tester.pump();
    await tester.pump();
    expect(find.text('home-body'), findsOneWidget);
    expect(find.text('replay-body'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

StatefulShellBranch _branch(String path, String name, String label) =>
    StatefulShellBranch(
      routes: [GoRoute(path: path, name: name, builder: (_, _) => Text(label))],
    );

class _Notes implements ChangelogRepository {
  @override
  Future<Result<List<ReleaseNote>>> releases({int page = 1}) async =>
      const Ok([]);

  @override
  Future<Result<Uint8List>> avatarBytes(String login) async =>
      const Err(UnexpectedFailure('no avatar'));
}
