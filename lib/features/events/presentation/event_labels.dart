/// The words and times an event card is shown with: its state, the kind of
/// each report, and when it was sent.
library;

import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_hazard.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// Where a card stands, as one label.
enum EventCardStatus {
  /// The latest report is a cancellation: the issuer withdrew the event.
  cancelled,

  /// In force with no end time yet (a tsunami warning before it is lifted).
  openEnded,

  /// In force until a known end time.
  active,

  /// Past its end time.
  ended;

  /// The state of a card whose latest report is of [kind], where [activeNow]
  /// says whether its end time is still ahead.
  ///
  /// A cancellation wins over everything: its `expires` is the moment it was
  /// withdrawn, and saying "ended" would hide that it was called off. An
  /// open end time comes next, because such a card is in force however long
  /// ago it was sent; only then is the end time compared with now.
  static EventCardStatus of({
    required EventReportKind kind,
    required bool expiresOpen,
    required bool activeNow,
  }) {
    if (kind == EventReportKind.cancel) return EventCardStatus.cancelled;
    if (expiresOpen) return EventCardStatus.openEnded;
    if (activeNow) return EventCardStatus.active;
    return EventCardStatus.ended;
  }

  /// The state [card] — a list card or a detail report — shows at [nowUtc],
  /// or `null` when it shows none.
  ///
  /// A card with no lifetime (see [showsLifetime]) shows no state, except a
  /// cancellation: a withdrawn early warning still says so.
  static EventCardStatus? ofCard(EventCard card, DateTime nowUtc) {
    if (!showsLifetime(card) && card.kind != EventReportKind.cancel) {
      return null;
    }
    return of(
      kind: card.kind,
      expiresOpen: card.expiresOpen,
      activeNow: card.isActiveAt(nowUtc),
    );
  }

  /// Whether [card] shows how long it is in force: its state and its end
  /// time.
  ///
  /// An earthquake has no lifetime a reader can act on — it is over by the
  /// time it is reported, and its end time only bounds how long the server
  /// lists it — so "in effect", "ended" and "no end time yet" would say
  /// nothing true about it. The same goes for the two tsunami types that only
  /// inform: `tsunami_note`, the sea-level remark on an earthquake report, and
  /// `tsunami.info`, whose end time is its last report plus a day, with
  /// nothing ever lifted. A tsunami warning keeps them: one in force and one
  /// lifted are different things.
  static bool showsLifetime(EventCard card) =>
      card.hazard != EventHazard.earthquake &&
      card.type != 'tsunami_note' &&
      card.type != 'tsunami.info';

  /// The state's label.
  String label(AppLocalizations l10n) => switch (this) {
    EventCardStatus.cancelled => l10n.eventStatusCancelled,
    EventCardStatus.openEnded => l10n.eventStatusOpenEnded,
    EventCardStatus.active => l10n.eventStatusActive,
    EventCardStatus.ended => l10n.eventStatusEnded,
  };
}

/// The label of a report's kind.
String eventReportKindLabel(EventReportKind kind, AppLocalizations l10n) =>
    switch (kind) {
      EventReportKind.issue => l10n.eventReportKindIssue,
      EventReportKind.update => l10n.eventReportKindUpdate,
      EventReportKind.correct => l10n.eventReportKindCorrect,
      EventReportKind.cancel => l10n.eventReportKindCancel,
      EventReportKind.unknown => l10n.eventReportKindUnknown,
    };

/// [instant] in Taipei wall time: `HH:mm` when it falls on the same Taipei
/// day as [nowUtc], otherwise the localized month and day before it.
///
/// Every card the server sends is either in force or ended within the last
/// three days, and a long-running warning can be days old, so a bare clock
/// time would be ambiguous. Taipei time, not the device's zone: the issuing
/// agencies and the rest of the app speak in it. [nowUtc] is a parameter so
/// this stays a pure function; callers pass [AppTime.utc]. [locale] must
/// already be `DateFormat`-safe (`intlDateLocale`).
String eventTimeLabel(
  DateTime instant, {
  required DateTime nowUtc,
  required String locale,
}) {
  final taipei = AppTime.taipei(instant);
  final today = AppTime.taipei(nowUtc);
  final sameDay =
      taipei.year == today.year &&
      taipei.month == today.month &&
      taipei.day == today.day;
  final clock = _clockFormat.format(taipei);
  if (sameDay) return clock;
  final day = _dayFormats.putIfAbsent(locale, () => DateFormat.Md(locale));
  return '${day.format(taipei)} $clock';
}

/// [instant] in Taipei wall time with the year, for a field that names one
/// exact moment (a report's end time on the detail page).
String eventDateTimeLabel(DateTime instant, {required String locale}) {
  final taipei = AppTime.taipei(instant);
  final day = _fullDayFormats.putIfAbsent(locale, () => DateFormat.yMd(locale));
  return '${day.format(taipei)} ${_clockFormat.format(taipei)}';
}

final DateFormat _clockFormat = DateFormat('HH:mm');

/// One [DateFormat] per locale: building one is not cheap and a scrolling
/// list formats a time on every row.
final Map<String, DateFormat> _dayFormats = {};
final Map<String, DateFormat> _fullDayFormats = {};
