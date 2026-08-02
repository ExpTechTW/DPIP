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
    this.refreshable = false,
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

  /// Wraps every state in a pull-to-refresh that re-runs [future].
  ///
  /// The empty and error states get it too: those are exactly the moments a user
  /// pulls — an empty feed after a dropped connection is indistinguishable from
  /// a genuinely quiet one, and reaching for the retry button is not the reflex.
  /// They are made scrollable (they otherwise fit the viewport and could not
  /// overscroll) so the gesture is available there at all.
  final bool refreshable;

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
  }

  void _retry() => setState(() {
    _attempt++;
    _future = widget.future();
  });

  /// Re-runs the request and completes when it settles, so the refresh spinner
  /// stays up until there is actually something new to show.
  Future<void> _refresh() async {
    final future = widget.future();
    setState(() {
      _attempt++;
      _future = future;
    });
    await future;
  }

  /// Makes a non-scrolling state (empty / error) overscrollable so a pull can
  /// still start there, without stretching its content.
  /// The success UI for [value] — the empty state when [AsyncView.isEmpty] says
  /// so, else the caller's builder.
  Widget _content(BuildContext context, T value) {
    _loaded = value;
    if (widget.isEmpty?.call(value) ?? false) {
      return _wrap(
        widget.empty?.call(context) ??
            EmptyView(
              icon: Icons.inbox_outlined,
              message: AppLocalizations.of(context).commonEmpty,
            ),
      );
    }
    return widget.builder(context, value);
  }

  Widget _wrap(Widget child) => widget.refreshable ? _pullable(child) : child;

  Widget _pullable(Widget child) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: child,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final view = _buildState(context);
    if (!widget.refreshable) return view;
    return RefreshIndicator(onRefresh: _refresh, child: view);
  }

  Widget _buildState(BuildContext context) {
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
          return _wrap(
            ErrorView(headline: l10n.commonFetchFailed, onRetry: _retry),
          );
        }
        return switch (snapshot.data!) {
          Ok(:final value) => _content(context, value),
          Err(:final failure) => _wrap(
            widget.error?.call(context, failure, _retry) ??
                ErrorView(headline: l10n.commonFetchFailed, onRetry: _retry),
          ),
        };
      },
    );
  }
}
