import 'package:dpip/model/history.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:dpip/widget/home/event_list_route.dart';

class HistoryTimelineItem extends StatelessWidget {
  final History history;
  final bool first;
  final bool last;
  final bool isExpired;

  const HistoryTimelineItem({
    super.key,
    required this.history,
    this.first = false,
    this.last = false,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => handleEventList(context, history),
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
                        color: isExpired ? context.colors.error : context.colors.primaryContainer,
                      ),
                      child: Icon(Symbols.rainy_rounded,
                          color: isExpired ? context.colors.onError : context.colors.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(context.i18n.time_format).format(history.time.send),
                            style: context.theme.textTheme.labelMedium?.copyWith(color: context.colors.outline),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            history.text.content["all"]!.subtitle,
                            style: context.theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              history.text.description["all"]!,
                              style: context.theme.textTheme.bodyMedium,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (shouldShowArrow(history))
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.arrow_forward_ios, color: context.colors.outline,size: 12),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
