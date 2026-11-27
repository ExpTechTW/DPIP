import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/events/presentation/event_hazard_style.dart';
import 'package:dpip/features/events/presentation/event_labels.dart';
import 'package:dpip/features/events/presentation/widgets/event_status_chip.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the detail page of card [id], with the per-township text for
/// [regionCode] when one is given.
void openEventDetail(BuildContext context, int id, {String? regionCode}) {
  context.pushNamed(
    AppRoutes.eventDetail,
    pathParameters: {'id': '$id'},
    queryParameters: {'region': ?regionCode},
  );
}

/// One event card as a row — the hazard badge, the title and subtitle, when
/// it was sent, and where it stands. Shared by the Events tab and the home
/// sheet; a tap opens the card's detail page.
///
/// The state is judged against [AppTime.utc] at build time, so a card whose
/// end time passes while it is on screen reads "ended" from the next rebuild
/// on (every list holding these re-fetches on appearance).
class EventCardTile extends StatelessWidget {
  const EventCardTile({
    super.key,
    required this.card,
    this.regionCode,
    this.foreground,
    this.secondary,
    this.compact = false,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.sm),
  });

  /// Badge diameter in the regular row.
  static const double badgeSize = 36;

  /// Badge diameter in the [compact] row.
  static const double compactBadgeSize = 32;

  /// The card shown.
  final EventCard card;

  /// The township the list is for, passed on to the detail page so its text
  /// is that township's; null for the nationwide feed.
  final String? regionCode;

  /// Title ink; the theme's on-surface colour when null. The home sheet
  /// passes the ink of the sky the row is drawn over.
  final Color? foreground;

  /// Ink of the subtitle, time and labels; the theme's on-surface-variant
  /// colour when null.
  final Color? secondary;

  /// A one-line title and a smaller badge, for the home sheet.
  final bool compact;

  /// Space around the row, inside its tap target.
  final EdgeInsetsGeometry padding;

  /// The badge diameter this row uses.
  double get badgeDiameter => compact ? compactBadgeSize : badgeSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final ink = foreground ?? colors.onSurface;
    final muted = secondary ?? colors.onSurfaceVariant;
    final now = AppTime.utc;
    final status = EventCardStatus.ofCard(card, now);
    final time = eventTimeLabel(
      card.send,
      nowUtc: now,
      locale: intlDateLocale(Localizations.localeOf(context)),
    );
    final meta = [
      card.hazard.label(l10n),
      if (card.serial >= 2) l10n.eventReportSerial(card.serial),
    ].join(' · ');

    return Material(
      // Transparent so the ripple draws over a glass or tinted card instead
      // of under it.
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => openEventDetail(context, card.id, regionCode: regionCode),
        borderRadius: AppRadius.small,
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventHazardBadge(hazard: card.hazard, size: badgeDiameter),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            card.title.isEmpty ? '—' : card.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: ink,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          time,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                    if (card.subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        card.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (status != null) EventStatusChip(status: status),
                        Text(
                          meta,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
