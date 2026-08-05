// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `erlang`.
///
/// Import this library only when you need `erlang` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightErlang {
  /// The grammar for `erlang`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("%.+")),
  GrammarToken(
      "string", compileHighlightPattern("\"(?:\\\\.|[^\\\\\"\\r\\n])*\""),
      greedy: true),
  GrammarToken("quoted-function",
      compileHighlightPattern("'(?:\\\\.|[^\\\\'\\r\\n])+'(?=\\()"),
      alias: "function"),
  GrammarToken(
      "quoted-atom", compileHighlightPattern("'(?:\\\\.|[^\\\\'\\r\\n])+'"),
      alias: "atom"),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:after|begin|case|catch|end|fun|if|of|receive|try|when)\\b")),
  GrammarToken("number", compileHighlightPattern("\\\$\\\\?.")),
  GrammarToken("number",
      compileHighlightPattern("\\b\\d+#[a-z0-9]+", caseSensitive: false)),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "(?:\\b\\d+(?:\\.\\d*)?|\\B\\.\\d+)(?:e[+-]?\\d+)?",
          caseSensitive: false)),
  GrammarToken("function", compileHighlightPattern("\\b[a-z][\\w@]*(?=\\()")),
  GrammarToken(
      "variable", compileHighlightPattern("(^|[^@])(?:\\b|\\?)[A-Z_][\\w@]*"),
      lookbehind: true),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "[=\\/<>:]=|=[:\\/]=|\\+\\+?|--?|[=*\\/!]|\\b(?:and|andalso|band|bnot|bor|bsl|bsr|bxor|div|not|or|orelse|rem|xor)\\b")),
  GrammarToken("operator", compileHighlightPattern("(^|[^<])<(?!<)"),
      lookbehind: true),
  GrammarToken("operator", compileHighlightPattern("(^|[^>])>(?!>)"),
      lookbehind: true),
  GrammarToken("atom", compileHighlightPattern("\\b[a-z][\\w@]*")),
  GrammarToken(
      "punctuation", compileHighlightPattern("[()[\\]{}:;,.#|]|<<|>>")),
]);
