// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `ocaml`.
///
/// Import this library only when you need `ocaml` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightOcaml {
  /// The grammar for `ocaml`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("\\(\\*[\\s\\S]*?\\*\\)"),
      greedy: true),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "'(?:[^\\\\\\r\\n']|\\\\(?:.|[ox]?[0-9a-f]{1,3}))'",
          caseSensitive: false),
      greedy: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\"(?:\\\\(?:[\\s\\S]|\\r\\n)|[^\\\\\\r\\n\"])*\""),
      greedy: true),
  GrammarToken(
      "string", compileHighlightPattern("\\{([a-z_]*)\\|[\\s\\S]*?\\|\\1\\}"),
      greedy: true),
  GrammarToken(
      "number",
      compileHighlightPattern("\\b(?:0b[01][01_]*|0o[0-7][0-7_]*)\\b",
          caseSensitive: false)),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0x[a-f0-9][a-f0-9_]*(?:\\.[a-f0-9_]*)?(?:p[+-]?\\d[\\d_]*)?(?!\\w)",
          caseSensitive: false)),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b\\d[\\d_]*(?:\\.[\\d_]*)?(?:e[+-]?\\d[\\d_]*)?(?!\\w)",
          caseSensitive: false)),
  GrammarToken("directive", compileHighlightPattern("\\B#\\w+"),
      alias: "property"),
  GrammarToken("label", compileHighlightPattern("\\B~\\w+"), alias: "property"),
  GrammarToken("type-variable", compileHighlightPattern("\\B'\\w+"),
      alias: "function"),
  GrammarToken("variant", compileHighlightPattern("`\\w+"), alias: "symbol"),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:as|assert|begin|class|constraint|do|done|downto|else|end|exception|external|for|fun|function|functor|if|in|include|inherit|initializer|lazy|let|match|method|module|mutable|new|nonrec|object|of|open|private|rec|sig|struct|then|to|try|type|val|value|virtual|when|where|while|with)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("operator-like-punctuation",
      compileHighlightPattern("\\[[<>|]|[>|]\\]|\\{<|>\\}"),
      alias: "punctuation"),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "\\.[.~]|:[=>]|[=<>@^|&+\\-*\\/\$%!?~][!\$%&*+\\-.\\/:<=>?@^|~]*|\\b(?:and|asr|land|lor|lsl|lsr|lxor|mod|or)\\b")),
  GrammarToken("punctuation",
      compileHighlightPattern(";;|::|[(){}\\[\\].,:;#]|\\b_\\b")),
]);
