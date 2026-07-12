import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/features/home/presentation/widgets/home_sheet_header.dart';
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
    this.reveal = 0,
    this.topInset = 0,
  });

  /// The draggable sheet's scroll controller.
  final ScrollController scrollController;

  /// Opacity of the grab handle — faded to 0 as the sheet reaches full, where
  /// the pull-up affordance is no longer needed.
  final double handleOpacity;

  /// How much the weather backdrop is revealed (0→1) — content shifts to light
  /// glass so it stays legible over the weather.
  final double reveal;

  /// Extra top padding that clears the region-bar overlay as the sheet reaches
  /// full, so the content isn't hidden behind it.
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cardColor = Color.lerp(
      colors.surfaceContainerHighest.withValues(alpha: 0.55),
      Colors.white.withValues(alpha: 0.16),
      reveal,
    )!;
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topInset,
        AppSpacing.lg,
        // Clear the bottom nav (the body extends behind it — extendBody).
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Opacity(opacity: handleOpacity, child: const HomeSheetHandle()),
        HomeSheetHeader(reveal: reveal),
        const SizedBox(height: AppSpacing.lg),
        // Placeholder cards until the real sections land.
        for (var i = 0; i < 6; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                color: cardColor,
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
