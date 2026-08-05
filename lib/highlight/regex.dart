// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `regex`.
///
/// Import this library only when you need `regex` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightRegex {
  /// The grammar for `regex`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "char-class",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\\\\\)*)\\[(?:[^\\\\\\]]|\\\\[\\s\\S])*\\]"),
      lookbehind: true,
      inside: () => _g1),
  GrammarToken(
      "special-escape", compileHighlightPattern("\\\\[\\\\(){}[\\]^\$+*?|.]"),
      alias: "escape"),
  GrammarToken(
      "char-set",
      compileHighlightPattern("\\.|\\\\[wsd]|\\\\p\\{[^{}]+\\}",
          caseSensitive: false),
      alias: "class-name"),
  GrammarToken(
      "backreference", compileHighlightPattern("\\\\(?![123][0-7]{2})[1-9]"),
      alias: "keyword"),
  GrammarToken("backreference", compileHighlightPattern("\\\\k<[^<>']+>"),
      alias: "keyword", inside: () => _g3),
  GrammarToken("anchor", compileHighlightPattern("[\$^]|\\\\[ABbGZz]"),
      alias: "function"),
  GrammarToken(
      "escape",
      compileHighlightPattern(
          "\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.)")),
  GrammarToken(
      "group",
      compileHighlightPattern(
          "\\((?:\\?(?:<[^<>']+>|'[^<>']+'|[>:]|<?[=!]|[idmnsuxU]+(?:-[idmnsuxU]+)?:?))?"),
      alias: "punctuation",
      inside: () => _g4),
  GrammarToken("group", compileHighlightPattern("\\)"), alias: "punctuation"),
  GrammarToken("quantifier",
      compileHighlightPattern("(?:[+*?]|\\{\\d+(?:,\\d*)?\\})[?+]?"),
      alias: "number"),
  GrammarToken("alternation", compileHighlightPattern("\\|"), alias: "keyword"),
]);

final Grammar _g1 = Grammar([
  GrammarToken("char-class-negation", compileHighlightPattern("(^\\[)\\^"),
      lookbehind: true, alias: "operator"),
  GrammarToken("char-class-punctuation", compileHighlightPattern("^\\[|\\]\$"),
      alias: "punctuation"),
  GrammarToken(
      "range",
      compileHighlightPattern(
          "(?:[^\\\\-]|\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.))-(?:[^\\\\-]|\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.))"),
      inside: () => _g2),
  GrammarToken(
      "special-escape", compileHighlightPattern("\\\\[\\\\(){}[\\]^\$+*?|.]"),
      alias: "escape"),
  GrammarToken(
      "char-set",
      compileHighlightPattern("\\\\[wsd]|\\\\p\\{[^{}]+\\}",
          caseSensitive: false),
      alias: "class-name"),
  GrammarToken(
      "escape",
      compileHighlightPattern(
          "\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.)")),
]);

final Grammar _g2 = Grammar([
  GrammarToken(
      "escape",
      compileHighlightPattern(
          "\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.)")),
  GrammarToken("range-punctuation", compileHighlightPattern("-"),
      alias: "operator"),
]);

final Grammar _g3 = Grammar([
  GrammarToken("group-name", compileHighlightPattern("(<|')[^<>']+(?=[>']\$)"),
      lookbehind: true, alias: "variable"),
]);

final Grammar _g4 = Grammar([
  GrammarToken("group-name", compileHighlightPattern("(<|')[^<>']+(?=[>']\$)"),
      lookbehind: true, alias: "variable"),
]);
