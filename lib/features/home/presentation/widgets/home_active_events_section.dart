/// Compact active-events list for the collapsed home sheet.
library;

import 'package:dpip/app/theme/app_glass.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

/// Builds the row of one active [card]: how an event card is drawn belongs to
/// the events feature, which this feature may not import, so the app layer
/// provides this (`app_router.dart` hands it the events list's own row, which
/// opens the card's detail with [regionCode]'s text).
///
/// [foreground] and [secondary] are the inks of the sky the row is drawn over.
typedef HomeEventRowBuilder = Widget Function(
  BuildContext context,
  EventCard card, {
  required String? regionCode,
  required Color foreground,
  required Color secondary,
});

/// Active (realtime) disaster notices under the home header. While the sheet is
/// at rest the list sits flush on the sheet (no card fill); once flush
/// full-screen it picks up the same glass card as the weather blocks above.
///
/// Always shows *some* area's notices, so it is only mounted for an area we can
/// name — `HomeContent` drops it entirely for 所在地 with no GPS fix rather than
/// having this widget carry a "nowhere" state.
class HomeActiveEventsSection extends StatelessWidget {
  const HomeActiveEventsSection({
    super.key,
    this.reveal = 0,
    this.expanded = false,
    this.sky,
    this.weatherMode = WeatherMode.auto,
  });

  /// Weather-backdrop reveal (0→1) — glass + lightened foregrounds.
  final double reveal;

  /// Sheet is flush full-screen — apply the glass card surface.
  final bool expanded;

  /// The sky colour the card tints itself from — `SkyLutCache.panelAmbient`, or
  /// null when no backdrop is running. The reference's card is a 20 % pane of the sky,
  /// so without one there is nothing for it to be a pane *of* and it falls back
  /// to an opaque plate.
  final Color? sky;

  /// Backdrop sky mode — decides whether card ink goes dark or white as the
  /// card dissolves into the sky.
  final WeatherMode weatherMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Card ink follows the sky: once [reveal] dissolves the card to the reference's
    // 20 % fill it is a pane of the sky, not a plate, and theme on-surface ink
    // stops being legible. At rest (reveal 0) these resolve to the theme roles.
    final skyIsLight = skyIsLightFrom(sky, weatherMode);
    final foreground = glassOnSurface(
      colors,
      reveal: reveal,
      skyIsLight: skyIsLight,
    );
    final secondary = glassOnSurfaceVariant(
      colors,
      reveal: reveal,
      skyIsLight: skyIsLight,
    );
    final controller = context.watch<HomeActiveEventsController>();
    final events = controller.events;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.notifications_active_outlined,
              size: 18,
              color: secondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.homeActiveEventsTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (controller.loading) InlineLoading(size: 14, color: secondary),
          ],
        ),
        // Each row pads itself by AppSpacing.xs above and below (see
        // `_homeEventRow` in app_router.dart), which makes up the rest.
        SizedBox(height: events.isEmpty ? AppSpacing.md : AppSpacing.sm),
        if (controller.failure != null && events.isEmpty)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homeActiveEventsEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
                ),
              ),
              TextButton(
                onPressed: controller.refresh,
                child: Text(l10n.commonRetry),
              ),
            ],
          )
        else if (events.isEmpty)
          Text(
            l10n.homeActiveEventsEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
          )
        else
          for (final card in events)
            context.watch<HomeEventRowBuilder>()(
              context,
              card,
              regionCode: controller.regionCode,
              foreground: foreground,
              secondary: secondary,
            ),
      ],
    );

    if (!expanded) return body;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: glassSurface(colors, reveal, sky: sky),
        borderRadius: AppRadius.medium,
      ),
      child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: body),
    );
  }
}
