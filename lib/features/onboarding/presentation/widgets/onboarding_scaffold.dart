/// Shared chrome for an onboarding step: a scrollable body with a pinned bottom
/// action that (optionally) unlocks only once the user has scrolled to the end.
library;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A step layout: [child] scrolls; [actionBuilder] builds the pinned bottom bar
/// and is told whether the content has been scrolled to the end (`atEnd`), so a
/// "read to continue" step can gate its button. When [requireScrollToEnd] is
/// false, `atEnd` is always true.
class OnboardingScaffold extends StatefulWidget {
  const OnboardingScaffold({
    super.key,
    required this.child,
    required this.actionBuilder,
    this.requireScrollToEnd = true,
  });

  final Widget child;
  final Widget Function(BuildContext context, bool atEnd) actionBuilder;
  final bool requireScrollToEnd;

  @override
  State<OnboardingScaffold> createState() => _OnboardingScaffoldState();
}

class _OnboardingScaffoldState extends State<OnboardingScaffold> {
  final ScrollController _controller = ScrollController();
  bool _atEnd = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_check);
    // Content that fits without scrolling counts as already "at end".
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didUpdateWidget(OnboardingScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The body may have changed size — e.g. switching language shortens the
    // terms so they now fit without scrolling. That fires no scroll event, so
    // re-evaluate "at end" after the new content lays out; otherwise a
    // scroll-gated step (the terms) would stay locked with an un-scrollable
    // "scroll to continue" hint.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final atEnd =
        position.maxScrollExtent <= 0 ||
        position.pixels >= position.maxScrollExtent - 12;
    if (atEnd != _atEnd) setState(() => _atEnd = atEnd);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atEnd = !widget.requireScrollToEnd || _atEnd;
    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: _controller,
            child: SingleChildScrollView(
              controller: _controller,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: widget.child,
            ),
          ),
        ),
        Material(
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: widget.actionBuilder(context, atEnd),
          ),
        ),
      ],
    );
  }
}

/// A full-width primary action for an onboarding step, with a small hint shown
/// above it while it's disabled (e.g. "scroll down to continue").
class OnboardingCta extends StatelessWidget {
  const OnboardingCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.hint,
  });

  /// Button label.
  final String label;

  /// Tap handler; null disables the button.
  final VoidCallback? onPressed;

  /// Shown above the button while it's disabled.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onPressed == null && hint != null) ...[
          Text(
            hint!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onPressed, child: Text(label)),
        ),
      ],
    );
  }
}
