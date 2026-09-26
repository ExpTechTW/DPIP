import 'dart:async';
import 'dart:convert';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/platform/widget_location_catalog_coordinator.dart';
import 'package:dpip/core/platform/widget_snapshot_writer.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final townDirectory = TownDirectory.fromJson({
    '407': {
      'city': '臺中',
      'town': '西屯',
      'lat': 24.1658213,
      'lng': 120.6336717,
      'cityLevel': '市',
      'townLevel': '區',
    },
    '700': {
      'city': '臺南',
      'town': '中西',
      'lat': 22.994821,
      'lng': 120.196452,
      'cityLevel': '市',
      'townLevel': '區',
    },
  });

  test('publishes the saved-location catalog when started', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['407'],
      }),
    );

    final writer = _RecordingWidgetSnapshotWriter();

    final coordinator = WidgetLocationCatalogCoordinator(
      regions,
      townDirectory,
      writer,
    );

    addTearDown(coordinator.dispose);

    coordinator.start();
    await coordinator.waitForPendingWrites();

    expect(writer.writes, hasLength(1));
    expect(writer.writes.single.kind, WidgetSnapshotKind.locationCatalog);

    final json = jsonDecode(writer.writes.single.json) as Map<String, dynamic>;

    expect(json['schemaVersion'], 1);

    final locations = json['locations'] as List<dynamic>;

    expect(locations, hasLength(1));
    expect((locations.single as Map<String, dynamic>)['regionCode'], '407');
  });

  test('does not republish when only the selected Home area changes', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['407'],
      }),
    );

    final writer = _RecordingWidgetSnapshotWriter();

    final coordinator = WidgetLocationCatalogCoordinator(
      regions,
      townDirectory,
      writer,
    );

    addTearDown(coordinator.dispose);

    coordinator.start();
    await coordinator.waitForPendingWrites();

    expect(writer.writes, hasLength(1));

    regions.select(0);

    await coordinator.waitForPendingWrites();

    expect(writer.writes, hasLength(1));
  });

  test('does not republish when only the current GPS code changes', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['407'],
      }),
    );

    final writer = _RecordingWidgetSnapshotWriter();

    final coordinator = WidgetLocationCatalogCoordinator(
      regions,
      townDirectory,
      writer,
    );

    addTearDown(coordinator.dispose);

    coordinator.start();
    await coordinator.waitForPendingWrites();

    expect(writer.writes, hasLength(1));

    regions.setCurrentCode('700');

    await coordinator.waitForPendingWrites();

    expect(writer.writes, hasLength(1));
  });

  test('republishes when the saved locations change', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['407'],
      }),
    );

    final writer = _RecordingWidgetSnapshotWriter();

    final coordinator = WidgetLocationCatalogCoordinator(
      regions,
      townDirectory,
      writer,
    );

    addTearDown(coordinator.dispose);

    coordinator.start();
    await coordinator.waitForPendingWrites();

    regions.addSaved('700');

    await coordinator.waitForPendingWrites();

    expect(writer.writes, hasLength(2));

    final json = jsonDecode(writer.writes.last.json) as Map<String, dynamic>;
    final locations = json['locations'] as List<dynamic>;

    expect(
      locations
          .cast<Map<String, dynamic>>()
          .map((location) => location['regionCode'])
          .toList(),
      ['407', '700'],
    );
  });

  test('republishes when a saved location is removed', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['407', '700'],
      }),
    );

    final writer = _RecordingWidgetSnapshotWriter();

    final coordinator = WidgetLocationCatalogCoordinator(
      regions,
      townDirectory,
      writer,
    );

    addTearDown(coordinator.dispose);

    coordinator.start();
    await coordinator.waitForPendingWrites();

    regions.removeSaved('407');

    await coordinator.waitForPendingWrites();

    expect(writer.writes, hasLength(2));

    final json = jsonDecode(writer.writes.last.json) as Map<String, dynamic>;
    final locations = json['locations'] as List<dynamic>;

    expect(
      locations
          .cast<Map<String, dynamic>>()
          .map((location) => location['regionCode'])
          .toList(),
      ['700'],
    );
  });

  test('republishes when a saved location is replaced', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['407'],
      }),
    );

    final writer = _RecordingWidgetSnapshotWriter();

    final coordinator = WidgetLocationCatalogCoordinator(
      regions,
      townDirectory,
      writer,
    );

    addTearDown(coordinator.dispose);

    coordinator.start();
    await coordinator.waitForPendingWrites();

    final replaced = regions.replaceSaved('407', '700');

    expect(replaced, isTrue);

    await coordinator.waitForPendingWrites();

    expect(writer.writes, hasLength(2));

    final json = jsonDecode(writer.writes.last.json) as Map<String, dynamic>;
    final locations = json['locations'] as List<dynamic>;

    expect(
      locations
          .cast<Map<String, dynamic>>()
          .map((location) => location['regionCode'])
          .toList(),
      ['700'],
    );
  });

  test('republishes when saved locations are reordered', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['407', '700'],
      }),
    );

    final writer = _RecordingWidgetSnapshotWriter();

    final coordinator = WidgetLocationCatalogCoordinator(
      regions,
      townDirectory,
      writer,
    );

    addTearDown(coordinator.dispose);

    coordinator.start();
    await coordinator.waitForPendingWrites();

    regions.reorderSaved(1, 0);

    await coordinator.waitForPendingWrites();

    expect(writer.writes, hasLength(2));

    final json = jsonDecode(writer.writes.last.json) as Map<String, dynamic>;
    final locations = json['locations'] as List<dynamic>;

    expect(
      locations
          .cast<Map<String, dynamic>>()
          .map((location) => location['regionCode'])
          .toList(),
      ['700', '407'],
    );
  });

  test('does not publish after disposal', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['407'],
      }),
    );

    final writer = _RecordingWidgetSnapshotWriter();

    final coordinator = WidgetLocationCatalogCoordinator(
      regions,
      townDirectory,
      writer,
    );

    coordinator.start();
    await coordinator.waitForPendingWrites();

    expect(writer.writes, hasLength(1));

    coordinator.dispose();

    regions.addSaved('700');

    await coordinator.waitForPendingWrites();

    expect(writer.writes, hasLength(1));
  });

  test('serializes writes so the newest catalog is written last', () async {
    final regions = RegionStore(
      SettingsStore.inMemory({
        'home.savedRegionCodes': ['407'],
      }),
    );

    final writer = _BlockingFirstWriteWidgetSnapshotWriter();

    final coordinator = WidgetLocationCatalogCoordinator(
      regions,
      townDirectory,
      writer,
    );

    addTearDown(coordinator.dispose);

    coordinator.start();

    // Wait until the initial catalog write has actually started.
    await writer.firstWriteStarted.future;

    expect(writer.writes, hasLength(1));

    // Change the saved locations while the first write is still blocked.
    regions.addSaved('700');

    // Give any queued async work a chance to run.
    await Future<void>.delayed(Duration.zero);

    // The second write must NOT start before the first one finishes.
    expect(writer.writes, hasLength(1));

    writer.releaseFirstWrite.complete();

    await coordinator.waitForPendingWrites();

    expect(writer.writes, hasLength(2));

    final firstJson =
        jsonDecode(writer.writes.first.json) as Map<String, dynamic>;
    final firstLocations = firstJson['locations'] as List<dynamic>;

    expect(
      firstLocations
          .cast<Map<String, dynamic>>()
          .map((location) => location['regionCode'])
          .toList(),
      ['407'],
    );

    final lastJson =
        jsonDecode(writer.writes.last.json) as Map<String, dynamic>;
    final lastLocations = lastJson['locations'] as List<dynamic>;

    expect(
      lastLocations
          .cast<Map<String, dynamic>>()
          .map((location) => location['regionCode'])
          .toList(),
      ['407', '700'],
    );
  });
}

final class _RecordingWidgetSnapshotWriter implements WidgetSnapshotWriter {
  final List<({WidgetSnapshotKind kind, String json})> writes = [];

  @override
  Future<Result<void>> write({
    required WidgetSnapshotKind kind,
    required String json,
    String? sourceIdentifier,
  }) async {
    writes.add((kind: kind, json: json));
    return const Ok(null);
  }

  @override
  Future<Result<void>> clear({required WidgetSnapshotKind kind}) async {
    return const Ok(null);
  }
}

final class _BlockingFirstWriteWidgetSnapshotWriter
    implements WidgetSnapshotWriter {
  final List<({WidgetSnapshotKind kind, String json})> writes = [];

  final Completer<void> firstWriteStarted = Completer<void>();
  final Completer<void> releaseFirstWrite = Completer<void>();

  @override
  Future<Result<void>> write({
    required WidgetSnapshotKind kind,
    required String json,
    String? sourceIdentifier,
  }) async {
    writes.add((kind: kind, json: json));

    if (writes.length == 1) {
      firstWriteStarted.complete();

      await releaseFirstWrite.future;
    }

    return const Ok(null);
  }

  @override
  Future<Result<void>> clear({required WidgetSnapshotKind kind}) async {
    return const Ok(null);
  }
}
