import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/list_icon.dart';
import 'package:dpip/widgets/home/event_list_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class HistoryTimelineItem extends StatelessWidget {
  final History history;
  final bool first;
  final bool last;
  final bool expired;

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
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Stack(
        clipBehavior: Clip.none,
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: hasDetail
                    ? () => handleEventList(context, history)
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('HH:mm:ss').format(history.time.send),
                              style: context.theme.textTheme.labelSmall
                                  ?.copyWith(
                                    color: context.colors.onSurfaceVariant
                                        .withValues(
                                          alpha: expired ? 0.6 : 1,
                                        ),
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              history.text.content['all']!.subtitle,
                              style: context.theme.textTheme.titleSmall
                                  ?.copyWith(
                                    color: context.colors.onSurface.withValues(
                                      alpha: expired ? 0.6 : 1,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              history.text.description['all']!,
                              style: context.theme.textTheme.bodySmall
                                  ?.copyWith(
                                    color: context.colors.onSurfaceVariant
                                        .withValues(
                                          alpha: expired ? 0.6 : 1,
                                        ),
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (hasDetail)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
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
