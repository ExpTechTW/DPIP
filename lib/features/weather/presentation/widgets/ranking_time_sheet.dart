/// Snapshot picker shared by every observation ranking tab.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One choice from [showRankingTimeSheet].
///
/// [second] is `null` for the newest snapshot, which is fetched through
/// `latest()` instead of being pinned to a timestamp — that is what keeps the
/// default list live across a refresh. A dismissed sheet returns `null`, so the
/// two cases cannot be confused.
typedef RankingTimeChoice = ({int? second});

final DateFormat _timeFormat = DateFormat('MM/dd HH:mm');

/// Taiwan wall-clock label for a snapshot second (`10/27 03:00`).
String rankingTimeLabel(int unixSeconds) => _timeFormat.format(
  AppTime.taipei(
    DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000, isUtc: true),
  ),
);

/// Shows the snapshot picker and resolves to the chosen time.
///
/// [times] are the Unix seconds the history endpoint lists, ascending. Only
/// times the API still serves are offered: the v5 snapshots are immutable and
/// addressed by their exact second, so a picked time is always fetchable.
/// [latest] is the snapshot the page is showing for "newest" (the history list
/// usually ends there), and [selected] is the page's current choice — `null`
/// when it is on the newest snapshot.
Future<RankingTimeChoice?> showRankingTimeSheet({
  required BuildContext context,
  required List<int> times,
  required int latest,
  int? selected,
}) => showModalBottomSheet<RankingTimeChoice>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) =>
      _RankingTimeSheet(times: times, latest: latest, selected: selected),
);

class _RankingTimeSheet extends StatelessWidget {
  const _RankingTimeSheet({
    required this.times,
    required this.latest,
    required this.selected,
  });

  final List<int> times;
  final int latest;
  final int? selected;

  /// Everything strictly older than the newest snapshot, newest first. The
  /// newest time is left out because the 「最新」 row already offers it, and
  /// listing it twice would make the sheet look like it disagrees with itself.
  List<int> get _older => [
    for (final second in times.reversed)
      if (second < latest) second,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final older = _older;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.weatherRankingPickTime,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                itemCount: older.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _TimeRow(
                      title: l10n.weatherRankingLatest,
                      subtitle: rankingTimeLabel(latest),
                      selected: selected == null,
                      onTap: () {
                        Navigator.of(context)
                            .pop<RankingTimeChoice>((second: null));
                      },
                    );
                  }
                  final second = older[index - 1];
                  return _TimeRow(
                    title: rankingTimeLabel(second),
                    selected: selected == second,
                    onTap: () {
                      Navigator.of(context)
                          .pop<RankingTimeChoice>((second: second));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row of the picker — the newest snapshot says so in words, the rest are
/// their own timestamp.
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: selected ? Icon(Icons.check, color: colors.primary) : null,
      selected: selected,
      onTap: onTap,
    );
  }
}
