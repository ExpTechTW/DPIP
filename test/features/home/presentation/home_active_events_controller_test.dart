/// The collapsed sheet lists the events for the area the user is on. Showing
/// the national feed when GPS has no town, or keeping a failed fetch's old
/// list, would tell them a disaster is happening where they are when it is not.
library;

import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:flutter_test/flutter_test.dart';

final _quake = Event(
  id: 'e1',
  type: EventType.earthquake,
  time: DateTime.utc(2026, 1, 1),
  title: 'Quake',
  description: 'Felt widely',
);

class _Events implements EventRepository {
  _Events(this.active);

  Result<List<Event>> active;
  Completer<void>? gate;
  String? lastCode;
  int calls = 0;

  @override
  Future<Result<List<Event>>> activeEvents({String? regionCode}) async {
    calls++;
    lastCode = regionCode;
    final gate = this.gate;
    if (gate != null) await gate.future;
    return active;
  }

  @override
  Future<Result<List<Event>>> events({String? regionCode}) async =>
      const Ok([]);
}

void main() {
  test('nationwide loads, a missing GPS town clears, and a failure empties the list', () async {
    final regions = RegionStore(SettingsStore.inMemory())..select(0);
    final repo = _Events(Ok([_quake]));
    final controller = HomeActiveEventsController(repo, regions);
    await pumpEventQueue();
    expect(repo.lastCode, isNull);
    expect(controller.events.single.title, 'Quake');
    expect(controller.loading, isFalse);

    regions.setCurrentCode(null);
    regions.select(1);
    await pumpEventQueue();
    expect(controller.events, isEmpty);
    expect(controller.failure, isNull);

    regions.select(0);
    repo.active = const Err(NetworkFailure('down'));
    await controller.refresh();
    expect(controller.failure, isA<NetworkFailure>());
    expect(controller.events, isEmpty);
    controller.dispose();
  });

  test('a response for a region the user has left is ignored', () async {
    final regions = RegionStore(SettingsStore.inMemory())..select(0);
    final gate = Completer<void>();
    final repo = _Events(Ok([_quake]))..gate = gate;
    final controller = HomeActiveEventsController(repo, regions);
    expect(controller.loading, isTrue);
    regions.setCurrentCode(null);
    regions.select(1);
    gate.complete();
    await pumpEventQueue();
    expect(controller.events, isEmpty);
    expect(repo.calls, 1);
    controller.dispose();
  });
}
