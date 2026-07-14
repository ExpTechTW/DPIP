import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A vertical timeline of disaster events, connected by a line so the feed reads
/// as one continuous thread (icon dot per event + line between them).
///
/// Placeholder events for now; swap [_placeholderEvents] for the history API's
/// list — each row is driven purely by an [Event], so nothing else changes.
///
/// l10n-ignore-file: [_placeholderEvents] below is throwaway mock data (fixed
/// titles + fully dynamic CJK sentences that could never be ARB keys). It is
/// deleted the moment the events history API is wired, so localizing it is
/// wasted effort. Real event labels will be localized at that point.
class EventTimeline extends StatelessWidget {
  const EventTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        // Clear the bottom nav (the shell body extends behind it).
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: _placeholderEvents.length,
      itemBuilder: (context, index) => _EventTile(
        event: _placeholderEvents[index],
        isFirst: index == 0,
        isLast: index == _placeholderEvents.length - 1,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Connector(
            icon: _iconFor(event.type),
            isFirst: isFirst,
            isLast: isLast,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('HH:mm').format(event.time),
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
    );
  }
}

/// The left rail: a connecting line with an icon dot, so consecutive events read
/// as one thread ([isFirst]/[isLast] trim the line at the ends).
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

IconData _iconFor(EventType type) => switch (type) {
  EventType.earthquake => Icons.crisis_alert,
  EventType.report => Icons.description_outlined,
  EventType.intensity => Icons.graphic_eq,
  EventType.thunderstorm => Icons.thunderstorm_outlined,
  EventType.heavyRain => Icons.water_drop_outlined,
  EventType.weatherWarning => Icons.warning_amber_rounded,
  EventType.tsunami => Icons.tsunami_outlined,
  EventType.other => Icons.notifications_outlined,
};

/// Placeholder feed until the history API is wired.
final List<Event> _placeholderEvents = [
  Event(
    id: '1',
    type: EventType.earthquake,
    time: DateTime(2026, 7, 13, 5, 28),
    title: '地震報告',
    description: '臺南市 楠西區 發生規模 5.2 地震,最大震度 4 級。',
  ),
  Event(
    id: '2',
    type: EventType.weatherWarning,
    time: DateTime(2026, 7, 13, 4, 10),
    title: '大豪雨特報',
    description: '臺南市 歸仁區 發布大豪雨特報,慎防坍方與積淹水。',
  ),
  Event(
    id: '3',
    type: EventType.thunderstorm,
    time: DateTime(2026, 7, 13, 3, 45),
    title: '雷雨即時訊息',
    description: '山區有局部大雷雨,請留意雷擊與強陣風。',
  ),
  Event(
    id: '4',
    type: EventType.intensity,
    time: DateTime(2026, 7, 13, 2, 12),
    title: '震度速報',
    description: '花蓮縣 實測最大震度 3 級。',
  ),
  Event(
    id: '5',
    type: EventType.report,
    time: DateTime(2026, 7, 12, 23, 50),
    title: '地震報告',
    description: '宜蘭縣 近海 發生規模 4.1 地震。',
  ),
  Event(
    id: '6',
    type: EventType.tsunami,
    time: DateTime(2026, 7, 12, 21, 5),
    title: '海嘯消息',
    description: '太平洋發生地震,經研判對臺灣無影響。',
  ),
];
