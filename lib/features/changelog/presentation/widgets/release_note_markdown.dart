import 'package:flutter/material.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';

/// How a release note is rendered in the app.
///
/// One file, used by every page that shows a note. The style sheet lived in
/// both pages as a 110-line copy, and the platform-tag builder lived in only
/// one of them — so the second page fetched its tags over the network on a
/// screen that exists to be read offline. A single owner is what stops that.
///
/// The note being styled is a specific document, not markdown in general:
///
///     _快照，取自 main 的 `290bba4e`。未經審查，可能有問題。_
///
///     ### 🌟 新功能
///
///     - ⬢ ⬡ 條目文字 — @whes1015 · `26w33a`
///
/// So `###` is the only structural heading there is, every list item is a
/// sentence that wraps, and each one already begins with two icons.
MarkdownStyleSheet releaseNoteStyleSheet(
  ThemeData theme,
  ColorScheme colors,
  Color accent,
) {
  final text = theme.textTheme;
  return MarkdownStyleSheet(
    p: text.bodyMedium?.copyWith(color: colors.onSurface, height: 1.6),
    pPadding: const EdgeInsets.only(bottom: AppSpacing.xs),

    // A note opens with one italic line — the snapshot caveat, or the range a
    // release covers. It is a caption, not a paragraph.
    em: text.bodySmall?.copyWith(
      fontStyle: FontStyle.italic,
      color: colors.onSurfaceVariant,
      height: 1.5,
    ),

    // `###` carries the weight the old design gave `##`, because a generated
    // note has no `##` at all: the section heading was rendering barely larger
    // than the entries under it, which is what flattened the whole note.
    // `#` and `##` stay sane for notes published before the current format.
    h1: text.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: colors.onSurface,
      letterSpacing: -0.3,
    ),
    h1Padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    h2: text.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: colors.onSurface,
    ),
    h2Padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
    h3: text.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: colors.onSurface,
      letterSpacing: -0.1,
    ),
    // Handled by the builder below, which owns the spacing around the rule.
    h3Padding: EdgeInsets.zero,
    h4: text.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.onSurfaceVariant,
    ),
    h4Padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),

    strong: text.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.onSurface,
    ),
    del: text.bodyMedium?.copyWith(
      decoration: TextDecoration.lineThrough,
      color: colors.onSurfaceVariant,
    ),
    a: text.bodyMedium?.copyWith(
      color: colors.primary,
      fontWeight: FontWeight.w600,
    ),

    // Entries are the body of the note and sit close together; the air belongs
    // above each heading, where the builder puts it.
    blockSpacing: AppSpacing.xs,
    // Each entry already opens with platform icons, so the bullet is a
    // position marker and nothing more — accent-coloured and bold, it was the
    // third thing competing for the start of every line.
    listIndent: AppSpacing.lg,
    listBullet: text.bodyMedium?.copyWith(color: colors.outline, height: 1.6),
    listBulletPadding: const EdgeInsets.only(right: AppSpacing.xs),

    blockquote: text.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
      height: 1.5,
    ),
    blockquoteDecoration: BoxDecoration(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: AppRadius.small,
      border: Border(left: BorderSide(color: accent, width: 3)),
    ),
    blockquotePadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),

    // The pre-release marker on the end of an entry is metadata. In `primary`
    // on a tinted ground it read as a button.
    code: text.bodySmall?.copyWith(
      fontFamily: 'monospace',
      color: colors.onSurfaceVariant,
      backgroundColor: colors.surfaceContainerHighest,
    ),
    codeblockPadding: const EdgeInsets.all(AppSpacing.md),
    codeblockDecoration: BoxDecoration(
      color: colors.surfaceContainerHighest,
      borderRadius: AppRadius.small,
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: colors.outlineVariant, width: 1)),
    ),

    tableHead: text.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: colors.onSurface,
    ),
    tableBody: text.bodySmall?.copyWith(color: colors.onSurface),
    tableBorder: TableBorder.all(color: colors.outlineVariant, width: 1),
    tableCellsPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    checkbox: text.bodyMedium?.copyWith(color: accent),
  );
}

/// Element builders for a release note. Pass alongside [releaseNoteStyleSheet].
Map<String, MarkdownElementBuilder> releaseNoteBuilders(ColorScheme colors) => {
  'h3': _SectionHeading(colors),
};

/// A section heading with a hairline above it.
///
/// The style sheet has no per-heading decoration, and space alone did not
/// separate the sections: a note is three short lists in a row, and without a
/// rule they read as one list with bold lines scattered through it. GitHub
/// draws the same rule, which is most of why a note looks structured there.
class _SectionHeading extends MarkdownElementBuilder {
  _SectionHeading(this.colors);

  final ColorScheme colors;

  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, thickness: 1, color: colors.outlineVariant),
          const SizedBox(height: AppSpacing.sm),
          Text(element.textContent, style: preferredStyle),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

/// Draws the platform tags in a release note without fetching anything, and
/// **inline with the words after them**.
///
/// A note marks which platforms an entry applies to with 14 px SVGs hosted in
/// this repository, because that is what GitHub renders. In the app the same
/// Markdown would become an `Image.network` — and this app is read when the
/// network is the thing that failed, so every tag would be a broken box
/// exactly when the note matters most.
///
/// The return type is what makes it flow. `MarkdownBuilder` merges a run of
/// inline children into one `RichText`, but only for widgets it can pull a
/// span out of — `Text`, `RichText`, `SelectableText`. Returning a bare `Icon`
/// (or an `Icon` in a `Padding`) is none of those, so the icon became its own
/// item in the surrounding `Wrap` and pushed the entry's whole sentence onto
/// the next line. Wrapped in a `WidgetSpan` inside a `Text.rich`, it merges
/// into the same paragraph and the text continues beside it.
///
/// Anything else still works: the builder cannot decline, so an unknown image
/// degrades to its own alt text rather than to a failed request.
Widget platformTagIcon(Uri uri, String? title, String? alt) {
  final name = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
  final icon = switch (name) {
    'android.svg' => Icons.android,
    'ios.svg' => Icons.apple,
    _ => null,
  };
  if (icon == null) return Text(alt ?? '');
  final brand = name == 'android.svg' ? _androidGreen : _appleGrey;
  return Text.rich(
    TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Builder(
            builder: (context) {
              final style = DefaultTextStyle.of(context).style;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Icon(
                  icon,
                  // Tied to the text it sits in, so it tracks the reader's
                  // font scale instead of staying 15 px while the words grow.
                  size: (style.fontSize ?? 14) + 1,
                  color: brand.resolve(Theme.of(context).brightness),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

/// The platform brand colours, in the app.
///
/// The published SVGs are a single fixed tint each, because an `<img>` on
/// GitHub inherits no theme. In the app the same mark is drawn twice — once
/// per theme — so each carries the shade that survives its own background.
///
/// Android's own `#3DDC84` scores 1.74:1 on a light surface, which is not a
/// mark, it is a smudge; the light variant keeps the hue and takes it to
/// 4.27:1. Apple's `#8E8E93` is their system grey and already clears both
/// (3.18:1 and 5.70:1), so it stands unchanged.
extension type const _Brand((Color light, Color dark) shades) {
  Color resolve(Brightness brightness) =>
      brightness == Brightness.dark ? shades.$2 : shades.$1;
}

const _androidGreen = _Brand((Color(0xFF1B8A50), Color(0xFF3DDC84)));
const _appleGrey = _Brand((Color(0xFF8E8E93), Color(0xFF8E8E93)));
