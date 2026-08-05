import 'package:flutter/painting.dart';

import '../highlight.dart';

/// Ready-made GitHub code themes for [MarkdownHighlighter].
///
/// Each theme is a separate `const` value; referencing one never retains the
/// other, so the theme you don't use is dropped from the build.
abstract final class HighlightThemes {
  /// GitHub "dark" code theme (background `#0D1117`).
  static const CodeHighlightTheme githubDark = _GithubTheme(
    background: Color(0xFF0D1117),
    foreground: Color(0xFFC9D1D9),
    comment: Color(0xFF8B949E),
    keyword: Color(0xFFFF7B72),
    string: Color(0xFFA5D6FF),
    number: Color(0xFF79C0FF),
    function: Color(0xFFD2A8FF),
    className: Color(0xFFFFA657),
    variable: Color(0xFF79C0FF),
    punctuation: Color(0xFFC9D1D9),
  );

  /// GitHub "light" code theme (background `#F6F8FA`).
  static const CodeHighlightTheme githubLight = _GithubTheme(
    background: Color(0xFFF6F8FA),
    foreground: Color(0xFF24292F),
    comment: Color(0xFF6E7781),
    keyword: Color(0xFFCF222E),
    string: Color(0xFF0A3069),
    number: Color(0xFF0550AE),
    function: Color(0xFF8250DF),
    className: Color(0xFF953800),
    variable: Color(0xFF0550AE),
    punctuation: Color(0xFF24292F),
  );
}

/// A GitHub-style theme parameterized by a small palette. Token classes are
/// resolved with a `switch` (no shared map), so each instance is self-contained
/// and tree-shakeable.
final class _GithubTheme implements CodeHighlightTheme {
  const _GithubTheme({
    required Color background,
    required Color foreground,
    required this.comment,
    required this.keyword,
    required this.string,
    required this.number,
    required this.function,
    required this.className,
    required this.variable,
    required this.punctuation,
  })  : _background = background,
        _foreground = foreground;

  final Color _background;
  final Color _foreground;

  /// Color for comments (also italicized).
  final Color comment;

  /// Color for keywords and operators.
  final Color keyword;

  /// Color for strings and characters.
  final Color string;

  /// Color for numbers, booleans and constants.
  final Color number;

  /// Color for function names.
  final Color function;

  /// Color for class names, builtins and namespaces.
  final Color className;

  /// Color for variables, properties and parameters.
  final Color variable;

  /// Color for punctuation.
  final Color punctuation;

  @override
  Color? get background => _background;

  @override
  Color? get foreground => _foreground;

  @override
  TextStyle? styleFor(String tokenType) => switch (tokenType) {
        'comment' ||
        'prolog' ||
        'doctype' ||
        'cdata' =>
          TextStyle(color: comment, fontStyle: FontStyle.italic),
        'keyword' ||
        'operator' ||
        'rule' ||
        'atrule' ||
        'selector' =>
          TextStyle(color: keyword),
        'string' ||
        'string-literal' ||
        'char' ||
        'attr-value' ||
        'regex' =>
          TextStyle(color: string),
        'number' ||
        'boolean' ||
        'constant' ||
        'null' ||
        'symbol' ||
        'unit' =>
          TextStyle(color: number),
        'function' || 'function-name' => TextStyle(color: function),
        'class-name' ||
        'builtin' ||
        'namespace' ||
        'important' ||
        'tag' =>
          TextStyle(color: className),
        'variable' ||
        'property' ||
        'parameter' ||
        'attr-name' ||
        'shebang' ||
        'environment' ||
        'file-descriptor' ||
        'for-or-select' ||
        'assign-left' =>
          TextStyle(color: variable),
        'punctuation' => TextStyle(color: punctuation),
        _ => null,
      };
}
