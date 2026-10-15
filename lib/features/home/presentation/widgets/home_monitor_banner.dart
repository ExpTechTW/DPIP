/// A tappable 地震速報 banner under the home region bar, shown only while an
/// alert is active — the location + report number — that jumps straight to
/// 強震監視器 (the map's live RTS monitor layer) on tap. Renders nothing when
/// calm, the same "don't say anything until there's something to say" choice
/// `HomeEewSection` makes further down the sheet.
///
/// Takes the same [dismiss] dial `RegionBar` does (fed from the same
/// sheet-extent selector) so it slides away in lockstep with the bar above it
/// as the sheet rises. No `blend` dial: unlike the region bar, this never
/// blends into the weather — an active alert always stays on its own fixed
/// error colours, never diluted into the scenery.
///
/// Floats as its own rounded, elevated pill (margin + [AppRadius.medium] +
/// shadow) rather than a flush full-bleed strip — the same card language the
/// EEW cards elsewhere in the app already use, so this reads as "a card that
/// happens to sit up here," not a raw coloured bar glued to the top of the
/// screen.
///
/// While the EEW feed is stale or offline the slot says so instead
/// ([EewFeedDownNotice]): an empty slot is what calm looks like, and a dead
/// feed must not look like calm.
///
/// A cancelled alert keeps the banner up for as long as it stays in the list,
/// but on neutral surface colours with 已取消 in place of the report number:
/// the user who saw the warning arrive needs to see it withdrawn, and a
/// banner that simply vanished would read the same as one that ran its
/// course.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_priority.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/eew_feed_down_notice.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeMonitorBanner extends StatelessWidget {
  const HomeMonitorBanner({super.key, this.dismiss = 0});

  /// How far the banner has slid up and faded out (0 shown → 1 gone).
  final double dismiss;

  /// The banner's own rendered height while showing, margin included. Public
  /// for the same reason `RegionBar.height` is: the Home map sits *behind*
  /// this banner too, so its camera fit has to leave room below the region
  /// bar for it — even though most frames it isn't there at all, an alert can
  /// appear at any moment and the framing must already have room for it.
  static const double height = 44;

  /// Whether the banner shows anything right now — an alert on a live feed,
  /// or the notice that the feed is down — the same check [build] gates on,
  /// exposed so a caller that needs to lay out *around* this banner (Home's
  /// overlap stack with the gold support bar) reads the identical condition
  /// instead of re-deriving it and risking the two disagreeing.
  static bool isActive(BuildContext context) =>
      // `select`, not `watch`: the Home overlap stack calls this to lay out
      // around the banner, and a watch there rebuilt it on every EEW serial
      // update. The boolean is the same; only a flip rebuilds the caller.
      context.select<RealtimeNotifier<List<Eew>>, bool>((eew) {
        final status = eew.state.status;
        if (EewFeedDownNotice.isDown(status)) return true;
        final alerts = eew.state.data ?? const <Eew>[];
        return status == RealtimeStatus.live && alerts.isNotEmpty;
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (!isActive(context)) return const SizedBox.shrink();

    final eew = context.watch<RealtimeNotifier<List<Eew>>>();
    final status = eew.state.status;
    if (EewFeedDownNotice.isDown(status)) {
      // The calm banner slot is empty, and an empty slot reads as "no
      // earthquake" — say the feed is down instead. Not tappable: the
      // monitor would only say the same thing.
      return _slide(
        child: EewFeedDownNotice(status: status, elevation: 8, maxLines: 1),
      );
    }
    final alerts = eew.state.data ?? const <Eew>[];
    // The same ranking the Home card uses ([rankEews]), at the selected
    // township — this banner resolves no GPS fix of its own. An alert still in
    // progress outranks a cancelled one, so the banner turns neutral and says
    // 已取消 only when nothing else is left to warn about.
    final code = context.watch<RegionStore>().selectedCode;
    final town = code == null
        ? null
        : context.read<TownDirectory>().byCode(code);
    final alert = primaryEew(
      alerts,
      now: AppTime.utc,
      observer: town == null ? null : LatLng(town.lat, town.lng),
    )!;
    final cancelled = alert.isCancelled;
    final ink = cancelled ? colors.onSurface : colors.onErrorContainer;

    return _slide(
      child: Material(
        color: cancelled
            ? colors.surfaceContainerHighest
            : colors.errorContainer,
        // Higher than the card language elsewhere uses — this one
        // genuinely overlaps the gold support bar underneath it (see
        // Home's overlap stack), so the shadow needs to read as real
        // depth, not just a card outline.
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        borderRadius: AppRadius.medium,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            context.read<MapCameraHandoff>().request(
              BaseMap.taiwanBounds,
              layerId: 'monitor',
            );
            context.goNamed(AppRoutes.map);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                // A circular chip around the icon reads as a badge, not
                // a bare glyph floating in the row — the same touch
                // the legacy monitor's own EEW pill used.
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cancelled
                        ? Icons.cancel_outlined
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: ink,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.info.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        cancelled
                            ? l10n.eewCancelled
                            : l10n.eewSerial(alert.serial),
                        maxLines: 1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ink.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Slides and fades [child] away with the region bar above it (see
  /// [dismiss]) — the alert and the feed-down notice ride it alike.
  Widget _slide({required Widget child}) => IgnorePointer(
    ignoring: dismiss > 0.5,
    child: Opacity(
      opacity: 1 - dismiss,
      child: FractionalTranslation(
        translation: Offset(0, -dismiss),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: child,
        ),
      ),
    ),
  );
}
