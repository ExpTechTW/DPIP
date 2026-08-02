import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/events/domain/event.dart';

/// Access to the DPIP disaster-event (事件) feed.
///
/// Returns a [Result] so an empty timeline is never ambiguous: "nothing has
/// happened here" and "we could not reach the server" look identical on screen
/// otherwise, and in a disaster app those must not be confused.
abstract interface class EventRepository {
  /// Events affecting the township [regionCode], newest first. Pass null for the
  /// nationwide (全國) feed.
  ///
  /// The text of each event is resolved for [regionCode], so a township's row
  /// describes that township.
  Future<Result<List<Event>>> events({String? regionCode});
}
