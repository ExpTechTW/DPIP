import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';

/// Renders a [RealtimeState] to the async-state contract, adding the freshness
/// dimension the one-shot [AsyncView] lacks:
/// - no data yet + `connecting` → loading;
/// - no data + `stale`/`offline` → error (never connected / gave up);
/// - has data → [builder], and if the feed is `stale`/`offline` a banner is
///   shown above it so aged safety data is never presented as current.
///
/// Fills its parent's height (it may add a banner above [builder]'s output), so
/// give it a bounded box such as a `Scaffold` body.
class RealtimeView<T> extends StatelessWidget {
  const RealtimeView({
    super.key,
    required this.state,
    required this.builder,
    this.loading,
    this.error,
    this.showFreshnessBanner = true,
  });

  /// The realtime snapshot to render.
  final RealtimeState<T> state;

  /// Builds the UI for the current [data]. Called only when data is present.
  final Widget Function(BuildContext context, T data) builder;

  /// Overrides the no-data loading state.
  final WidgetBuilder? loading;

  /// Overrides the no-data error state.
  final Widget Function(BuildContext context, Failure? failure)? error;

  /// Whether to show the stale/offline banner over present data.
  final bool showFreshnessBanner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = state.data;

    if (data == null) {
      switch (state.status) {
        case RealtimeStatus.connecting:
        case RealtimeStatus.live:
          return loading?.call(context) ??
              LoadingView(label: l10n.feedConnecting);
        case RealtimeStatus.stale:
        case RealtimeStatus.offline:
          return error?.call(context, state.lastFailure) ??
              ErrorView(
                icon: Icons.cloud_off_outlined,
                headline: l10n.feedOffline,
                detail: state.lastFailure?.message,
              );
      }
    }

    final content = builder(context, data);
    final showBanner =
        showFreshnessBanner &&
        (state.status == RealtimeStatus.stale ||
            state.status == RealtimeStatus.offline);
    if (!showBanner) return content;

    return Column(
      children: [
        _FreshnessBanner(status: state.status),
        Expanded(child: content),
      ],
    );
  }
}

/// A thin banner flagging that shown data has aged (stale) or the feed dropped
/// (offline) — the "still showing last known data, but…" affordance.
class _FreshnessBanner extends StatelessWidget {
  const _FreshnessBanner({required this.status});

  final RealtimeStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    final (
      Color background,
      Color foreground,
      IconData icon,
      String label,
    ) = switch (status) {
      RealtimeStatus.offline => (
        colors.errorContainer,
        colors.onErrorContainer,
        Icons.cloud_off_outlined,
        l10n.feedOffline,
      ),
      _ => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
        Icons.schedule,
        l10n.feedStale,
      ),
    };

    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
