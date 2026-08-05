// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `elm`.
///
/// Import this library only when you need `elm` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightElm {
  /// The grammar for `elm`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("--.*|\\{-[\\s\\S]*?-\\}")),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "'(?:[^\\\\'\\r\\n]|\\\\(?:[abfnrtv\\\\']|\\d+|x[0-9a-fA-F]+|u\\{[0-9a-fA-F]+\\}))'"),
      greedy: true),
  GrammarToken("string", compileHighlightPattern("\"\"\"[\\s\\S]*?\"\"\""),
      greedy: true),
  GrammarToken(
      "string", compileHighlightPattern("\"(?:[^\\\\\"\\r\\n]|\\\\.)*\""),
      greedy: true),
  GrammarToken(
      "import-statement",
      compileHighlightPattern(
          "(^[\\t ]*)import\\s+[A-Z]\\w*(?:\\.[A-Z]\\w*)*(?:\\s+as\\s+(?:[A-Z]\\w*)(?:\\.[A-Z]\\w*)*)?(?:\\s+exposing\\s+)?",
          multiLine: true),
      lookbehind: true,
      inside: () => _g1),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:alias|as|case|else|exposing|if|in|infixl|infixr|let|module|of|then|type)\\b")),
  GrammarToken(
      "builtin",
      compileHighlightPattern(
          "\\b(?:abs|acos|always|asin|atan|atan2|ceiling|clamp|compare|cos|curry|degrees|e|flip|floor|fromPolar|identity|isInfinite|isNaN|logBase|max|min|negate|never|not|pi|radians|rem|round|sin|sqrt|tan|toFloat|toPolar|toString|truncate|turns|uncurry|xor)\\b")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b(?:\\d+(?:\\.\\d+)?(?:e[+-]?\\d+)?|0x[0-9a-f]+)\\b",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "\\s\\.\\s|[+\\-/*=.\$<>:&|^?%#@~!]{2,}|[+\\-/*=\$<>:&|^?%#@~!]")),
  GrammarToken(
      "hvariable", compileHighlightPattern("\\b(?:[A-Z]\\w*\\.)*[a-z]\\w*\\b")),
  GrammarToken(
      "constant", compileHighlightPattern("\\b(?:[A-Z]\\w*\\.)*[A-Z]\\w*\\b")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\]|(),.:]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "keyword", compileHighlightPattern("\\b(?:as|exposing|import)\\b")),
]);
