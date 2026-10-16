/// The sheet is where the track layer says what it is: the local-only notice
/// at rest, the empty state that leads to the grant, what is stored, and a
/// clear that cannot happen by accident.
library;

import 'dart:io';

import 'package:dpip/core/geo/location_track.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/storage/app_storage_scan.dart';
import 'package:dpip/features/map/presentation/layers/location_track_layer.dart';
import 'package:dpip/features/map/presentation/widgets/location_track_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../../../core/geo/location_track_fixture.dart';
import '../../raster_timeline_harness.dart';

/// 2026-10-16 03:00 UTC — 11:00 in Taipei.
final _now = DateTime.utc(2026, 10, 16, 3);

List<(int, double, double)> _walk(Duration ago, {int count = 10}) {
  final start = _now.subtract(ago).millisecondsSinceEpoch ~/ 1000;
  return [
    for (var i = 0; i < count; i++)
      (start + i * 60, 25.0330 + i * 0.0003, 121.5654 + i * 0.0002),
  ];
}

void main() {
  late Directory dir;
  late String path;
  late List<String> channelCalls;
  late BackgroundLocationService service;
  late AppLocalizations l10n;
  const channel = MethodChannel('test/background_location_sheet');

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() {
    dir = Directory.systemTemp.createTempSync('location_track_sheet_test');
    path = '${dir.path}/location_track.db';
    channelCalls = [];
    service = BackgroundLocationService(
      platform: 0,
      version: 'test',
      channel: channel,
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  void mockChannel(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      channelCalls.add(call.method);
      if (call.method == 'clearTrack') {
        final db = sqlite3.sqlite3.open(path);
        db.execute('DELETE FROM fix');
        db.close();
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
  }

  LocationTrackMapLayer makeLayer() => LocationTrackMapLayer(
    service,
    open: () async => LocationTrack.at(path),
    now: () => _now,
  );

  /// Lets the layer's database and isolate work finish: real time for the I/O,
  /// a pump for the callbacks it schedules back into the test zone.
  Future<void> drain(WidgetTester tester, LocationTrackMapLayer layer) async {
    for (var i = 0; i < 200; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (!layer.busy.value) return;
    }
    fail('the layer never finished loading');
  }

  Future<void> pumpSheet(
    WidgetTester tester,
    LocationTrackMapLayer layer, {
    Size size = const Size(400, 900),
    double navBar = 0,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: MediaQuery(
              // What the shell's `extendBody` hands the map: the navigation
              // bar's height as bottom padding, over the bottom of the map.
              data: MediaQuery.of(context).copyWith(
                padding: EdgeInsets.only(bottom: navBar),
                textScaler: TextScaler.linear(textScale),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: LocationTrackSheet(layer: layer)),
                ],
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.permissionsPath,
          name: AppRoutes.permissions,
          builder: (_, _) => const Scaffold(body: Text('permission check')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    // Two frames: the peek is measured after the first one.
    await tester.pump();
    await tester.pump();
  }

  Future<void> expandSheet(WidgetTester tester) async {
    await tester.drag(
      find.text(l10n.mapLayerLocationTrack),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();
  }

  Future<void> closeLayer(WidgetTester tester, LocationTrackMapLayer layer) =>
      tester.runAsync(() => layer.clear(RecordingMapController()));

  testWidgets('nothing recorded: how recording starts, and the way there', (
    tester,
  ) async {
    final layer = makeLayer();
    await tester.runAsync(layer.refresh);
    await pumpSheet(tester, layer);
    await expandSheet(tester);

    expect(find.text(l10n.locationTrackEmpty), findsOneWidget);
    expect(find.text(l10n.locationTrackEmptyBody), findsOneWidget);
    // The notice says what will happen to the data before there is any.
    expect(find.text(l10n.locationTrackLocalOnly), findsOneWidget);
    // No range to pick and nothing to clear when nothing was recorded.
    expect(find.text(l10n.locationTrackRangeAll), findsNothing);
    expect(find.text(l10n.locationTrackClear), findsNothing);

    await tester.tap(find.text(l10n.permissionsTitle));
    await tester.pumpAndSettle();
    expect(find.text('permission check'), findsOneWidget);
  });

  testWidgets('recorded: what is stored, and the pills pick the window', (
    tester,
  ) async {
    writeTrackFixture(path, [
      ..._walk(const Duration(days: 20)),
      ..._walk(const Duration(days: 3)),
    ]);
    final layer = makeLayer();
    await tester.runAsync(layer.refresh);
    final bytes = layer.snapshot.value!.bytes;
    await pumpSheet(tester, layer);
    await expandSheet(tester);

    expect(find.text(l10n.locationTrackLocalOnly), findsOneWidget);
    expect(find.text(l10n.locationTrackRangePoints('10')), findsOneWidget);
    expect(
      find.text(l10n.locationTrackStored('20', formatBytes(bytes))),
      findsOneWidget,
    );
    expect(
      find.text(l10n.locationTrackOldest('2026/09/26')),
      findsOneWidget,
      reason: 'twenty days before 2026-10-16, in Taipei',
    );
    expect(find.text(l10n.locationTrackCapacity), findsOneWidget);
    expect(find.text(l10n.locationTrackGapNote(2)), findsOneWidget);

    await tester.tap(find.text(l10n.locationTrackRangeMonth));
    expect(layer.range.value, TrackRange.month);
    await drain(tester, layer);
    expect(find.text(l10n.locationTrackRangePoints('20')), findsOneWidget);

    await closeLayer(tester, layer);
  });

  testWidgets('clearing asks first, and cancelling keeps everything', (
    tester,
  ) async {
    mockChannel(tester);
    writeTrackFixture(path, _walk(const Duration(hours: 1)));
    final layer = makeLayer();
    await tester.runAsync(layer.refresh);
    await pumpSheet(tester, layer);
    await expandSheet(tester);

    // Exactly one match while the dialog is closed: the sheet's button.
    await tester.tap(find.text(l10n.locationTrackClear));
    await tester.pumpAndSettle();
    expect(find.text(l10n.locationTrackClearConfirm), findsOneWidget);
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();
    expect(channelCalls, isEmpty);
    expect(layer.snapshot.value!.recorded, isTrue);

    await tester.tap(find.text(l10n.locationTrackClear));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.locationTrackClear),
    );
    await tester.pump();
    await drain(tester, layer);
    await tester.pump();

    expect(channelCalls, ['clearTrack']);
    expect(layer.snapshot.value!.recorded, isFalse);
    expect(find.text(l10n.locationTrackCleared), findsOneWidget);
    expect(find.text(l10n.locationTrackEmpty), findsOneWidget);
    await closeLayer(tester, layer);
  });

  for (final (label, textScale) in [
    ('default text', 1.0),
    ('large text', 1.3),
  ]) {
    testWidgets('the local-only notice rests above the navigation bar '
        '($label)', (tester) async {
      writeTrackFixture(path, _walk(const Duration(hours: 1)));
      final layer = makeLayer();
      await tester.runAsync(layer.refresh);
      // A small phone, with the shell's navigation bar over the map.
      const height = 640.0;
      const navBar = 96.0;
      await pumpSheet(
        tester,
        layer,
        size: const Size(360, height),
        navBar: navBar,
        textScale: textScale,
      );

      final notice = tester.getRect(find.text(l10n.locationTrackLocalOnly));
      expect(notice.bottom, lessThanOrEqualTo(height - navBar));
      expect(layer.peekExtent, greaterThan(navBar / height));
      expect(layer.bottomChromeFraction, layer.peekExtent);
      await closeLayer(tester, layer);
    });
  }
}
