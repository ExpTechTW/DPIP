/// Compact active-events list for the collapsed home sheet.
library;

import 'package:dpip/app/theme/app_glass.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/features/events/domain/event.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
            if (controller.loading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: secondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (controller.failure != null && controller.events.isEmpty)
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
        else if (controller.events.isEmpty)
          Text(
            l10n.homeActiveEventsEmpty,
            style: theme.textTheme.bodyMedium?.copyWith(color: secondary),
          )
        else
          for (var i = 0; i < controller.events.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _ActiveEventRow(
              event: controller.events[i],
              foreground: foreground,
              secondary: secondary,
            ),
          ],
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

class _ActiveEventRow extends StatelessWidget {
  const _ActiveEventRow({
    required this.event,
    required this.foreground,
    required this.secondary,
  });

  final Event event;
  final Color foreground;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _iconFor(event.type),
            size: 18,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title.isEmpty ? '—' : event.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    DateFormat('HH:mm').format(event.time),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: secondary,
                    ),
                  ),
                ],
              ),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  event.description,
                  style: theme.textTheme.bodySmall?.copyWith(color: secondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
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
