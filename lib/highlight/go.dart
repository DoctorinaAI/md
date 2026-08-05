// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `go`.
///
/// Import this library only when you need `go` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightGo {
  /// The grammar for `go`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "char", compileHighlightPattern("'(?:\\\\.|[^'\\\\\\r\\n]){0,10}'"),
      greedy: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(^|[^\\\\])\"(?:\\\\.|[^\"\\\\\\r\\n])*\"|`[^`]*`"),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:break|case|chan|const|continue|default|defer|else|fallthrough|for|func|go(?:to)?|if|import|interface|map|package|range|return|select|struct|switch|type|var)\\b")),
  GrammarToken(
      "boolean", compileHighlightPattern("\\b(?:_|false|iota|nil|true)\\b")),
  GrammarToken("function", compileHighlightPattern("\\b\\w+(?=\\()")),
  GrammarToken(
      "number",
      compileHighlightPattern("\\b0(?:b[01_]+|o[0-7_]+)i?\\b",
          caseSensitive: false)),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0x(?:[a-f\\d_]+(?:\\.[a-f\\d_]*)?|\\.[a-f\\d_]+)(?:p[+-]?\\d+(?:_\\d+)*)?i?(?!\\w)",
          caseSensitive: false)),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "(?:\\b\\d[\\d_]*(?:\\.[\\d_]*)?|\\B\\.\\d[\\d_]*)(?:e[+-]?[\\d_]+)?i?(?!\\w)",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "[*\\/%^!=]=?|\\+[=+]?|-[=-]?|\\|[=|]?|&(?:=|&|\\^=?)?|>(?:>=?|=)?|<(?:<=?|=|-)?|:=|\\.\\.\\.")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
  GrammarToken(
      "builtin",
      compileHighlightPattern(
          "\\b(?:append|bool|byte|cap|close|complex|complex(?:64|128)|copy|delete|error|float(?:32|64)|u?int(?:8|16|32|64)?|imag|len|make|new|panic|print(?:ln)?|real|recover|rune|string|uintptr)\\b")),
]);
