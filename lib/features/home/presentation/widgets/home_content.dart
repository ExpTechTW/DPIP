import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// The scrollable home dashboard shown inside the draggable sheet — the surface
/// that fills the screen when the sheet is pulled up.
///
/// This is where weather / alert / event sections land as they are built, so
/// [HomePage] stays a thin host and this file grows independently. It must be
/// driven by the sheet's [scrollController] so scrolling past the top expands
/// the sheet.
class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.scrollController,
    this.handleOpacity = 1,
  });

  /// The draggable sheet's scroll controller.
  final ScrollController scrollController;

  /// Opacity of the grab handle — faded to 0 as the sheet reaches full, where
  /// the pull-up affordance is no longer needed.
  final double handleOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Opacity(opacity: handleOpacity, child: const HomeSheetHandle()),
        // Placeholder cards until the real sections land.
        for (var i = 0; i < 8; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: AppRadius.medium,
              ),
            ),
          ),
      ],
    );
  }
}

/// The grab handle shown at the top of the home sheet.
class HomeSheetHandle extends StatelessWidget {
  const HomeSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
