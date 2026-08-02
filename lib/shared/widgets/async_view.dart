import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';

/// Renders a one-shot `Future<Result<T>>` to the async-state contract:
/// waiting → loading, [Ok] → [builder] (or [empty] when [isEmpty]), [Err] →
/// error with "couldn't load data, please try again" and a **retry** button.
/// Pairs with the repository `Result` contract so a feature never hand-rolls a
/// `FutureBuilder` that drops the error case into a blank screen.
///
/// [future] is a **factory**, not a `Future`, so the built-in retry can re-run
/// it — the error state always has a working button without the caller wiring
/// one. This is the app's global data-fetch error handling: every API-backed
/// screen inherits the same failure UI and recovery.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.future,
    required this.builder,
    this.loading,
    this.error,
    this.empty,
    this.isEmpty,
    this.refreshSignal,
  });

  /// Produces the request. Re-invoked on retry.
  final Future<Result<T>> Function() future;

  /// Builds the UI for a successful value.
  final Widget Function(BuildContext context, T value) builder;

  /// Overrides the loading state.
  final WidgetBuilder? loading;

  /// Overrides the error state (gets the failure and a retry callback).
  final Widget Function(
    BuildContext context,
    Failure failure,
    VoidCallback retry,
  )?
  error;

  /// Overrides the empty state (shown when [isEmpty] returns true).
  final WidgetBuilder? empty;

  /// Marks a successful value as "empty" so [empty] is shown instead of
  /// [builder] (e.g. an empty list).
  final bool Function(T value)? isEmpty;

  /// Re-runs [future] whenever this fires — the screen's "refresh now" signal
  /// (see `RefreshOnAppear`: entering the tab, or returning from the background).
  ///
  /// The previous value stays on screen while the new one loads, so a routine
  /// refresh never flashes the screen back to a spinner.
  final Listenable? refreshSignal;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<Result<T>> _future;
  int _attempt = 0;

  /// The last value that loaded successfully, kept so a refresh renders the
  /// existing content under the spinner instead of tearing the screen down to a
  /// loading state — pulling to check for news should never first take away the
  /// news you already had.
  T? _loaded;

  @override
  void initState() {
    super.initState();
    _future = widget.future();
    widget.refreshSignal?.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant AsyncView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal?.removeListener(_refresh);
      widget.refreshSignal?.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_refresh);
    super.dispose();
  }

  void _retry() => setState(() {
    _attempt++;
    _future = widget.future();
  });

  /// Re-runs the request, keeping the current content on screen until the new
  /// value lands.
  void _refresh() {
    if (!mounted) return;
    setState(() {
      _attempt++;
      _future = widget.future();
    });
  }

  /// The success UI for [value] — the empty state when [AsyncView.isEmpty] says
  /// so, else the caller's builder.
  Widget _content(BuildContext context, T value) {
    _loaded = value;
    if (widget.isEmpty?.call(value) ?? false) {
      return widget.empty?.call(context) ??
          EmptyView(
            icon: Icons.inbox_outlined,
            message: AppLocalizations.of(context).commonEmpty,
          );
    }
    return widget.builder(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<Result<T>>(
      // Key by attempt so a retry re-subscribes to the fresh future rather than
      // retaining the prior snapshot.
      key: ValueKey(_attempt),
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          final previous = _loaded;
          if (previous != null) return _content(context, previous);
          return widget.loading?.call(context) ?? const LoadingView();
        }
        // Repositories return Result and don't throw; a raw error here is
        // unexpected, but surface the failure state rather than a blank.
        if (snapshot.hasError || !snapshot.hasData) {
          return ErrorView(headline: l10n.commonFetchFailed, onRetry: _retry);
        }
        return switch (snapshot.data!) {
          Ok(:final value) => _content(context, value),
          Err(:final failure) =>
            widget.error?.call(context, failure, _retry) ??
                ErrorView(headline: l10n.commonFetchFailed, onRetry: _retry),
        };
      },
    );
  }
}
