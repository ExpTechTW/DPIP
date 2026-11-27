/// Day headings for lists grouped by Taipei calendar day.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Taipei calendar date of a UTC instant (date-only, comparable with `==`).
DateTime taipeiCalendarDay(DateTime utc) {
  final t = AppTime.taipei(utc);
  return DateTime(t.year, t.month, t.day);
}

/// One day's heading in a list grouped by Taipei calendar day: the date on
/// the left, how many items the day holds on the right, and a rule filling
/// whatever is left between them. The earthquake report list and the event
/// timeline both group this way.
class DayHeader extends StatelessWidget {
  const DayHeader({required this.day, required this.count, super.key});

  /// Calendar day at midnight Taipei, as [taipeiCalendarDay] returns it.
  final DateTime day;

  /// How many items this day holds.
  final int count;

  /// Width held back from the date for everything to its right: the two gaps, a
  /// stub of rule so the row never reads as a bare date, and room for a
  /// three-digit count.
  ///
  /// Past this the date scales down rather than pushing the count off the row.
  /// Deliberately a reserve and not a fraction of the row: a half-the-row cap
  /// shrinks a Taipei date with its weekday on any phone, which is the same
  /// disease as the flex layout it replaced. At phone width this leaves the date
  /// well over what it needs.
  static const double _trailingReserve = AppSpacing.sm * 3 + 32;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = intlDateLocale(Localizations.localeOf(context));

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            // Bounded, but *not* flexible. An Expanded here would hand the
            // date a tight half of the row: a short date then sits in a hole
            // with the rule starting at the midpoint, and a long one gets
            // scaled down to half width with empty space beside it. A
            // Flexible has the mirror flaw — Row splits the free space evenly
            // between flex children and never gives a tight child what a
            // loose sibling left over, so the rule would stop at the midpoint
            // and the count would drift in from the right edge. Keeping the
            // date rigid leaves the rule as the only flex child, which is
            // what makes it fill the real remainder.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (constraints.maxWidth - _trailingReserve).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  dayHeaderLabel(
                    day,
                    todayTaipei: taipeiCalendarDay(AppTime.utc),
                    l10n: l10n,
                    locale: locale,
                  ),
                  softWrap: false,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Divider(
                height: 1,
                thickness: 1,
                color: colors.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n.reportListDayCount(count),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The heading's date text: the localized date, with a relative hint appended
/// in parentheses when [day] is [todayTaipei] or the day before it.
///
/// The date always leads and is always the same format — `今天` alone answers
/// "which day is this" only for someone who already knows today's date, and a
/// relative-only heading changes meaning overnight while the list is open.
///
/// [todayTaipei] is a parameter rather than a read of [AppTime] so this stays a
/// pure function of its inputs: "today" is the part worth testing, and a
/// process-wide clock cannot be wound forward for one test without leaking into
/// the next.
String dayHeaderLabel(
  DateTime day, {
  required DateTime todayTaipei,
  required AppLocalizations l10n,
  required String locale,
}) {
  String? relative;
  if (day == todayTaipei) {
    relative = l10n.reportListToday;
  } else if (day == todayTaipei.subtract(const Duration(days: 1))) {
    relative = l10n.reportListYesterday;
  }
  final date = _dayFormats
      .putIfAbsent(locale, () => DateFormat.yMMMEd(locale))
      .format(day);
  return relative == null ? date : '$date ($relative)';
}

/// One [DateFormat] per locale — building one is not cheap and a scrolling list
/// rebuilds these headings constantly.
final Map<String, DateFormat> _dayFormats = {};
