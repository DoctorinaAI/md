import 'package:flutter/material.dart';

/// {@template markdown_theme_data}
/// Theme data for Markdown widgets.
/// {@endtemplate}
@immutable
class MarkdownThemeData implements ThemeExtension<MarkdownThemeData> {
  /// Creates a [MarkdownThemeData] instance.
  /// {@macro markdown_theme_data}
  const MarkdownThemeData();

  @override
  Object get type => MarkdownThemeData;

  @override
  ThemeExtension<MarkdownThemeData> copyWith() => const MarkdownThemeData();

  @override
  ThemeExtension<MarkdownThemeData> lerp(
          covariant ThemeExtension<MarkdownThemeData>? other, double t) =>
      const MarkdownThemeData();

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
