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

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<Result<T>> _future;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.future();
  }

  void _retry() => setState(() {
    _attempt++;
    _future = widget.future();
  });

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
          return widget.loading?.call(context) ?? const LoadingView();
        }
        // Repositories return Result and don't throw; a raw error here is
        // unexpected, but surface the failure state rather than a blank.
        if (snapshot.hasError || !snapshot.hasData) {
          return ErrorView(headline: l10n.commonFetchFailed, onRetry: _retry);
        }
        return switch (snapshot.data!) {
          Ok(:final value) =>
            (widget.isEmpty?.call(value) ?? false)
                ? (widget.empty?.call(context) ??
                      EmptyView(
                        icon: Icons.inbox_outlined,
                        message: l10n.commonEmpty,
                      ))
                : widget.builder(context, value),
          Err(:final failure) =>
            widget.error?.call(context, failure, _retry) ??
                ErrorView(headline: l10n.commonFetchFailed, onRetry: _retry),
        };
      },
    );
  }
}
