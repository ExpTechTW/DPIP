import 'dart:convert';

import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/platform/widget_location_catalog.dart';
import 'package:dpip/core/platform/widget_snapshot_writer.dart';
import 'package:dpip/core/settings/region_store.dart';

final class WidgetLocationCatalogCoordinator {
  WidgetLocationCatalogCoordinator(
    this._regions,
    this._directory,
    this._writer,
  );

  final RegionStore _regions;
  final TownDirectory _directory;
  final WidgetSnapshotWriter _writer;

  List<String>? _lastSavedCodes;
  Future<void> _pendingWrite = Future<void>.value();
  bool _started = false;

  void start() {
    if (_started) return;

    _started = true;
    _regions.addListener(_handleRegionChanged);

    _schedulePublish(force: true);
  }

  void dispose() {
    if (!_started) return;

    _regions.removeListener(_handleRegionChanged);
    _started = false;
  }

  Future<void> waitForPendingWrites() => _pendingWrite;

  void _handleRegionChanged() {
    _schedulePublish();
  }

  void _schedulePublish({bool force = false}) {
    final savedCodes = _regions.savedCodes;

    if (!force && _sameCodes(_lastSavedCodes, savedCodes)) {
      return;
    }

    _lastSavedCodes = List<String>.unmodifiable(savedCodes);

    final catalog = createWidgetLocationCatalog(
      savedCodes: savedCodes,
      townDirectory: _directory,
    );

    final json = jsonEncode(catalog.toJson());

    _pendingWrite = _pendingWrite.then((_) async {
      await _writer.write(kind: WidgetSnapshotKind.locationCatalog, json: json);
    });
  }

  bool _sameCodes(List<String>? previous, List<String> current) {
    if (previous == null || previous.length != current.length) {
      return false;
    }

    for (var index = 0; index < current.length; index++) {
      if (previous[index] != current[index]) {
        return false;
      }
    }

    return true;
  }
}
