// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `json`.
///
/// Import this library only when you need `json` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightJson {
  /// The grammar for `json`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "property",
      compileHighlightPattern(
          "(^|[^\\\\])\"(?:\\\\.|[^\\\\\"\\r\\n])*\"(?=\\s*:)"),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(^|[^\\\\])\"(?:\\\\.|[^\\\\\"\\r\\n])*\"(?!\\s*:)"),
      lookbehind: true,
      greedy: true),
  GrammarToken("comment",
      compileHighlightPattern("\\/\\/.*|\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      greedy: true),
  GrammarToken(
      "number",
      compileHighlightPattern("-?\\b\\d+(?:\\.\\d+)?(?:e[+-]?\\d+)?\\b",
          caseSensitive: false)),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\],]")),
  GrammarToken("operator", compileHighlightPattern(":")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("null", compileHighlightPattern("\\bnull\\b"), alias: "keyword"),
]);
