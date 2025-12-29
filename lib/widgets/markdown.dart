/// Markdown rendering widget.
///
/// This file provides a customizable markdown renderer that supports:
/// - Standard markdown syntax
/// - Syntax highlighting for code blocks
/// - Custom styled headings, links, and blockquotes
/// - Copy-to-clipboard functionality for code blocks
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:markdown_widget/markdown_widget.dart' hide ImageViewer;
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:simple_icons/simple_icons.dart';

import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/string.dart';

/// Programming languages supported for syntax highlighting in code blocks.
///
/// Each language can optionally define an icon and color for visual
/// identification in code block headers.
enum Language {
  /// The C programming language.
  c(name: 'C', icon: SimpleIcons.c, iconColor: SimpleIconColors.c),

  /// The C++ programming language.
  cpp(
    name: 'C++',
    icon: SimpleIcons.cplusplus,
    iconColor: SimpleIconColors.cplusplus,
  ),

  /// The C# programming language.
  csharp(name: 'C#'),

  /// The Dart programming language.
  dart(name: 'Dart', icon: SimpleIcons.dart, iconColor: SimpleIconColors.dart),

  /// The Java programming language.
  java(name: 'Java'),

  /// The JavaScript programming language.
  javascript(
    name: 'JavaScript',
    icon: SimpleIcons.javascript,
    iconColor: SimpleIconColors.javascript,
  ),

  /// The JavaScript programming language with XML syntax support (aka .jsx).
  javascriptReact(
    name: 'JavaScript React',
    icon: SimpleIcons.react,
    iconColor: SimpleIconColors.javascript,
  ),

  /// The Kotlin programming language.
  kotlin(
    name: 'Kotlin',
    icon: SimpleIcons.kotlin,
    iconColor: SimpleIconColors.kotlin,
  ),

  /// The Markdown markup language.
  markdown(
    name: 'Markdown',
    icon: Symbols.markdown_rounded,
    iconColor: SimpleIconColors.markdown,
  ),

  /// The Python programming language.
  python(
    name: 'Python',
    icon: SimpleIcons.python,
    iconColor: SimpleIconColors.python,
  ),

  /// The TypeScript programming language.
  typescript(
    name: 'TypeScript',
    icon: SimpleIcons.typescript,
    iconColor: SimpleIconColors.typescript,
  ),

  /// The TypeScript programming language with XML syntax support (aka .tsx).
  typescriptReact(
    name: 'TypeScript React',
    icon: SimpleIcons.react,
    iconColor: SimpleIconColors.react,
  ),

  /// The Vue framework language.
  vue(
    name: 'Vue',
    icon: SimpleIcons.vuedotjs,
    iconColor: SimpleIconColors.vuedotjs,
  )
  ;

  /// The display name of the language.
  final String name;

  /// The icon representing this language (optional).
  final IconData? icon;

  /// The color to apply to the icon (optional).
  final Color? iconColor;

  const Language({required this.name, this.icon, this.iconColor});
}

/// Resolves a language identifier string to a [Language] enum value.
///
/// Supports multiple aliases for each language (e.g., 'js', 'javascript').
/// Returns `null` if the language is not recognized.
///
/// Example:
/// ```dart
/// resolveLanguage('js') // Returns Language.javascript
/// resolveLanguage('tsx') // Returns Language.typescriptReact
/// resolveLanguage('unknown') // Returns null
/// ```
Language? resolveLanguage(String language) {
  switch (language) {
    case 'c':
      return Language.c;

    case 'cpp':
    case 'c++':
      return Language.cpp;

    case 'cs':
    case 'csharp':
      return Language.csharp;

    case 'dart':
      return Language.dart;

    case 'java':
      return Language.java;

    case 'js':
    case 'javascript':
      return Language.javascript;

    case 'jsx':
    case 'javascriptreact':
      return Language.javascriptReact;

    case 'kt':
    case 'kotlin':
      return Language.kotlin;

    case 'md':
    case 'markdown':
      return Language.markdown;

    case 'py':
    case 'python':
      return Language.python;

    case 'tsx':
    case 'typescriptreact':
      return Language.typescriptReact;

    case 'ts':
    case 'typescript':
      return Language.typescript;

    case 'vue':
      return Language.vue;
  }

  return null;
}

/// A wrapper widget for markdown code blocks that adds a language header
/// and copy-to-clipboard functionality.
///
/// This widget displays a header bar showing the programming language with
/// an icon and a copy button. When the copy button is pressed, the code
/// content is copied to the clipboard and the button icon changes to a
/// checkmark for 1 second to provide visual feedback.
class MarkdownPreWrapper extends StatefulWidget {
  /// The code block content widget to wrap.
  final Widget child;

  /// The programming language identifier for the code block.
  final String language;

  /// The raw code text to copy to clipboard.
  final String code;

  /// Construct a [MarkdownPreWrapper] that wraps a pre block with custom Container
  const MarkdownPreWrapper(this.child, this.code, this.language, {super.key});

  @override
  State<MarkdownPreWrapper> createState() => _MarkdownPreWrapperState();
}

class _MarkdownPreWrapperState extends State<MarkdownPreWrapper> {
  bool _isCopied = false;
  Timer? _timer;

  void copy() async {
    _timer?.cancel();
    setState(() => _isCopied = true);
    await widget.code.copy();
    _timer = Timer(
      const Duration(seconds: 1),
      () => setState(() => _isCopied = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.language.isEmpty) {
      return widget.child;
    }

    final language = resolveLanguage(widget.language);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: .circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const .only(left: 16),
            child: Row(
              spacing: 8,
              children: [
                Icon(
                  language?.icon ?? Symbols.code_rounded,
                  color: language?.iconColor,
                  size: 16,
                ),
                Expanded(
                  child: Text(
                    language?.name ?? widget.language,
                    style: context.texts.bodyMedium!.copyWith(
                      fontWeight: .bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: copy,
                  tooltip: _isCopied ? '已複製' : '複製',
                  icon: Icon(
                    _isCopied
                        ? Symbols.check_rounded
                        : Symbols.content_copy_rounded,
                    size: 16,
                  ),
                  visualDensity: .compact,
                ),
              ],
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// Utilities for processing markdown markup formats.
///
/// This class provides static methods for:
/// - HTML entity unescaping
/// - Auto-linking bare URLs
/// - Formatting blockquotes
abstract class MarkdownUtils {
  static final _escaper = HtmlUnescape();
  static final _autoLinkPattern = RegExp(
    r'(?<!<)(?<!\]\()(?<!\]:\s*)(https?:\/\/[^\s>)\]]+)(?!>)',
  );

  /// Unescapes HTML entities in the given text.
  ///
  /// Converts HTML entities like `&amp;`, `&lt;`, `&gt;` to their
  /// corresponding characters.
  static String unescape(String text) {
    return _escaper.convert(text);
  }

  /// Wraps bare URLs in angle brackets to enable auto-linking.
  ///
  /// This ensures that URLs not already in markdown link syntax are
  /// properly recognized and rendered as clickable links.
  static String fixAutoLinks(String text) {
    return text.replaceAllMapped(_autoLinkPattern, (m) => '<${m[1]}>');
  }

  /// Processes text through auto-detection, conversion, and escaping.
  ///
  /// This is the main entry point for text processing. It:
  /// 1. Unescapes HTML entities
  /// 2. Auto-links bare URLs
  ///
  /// Returns the processed markdown string ready for rendering.
  static String apply(String text) {
    return fixAutoLinks(
      unescape(text),
    );
  }

  /// Formats text as a markdown blockquote.
  ///
  /// Prepends `> ` to each line of the text to create a blockquote block.
  static String blockquote(String text) {
    return text.split('\n').map((line) => '> $line').join('\n');
  }
}

/// Applies JetBrains Mono font to a text style with ligatures enabled.
///
/// Used for code blocks and inline code to provide monospace rendering
/// with programming ligatures enabled via the 'calt' font feature.
TextStyle applyFont(TextStyle style) {
  return GoogleFonts.jetBrainsMono(
    textStyle: style,
    fontFeatures: [.enable('calt')],
  );
}

Map<String, TextStyle> _githubTheme = {
  'root': applyFont(
    TextStyle(color: Color(0xff333333), backgroundColor: Color(0xfff8f8f8)),
  ),
  'comment': applyFont(
    TextStyle(color: Color(0xff999988), fontStyle: .italic),
  ),
  'quote': applyFont(
    TextStyle(color: Color(0xff999988), fontStyle: .italic),
  ),
  'keyword': applyFont(
    TextStyle(color: Color(0xff333333), fontWeight: .bold),
  ),
  'selector-tag': applyFont(
    TextStyle(color: Color(0xff333333), fontWeight: .bold),
  ),
  'subst': applyFont(
    TextStyle(color: Color(0xff333333), fontWeight: .normal),
  ),
  'number': applyFont(TextStyle(color: Color(0xff008080))),
  'literal': applyFont(TextStyle(color: Color(0xff008080))),
  'variable': applyFont(TextStyle(color: Color(0xff008080))),
  'template-variable': applyFont(TextStyle(color: Color(0xff008080))),
  'string': applyFont(TextStyle(color: Color(0xffdd1144))),
  'doctag': applyFont(TextStyle(color: Color(0xffdd1144))),
  'title': applyFont(
    TextStyle(color: Color(0xff990000), fontWeight: .bold),
  ),
  'section': applyFont(
    TextStyle(color: Color(0xff990000), fontWeight: .bold),
  ),
  'selector-id': applyFont(
    TextStyle(color: Color(0xff990000), fontWeight: .bold),
  ),
  'type': applyFont(
    TextStyle(color: Color(0xff445588), fontWeight: .bold),
  ),
  'tag': applyFont(
    TextStyle(color: Color(0xff000080), fontWeight: .normal),
  ),
  'name': applyFont(
    TextStyle(color: Color(0xff000080), fontWeight: .normal),
  ),
  'attribute': applyFont(
    TextStyle(color: Color(0xff000080), fontWeight: .normal),
  ),
  'regexp': applyFont(TextStyle(color: Color(0xff009926))),
  'link': applyFont(TextStyle(color: Color(0xff009926))),
  'symbol': applyFont(TextStyle(color: Color(0xff990073))),
  'bullet': applyFont(TextStyle(color: Color(0xff990073))),
  'built_in': applyFont(TextStyle(color: Color(0xff0086b3))),
  'builtin-name': applyFont(TextStyle(color: Color(0xff0086b3))),
  'meta': applyFont(
    TextStyle(color: Color(0xff999999), fontWeight: .bold),
  ),
  'deletion': applyFont(TextStyle(backgroundColor: Color(0xffffdddd))),
  'addition': applyFont(TextStyle(backgroundColor: Color(0xffddffdd))),
  'emphasis': applyFont(TextStyle(fontStyle: .italic)),
  'strong': applyFont(TextStyle(fontWeight: .bold)),
};

Map<String, TextStyle> _githubThemeDark = {
  'root': applyFont(
    TextStyle(color: Color(0xffadbac7), backgroundColor: Color(0xff22272e)),
  ),
  'comment': applyFont(TextStyle(color: Color(0xff768390))),
  'quote': applyFont(TextStyle(color: Color(0xff8ddb8c))),
  'keyword': applyFont(TextStyle(color: Color(0xfff47067))),
  'selector-tag': applyFont(TextStyle(color: Color(0xfff47067))),
  'subst': applyFont(TextStyle(color: Color(0xffadbac7))),
  'number': applyFont(TextStyle(color: Color(0xff6cb6ff))),
  'literal': applyFont(TextStyle(color: Color(0xff6cb6ff))),
  'variable': applyFont(TextStyle(color: Color(0xff6cb6ff))),
  'template-variable': applyFont(TextStyle(color: Color(0xff6cb6ff))),
  'string': applyFont(TextStyle(color: Color(0xff96d0ff))),
  'doctag': applyFont(TextStyle(color: Color(0xff96d0ff))),
  'title': applyFont(TextStyle(color: Color(0xffdcbdfb))),
  'section': applyFont(
    TextStyle(color: Color(0xff316dca), fontWeight: .bold),
  ),
  'selector-id': applyFont(TextStyle(color: Color(0xff6cb6ff))),
  'type': applyFont(TextStyle(color: Color(0xffdcbdfb))),
  'tag': applyFont(TextStyle(color: Color(0xff8ddb8c))),
  'name': applyFont(TextStyle(color: Color(0xff8ddb8c))),
  'attribute': applyFont(TextStyle(color: Color(0xff6cb6ff))),
  'regexp': applyFont(TextStyle(color: Color(0xff96d0ff))),
  'link': applyFont(TextStyle(color: Color(0xff96d0ff))),
  'symbol': applyFont(TextStyle(color: Color(0xfff69d50))),
  'bullet': applyFont(TextStyle(color: Color(0xffeac55f))),
  'built_in': applyFont(TextStyle(color: Color(0xfff69d50))),
  'builtin-name': applyFont(TextStyle(color: Color(0xfff69d50))),
  'meta': applyFont(TextStyle(color: Color(0xff768390))),
  'deletion': applyFont(
    TextStyle(color: Color(0xffffd8d3), backgroundColor: Color(0xff78191b)),
  ),
  'addition': applyFont(
    TextStyle(color: Color(0xffb4f1b4), backgroundColor: Color(0xff1b4721)),
  ),
  'emphasis': applyFont(
    TextStyle(color: Color(0xffadbac7), fontStyle: .italic),
  ),
  'strong': applyFont(
    TextStyle(color: Color(0xffadbac7), fontWeight: .bold),
  ),
};

class _H1Config extends H1Config {
  final Color divierColor;

  _H1Config({required this.divierColor, super.style});

  @override
  HeadingDivider? get divider => HeadingDivider.h1.copy(color: divierColor);
}

class _H2Config extends H2Config {
  final Color divierColor;

  _H2Config({required this.divierColor, super.style});

  @override
  HeadingDivider? get divider => HeadingDivider.h2.copy(color: divierColor);
}

class _H3Config extends H3Config {
  _H3Config({super.style});

  @override
  HeadingDivider? get divider => null;
}

class Markdown extends StatelessWidget {
  final String text;

  const Markdown(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;

    TextStyle applyFont(TextStyle style) => GoogleFonts.lato(textStyle: style);

    final headlineSmall = applyFont(context.texts.headlineSmall!);
    final titleLarge = applyFont(context.texts.titleLarge!);
    final titleMedium = applyFont(context.texts.titleMedium!);
    final titleSmall = applyFont(context.texts.titleSmall!);
    final bodyMedium = applyFont(context.texts.bodyMedium!);

    return MarkdownBlock(
      data: MarkdownUtils.apply(text),
      config:
          (isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig)
              .copy(
                configs: [
                  _H1Config(
                    style: headlineSmall.copyWith(fontWeight: .bold),
                    divierColor: context.colors.outlineVariant,
                  ),
                  _H2Config(
                    style: titleLarge.copyWith(fontWeight: .bold),
                    divierColor: context.colors.outlineVariant,
                  ),
                  _H3Config(
                    style: titleMedium.copyWith(fontWeight: .bold),
                  ),
                  H4Config(
                    style: titleSmall.copyWith(fontWeight: .bold),
                  ),
                  HrConfig(color: context.colors.outlineVariant),
                  LinkConfig(
                    style: TextStyle(
                      color: context.colors.primary,
                      decoration: .underline,
                      decorationColor: context.colors.primary,
                    ),
                    onTap: (url) => url.launch(),
                  ),
                  ImgConfig(
                    builder: (url, attributes) {
                      return CachedNetworkImage(imageUrl: url);
                    },
                  ),
                  BlockquoteConfig(
                    sideColor: context.colors.outlineVariant,
                    textColor: context.colors.outline,
                  ),
                  PConfig(textStyle: bodyMedium),
                  CodeConfig(style: applyFont(bodyMedium)),
                  PreConfig(
                    wrapper: MarkdownPreWrapper.new,
                    margin: .zero,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                    ),
                    language: 'text',
                    theme: isDark ? _githubThemeDark : _githubTheme,
                    styleNotMatched: applyFont(bodyMedium),
                  ),
                ],
              ),
    );
  }
}
