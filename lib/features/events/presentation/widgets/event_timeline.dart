import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:dpip/shared/widgets/event_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// A vertical timeline of disaster events, connected by a line so the feed reads
/// as one continuous thread (icon dot per event + line between them).
///
/// Fed by [EventRepository] for one area: [regionCode] is the township being
/// viewed, or null for 全國. Rendered through [AsyncView] so a failed fetch shows
/// an error with retry rather than an empty thread — "nothing happened here" and
/// "we could not reach the server" must never look the same in a disaster app.
class EventTimeline extends StatelessWidget {
  const EventTimeline({super.key, this.regionCode, this.refreshSignal});

  /// The township whose events to show; null for the nationwide feed.
  final String? regionCode;

  /// Fires when the page reappears (tab entry / app resume) — re-fetches.
  final Listenable? refreshSignal;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<EventRepository>();
    return AsyncView<List<Event>>(
      // Keyed by area so switching pages refetches for the new township.
      key: ValueKey(regionCode),
      future: () => repository.events(regionCode: regionCode),
      isEmpty: (events) => events.isEmpty,
      refreshSignal: refreshSignal,
      builder: (context, events) => ListView.builder(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          // Clear the bottom nav (the shell body extends behind it).
          AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: events.length,
        itemBuilder: (context, index) => _EventTile(
          event: events[index],
          isFirst: index == 0,
          isLast: index == events.length - 1,
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  final Event event;
  final bool isFirst;
  final bool isLast;

  static final DateFormat _clockFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Stack(
      children: [
        // The rail spans the whole tile, but the tile's height comes from the
        // text beside it — or the dot, whichever is taller — which a Row can
        // only hand back through an IntrinsicHeight, i.e. a speculative pass
        // that re-measures all three Texts on every layout of the tile, not
        // just on inflation: a width or text-scale change re-runs it too.
        // Positioning the connector against the Stack gets it the same tight
        // height for nothing: the Row below sizes the Stack, the connector then
        // fills it.
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: _Connector._dotSize,
          child: _Connector(
            icon: eventTypeIcon(event.type.iconKey),
            isFirst: isFirst,
            isLast: isLast,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Holds open the column the connector is positioned over, plus the
            // gap after it. Its height is the connector's own: a tile with very
            // little text must still be tall enough for the dot, which is what
            // IntrinsicHeight used to guarantee.
            const SizedBox(
              width: _Connector._dotSize + AppSpacing.md,
              height: _Connector._minHeight,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _clockFormat.format(event.time),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      event.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      event.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The leading rail — start-side, so it mirrors to the right under RTL: a
/// connecting line with an icon dot, so consecutive events read as one thread
/// ([isFirst]/[isLast] trim the line at the ends).
///
/// [_EventTile] positions this to the full height of its tile, so the trailing
/// [Expanded] line can fill whatever is left below the dot.
class _Connector extends StatelessWidget {
  const _Connector({
    required this.icon,
    required this.isFirst,
    required this.isLast,
  });

  final IconData icon;
  final bool isFirst;
  final bool isLast;

  static const double _dotSize = 36;

  /// Stub plus dot — the shortest this can draw itself. [_EventTile] reserves
  /// it in its Row so the tile is never too short to hold the dot.
  static const double _minHeight = AppSpacing.sm + _dotSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final line = colors.outlineVariant;
    return SizedBox(
      width: _dotSize,
      child: Column(
        children: [
          Container(
            width: 2,
            height: AppSpacing.sm,
            color: isFirst ? Colors.transparent : line,
          ),
          Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: colors.onPrimaryContainer),
          ),
          Expanded(
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : line,
            ),
          ),
        ],
      ),
    );
  }
}
