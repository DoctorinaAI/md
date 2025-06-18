import 'dart:collection';

import 'package:flutter/material.dart';

import '../md.dart';

/// {@template markdown_theme_data}
/// Theme data for Markdown widgets.
/// {@endtemplate}
class MarkdownThemeData implements ThemeExtension<MarkdownThemeData> {
  /// Creates a [MarkdownThemeData] instance.
  /// {@macro markdown_theme_data}
  MarkdownThemeData({
    this.textDirection = TextDirection.ltr,
    this.textScaler = TextScaler.noScaling,
    this.textStyle = const TextStyle(fontSize: 14.0),
    this.h1Style = const TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.solid,
    ),
    this.h2Style = const TextStyle(
      fontSize: 22.0,
      fontWeight: FontWeight.bold,
    ),
    this.h3Style = const TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    ),
    this.h4Style = const TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
    ),
    this.h5Style = const TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.bold,
    ),
    this.h6Style = const TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    ),
    this.quoteStyle = const TextStyle(
      fontSize: 14.0,
    ),
    this.blockFilter,
    this.spanFilter,
    this.onLinkTap,
  }) : _textStyles = HashMap<int, TextStyle>();

  @override
  Object get type => MarkdownThemeData;

  /// The text direction to use for rendering Markdown widgets.
  final TextDirection textDirection;

  /// The text scaler to use for scaling text in Markdown widgets.
  final TextScaler textScaler;

  /// The default text style to use for Markdown widgets.
  final TextStyle textStyle;

  /// Default text style for headings h1.
  final TextStyle h1Style;

  /// Default text style for headings h2.
  final TextStyle h2Style;

  /// Default text style for headings h3.
  final TextStyle h3Style;

  /// Default text style for headings h4.
  final TextStyle h4Style;

  /// Default text style for headings h5.
  final TextStyle h5Style;

  /// Default text style for headings h6.
  final TextStyle h6Style;

  /// Default text style for quote blocks.
  final TextStyle quoteStyle;

  /// A filter function to determine whether a block should be rendered.
  /// If the function returns `true`, the block will be rendered.
  ///
  /// For example, you can use this to filter out blocks that are not
  /// relevant to the current context, such as code blocks or tables.
  final bool Function(MD$Block block)? blockFilter;

  /// A filter function to determine whether a span should be rendered.
  /// If the function returns `true`, the span will be rendered.
  ///
  /// For example, you can use this to filter out spans that are not
  /// relevant to the current context, such as links or images.
  /// This can be useful for customizing the rendering of Markdown spans.
  final bool Function(MD$Span span)? spanFilter;

  /// A callback function that is called when a link is tapped.
  /// It receives the link title and URL as parameters.
  final void Function(String title, String url)? onLinkTap;

  final HashMap<int, TextStyle> _textStyles;

  /// Returns a [TextStyle] for the given [MD$Style].
  TextStyle textStyleFor(MD$Style style) => _textStyles.putIfAbsent(
        style.hashCode,
        () => TextStyle(
          fontWeight:
              style.contains(MD$Style.bold) || style.contains(MD$Style.link)
                  ? FontWeight.bold
                  : FontWeight.normal,
          fontStyle: style.contains(MD$Style.italic)
              ? FontStyle.italic
              : FontStyle.normal,
          decoration: style.contains(MD$Style.underline)
              ? TextDecoration.underline
              : style.contains(MD$Style.strikethrough)
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
          fontFamily: style.contains(MD$Style.monospace)
              ? 'monospace'
              : textStyle.fontFamily,
          color: style.contains(MD$Style.link)
              ? Colors.purple
              : style.contains(MD$Style.highlight)
                  ? Colors.yellow
                  : textStyle.color,
          backgroundColor: style.contains(MD$Style.monospace)
              ? Colors.black12
              : textStyle.backgroundColor,
        ),
      );

  @override
  ThemeExtension<MarkdownThemeData> copyWith({
    TextDirection? textDirection,
    TextScaler? textScaler,
    TextStyle? textStyle,
    TextStyle? h1Style,
    TextStyle? h2Style,
    TextStyle? h3Style,
    TextStyle? h4Style,
    TextStyle? h5Style,
    TextStyle? h6Style,
    TextStyle? quoteStyle,
    bool Function(MD$Block block)? blockFilter,
    bool Function(MD$Span span)? spanFilter,
  }) =>
      MarkdownThemeData(
        textDirection: textDirection ?? this.textDirection,
        textScaler: textScaler ?? this.textScaler,
        textStyle: textStyle ?? this.textStyle,
        h1Style: h1Style ?? this.h1Style,
        h2Style: h2Style ?? this.h2Style,
        h3Style: h3Style ?? this.h3Style,
        h4Style: h4Style ?? this.h4Style,
        h5Style: h5Style ?? this.h5Style,
        h6Style: h6Style ?? this.h6Style,
        quoteStyle: quoteStyle ?? this.quoteStyle,
        blockFilter: blockFilter ?? this.blockFilter,
        spanFilter: spanFilter ?? this.spanFilter,
      );

  @override
  ThemeExtension<MarkdownThemeData> lerp(
          covariant ThemeExtension<MarkdownThemeData>? other, double t) =>
      MarkdownThemeData();

  @override
  String toString() => 'MarkdownThemeData{}';
}

/// {@template theme}
/// MarkdownTheme widget.
/// {@endtemplate}
class MarkdownTheme extends InheritedWidget {
  /// {@macro theme}
  const MarkdownTheme({
    required this.data,
    required super.child,
    super.key, // ignore: unused_element
  });

  /// The state from the closest instance of this class
  /// that encloses the given context, if any.
  /// e.g. `Theme.maybeOf(context)`.
  static MarkdownThemeData? maybeOf(BuildContext context,
          {bool listen = true}) =>
      listen
          ? context.dependOnInheritedWidgetOfExactType<MarkdownTheme>()?.data
          : context.getInheritedWidgetOfExactType<MarkdownTheme>()?.data;

  static Never _notFoundInheritedWidgetOfExactType() => throw ArgumentError(
        'Out of scope, not found inherited widget '
            'a MarkdownTheme of the exact type',
        'out_of_scope',
      );

  /// The state from the closest instance of this class
  /// that encloses the given context.
  /// e.g. `Theme.of(context)`
  static MarkdownThemeData of(BuildContext context, {bool listen = true}) =>
      maybeOf(context, listen: listen) ?? _notFoundInheritedWidgetOfExactType();

  /// The current theme data for Markdown widgets.
  final MarkdownThemeData data;

  @override
  bool updateShouldNotify(covariant MarkdownTheme oldWidget) =>
      !identical(data, oldWidget.data);
}
