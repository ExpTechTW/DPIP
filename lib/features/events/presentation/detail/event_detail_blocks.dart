import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/features/events/domain/event_facts.dart';
import 'package:dpip/features/events/presentation/widgets/event_fact_chip.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Building blocks the type families share, so every family's content looks
/// like one page.

/// A report's headline facts as a wrap of chips.
class EventFactsWrap extends StatelessWidget {
  const EventFactsWrap({super.key, required this.facts});

  final List<EventFact> facts;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [for (final fact in facts) EventFactChip(fact: fact)],
  );
}

/// A titled block of card-level content, drawn like a report so the page
/// reads as one column of cards.
class EventDetailSection extends StatelessWidget {
  const EventDetailSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadius.medium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

/// One line of an [EventDetailRows] list.
final class EventDetailRow {
  const EventDetailRow({
    required this.label,
    required this.value,
    this.leading,
  });

  /// What the line is about, for example a station or a township.
  final String label;

  /// Its reading, already formatted with its unit.
  final String value;

  /// An optional mark before [label], for example an intensity badge.
  final Widget? leading;
}

/// A label–value list that shows its first [initialCount] lines and offers
/// the rest behind a toggle. Callers order the rows; the most important
/// first, so the collapsed list is the useful part.
class EventDetailRows extends StatefulWidget {
  const EventDetailRows({super.key, required this.rows, this.initialCount = 8});

  final List<EventDetailRow> rows;
  final int initialCount;

  @override
  State<EventDetailRows> createState() => _EventDetailRowsState();
}

class _EventDetailRowsState extends State<EventDetailRows> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final rows = widget.rows;
    final collapsible = rows.length > widget.initialCount;
    final shown = _expanded || !collapsible
        ? rows
        : rows.sublist(0, widget.initialCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                if (row.leading != null) ...[
                  row.leading!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  flex: 2,
                  child: Text(row.label, style: theme.textTheme.bodyMedium),
                ),
                const SizedBox(width: AppSpacing.sm),
                // The value wraps rather than overflowing: a whole city's
                // townships in one line is a long string.
                Expanded(
                  flex: 3,
                  child: Text(
                    row.value,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (collapsible)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded
                    ? l10n.eventDetailShowLess
                    : l10n.eventDetailShowAll(rows.length),
              ),
            ),
          ),
      ],
    );
  }
}

/// An [EventDetailSection] titled with the affected areas, listing the
/// townships of [codes] one city per row: the city as the label and its
/// townships, in [codes] order, as the value.
///
/// Cities are in the order their first township appears in [codes]; a code
/// listed twice counts once. A code the township directory does not know is
/// left out. Null when no [TownDirectory] is provided above [context] or none
/// of [codes] resolves to a township.
Widget? eventAffectedAreasSection(BuildContext context, List<int> codes) {
  if (codes.isEmpty) return null;
  // Nullable, so a tree without the directory reads null instead of
  // throwing; the app provides it at the root.
  final directory = context.read<TownDirectory?>();
  if (directory == null) return null;

  final townsByCity = <String, List<Town>>{};
  final seen = <int>{};
  for (final code in codes) {
    if (!seen.add(code)) continue;
    final town = directory.byCode('$code');
    if (town == null) continue;
    (townsByCity[town.cityName] ??= []).add(town);
  }
  if (townsByCity.isEmpty) return null;

  final separator = _listSeparator(context);
  return EventDetailSection(
    title: AppLocalizations.of(context).eventDetailAffectedAreas,
    child: EventDetailRows(
      rows: [
        for (final MapEntry(key: city, value: towns) in townsByCity.entries)
          EventDetailRow(
            label: city,
            value: towns.map((town) => town.townName).join(separator),
          ),
      ],
    ),
  );
}

/// What joins township names in the current locale: the ideographic comma in
/// Chinese and Japanese, a comma and a space elsewhere.
String _listSeparator(
  BuildContext context,
) => switch (Localizations.maybeLocaleOf(context)?.languageCode) {
  // l10n-ignore: the enumeration comma joining place names, not display text.
  'zh' || 'ja' => '、',
  _ => ', ',
};
