import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/empty_view.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';

/// Renders a one-shot `Future<Result<T>>` to the async-state contract:
/// waiting → loading, [Ok] → [builder] (or [empty] when [isEmpty]), [Err] →
/// error with the failure and an optional retry. Pairs with the repository
/// `Result` contract so a feature never hand-rolls a `FutureBuilder` that drops
/// the error case into a blank screen.
///
/// [onRetry] typically rebuilds the caller with a fresh [future].
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.future,
    required this.builder,
    this.loading,
    this.error,
    this.empty,
    this.isEmpty,
    this.onRetry,
  });

  /// The pending request.
  final Future<Result<T>> future;

  /// Builds the UI for a successful value.
  final Widget Function(BuildContext context, T value) builder;

  /// Overrides the loading state.
  final WidgetBuilder? loading;

  /// Overrides the error state.
  final Widget Function(BuildContext context, Failure failure)? error;

  /// Overrides the empty state (shown when [isEmpty] returns true).
  final WidgetBuilder? empty;

  /// Marks a successful value as "empty" so [empty] is shown instead of
  /// [builder] (e.g. an empty list).
  final bool Function(T value)? isEmpty;

  /// When non-null, the error state shows a retry button that invokes this.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<Result<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return loading?.call(context) ?? const LoadingView();
        }
        // Repositories return Result and don't throw; a raw error here is
        // unexpected, but surface it rather than showing a blank.
        if (snapshot.hasError || !snapshot.hasData) {
          return ErrorView(detail: '${snapshot.error}', onRetry: onRetry);
        }
        return switch (snapshot.data!) {
          Ok(:final value) =>
            (isEmpty?.call(value) ?? false)
                ? (empty?.call(context) ??
                      EmptyView(
                        icon: Icons.inbox_outlined,
                        message: l10n.commonEmpty,
                      ))
                : builder(context, value),
          Err(:final failure) =>
            error?.call(context, failure) ??
                ErrorView(detail: failure.message, onRetry: onRetry),
        };
      },
    );
  }
}
