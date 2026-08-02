import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/events/data/event_api.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';

/// [EventRepository] backed by [EventApi], mapping transport/decode errors to
/// typed failures via [guardResult] and owning the JSON → [Event] mapping.
class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl(this._api);

  final EventApi _api;

  @override
  Future<Result<List<Event>>> events({String? regionCode}) =>
      guardResult(() async {
        final raw = regionCode == null
            ? await _api.getHistoryList()
            : await _api.getHistoryRegion(regionCode);
        return parseEvents(raw, regionCode: regionCode);
      });

  /// Maps the wire list to [Event]s, newest first.
  ///
  /// Unmappable entries are skipped rather than failing the whole feed: one
  /// malformed record from a legacy v1 endpoint must not blank out every other
  /// hazard the user needs to see. Pure and public so the mapping is testable
  /// without the network.
  static List<Event> parseEvents(List<dynamic> raw, {String? regionCode}) {
    final events = <Event>[
      for (final item in raw)
        if (item is Map)
          ?Event.fromJson(item.cast<String, dynamic>(), regionCode: regionCode),
    ];
    events.sort((a, b) => b.time.compareTo(a.time));
    return events;
  }
}
