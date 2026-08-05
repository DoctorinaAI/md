// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `elixir`.
///
/// Import this library only when you need `elixir` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightElixir {
  /// The grammar for `elixir`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "doc",
      compileHighlightPattern(
          "@(?:doc|moduledoc)\\s+(?:(\"\"\"|''')[\\s\\S]*?\\1|(\"|')(?:\\\\(?:\\r\\n|[\\s\\S])|(?!\\2)[^\\\\\\r\\n])*\\2)"),
      inside: () => _g1),
  GrammarToken("comment", compileHighlightPattern("#.*"), greedy: true),
  GrammarToken(
      "regex",
      compileHighlightPattern(
          "~[rR](?:(\"\"\"|''')(?:\\\\[\\s\\S]|(?!\\1)[^\\\\])+\\1|([\\/|\"'])(?:\\\\.|(?!\\2)[^\\\\\\r\\n])+\\2|\\((?:\\\\.|[^\\\\)\\r\\n])+\\)|\\[(?:\\\\.|[^\\\\\\]\\r\\n])+\\]|\\{(?:\\\\.|[^\\\\}\\r\\n])+\\}|<(?:\\\\.|[^\\\\>\\r\\n])+>)[uismxfr]*"),
      greedy: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "~[cCsSwW](?:(\"\"\"|''')(?:\\\\[\\s\\S]|(?!\\1)[^\\\\])+\\1|([\\/|\"'])(?:\\\\.|(?!\\2)[^\\\\\\r\\n])+\\2|\\((?:\\\\.|[^\\\\)\\r\\n])+\\)|\\[(?:\\\\.|[^\\\\\\]\\r\\n])+\\]|\\{(?:\\\\.|#\\{[^}]+\\}|#(?!\\{)|[^#\\\\}\\r\\n])+\\}|<(?:\\\\.|[^\\\\>\\r\\n])+>)[csa]?"),
      greedy: true,
      inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("(\"\"\"|''')[\\s\\S]*?\\1"),
      greedy: true, inside: () => _g4),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(\"|')(?:\\\\(?:\\r\\n|[\\s\\S])|(?!\\1)[^\\\\\\r\\n])*\\1"),
      greedy: true,
      inside: () => _g6),
  GrammarToken("atom", compileHighlightPattern("(^|[^:]):\\w+"),
      lookbehind: true, alias: "symbol"),
  GrammarToken("module", compileHighlightPattern("\\b[A-Z]\\w*\\b"),
      alias: "class-name"),
  GrammarToken("attr-name", compileHighlightPattern("\\b\\w+\\??:(?!:)")),
  GrammarToken("argument", compileHighlightPattern("(^|[^&])&\\d+"),
      lookbehind: true, alias: "variable"),
  GrammarToken("attribute", compileHighlightPattern("@\\w+"),
      alias: "variable"),
  GrammarToken(
      "function",
      compileHighlightPattern(
          "\\b[_a-zA-Z]\\w*[?!]?(?:(?=\\s*(?:\\.\\s*)?\\()|(?=\\/\\d))")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b(?:0[box][a-f\\d_]+|\\d[\\d_]*)(?:\\.[\\d_]+)?(?:e[+-]?[\\d_]+)?\\b",
          caseSensitive: false)),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:after|alias|and|case|catch|cond|def(?:callback|delegate|exception|impl|macro|module|n|np|p|protocol|struct)?|do|else|end|fn|for|if|import|not|or|quote|raise|require|rescue|try|unless|unquote|use|when)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|nil|true)\\b")),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "\\bin\\b|&&?|\\|[|>]?|\\\\\\\\|::|\\.\\.\\.?|\\+\\+?|-[->]?|<[-=>]|>=|!==?|\\B!|=(?:==?|[>~])?|[*\\/^]")),
  GrammarToken("operator", compileHighlightPattern("([^<])<(?!<)"),
      lookbehind: true),
  GrammarToken("operator", compileHighlightPattern("([^>])>(?!>)"),
      lookbehind: true),
  GrammarToken("punctuation", compileHighlightPattern("<<|>>|[.,%\\[\\]{}()]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("attribute", compileHighlightPattern("^@\\w+")),
  GrammarToken("string", compileHighlightPattern("['\"][\\s\\S]+")),
]);

final Grammar _g2 = Grammar([
  GrammarToken("interpolation", compileHighlightPattern("#\\{[^}]+\\}"),
      inside: () => _g3),
]);

final Grammar _g3 = Grammar([
  GrammarToken("delimiter", compileHighlightPattern("^#\\{|\\}\$"),
      alias: "punctuation"),
], rest: () => _g0);

final Grammar _g4 = Grammar([
  GrammarToken("interpolation", compileHighlightPattern("#\\{[^}]+\\}"),
      inside: () => _g5),
]);

final Grammar _g5 = Grammar([
  GrammarToken("delimiter", compileHighlightPattern("^#\\{|\\}\$"),
      alias: "punctuation"),
], rest: () => _g0);

final Grammar _g6 = Grammar([
  GrammarToken("interpolation", compileHighlightPattern("#\\{[^}]+\\}"),
      inside: () => _g7),
]);

final Grammar _g7 = Grammar([
  GrammarToken("delimiter", compileHighlightPattern("^#\\{|\\}\$"),
      alias: "punctuation"),
], rest: () => _g0);
