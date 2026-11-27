/// The collapsed sheet lists the events for the area the user is on. Showing
/// the national feed when GPS has no town, or keeping a failed fetch's old
/// list, would tell them a disaster is happening where they are when it is not.
library;

import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_hazard.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../events/presentation/event_card_fixtures.dart';

final _quake = eventCard(
  id: 7,
  hazard: EventHazard.earthquake,
  type: 'earthquake.eew',
  title: 'Quake',
  subtitle: 'Felt widely',
  send: AppTime.utc.subtract(const Duration(minutes: 5)),
  expires: AppTime.utc.add(const Duration(days: 1)),
);

class _Events implements EventRepository {
  _Events(this.active);

  Result<List<EventCard>> active;
  Completer<void>? gate;
  String? lastCode;
  int calls = 0;

  @override
  Future<Result<List<EventCard>>> activeEvents({String? regionCode}) async {
    calls++;
    lastCode = regionCode;
    final gate = this.gate;
    if (gate != null) await gate.future;
    return active;
  }

  @override
  Future<Result<List<EventCard>>> events({String? regionCode}) async =>
      const Ok([]);

  @override
  Future<Result<EventCardDetail>> detail({
    required int id,
    String? regionCode,
  }) async => const Err(NetworkFailure('unused'));
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

  test('only cards in force now are listed, newest first', () async {
    final now = AppTime.utc;
    final regions = RegionStore(SettingsStore.inMemory())..select(0);
    final repo = _Events(
      Ok([
        // The server's order: ascending id.
        eventCard(
          id: 1,
          title: 'Older',
          send: now.subtract(const Duration(hours: 3)),
          expires: now.add(const Duration(hours: 1)),
        ),
        eventCard(
          id: 2,
          title: 'Ended',
          send: now.subtract(const Duration(hours: 2)),
          expires: now.subtract(const Duration(minutes: 1)),
        ),
        eventCard(
          id: 3,
          title: 'Open-ended',
          send: now.subtract(const Duration(hours: 1)),
          expiresOpen: true,
        ),
        eventCard(
          id: 4,
          title: 'Cancelled',
          kind: EventReportKind.cancel,
          send: now.subtract(const Duration(minutes: 10)),
          expires: now.subtract(const Duration(minutes: 10)),
        ),
      ]),
    );
    final controller = HomeActiveEventsController(repo, regions);
    await pumpEventQueue();
    expect(controller.events.map((card) => card.title), [
      'Open-ended',
      'Older',
    ]);
    controller.dispose();
  });
}
