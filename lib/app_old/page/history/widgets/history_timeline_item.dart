import 'package:dpip/api/model/history.dart';
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

    return InkWell(
      onTap: hasDetail ? () => handleEventList(context, history) : null,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: first ? 42 : 0,
                    bottom: last ? null : 0,
                    height: last ? 42 : null,
                    width: 1,
                    child: Container(color: context.colors.outlineVariant),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: expired ? context.colors.surface : context.colors.primaryContainer,
                        border: expired ? Border.all(color: context.colors.outlineVariant) : null,
                      ),
                      child: Icon(
                        ListIcons.getListIcon(history.icon),
                        color: expired ? context.colors.outline : context.colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(context.i18n.time_format).format(history.time.send),
                      style: context.theme.textTheme.labelMedium?.copyWith(
                        color: context.colors.outline.withOpacity(expired ? 0.6 : 1),
                      ),
                    ),
                    Text(
                      history.text.content["all"]!.subtitle,
                      style: context.theme.textTheme.titleMedium?.copyWith(
                        color: context.colors.onSurface.withOpacity(expired ? 0.6 : 1),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      history.text.description["all"]!,
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: context.colors.onSurface.withOpacity(expired ? 0.6 : 1),
                      ),
                      textAlign: TextAlign.justify,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (hasDetail)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Symbols.chevron_right_rounded, color: context.colors.outline),
              ),
          ],
        ),
      ),
    );
  }
}
