/// Display settings: theme mode, text size, text weight, contrast, and
/// colour-vision correction.
///
/// One sample at the top, the five settings below it. The sample stays put
/// while the options scroll, because the whole argument of the page is *look
/// what this does* — a preview that scrolls away as you reach for the control
/// that changes it is no preview at all. It needs no state plumbing: every one
/// of these settings is applied at the app root, so the sample redraws with the
/// rest of the app on the next frame (see `display_preview.dart`).
///
/// The options themselves are drawn small and self-demonstrating rather than as
/// mock screens. There used to be seventeen thumbnails here, one per option,
/// each rendering a whole fake app under a hypothetical setting — a page of
/// pictures too small to read, and seventeen `ColorScheme.fromSeed`
/// constructions per build. The sample answers "what will the app look like";
/// each option only has to answer "what does *this* one do", which an A drawn
/// at its own size, or a swatch built at its own contrast, answers better in
/// 20dp than a thumbnail did in a card.
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/app/theme/app_theme.dart';
import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/settings/color_vision_controller.dart';
import 'package:dpip/core/settings/display_settings.dart';
import 'package:dpip/core/settings/theme_controller.dart';
import 'package:dpip/features/settings/presentation/widgets/display_preview.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Schemes for the option swatches, built once per (brightness, contrast).
///
/// `ColorScheme.fromSeed` runs a full tonal-palette derivation; the contrast
/// swatches would otherwise rebuild three of them on every tap, on the page
/// whose subject is how the app feels.
///
/// Keyed only on what `AppTheme.scheme` actually takes — never widen this with
/// anything user-varying or it stops being a fixed-size table.
final Map<(Brightness, ContrastStep), ColorScheme> _schemeCache = {};

ColorScheme _schemeFor(
  Brightness brightness, [
  ContrastStep contrast = ContrastStep.standard,
]) => _schemeCache.putIfAbsent((
  brightness,
  contrast,
), () => AppTheme.scheme(brightness, contrast: contrast));

class DisplayPage extends StatelessWidget {
  const DisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.displaySettings)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Deliberately not a SliverPersistentHeader or an AppBar.bottom:
          // both need their extent as a constant known before layout, and this
          // page's subject is a runtime text scaler, so any extent hardcoded
          // here is wrong at one of the four steps. A sibling of the scrollable
          // makes "stays visible" structural instead of negotiated.
          final wide =
              constraints.maxWidth >= 600 ||
              constraints.maxWidth > constraints.maxHeight;

          if (wide) {
            // Landscape and tablets: side by side, so the sample keeps its full
            // size on exactly the screens where stacking would squeeze it into
            // a strip.
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: math.min(constraints.maxWidth * 0.45, 380),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom:
                          AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: DisplayPreview(availableHeight: double.infinity),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                const Expanded(child: _OptionList()),
              ],
            );
          }

          return Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      constraints.maxHeight * DisplayPreview.heightFraction,
                ),
                // The vertical-overflow contract. A viewport clips by
                // construction, so no combination of text scale and screen
                // height can stripe this panel with a RenderFlex overflow —
                // which would be a particularly bad look on the page that
                // promises big text still fits.
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: AnimatedSize(
                    duration: AppMotion.medium,
                    curve: Curves.easeOut,
                    // Grows downward, so a text-size change never shoves the
                    // sample up under the app bar.
                    alignment: Alignment.topCenter,
                    child: DisplayPreview(
                      availableHeight: constraints.maxHeight,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1),
              const Expanded(child: _OptionList()),
            ],
          );
        },
      ),
    );
  }
}

/// The five settings.
///
/// Two shapes, chosen by what the options *are*. Text size, weight and contrast
/// are ordinal — three or four points on one scale — so they read as a strip of
/// chips you compare left to right. Theme and colour vision are nominal, and
/// their names are long ("Blue-yellow weak (tritanopia)"), so they are list
/// rows, which wrap instead of overflowing and match the rest of the app's
/// settings pages.
///
/// Not `SegmentedButton`: it cannot wrap, and three "Standard"-length English
/// labels at text scale 1.45 need more width than a 320dp phone has. Not a
/// `Slider` for text size: it takes three of the four option names off the
/// screen and re-themes the whole app continuously under a moving finger.
class _OptionList extends StatelessWidget {
  const _OptionList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final themeMode = context.watch<ThemeController>().mode;
    final display = context.watch<DisplaySettings>();
    final vision = context.watch<ColorVisionController>().vision;

    return ListView(
      padding: EdgeInsets.only(
        bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        SectionHeader(l10n.displayTheme),
        for (final (mode, label) in [
          (ThemeMode.system, l10n.themeSystem),
          (ThemeMode.light, l10n.themeLight),
          (ThemeMode.dark, l10n.themeDark),
        ])
          _OptionRow(
            label: label,
            selected: themeMode == mode,
            glyph: _ThemeGlyph(mode: mode),
            onTap: () => context.read<ThemeController>().setMode(mode),
          ),

        SectionHeader(l10n.displayTextSize),
        _Description(l10n.displayTextSizeDesc),
        _ChipRow(
          children: [
            for (final (step, label) in [
              (TextScaleStep.small, l10n.displayScaleSmall),
              (TextScaleStep.normal, l10n.displayScaleDefault),
              (TextScaleStep.large, l10n.displayScaleLarge),
              (TextScaleStep.huge, l10n.displayScaleHuge),
            ])
              _OptionChip(
                label: label,
                selected: display.textScale == step,
                avatar: _SizeGlyph(step: step),
                onSelected: () => display.setTextScale(step),
              ),
          ],
        ),

        SectionHeader(l10n.displayTextWeight),
        _Description(l10n.displayTextWeightDesc),
        _ChipRow(
          children: [
            for (final (step, label) in [
              (TextWeightStep.normal, l10n.displayWeightNormal),
              (TextWeightStep.medium, l10n.displayWeightMedium),
              (TextWeightStep.bold, l10n.displayWeightBold),
            ])
              _OptionChip(
                label: label,
                selected: display.textWeight == step,
                // The option is its own specimen: no avatar needed, so the
                // chip keeps its default checkmark as the non-colour cue.
                // `copyWith` overrides the ambient (already bumped) weight, so
                // each chip shows the absolute weight its option produces
                // rather than one compounded with the current setting.
                labelStyle: TextStyle(fontWeight: weightOfStep(step)),
                onSelected: () => display.setTextWeight(step),
              ),
          ],
        ),

        SectionHeader(l10n.displayContrast),
        _Description(l10n.displayContrastDesc),
        _ChipRow(
          children: [
            for (final (step, label) in [
              (ContrastStep.standard, l10n.displayContrastStandard),
              (ContrastStep.medium, l10n.displayContrastMedium),
              (ContrastStep.high, l10n.displayContrastHigh),
            ])
              _OptionChip(
                label: label,
                selected: display.contrast == step,
                avatar: _ContrastGlyph(step: step, brightness: brightness),
                onSelected: () => display.setContrast(step),
              ),
          ],
        ),

        SectionHeader(l10n.displayColorVision),
        _Description(l10n.displayColorVisionDesc),
        for (final (option, label) in [
          (ColorVision.none, l10n.displayColorVisionNone),
          (ColorVision.protan, l10n.displayColorVisionProtan),
          (ColorVision.deutan, l10n.displayColorVisionDeutan),
          (ColorVision.tritan, l10n.displayColorVisionTritan),
        ])
          _OptionRow(
            label: label,
            selected: vision == option,
            glyph: _VisionGlyph(vision: option),
            onTap: () => context.read<ColorVisionController>().set(option),
          ),
      ],
    );
  }
}

/// The absolute [FontWeight] a [TextWeightStep] produces from Material's w400
/// default — index 3 in [FontWeight.values].
FontWeight weightOfStep(TextWeightStep step) =>
    FontWeight.values[(3 + step.steps).clamp(0, FontWeight.values.length - 1)];

/// The line under a section header saying what the setting does.
class _Description extends StatelessWidget {
  const _Description(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A strip of option chips. A `Wrap` rather than a `Row`, so a long label at a
/// large text scale takes a second line instead of overflowing.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.md,
    ),
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: children,
    ),
  );
}

/// One option on an ordinal scale.
class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.avatar,
    this.labelStyle,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  /// The option drawn as itself. When present the checkmark is suppressed — it
  /// would *replace* the avatar on selection, deleting the one member of the
  /// comparison strip the reader just chose.
  final Widget? avatar;

  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ChoiceChip(
      avatar: avatar == null ? null : ExcludeSemantics(child: avatar),
      showCheckmark: avatar == null,
      label: Text(
        label,
        style: (labelStyle ?? const TextStyle()).copyWith(
          color: selected ? colors.onSecondaryContainer : null,
        ),
      ),
      selected: selected,
      side: selected ? BorderSide(color: colors.primary, width: 2) : null,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onSelected();
      },
    );
  }
}

/// One option on a nominal scale — a settings row with its specimen as the
/// leading glyph.
///
/// The glyph stands in for the leading icon every menu row in this app carries.
/// It is a declared exception: for these two settings the *colour* is the
/// information, and no Material glyph distinguishes protanopia from
/// deuteranopia.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.glyph,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Widget glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: ExcludeSemantics(child: glyph),
      title: Text(label),
      selected: selected,
      trailing: selected ? Icon(Icons.check, color: colors.primary) : null,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }
}

/// A theme mode as a square of its own surface colour. `system` splits
/// diagonally, showing both at once.
///
/// These are *not* colour-vision corrected: `ColorScheme.fromSeed` output never
/// goes through the filter in this app, so correcting here would make the glyph
/// disagree with the theme it advertises.
class _ThemeGlyph extends StatelessWidget {
  const _ThemeGlyph({required this.mode});

  final ThemeMode mode;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final light = _schemeFor(Brightness.light);
    final dark = _schemeFor(Brightness.dark);
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        borderRadius: AppRadius.small,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.small,
        child: switch (mode) {
          ThemeMode.light => _half(light, Icons.light_mode_outlined),
          ThemeMode.dark => _half(dark, Icons.dark_mode_outlined),
          ThemeMode.system => Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: light.surface),
              ClipPath(
                clipper: _DiagonalClipper(),
                child: ColoredBox(color: dark.surface),
              ),
              Align(
                alignment: const Alignment(-0.45, -0.45),
                child: Icon(
                  Icons.light_mode_outlined,
                  size: 14,
                  color: light.onSurface,
                ),
              ),
              Align(
                alignment: const Alignment(0.45, 0.45),
                child: Icon(
                  Icons.dark_mode_outlined,
                  size: 14,
                  color: dark.onSurface,
                ),
              ),
            ],
          ),
        },
      ),
    );
  }

  Widget _half(ColorScheme scheme, IconData icon) => ColoredBox(
    color: scheme.surface,
    child: Center(child: Icon(icon, size: 18, color: scheme.onSurface)),
  );
}

/// An `A` at the option's own size — a staircase across the four chips.
class _SizeGlyph extends StatelessWidget {
  const _SizeGlyph({required this.step});

  final TextScaleStep step;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 20,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Text(
        // l10n-ignore: a letterform specimen, not a word.
        'A',
        // Load-bearing, and it reads like an oversight: the glyph is a specimen
        // of a *ratio*. Inheriting the ambient scaler would grow all four A's
        // together and flatten the comparison to nothing. The chip's label
        // beside it scales normally, so the control itself stays readable.
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontSize: 11 * step.factor,
          height: 1,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
  );
}

/// Text on a surface, both taken from a scheme built at the option's own
/// contrast — the whole difference between the three is in the palette, so a
/// shared scheme would show nothing.
///
/// Uses the `surfaceContainerHighest` / `onSurfaceVariant` pair on purpose:
/// Material's contrast level moves those, while `surface` and `onSurface` stay
/// near-white and near-black at all three steps and would render three
/// identical swatches.
class _ContrastGlyph extends StatelessWidget {
  const _ContrastGlyph({required this.step, required this.brightness});

  final ContrastStep step;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final scheme = _schemeFor(brightness, step);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.small,
        border: Border.all(color: scheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Text(
        // l10n-ignore: a letterform specimen, not a word.
        'A',
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Four intensity colours under one colour-vision option — the test plate.
///
/// Blue/green is the pair tritanopia collapses; green/yellow/red is the run
/// protanopia and deuteranopia flatten. Together they make the four rows
/// distinguishable to the eye each one is for.
///
/// Painted from [IntensityColors.published], the *untransformed* table, then
/// through this option's own transform. Reading `discrete` here would correct a
/// colour the current setting had already corrected, and the four swatches
/// would drift the moment any option but standard was in force.
class _VisionGlyph extends StatelessWidget {
  const _VisionGlyph({required this.vision});

  final ColorVision vision;

  /// Blue and green (tritan's pair) on top, yellow and red (the protan and
  /// deutan run) below.
  static const List<List<int>> _levels = [
    [2, 3],
    [4, 7],
  ];

  Color _cell(int level) =>
      ColorVisionFilter.transform(IntensityColors.published(level), vision);

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 36,
    child: ClipRRect(
      borderRadius: AppRadius.small,
      // Four Expandeds rather than a GridView: a two-by-two of fixed colours
      // needs no viewport, and a scrollable here would be one more Scrollable
      // in the page for anything walking the tree to trip over.
      child: Column(
        children: [
          for (final row in _levels)
            Expanded(
              child: Row(
                children: [
                  for (final level in row)
                    Expanded(child: ColoredBox(color: _cell(level))),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// Clips to the bottom-right triangle, for the split light/dark system glyph.
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
