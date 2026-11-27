import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/events/domain/event_card.dart';

/// Access to the DPIP disaster-event cards (事件卡片).
///
/// Returns a [Result] so an empty timeline is never ambiguous: "nothing has
/// happened here" and "we could not reach the server" look identical on screen
/// otherwise, and in a disaster app those must not be confused.
///
/// The text of every card is in the app's current language where the server
/// has a translation; a card without one comes back in the original Taiwan
/// Traditional text, with its own `lang` saying so.
///
/// [regionCode] is a township code. One that is not a decimal integer is
/// treated as absent: the lists fall back to the nationwide feed, and [detail]
/// to the nationwide text.
abstract interface class EventRepository {
  /// Cards in force or ended within the last 3 days, for the township
  /// [regionCode], in the server's order (ascending card id, so the card
  /// opened most recently is last). Pass null for the nationwide (全國) feed.
  /// Used by the Events tab.
  ///
  /// May be a saved copy when the server cannot be reached; [Ok.stale] then
  /// says so.
  Future<Result<List<EventCard>>> events({String? regionCode});

  /// Cards in force now for the township [regionCode], in the same order as
  /// [events]. Pass null for the nationwide feed. Used by the home sheet when
  /// collapsed. Never a saved copy.
  Future<Result<List<EventCard>>> activeEvents({String? regionCode});

  /// Every report of card [id], first to latest, with the per-township text
  /// for [regionCode]; the nationwide text when [regionCode] is null.
  ///
  /// A card that does not exist is an `Err` carrying a `NotFoundFailure`.
  Future<Result<EventCardDetail>> detail({required int id, String? regionCode});
}
