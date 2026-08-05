// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `json5`.
///
/// Import this library only when you need `json5` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightJson5 {
  /// The grammar for `json5`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "property",
      compileHighlightPattern(
          "(\"|')(?:\\\\(?:\\r\\n?|\\n|.)|(?!\\1)[^\\\\\\r\\n])*\\1(?=\\s*:)"),
      greedy: true),
  GrammarToken(
      "property",
      compileHighlightPattern(
          "(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*(?=\\s*:)"),
      alias: "unquoted"),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(\"|')(?:\\\\(?:\\r\\n?|\\n|.)|(?!\\1)[^\\\\\\r\\n])*\\1"),
      greedy: true),
  GrammarToken("comment",
      compileHighlightPattern("\\/\\/.*|\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      greedy: true),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "[+-]?\\b(?:NaN|Infinity|0x[a-fA-F\\d]+)\\b|[+-]?(?:\\b\\d+(?:\\.\\d*)?|\\B\\.\\d+)(?:[eE][+-]?\\d+\\b)?")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\],]")),
  GrammarToken("operator", compileHighlightPattern(":")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("null", compileHighlightPattern("\\bnull\\b"), alias: "keyword"),
]);
