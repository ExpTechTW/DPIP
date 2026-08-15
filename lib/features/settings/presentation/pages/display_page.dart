/// Display settings: theme mode, text size, text weight, contrast, and
/// colour-vision correction.
///
/// Everything here changes how the whole app is drawn, so each control is a
/// segmented row rather than a menu — the choices are few, and seeing the
/// alternatives beside the current one is most of the answer.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/app/theme/app_theme.dart';
import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/settings/color_vision_controller.dart';
import 'package:dpip/core/settings/display_settings.dart';
import 'package:dpip/core/settings/theme_controller.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DisplayPage extends StatelessWidget {
  const DisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = context.watch<ThemeController>().mode;
    final display = context.watch<DisplaySettings>();
    final settings = context.read<DisplaySettings>();
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
          _Choice<TextScaleStep>(
            title: l10n.displayTextSize,
            description: l10n.displayTextSizeDesc,
            value: display.textScale,
            options: [
              (TextScaleStep.small, l10n.displayScaleSmall),
              (TextScaleStep.normal, l10n.displayScaleDefault),
              (TextScaleStep.large, l10n.displayScaleLarge),
              (TextScaleStep.huge, l10n.displayScaleHuge),
            ],
            onChanged: settings.setTextScale,
            preview: (step) =>
                _MiniScreen(scheme: Theme.of(context).colorScheme, scale: step),
          ),
          _Choice<TextWeightStep>(
            title: l10n.displayTextWeight,
            description: l10n.displayTextWeightDesc,
            value: display.textWeight,
            options: [
              (TextWeightStep.normal, l10n.displayWeightNormal),
              (TextWeightStep.medium, l10n.displayWeightMedium),
              (TextWeightStep.bold, l10n.displayWeightBold),
            ],
            onChanged: settings.setTextWeight,
            preview: (step) => _MiniScreen(
              scheme: Theme.of(context).colorScheme,
              weight: step,
            ),
          ),
          _Choice<ContrastStep>(
            title: l10n.displayContrast,
            description: l10n.displayContrastDesc,
            value: display.contrast,
            options: [
              (ContrastStep.standard, l10n.displayContrastStandard),
              (ContrastStep.medium, l10n.displayContrastMedium),
              (ContrastStep.high, l10n.displayContrastHigh),
            ],
            onChanged: settings.setContrast,
            preview: (step) => _MiniScreen(
              // Its own scheme, built at that contrast — the whole difference
              // is in the palette, so a shared one would show nothing.
              scheme: AppTheme.scheme(
                Theme.of(context).brightness,
                contrast: step,
              ),
            ),
          ),
          _Choice<ColorVision>(
            title: l10n.displayColorVision,
            description: l10n.displayColorVisionDesc,
            value: context.watch<ColorVisionController>().vision,
            options: [
              (ColorVision.none, l10n.displayColorVisionNone),
              (ColorVision.protan, l10n.displayColorVisionProtan),
              (ColorVision.deutan, l10n.displayColorVisionDeutan),
              (ColorVision.tritan, l10n.displayColorVisionTritan),
            ],
            onChanged: context.read<ColorVisionController>().set,
            preview: (option) => _MiniScreen(
              scheme: Theme.of(context).colorScheme,
              vision: option,
            ),
          ),
        ],
      ),
    );
  }
}

/// One setting: a header, a line saying what it does, and its options as a row
/// of previews.
///
/// Previews rather than labels because none of these settings can be judged
/// from its name — "medium contrast" and "deuteranopia" mean nothing until you
/// see them, and the whole point of the page is choosing what you can read.
/// Each card paints the same mock screen under its own option, so the row is a
/// comparison rather than four assertions.
class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.description,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.preview,
  });

  final String title;
  final String description;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  /// The mock screen as this option would draw it.
  final Widget Function(T option) preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, (option, label)) in options.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ThemeOptionCard(
                    label: label,
                    selected: option == value,
                    onTap: () => onChanged(option),
                    child: preview(option),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
    // The whole card is the target, label included: the name is what a reader
    // looks at to decide, so it is what they reach for. Only the preview used to
    // take the tap, which left the label looking inert.
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.medium,
      child: Column(
        children: [
          AnimatedContainer(
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
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
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

/// A minimal mock of the app UI, painted under one specific set of display
/// settings — so a row of these shows what each option actually does instead of
/// naming it.
///
/// Every option renders the same screen with **its own** settings, not the ones
/// currently in force, which is why the colours go through
/// [ColorVisionFilter.transform] with an explicit [vision] rather than the
/// `.vision` extension: the extension reads the global setting, and here each
/// card needs a different one.
///
/// The intensity ramp is in the mock deliberately. It is the app's signature
/// colour semantics and the sequence a red- or green-weak eye collapses worst,
/// so it is where a colour-vision option is visible at all — a mock made only
/// of theme greys would look identical in all four.
class _MiniScreen extends StatelessWidget {
  const _MiniScreen({
    required this.scheme,
    this.vision = ColorVision.none,
    this.scale = TextScaleStep.normal,
    this.weight = TextWeightStep.normal,
  });

  final ColorScheme scheme;
  final ColorVision vision;
  final TextScaleStep scale;
  final TextWeightStep weight;

  Color _c(Color color) => ColorVisionFilter.transform(color, vision);

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

    // The felt-intensity scale, 1 → 7: the app's own palette, and the sequence
    // a colour-vision option changes most visibly.
    final ramp = Row(
      children: [
        for (var level = 1; level <= 9; level++)
          Expanded(
            child: Container(
              height: 10,
              margin: const EdgeInsets.only(right: 1),
              color: _c(IntensityColors.discrete(level)),
            ),
          ),
      ],
    );

    return Container(
      color: _c(scheme.surface),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: _c(scheme.primary),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ramp,
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _c(scheme.primaryContainer),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              // Real text, at this option's size and weight — the only way a
              // type setting reads as anything in a thumbnail.
              child: Text(
                '5\u207B',
                textScaler: TextScaler.linear(scale.factor),
                style: TextStyle(
                  fontSize: 13,
                  height: 1,
                  color: _c(scheme.onPrimaryContainer),
                  fontWeight:
                      FontWeight.values[(3 + weight.steps).clamp(
                        0,
                        FontWeight.values.length - 1,
                      )],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          bar(_c(scheme.surfaceContainerHighest)),
          const SizedBox(height: AppSpacing.xs),
          bar(_c(scheme.surfaceContainerHighest), widthFactor: 0.6),
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
