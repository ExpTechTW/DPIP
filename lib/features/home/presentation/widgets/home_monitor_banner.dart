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
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final eew = context.watch<RealtimeNotifier<List<Eew>>>();
    final alerts = eew.state.data ?? const <Eew>[];
    final hasActiveEew =
        eew.state.status == RealtimeStatus.live && alerts.isNotEmpty;
    if (!hasActiveEew) return const SizedBox.shrink();

    final ink = colors.onErrorContainer;
    final alert = alerts.first;

    return IgnorePointer(
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
            child: Material(
              color: colors.errorContainer,
              elevation: 3,
              shadowColor: Colors.black.withValues(alpha: 0.25),
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
                          Icons.warning_amber_rounded,
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
                              l10n.eewSerial(alert.serial),
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
          ),
        ),
      ),
    );
  }
}
