import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

/// A widget that displays text using Material Design 3 display text styles.
///
/// Display text is the largest text style in Material Design 3, typically used for hero text and prominent displays.
/// This widget provides convenient constructors for small, medium, and large display text variants, each corresponding
/// to Material Design 3's display text styles.
///
/// The text style is automatically retrieved from the theme's [TextTheme] and can be customized through optional
/// parameters like [color], [weight], and [style].
class DisplayText extends StatelessWidget {
  /// The text content to display.
  final String data;

  /// Optional custom text style that will be merged with the theme's display text style.
  final TextStyle? style;

  /// Optional text alignment.
  final TextAlign? align;

  /// Internal function that retrieves the appropriate display text style from the theme.
  final TextStyle? Function(BuildContext) _textStyleGetter;

  /// Creates a small display text widget.
  ///
  /// Uses the theme's `displaySmall` text style. The [color], [weight], and [style] parameters can be used to customize
  /// the appearance, and will be merged with the theme's base style.
  DisplayText.small(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(color: color, fontWeight: weight).merge(style),
       _textStyleGetter = ((context) => context.texts.displaySmall);

  /// Creates a medium display text widget.
  ///
  /// Uses the theme's `displayMedium` text style. The [color], [weight], and [style] parameters can be used to
  /// customize the appearance, and will be merged with the theme's base style.
  DisplayText.medium(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(color: color, fontWeight: weight).merge(style),
       _textStyleGetter = ((context) => context.texts.displayMedium);

  /// Creates a large display text widget.
  ///
  /// Uses the theme's `displayLarge` text style. The [color], [weight], and [style] parameters can be used to customize
  /// the appearance, and will be merged with the theme's base style.
  DisplayText.large(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(color: color, fontWeight: weight).merge(style),
       _textStyleGetter = ((context) => context.texts.displayLarge);

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: _textStyleGetter(context)?.merge(style),
      textAlign: align,
    );
  }
}

/// A widget that displays text using Material Design 3 headline text styles.
///
/// Headline text is used for section headings and prominent titles. This widget provides convenient constructors for
/// small, medium, and large headline text variants, each corresponding to Material Design 3's headline text styles.
///
/// The text style is automatically retrieved from the theme's [TextTheme] and can be customized through optional
/// parameters like [color], [weight], and [style].
class HeadLineText extends StatelessWidget {
  /// The text content to display.
  final String data;

  /// Optional custom text style that will be merged with the theme's headline text style.
  final TextStyle? style;

  /// Optional text alignment.
  final TextAlign? align;

  /// Internal function that retrieves the appropriate headline text style from the theme.
  final TextStyle? Function(BuildContext) _textStyleGetter;

  /// Creates a small headline text widget.
  ///
  /// Uses the theme's `headlineSmall` text style. The [color], [weight], and [style] parameters can be used to
  /// customize the appearance, and will be merged with the theme's base style.
  HeadLineText.small(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(color: color, fontWeight: weight).merge(style),
       _textStyleGetter = ((context) => context.texts.headlineSmall);

  /// Creates a medium headline text widget.
  ///
  /// Uses the theme's `headlineMedium` text style. The [color], [weight], and [style] parameters can be used to
  /// customize the appearance, and will be merged with the theme's base style.
  HeadLineText.medium(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(color: color, fontWeight: weight).merge(style),
       _textStyleGetter = ((context) => context.texts.headlineMedium);

  /// Creates a large headline text widget.
  ///
  /// Uses the theme's `headlineLarge` text style. The [color], [weight], and [style] parameters can be used to
  /// customize the appearance, and will be merged with the theme's base style.
  HeadLineText.large(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(color: color, fontWeight: weight).merge(style),
       _textStyleGetter = ((context) => context.texts.headlineLarge);

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: _textStyleGetter(context)?.merge(style),
      textAlign: align,
    );
  }
}

/// A widget that displays text using Material Design 3 title text styles.
///
/// Title text is used for card titles, list item titles, and other prominent text elements. This widget provides
/// convenient constructors for small, medium, and large title text variants, each corresponding to Material Design 3's
/// title text styles.
///
/// The text style is automatically retrieved from the theme's [TextTheme] and can be customized through optional
/// parameters like [color], [weight], [leading], and [style].
class TitleText extends StatelessWidget {
  /// The text content to display.
  final String data;

  /// Optional custom text style that will be merged with the theme's title text style.
  final TextStyle? style;

  /// Optional text alignment.
  final TextAlign? align;

  /// Internal function that retrieves the appropriate title text style from the theme.
  final TextStyle? Function(BuildContext) _textStyleGetter;

  /// Creates a small title text widget.
  ///
  /// Uses the theme's `titleSmall` text style. The [color], [weight], [leading], and [style] parameters can be used to
  /// customize the appearance, and will be merged with the theme's base style.
  TitleText.small(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    double? leading,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(
         color: color,
         fontWeight: weight,
         height: leading,
       ).merge(style),
       _textStyleGetter = ((context) => context.texts.titleSmall);

  /// Creates a medium title text widget.
  ///
  /// Uses the theme's `titleMedium` text style. The [color], [weight], [leading], and [style] parameters can be used to
  /// customize the appearance, and will be merged with the theme's base style.
  TitleText.medium(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    double? leading,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(
         color: color,
         fontWeight: weight,
         height: leading,
       ).merge(style),
       _textStyleGetter = ((context) => context.texts.titleMedium);

  /// Creates a large title text widget.
  ///
  /// Uses the theme's `titleLarge` text style. The [color], [weight], [leading], and [style] parameters can be used to
  /// customize the appearance, and will be merged with the theme's base style.
  TitleText.large(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    double? leading,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(
         color: color,
         fontWeight: weight,
         height: leading,
       ).merge(style),
       _textStyleGetter = ((context) => context.texts.titleLarge);

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: _textStyleGetter(context)?.merge(style),
      textAlign: align,
    );
  }
}

/// A widget that displays text using Material Design 3 body text styles.
///
/// Body text is used for the main content of the application, such as paragraphs, descriptions, and general text
/// content. This widget provides convenient constructors for small, medium, and large body text variants, each
/// corresponding to Material Design 3's body text styles.
///
/// The text style is automatically retrieved from the theme's [TextTheme] and can be customized through optional
/// parameters like [color], [weight], [leading], and [style].
class BodyText extends StatelessWidget {
  /// The text content to display.
  final String data;

  /// Optional custom text style that will be merged with the theme's body text style.
  final TextStyle? style;

  /// Optional text alignment.
  final TextAlign? align;

  /// Internal function that retrieves the appropriate body text style from the theme.
  final TextStyle? Function(BuildContext) _textStyleGetter;

  /// Creates a small body text widget.
  ///
  /// Uses the theme's `bodySmall` text style. The [color], [weight], [leading], and [style] parameters can be used to
  /// customize the appearance, and will be merged with the theme's base style.
  BodyText.small(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    double? leading,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(
         color: color,
         fontWeight: weight,
         height: leading,
       ).merge(style),
       _textStyleGetter = ((context) => context.texts.bodySmall);

  /// Creates a medium body text widget.
  ///
  /// Uses the theme's `bodyMedium` text style. The [color], [weight], [leading], and [style] parameters can be used to
  /// customize the appearance, and will be merged with the theme's base style.
  BodyText.medium(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    double? leading,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(
         color: color,
         fontWeight: weight,
         height: leading,
       ).merge(style),
       _textStyleGetter = ((context) => context.texts.bodyMedium);

  /// Creates a large body text widget.
  ///
  /// Uses the theme's `bodyLarge` text style. The [color], [weight], [leading], and [style] parameters can be used to
  /// customize the appearance, and will be merged with the theme's base style.
  BodyText.large(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    double? leading,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(
         color: color,
         fontWeight: weight,
         height: leading,
       ).merge(style),
       _textStyleGetter = ((context) => context.texts.bodyLarge);

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: _textStyleGetter(context)?.merge(style),
      textAlign: align,
    );
  }
}

/// A widget that displays text using Material Design 3 label text styles.
///
/// Label text is used for buttons, tabs, and other UI elements that need compact, readable text. This widget provides
/// convenient constructors for small, medium, and large label text variants, each corresponding to Material Design 3's
/// label text styles.
///
/// The text style is automatically retrieved from the theme's [TextTheme] and can be customized through optional
/// parameters like [color], [weight], [leading], and [style].
class LabelText extends StatelessWidget {
  /// The text content to display.
  final String data;

  /// Optional custom text style that will be merged with the theme's label text style.
  final TextStyle? style;

  /// Optional text alignment.
  final TextAlign? align;

  /// Internal function that retrieves the appropriate label text style from the theme.
  final TextStyle? Function(BuildContext) _textStyleGetter;

  /// Creates a small label text widget.
  ///
  /// Uses the theme's `labelSmall` text style. The [color], [weight], [leading], and [style] parameters can be used to
  /// customize the appearance, and will be merged with the theme's base style.
  LabelText.small(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    double? leading,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(
         color: color,
         fontWeight: weight,
         height: leading,
       ).merge(style),
       _textStyleGetter = ((context) => context.texts.labelSmall);

  /// Creates a medium label text widget.
  ///
  /// Uses the theme's `labelMedium` text style. The [color], [weight], [leading], and [style] parameters can be used to
  /// customize the appearance, and will be merged with the theme's base style.
  LabelText.medium(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    double? leading,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(
         color: color,
         fontWeight: weight,
         height: leading,
       ).merge(style),
       _textStyleGetter = ((context) => context.texts.labelMedium);

  /// Creates a large label text widget.
  ///
  /// Uses the theme's `labelLarge` text style. The [color], [weight], [leading], and [style] parameters can be used to
  /// customize the appearance, and will be merged with the theme's base style.
  LabelText.large(
    this.data, {
    super.key,
    Color? color,
    FontWeight? weight,
    double? leading,
    TextStyle? style,
    this.align,
  }) : style = TextStyle(
         color: color,
         fontWeight: weight,
         height: leading,
       ).merge(style),
       _textStyleGetter = ((context) => context.texts.labelLarge);

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style: _textStyleGetter(context)?.merge(style),
      textAlign: align,
    );
  }
}
