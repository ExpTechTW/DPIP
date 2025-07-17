import 'package:flutter/widgets.dart';

class _VerticalLayout {
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final TextBaseline? textBaseline;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final double spacing;

  const _VerticalLayout({
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.spacing = 0.0,
  });

  _VerticalLayout copyWith({
    MainAxisAlignment? mainAxisAlignment,
    MainAxisSize? mainAxisSize,
    CrossAxisAlignment? crossAxisAlignment,
    TextDirection? textDirection,
    VerticalDirection? verticalDirection,
    TextBaseline? textBaseline,
    double? spacing,
  }) {
    return _VerticalLayout(
      mainAxisAlignment: mainAxisAlignment ?? this.mainAxisAlignment,
      mainAxisSize: mainAxisSize ?? this.mainAxisSize,
      crossAxisAlignment: crossAxisAlignment ?? this.crossAxisAlignment,
      textDirection: textDirection ?? this.textDirection,
      verticalDirection: verticalDirection ?? this.verticalDirection,
      textBaseline: textBaseline ?? this.textBaseline,
      spacing: spacing ?? this.spacing,
    );
  }

  Widget call({Key? key, required List<Widget> children, EdgeInsets? padding}) {
    final widget = Column(
      key: key,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      spacing: spacing,
      children: children,
    );

    if (padding != null) {
      return Padding(padding: padding, child: widget);
    }

    return widget;
  }

  _VerticalLayout get top => copyWith(mainAxisAlignment: MainAxisAlignment.start);
  _VerticalLayout get bottom => copyWith(mainAxisAlignment: MainAxisAlignment.end);
  _VerticalLayout get center => copyWith(mainAxisAlignment: MainAxisAlignment.center);
  _VerticalLayout get left => copyWith(crossAxisAlignment: CrossAxisAlignment.start);
  _VerticalLayout get right => copyWith(crossAxisAlignment: CrossAxisAlignment.end);
  _VerticalLayout get stretch => copyWith(crossAxisAlignment: CrossAxisAlignment.stretch);
  _VerticalLayout get min => copyWith(mainAxisSize: MainAxisSize.min);
  _VerticalLayout get max => copyWith(mainAxisSize: MainAxisSize.max);
  _VerticalLayout get reverse => copyWith(verticalDirection: VerticalDirection.up);

  /// Set the spacing between children.
  _VerticalLayout operator [](double spacing) => copyWith(spacing: spacing);
}

class VLayout {
  const VLayout._();

  static const base = _VerticalLayout();

  static _VerticalLayout get top => base.top;
  static _VerticalLayout get bottom => base.bottom;
  static _VerticalLayout get center => base.center;
  static _VerticalLayout get left => base.left;
  static _VerticalLayout get right => base.right;
  static _VerticalLayout get stretch => base.stretch;
  static _VerticalLayout get min => base.min;
  static _VerticalLayout get max => base.max;
  static _VerticalLayout get reverse => base.reverse;

  /// Creates a vertical array of children.
  ///
  /// If [crossAxisAlignment] is [CrossAxisAlignment.baseline], then
  /// [textBaseline] must not be null.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, and a text direction is going
  /// to be necessary to disambiguate `start` or `end` values for the
  /// [crossAxisAlignment], the [textDirection] must not be null.
  static Column raw({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    double spacing = 0.0,
    List<Widget> children = const <Widget>[],
  }) {
    return Column(
      key: key,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      spacing: spacing,
      children: children,
    );
  }
}

class _HorizontalLayout {
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final TextBaseline? textBaseline;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final double spacing;

  const _HorizontalLayout({
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.spacing = 0.0,
  });

  _HorizontalLayout copyWith({
    MainAxisAlignment? mainAxisAlignment,
    MainAxisSize? mainAxisSize,
    CrossAxisAlignment? crossAxisAlignment,
    TextDirection? textDirection,
    VerticalDirection? verticalDirection,
    TextBaseline? textBaseline,
    double? spacing,
  }) {
    return _HorizontalLayout(
      mainAxisAlignment: mainAxisAlignment ?? this.mainAxisAlignment,
      mainAxisSize: mainAxisSize ?? this.mainAxisSize,
      crossAxisAlignment: crossAxisAlignment ?? this.crossAxisAlignment,
      textDirection: textDirection ?? this.textDirection,
      verticalDirection: verticalDirection ?? this.verticalDirection,
      textBaseline: textBaseline ?? this.textBaseline,
      spacing: spacing ?? this.spacing,
    );
  }

  Widget call({Key? key, required List<Widget> children, EdgeInsets? padding}) {
    final widget = Row(
      key: key,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      spacing: spacing,
      children: children,
    );

    if (padding != null) {
      return Padding(padding: padding, child: widget);
    }

    return widget;
  }

  _HorizontalLayout get left => copyWith(mainAxisAlignment: MainAxisAlignment.start);
  _HorizontalLayout get right => copyWith(mainAxisAlignment: MainAxisAlignment.end);
  _HorizontalLayout get top => copyWith(crossAxisAlignment: CrossAxisAlignment.start);
  _HorizontalLayout get bottom => copyWith(crossAxisAlignment: CrossAxisAlignment.end);
  _HorizontalLayout get center => copyWith(crossAxisAlignment: CrossAxisAlignment.center);
  _HorizontalLayout get stretch => copyWith(crossAxisAlignment: CrossAxisAlignment.stretch);
  _HorizontalLayout get min => copyWith(mainAxisSize: MainAxisSize.min);
  _HorizontalLayout get max => copyWith(mainAxisSize: MainAxisSize.max);
  _HorizontalLayout get reverse => copyWith(verticalDirection: VerticalDirection.up);

  /// Set the spacing between children.
  _HorizontalLayout operator [](double spacing) => copyWith(spacing: spacing);
}

class HLayout {
  const HLayout._();

  static const base = _HorizontalLayout();

  static _HorizontalLayout get left => base.left;
  static _HorizontalLayout get right => base.right;
  static _HorizontalLayout get top => base.top;
  static _HorizontalLayout get bottom => base.bottom;
  static _HorizontalLayout get center => base.center;
  static _HorizontalLayout get stretch => base.stretch;
  static _HorizontalLayout get min => base.min;
  static _HorizontalLayout get max => base.max;
  static _HorizontalLayout get reverse => base.reverse;

  /// Creates a horizontal array of children.
  ///
  /// If [crossAxisAlignment] is [CrossAxisAlignment.baseline], then
  /// [textBaseline] must not be null.
  ///
  /// The [textDirection] argument defaults to the ambient [Directionality], if
  /// any. If there is no ambient directionality, and a text direction is going
  /// to be necessary to determine the layout order (which is always the case
  /// unless the row has no children or only one child) or to disambiguate
  /// `start` or `end` values for the [mainAxisAlignment], the [textDirection]
  /// must not be null.
  static Row raw({
    Key? key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    double spacing = 0.0,
    List<Widget> children = const <Widget>[],
  }) {
    return Row(
      key: key,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      spacing: spacing,
      children: children,
    );
  }
}

class Layout {
  const Layout._();

  static _VerticalLayout get v => VLayout.base;
  static _HorizontalLayout get h => HLayout.base;
}
