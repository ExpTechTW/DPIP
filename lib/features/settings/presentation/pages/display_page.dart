/// Display settings: the app-wide theme mode (light / dark / follow system),
/// each shown with a small true-to-theme preview.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/app/theme/app_theme.dart';
import 'package:dpip/core/settings/theme_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DisplayPage extends StatelessWidget {
  const DisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = context.watch<ThemeController>().mode;
    final options = <({ThemeMode mode, String label})>[
      (mode: ThemeMode.system, label: l10n.themeSystem),
      (mode: ThemeMode.light, label: l10n.themeLight),
      (mode: ThemeMode.dark, label: l10n.themeDark),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.displaySettings)),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          SectionHeader(l10n.displayTheme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, option) in options.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ThemeOptionCard(
                      label: option.label,
                      selected: current == option.mode,
                      onTap: () =>
                          context.read<ThemeController>().setMode(option.mode),
                      child: _ThemePreview(mode: option.mode),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable theme option — a framed preview with the option's name below and a
/// check once selected; the frame highlights in the primary colour when active.
class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.medium,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: AppRadius.medium,
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.small,
              child: AspectRatio(aspectRatio: 3 / 4, child: child),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              Icon(Icons.check_circle, size: 16, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? colors.primary : colors.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A tiny mock app screen painted with the theme a [mode] resolves to. For
/// [ThemeMode.system] it splits diagonally, showing light and dark together to
/// signal "follows the system".
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case ThemeMode.light:
        return _MiniScreen(scheme: AppTheme.scheme(Brightness.light));
      case ThemeMode.dark:
        return _MiniScreen(scheme: AppTheme.scheme(Brightness.dark));
      case ThemeMode.system:
        // Light fills; the dark half is clipped to the bottom-right triangle.
        return Stack(
          fit: StackFit.expand,
          children: [
            _MiniScreen(scheme: AppTheme.scheme(Brightness.light)),
            ClipPath(
              clipper: _DiagonalClipper(),
              child: _MiniScreen(scheme: AppTheme.scheme(Brightness.dark)),
            ),
          ],
        );
    }
  }
}

/// A minimal mock of the app UI — a top bar and a few content blocks — painted
/// in [scheme]'s roles so each preview reads as that theme at a glance.
class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    Widget bar(Color color, {double widthFactor = 1}) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );

    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          bar(scheme.surfaceContainerHighest),
          const SizedBox(height: AppSpacing.xs),
          bar(scheme.surfaceContainerHighest, widthFactor: 0.6),
        ],
      ),
    );
  }
}

/// Clips to the bottom-right triangle, for the split light/dark system preview.
class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
