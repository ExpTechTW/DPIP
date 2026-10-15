/// Nationwide and a township are different requests. Serving one as the other
/// tells a user about a warning that does not cover them, or hides one that
/// does.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/events/data/event_api.dart';
import 'package:dpip/features/events/data/event_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api implements EventApi {
  String? historyRegion;
  String? realtimeRegion;
  var historyAll = false;
  var realtimeAll = false;

  Staleness? stale;

  @override
  Future<Fetched<List<dynamic>>> getHistoryList() async {
    historyAll = true;
    return (data: [_event('h-all', 20), 'skip'], stale: stale);
  }

  @override
  Future<Fetched<List<dynamic>>> getHistoryRegion(String region) async {
    historyRegion = region;
    return (data: <dynamic>[_event('h-town', 10)], stale: stale);
  }

  @override
  Future<List<dynamic>> getRealtimeList() async {
    realtimeAll = true;
    return [_event('r-all', 30)];
  }

  @override
  Future<List<dynamic>> getRealtimeRegion(String region) async {
    realtimeRegion = region;
    return [_event('r-town', 40)];
  }
}

Map<String, dynamic> _event(String id, int send) => {
  'id': id,
  'status': 1,
  'type': 'heavy-rain',
  'author': 'cwa',
  'time': {'send': send},
  'text': {
    'content': {
      'all': {'title': '大雨', 'subtitle': ''},
    },
    'description': {'all': '全國'},
  },
};

void main() {
  test(
    'history and active each have a nationwide and a township request',
    () async {
      final api = _Api();
      final repo = EventRepositoryImpl(api);

      final history = await repo.events();
      final townHistory = await repo.events(regionCode: '710');
      final active = await repo.activeEvents();
      final townActive = await repo.activeEvents(regionCode: '237');

      expect(api.historyAll, isTrue);
      expect(api.historyRegion, '710');
      expect(api.realtimeAll, isTrue);
      expect(api.realtimeRegion, '237');
      expect(history.valueOrNull!.single.id, 'h-all');
      expect(townHistory.valueOrNull!.single.id, 'h-town');
      expect(active.valueOrNull!.single.id, 'r-all');
      expect(townActive.valueOrNull!.single.id, 'r-town');
    },
  );

  test(
    'saved history keeps its marker; active events never have one',
    () async {
      final since = DateTime.utc(2026, 10, 16, 1);
      final api = _Api()
        ..stale = Staleness(
          failure: const NetworkFailure('down'),
          since: since,
        );
      final repo = EventRepositoryImpl(api);

      final history = await repo.events(regionCode: '710');
      final active = await repo.activeEvents();

      expect((history as Ok).stale?.since, since);
      expect((active as Ok).stale, isNull);
    },
  );
}
