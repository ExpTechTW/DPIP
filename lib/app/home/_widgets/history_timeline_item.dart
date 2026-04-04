/// Timeline item widget for a single history event entry.
library;

import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/list_icon.dart';
import 'package:dpip/widgets/home/event_list_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Renders a single [History] event as a card within the home timeline.
///
/// Tapping the card opens the detail view when the event supports it.
/// Expired events are rendered with reduced opacity to indicate they have
/// ended.
class HistoryTimelineItem extends StatelessWidget {
  /// The history event to display.
  final History history;

  /// Whether this is the first item in the timeline group.
  final bool first;

  /// Whether this is the last item in the timeline group.
  final bool last;

  /// Whether the event has already expired.
  final bool expired;

  /// Creates a [HistoryTimelineItem] for the given [history] event.
  const HistoryTimelineItem({
    super.key,
    required this.history,
    this.first = false,
    this.last = false,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) {
    final hasDetail = shouldShowArrow(history);

    return Container(
      margin: const .fromLTRB(16, 4, 16, 4),
      child: Stack(
        clipBehavior: .none,
        children: [
          Positioned(
            left: 20.5,
            top: -4,
            bottom: last ? null : -4,
            width: 1,
            child: Container(
              height: last ? 8 : null,
              color: context.colors.outlineVariant,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceContainer,
              borderRadius: .circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: hasDetail
                    ? () => handleEventList(context, history)
                    : null,
                borderRadius: .circular(12),
                child: Padding(
                  padding: const .all(12),
                  child: Row(
                    crossAxisAlignment: .start,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          shape: .circle,
                          color: expired
                              ? context.colors.surfaceContainerHighest
                              : context.colors.primaryContainer,
                        ),
                        child: Icon(
                          getListIcon(history.icon),
                          size: 20,
                          color: expired
                              ? context.colors.outline
                              : context.colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              DateFormat('HH:mm:ss').format(
                                history.time.send,
                              ),
                              style: context.texts.labelSmall?.copyWith(
                                color: context.colors.onSurfaceVariant
                                    .withValues(
                                      alpha: expired ? 0.6 : 1,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              history.text.content['all']!.subtitle,
                              style: context.texts.titleSmall?.copyWith(
                                color: context.colors.onSurface.withValues(
                                  alpha: expired ? 0.6 : 1,
                                ),
                                fontWeight: .w600,
                              ),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              history.text.description['all']!,
                              style: context.texts.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant
                                    .withValues(
                                      alpha: expired ? 0.6 : 1,
                                    ),
                              ),
                              maxLines: 2,
                              overflow: .ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (hasDetail)
                        Padding(
                          padding: const .only(left: 8),
                          child: Icon(
                            Symbols.chevron_right_rounded,
                            size: 20,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
