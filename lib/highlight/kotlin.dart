// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `kotlin`.
///
/// Import this library only when you need `kotlin` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightKotlin {
  /// The grammar for `kotlin`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "string-literal",
      compileHighlightPattern(
          "\"\"\"(?:[^\$]|\\\$(?:(?!\\{)|\\{[^{}]*\\}))*?\"\"\""),
      alias: "multiline",
      inside: () => _g1),
  GrammarToken(
      "string-literal",
      compileHighlightPattern(
          "\"(?:[^\"\\\\\\r\\n\$]|\\\\.|\\\$(?:(?!\\{)|\\{[^{}]*\\}))*\""),
      alias: "singleline",
      inside: () => _g3),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "'(?:[^'\\\\\\r\\n]|\\\\(?:.|u[a-fA-F0-9]{0,4}))'"),
      greedy: true),
  GrammarToken("annotation",
      compileHighlightPattern("\\B@(?:\\w+:)?(?:[A-Z]\\w*|\\[[^\\]]+\\])"),
      alias: "builtin"),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(^|[^.])\\b(?:abstract|actual|annotation|as|break|by|catch|class|companion|const|constructor|continue|crossinline|data|do|dynamic|else|enum|expect|external|final|finally|for|fun|get|if|import|in|infix|init|inline|inner|interface|internal|is|lateinit|noinline|null|object|open|operator|out|override|package|private|protected|public|reified|return|sealed|set|super|suspend|tailrec|this|throw|to|try|typealias|val|var|vararg|when|where|while)\\b"),
      lookbehind: true),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("label", compileHighlightPattern("\\b\\w+@|@\\w+\\b"),
      alias: "symbol"),
  GrammarToken("function",
      compileHighlightPattern("(?:`[^\\r\\n`]+`|\\b\\w+)(?=\\s*\\()"),
      greedy: true),
  GrammarToken("function",
      compileHighlightPattern("(\\.)(?:`[^\\r\\n`]+`|\\w+)(?=\\s*\\{)"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b(?:0[xX][\\da-fA-F]+(?:_[\\da-fA-F]+)*|0[bB][01]+(?:_[01]+)*|\\d+(?:_\\d+)*(?:\\.\\d+(?:_\\d+)*)?(?:[eE][+-]?\\d+(?:_\\d+)*)?[fFL]?)\\b")),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "\\+[+=]?|-[-=>]?|==?=?|!(?:!|==?)?|[\\/*%<>]=?|[?:]:?|\\.\\.|&&|\\|\\||\\b(?:and|inv|or|shl|shr|ushr|xor)\\b")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern("\\\$(?:[a-z_]\\w*|\\{[^{}]*\\})",
          caseSensitive: false),
      inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g2 = Grammar([
  GrammarToken(
      "interpolation-punctuation", compileHighlightPattern("^\\\$\\{?|\\}\$"),
      alias: "punctuation"),
  GrammarToken("expression", compileHighlightPattern("[\\s\\S]+"),
      inside: () => _g0),
]);

final Grammar _g3 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\{2})*)\\\$(?:[a-z_]\\w*|\\{[^{}]*\\})",
          caseSensitive: false),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);
