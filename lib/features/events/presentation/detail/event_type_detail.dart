import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_facts.dart';
import 'package:dpip/features/events/presentation/detail/event_detail_blocks.dart';
import 'package:material_ui/material_ui.dart';

/// What one family of card types adds to the shared detail page.
///
/// The page draws everything every card has: loading and errors, the header,
/// and each report's number, kind, time, text, translation toggle and end
/// time. A family adds two things, both optional:
///
/// - [summary]: content about the whole card, under the header. It receives
///   every report, so it can show how a value moved between them.
/// - [reportBody]: content inside one report, between its text and its end
///   time. The default is the report's headline facts.
///
/// [eventTypeDetailFor] picks the family by `type`, per report: one card's
/// reports can have different types (an EEW becomes `earthquake.eew.alert`
/// from the report that upgraded it). A type it does not know gets
/// [GenericEventDetail], so a new server type still renders.
abstract base class EventTypeDetail {
  const EventTypeDetail();

  /// Card-level content under the header, or null for none.
  Widget? summary(BuildContext context, EventCardDetail detail) => null;

  /// Content inside [report], or null for none.
  Widget? reportBody(BuildContext context, EventReport report) {
    final facts = eventFactsOfReport(report);
    return facts.isEmpty ? null : EventFactsWrap(facts: facts);
  }
}

/// The detail of a type no family claims: the shared page and the report's
/// headline facts, nothing more.
final class GenericEventDetail extends EventTypeDetail {
  const GenericEventDetail();
}
