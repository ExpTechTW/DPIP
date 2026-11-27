import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/events/presentation/widgets/event_card_tile.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// A vertical timeline of event cards, connected by a line so the feed reads
/// as one continuous thread (a hazard badge per card, a line between them).
///
/// Fed by [EventRepository] for one area: [regionCode] is the township being
/// viewed, or null for 全國. Rendered through [AsyncView] so a failed fetch shows
/// an error with retry rather than an empty thread — "nothing happened here" and
/// "we could not reach the server" must never look the same in a disaster app.
///
/// Pulling the list down fetches it again.
///
/// The server lists cards by ascending id; this shows them by [EventCard.send],
/// newest first (see [newestFirst]).
class EventTimeline extends StatelessWidget {
  const EventTimeline({super.key, this.regionCode, this.refreshSignal});

  /// The township whose events to show; null for the nationwide feed.
  final String? regionCode;

  /// Fires when the page reappears (tab entry / app resume) — re-fetches.
  final Listenable? refreshSignal;

  /// [cards] by send time, newest first; cards sent at the same instant keep
  /// the newer card (the larger id) first.
  static List<EventCard> newestFirst(List<EventCard> cards) {
    final sorted = [...cards];
    sorted.sort((a, b) {
      final bySend = b.send.compareTo(a.send);
      return bySend != 0 ? bySend : b.id.compareTo(a.id);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<EventRepository>();
    return AsyncView<List<EventCard>>(
      // Keyed by area so switching pages refetches for the new township.
      key: ValueKey(regionCode),
      future: () => repository
          .events(regionCode: regionCode)
          .then((result) => result.map(newestFirst)),
      isEmpty: (cards) => cards.isEmpty,
      refreshSignal: refreshSignal,
      pullToRefresh: true,
      builder: (context, cards) => ListView.builder(
        // A short feed must still be pullable.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          // Clear the bottom nav (the shell body extends behind it).
          AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) => _TimelineEntry(
          card: cards[index],
          regionCode: regionCode,
          isFirst: index == 0,
          isLast: index == cards.length - 1,
        ),
      ),
    );
  }
}

/// One card on the thread: the rail drawn behind an [EventCardTile].
///
/// The rail is positioned against the Stack, so it takes the tile's height
/// without an IntrinsicHeight pass; the tile's badge is opaque and covers the
/// line where the two cross.
class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.card,
    required this.regionCode,
    required this.isFirst,
    required this.isLast,
  });

  final EventCard card;
  final String? regionCode;
  final bool isFirst;
  final bool isLast;

  static const EdgeInsets _padding = EdgeInsets.only(
    top: AppSpacing.sm,
    bottom: AppSpacing.lg,
  );

  @override
  Widget build(BuildContext context) {
    const badge = EventCardTile.badgeSize;
    return Stack(
      children: [
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: badge,
          child: _Rail(
            // The line meets the badge's centre, so the first and last
            // cards end the thread there.
            stub: _padding.top + badge / 2,
            isFirst: isFirst,
            isLast: isLast,
          ),
        ),
        EventCardTile(card: card, regionCode: regionCode, padding: _padding),
      ],
    );
  }
}

/// The connecting line of the thread, start-side so it mirrors under RTL.
/// [isFirst] and [isLast] trim it at the ends, so the thread does not look
/// endless.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.stub,
    required this.isFirst,
    required this.isLast,
  });

  /// Height from the top of the entry to the badge's centre.
  final double stub;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outlineVariant;
    return Column(
      children: [
        Container(
          width: 2,
          height: stub,
          color: isFirst ? Colors.transparent : line,
        ),
        Expanded(
          child: Container(width: 2, color: isLast ? Colors.transparent : line),
        ),
      ],
    );
  }
}
