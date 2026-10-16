/// The movement-track layer's sheet: the time range, what is stored, the clear
/// action, and — always in the resting peek, never behind a drag — the fact
/// that the history exists only on this phone.
library;

import 'dart:async';

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/geo/track_digest.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/core/storage/app_storage_scan.dart';
import 'package:dpip/features/map/presentation/layers/location_track_layer.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:dpip/shared/widgets/selectable_pill.dart';
import 'package:dpip/shared/widgets/sheet_extent.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Collapsible sheet on the same peek / rest / full skeleton as the station,
/// tsunami and mesh sheets — except that its peek is measured, not declared.
///
/// The other sheets' peeks are a grip and a line, and a fixed fraction of the
/// screen fits that on any phone. This one has to show the local-only notice
/// at rest, and the shell draws its navigation bar *over* the bottom of the map
/// (`extendBody`): a fraction that clears the bar on a tall phone leaves the
/// notice behind it on a short one, or at a larger text size, or in a language
/// that wraps to three lines. So the sheet lays the peek block out, measures
/// it, and rests exactly that high above the bar.
class LocationTrackSheet extends StatefulWidget {
  const LocationTrackSheet({super.key, required this.layer});

  final LocationTrackMapLayer layer;

  /// The peek before the first measurement — and what the scaffold frames
  /// around until then.
  static const double fallbackPeekExtent = 0.3;

  /// Bounds on the measured peek, so a pathological measurement (a zero-height
  /// first layout, an enormous text scale) still leaves a sheet and a map.
  static const double _minPeek = 0.15;
  static const double _maxPeek = 0.7;

  static const double _expanded = 1;

  @override
  State<LocationTrackSheet> createState() => _LocationTrackSheetState();
}

class _LocationTrackSheetState extends State<LocationTrackSheet> {
  late double _peek = widget.layer.peekExtent;
  late final ValueNotifier<double> _extent = ValueNotifier(_peek);

  /// The map's height at the last layout — what the measured block is a
  /// fraction of.
  double _height = 0;

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  /// [SheetGrip]'s bar plus its margins. Outside the measured block because
  /// the grip hides when the sheet reaches the top — measuring it would change
  /// the peek mid-drag and remount the sheet under the finger.
  static const double _gripHeight = 4 + AppSpacing.sm * 2;

  /// The peek block laid out at [blockHeight]: rest the sheet so all of it
  /// clears the navigation bar.
  ///
  /// Only while resting at the peek. Re-measuring a dragged-open sheet would
  /// remount it, and snap it shut, because its content changed underneath —
  /// pills appearing after the first read, say.
  void _onPeekMeasured(double blockHeight) {
    if (!mounted || _height <= 0) return;
    if ((_extent.value - _peek).abs() > 0.02) return;
    final covered = MediaQuery.paddingOf(context).bottom;
    final next = ((_gripHeight + blockHeight + covered) / _height).clamp(
      LocationTrackSheet._minPeek,
      LocationTrackSheet._maxPeek,
    );
    // A pixel or two of drift is not worth remounting the sheet for.
    if ((next - _peek).abs() < 0.01) return;
    widget.layer.peekExtent = next;
    setState(() => _peek = next);
    // The remount below starts the sheet at the new peek; the chrome only
    // hears about the extent after a drag, so seed it.
    _extent.value = next;
  }

  @override
  Widget build(BuildContext context) {
    final layer = widget.layer;
    final topInset = MediaQuery.paddingOf(context).top;
    final rest = (_peek + 0.3).clamp(_peek, LocationTrackSheet._expanded);
    return LayoutBuilder(
      builder: (context, constraints) {
        // The sheet fills the map, so its constraints are the map's own size —
        // what the camera fit needs, rather than the screen's.
        final viewport = constraints.biggest;
        _height = viewport.height.isFinite ? viewport.height : 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !viewport.isFinite) return;
          layer.rememberFrameMetrics(
            viewport: viewport,
            topInset: topInset,
            bottomInset: viewport.height * _peek,
          );
        });
        return ExtentSheetChrome(
          extent: _extent,
          // Keyed on the peek so a new measurement remounts the sheet at it.
          keyValue: '${LocationTrackMapLayer.layerId}-$_peek',
          initial: _peek,
          min: _peek,
          max: LocationTrackSheet._expanded,
          snapSizes: [if (rest < LocationTrackSheet._expanded) rest],
          content: (context, scrollController) =>
              ValueListenableBuilder<LocationTrackSnapshot?>(
                valueListenable: layer.snapshot,
                builder: (context, snapshot, _) => ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom:
                        MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
                  ),
                  children: [
                    SheetGrip(extent: _extent),
                    _Measured(
                      onHeight: _onPeekMeasured,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(layer: layer, snapshot: snapshot),
                          // Kept while loading too, so the peek does not jump
                          // when the first read lands.
                          if (snapshot?.recorded ?? true)
                            _RangePicker(layer: layer),
                          const _LocalOnlyNotice(),
                        ],
                      ),
                    ),
                    ...switch (snapshot) {
                      null => const [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                          ),
                          child: LoadingView(),
                        ),
                      ],
                      LocationTrackSnapshot(recorded: false) => const [
                        _NothingRecorded(),
                      ],
                      final recorded => [
                        _Storage(layer: layer, snapshot: recorded),
                      ],
                    },
                  ],
                ),
              ),
        );
      },
    );
  }
}

/// Reports [child]'s laid-out height after every build.
class _Measured extends StatelessWidget {
  const _Measured({required this.onHeight, required this.child});

  final ValueChanged<double> onHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final box = context.findRenderObject();
      if (box is RenderBox && box.hasSize) onHeight(box.size.height);
    });
    return child;
  }
}

/// Title, and how much the selected window holds — or a spinner while it is
/// being read, since "all" can take a moment on a long history.
class _Header extends StatelessWidget {
  const _Header({required this.layer, required this.snapshot});

  final LocationTrackMapLayer layer;
  final LocationTrackSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final snapshot = this.snapshot;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.route_outlined, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.mapLayerLocationTrack, style: theme.textTheme.titleMedium),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ValueListenableBuilder<bool>(
              valueListenable: layer.busy,
              builder: (context, busy, _) {
                if (busy) {
                  return const Align(
                    alignment: Alignment.centerRight,
                    child: InlineLoading(size: 16),
                  );
                }
                if (snapshot == null || !snapshot.recorded) {
                  return const SizedBox.shrink();
                }
                final fixes = snapshot.digest.fixes;
                return Text(
                  fixes == 0
                      ? l10n.locationTrackRangeEmpty
                      : l10n.locationTrackRangePoints(
                          formatTrackCount(context, fixes),
                        ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 今天 / 7 天 / 30 天 / 全部.
class _RangePicker extends StatelessWidget {
  const _RangePicker({required this.layer});

  final LocationTrackMapLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<TrackRange>(
      valueListenable: layer.range,
      builder: (context, selected, _) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final range in TrackRange.values)
              SelectablePill(
                label: switch (range) {
                  TrackRange.today => l10n.locationTrackRangeToday,
                  TrackRange.week => l10n.locationTrackRangeWeek,
                  TrackRange.month => l10n.locationTrackRangeMonth,
                  TrackRange.all => l10n.locationTrackRangeAll,
                },
                selected: range == selected,
                onTap: () => unawaited(layer.selectRange(range)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Where the data lives, and what loses it.
///
/// In the peek, above everything that needs a drag, and present in every state
/// — empty, loading, recorded. A movement history is the most personal thing
/// the app holds; whether it leaves the phone is not a detail to find on page
/// two, and "uninstalling deletes it" is something to know before relying on
/// it, not after.
class _LocalOnlyNotice extends StatelessWidget {
  const _LocalOnlyNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.phonelink_lock_outlined, size: 18, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppLocalizations.of(context).locationTrackLocalOnly,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nothing has been recorded: say how recording starts, and offer the way
/// there. Recording itself has no switch — it follows the background-location
/// grant.
class _NothingRecorded extends StatelessWidget {
  const _NothingRecorded();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          EmptyView(
            icon: Icons.route_outlined,
            message: l10n.locationTrackEmpty,
          ),
          Text(
            l10n.locationTrackEmptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonalIcon(
            onPressed: () => context.pushNamed(AppRoutes.permissions),
            icon: const Icon(Icons.verified_user_outlined),
            label: Text(l10n.permissionsTitle),
          ),
        ],
      ),
    );
  }
}

/// What is on disk, how much fits, and the clear action.
class _Storage extends StatelessWidget {
  const _Storage({required this.layer, required this.snapshot});

  final LocationTrackMapLayer layer;
  final LocationTrackSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final body = theme.textTheme.bodyMedium;
    final note = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final dateLocale = intlDateLocale(Localizations.localeOf(context));
    final oldest = snapshot.oldest;
    final latest = snapshot.digest.latest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.locationTrackStorage),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.locationTrackStored(
                  formatTrackCount(context, snapshot.fixes),
                  formatBytes(snapshot.bytes),
                ),
                style: body,
              ),
              if (oldest != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.locationTrackOldest(
                    // Taipei wall time, like every other date in the app.
                    DateFormat(
                      'yyyy/MM/dd',
                      dateLocale,
                    ).format(AppTime.taipei(oldest)),
                  ),
                  style: body,
                ),
              ],
              if (latest != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.locationTrackLatest(
                    DateFormat(
                      'yyyy/MM/dd HH:mm',
                      dateLocale,
                    ).format(AppTime.taipei(latest.time)),
                  ),
                  style: body,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(l10n.locationTrackCapacity, style: note),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.locationTrackGapNote(
                  TrackDigestBuilder.defaultGap.inHours,
                ),
                style: note,
              ),
              const SizedBox(height: AppSpacing.lg),
              ValueListenableBuilder<bool>(
                valueListenable: layer.busy,
                builder: (context, busy, _) => OutlinedButton.icon(
                  onPressed: busy ? null : () => _confirmClear(context),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.locationTrackClear),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Confirmed first, and worded as permanent: unlike a cache there is no
  /// copy anywhere to fetch it back from — that is what "only on this phone"
  /// means.
  Future<void> _confirmClear(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: const Icon(Icons.delete_outline),
          title: Text(l10n.locationTrackClear),
          content: Text(l10n.locationTrackClearConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              child: Text(l10n.locationTrackClear),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    // A failed clear leaves the storage section showing what is still there,
    // which says so better than a message would.
    if (!await layer.clearTrack()) return;
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.locationTrackCleared)));
  }
}

/// [count] with the reader's digit grouping (`1,234` / `1.234`).
///
/// `intl` has number data for fewer locales than the app ships, and asking it
/// for one it lacks throws instead of falling back — so the full tag, then the
/// language, then English.
String formatTrackCount(BuildContext context, int count) {
  final locale = Localizations.localeOf(context);
  final tag = locale.toString();
  final resolved = NumberFormat.localeExists(tag)
      ? tag
      : NumberFormat.localeExists(locale.languageCode)
      ? locale.languageCode
      : 'en';
  return NumberFormat.decimalPattern(resolved).format(count);
}
