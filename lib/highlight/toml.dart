// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `toml`.
///
/// Import this library only when you need `toml` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightToml {
  /// The grammar for `toml`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("#.*"), greedy: true),
  GrammarToken(
      "table",
      compileHighlightPattern(
          "(^[\\t ]*\\[\\s*(?:\\[\\s*)?)(?:[\\w-]+|'[^'\\n\\r]*'|\"(?:\\\\.|[^\\\\\"\\r\\n])*\")(?:\\s*\\.\\s*(?:[\\w-]+|'[^'\\n\\r]*'|\"(?:\\\\.|[^\\\\\"\\r\\n])*\"))*(?=\\s*\\])",
          multiLine: true),
      lookbehind: true,
      greedy: true,
      alias: "class-name"),
  GrammarToken(
      "key",
      compileHighlightPattern(
          "(^[\\t ]*|[{,]\\s*)(?:[\\w-]+|'[^'\\n\\r]*'|\"(?:\\\\.|[^\\\\\"\\r\\n])*\")(?:\\s*\\.\\s*(?:[\\w-]+|'[^'\\n\\r]*'|\"(?:\\\\.|[^\\\\\"\\r\\n])*\"))*(?=\\s*=)",
          multiLine: true),
      lookbehind: true,
      greedy: true,
      alias: "property"),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\"\"\"(?:\\\\[\\s\\S]|[^\\\\])*?\"\"\"|'''[\\s\\S]*?'''|'[^'\\n\\r]*'|\"(?:\\\\.|[^\\\\\"\\r\\n])*\""),
      greedy: true),
  GrammarToken(
      "date",
      compileHighlightPattern(
          "\\b\\d{4}-\\d{2}-\\d{2}(?:[T\\s]\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?(?:Z|[+-]\\d{2}:\\d{2})?)?\\b",
          caseSensitive: false),
      alias: "number"),
  GrammarToken(
      "date", compileHighlightPattern("\\b\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?\\b"),
      alias: "number"),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "(?:\\b0(?:x[\\da-zA-Z]+(?:_[\\da-zA-Z]+)*|o[0-7]+(?:_[0-7]+)*|b[10]+(?:_[10]+)*))\\b|[-+]?\\b\\d+(?:_\\d+)*(?:\\.\\d+(?:_\\d+)*)?(?:[eE][+-]?\\d+(?:_\\d+)*)?\\b|[-+]?\\b(?:inf|nan)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("punctuation", compileHighlightPattern("[.,=[\\]{}]")),
]);
