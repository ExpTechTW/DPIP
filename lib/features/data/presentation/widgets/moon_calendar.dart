/// A month of moons — the coarse control for the lunar page.
///
/// The timeline beside it steps two hours at a time, which is the right
/// resolution for watching a terminator move and the wrong one for "show me
/// next month". This is the other half: a month at a glance, every day drawn
/// with its own phase, so the lunation reads as a shape rather than as a list
/// of dates.
///
/// Weekday order and month titles come from [MaterialLocalizations] rather
/// than `intl` — the app never initialises `intl`'s locale symbol data (the
/// timelines all format numerically for that reason), and Flutter already
/// carries a correctly localised calendar for every supported locale.
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/data/presentation/widgets/moon_glyph.dart';
import 'package:flutter/material.dart';

class MoonCalendar extends StatelessWidget {
  const MoonCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.today,
    required this.firstDay,
    required this.lastDay,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.phaseAt,
  });

  /// Any instant inside the month being shown (Taipei wall time).
  final DateTime month;

  /// The selected day (Taipei wall time).
  final DateTime selected;

  /// Today (Taipei wall time), outlined rather than filled.
  final DateTime today;

  /// The selectable range — the same span the timeline covers, so the two
  /// controls can never point somewhere the other cannot reach.
  final DateTime firstDay;
  final DateTime lastDay;

  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;

  /// Phase angle for a day, in radians. Passed in so the calendar stays a
  /// layout — the page owns which instant of the day it means.
  final double Function(DateTime day) phaseAt;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final materialL10n = MaterialLocalizations.of(context);

    final firstOfMonth = DateTime.utc(month.year, month.month);
    final daysInMonth = DateTime.utc(
      month.year,
      month.month + 1,
    ).difference(firstOfMonth).inDays;
    // Monday is 1 in Dart; narrowWeekdays is indexed from Sunday.
    final leading =
        (firstOfMonth.weekday % 7 - materialL10n.firstDayOfWeekIndex + 7) % 7;

    final canGoBack = !firstOfMonth
        .subtract(const Duration(days: 1))
        .isBefore(DateTime.utc(firstDay.year, firstDay.month));
    final canGoForward = !DateTime.utc(
      month.year,
      month.month + 1,
    ).isAfter(DateTime.utc(lastDay.year, lastDay.month));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: canGoBack
                  ? () => onMonthChanged(
                      DateTime.utc(month.year, month.month - 1),
                    )
                  : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: materialL10n.previousMonthTooltip,
            ),
            Expanded(
              child: Text(
                materialL10n.formatMonthYear(firstOfMonth),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: canGoForward
                  ? () => onMonthChanged(
                      DateTime.utc(month.year, month.month + 1),
                    )
                  : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: materialL10n.nextMonthTooltip,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  materialL10n
                      .narrowWeekdays[(materialL10n.firstDayOfWeekIndex + i) %
                      7],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.78,
          ),
          itemCount: leading + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leading) return const SizedBox.shrink();
            final day = DateTime.utc(
              month.year,
              month.month,
              index - leading + 1,
            );
            final inRange =
                !day.isBefore(
                  DateTime.utc(firstDay.year, firstDay.month, firstDay.day),
                ) &&
                !day.isAfter(
                  DateTime.utc(lastDay.year, lastDay.month, lastDay.day),
                );
            return _DayCell(
              day: day,
              angle: phaseAt(day),
              isSelected: _sameDay(day, selected),
              isToday: _sameDay(day, today),
              onTap: inRange ? () => onDaySelected(day) : null,
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.angle,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final double angle;
  final bool isSelected;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onTap != null;
    final label = isSelected ? colors.onPrimary : colors.onSurface;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : null,
          borderRadius: AppRadius.small,
          border: isToday && !isSelected
              ? Border.all(color: colors.primary, width: 1.5)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: enabled ? 1 : 0.3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MoonGlyph(
                  angle: angle,
                  size: 20,
                  lit: isSelected ? colors.onPrimary : const Color(0xFFE8E3DA),
                  dark: isSelected
                      ? colors.primary.withValues(alpha: 0.45)
                      : colors.surfaceContainerHighest,
                ),
                const SizedBox(height: 2),
                Text(
                  // l10n-ignore: day-of-month number
                  '${day.day}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: label,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
