// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `python`.
///
/// Import this library only when you need `python` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightPython {
  /// The grammar for `python`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\])#.*"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "string-interpolation",
      compileHighlightPattern(
          "(?:f|fr|rf)(?:(\"\"\"|''')[\\s\\S]*?\\1|(\"|')(?:\\\\.|(?!\\2)[^\\\\\\r\\n])*\\2)",
          caseSensitive: false),
      greedy: true,
      inside: () => _g1),
  GrammarToken(
      "triple-quoted-string",
      compileHighlightPattern("(?:[rub]|br|rb)?(\"\"\"|''')[\\s\\S]*?\\1",
          caseSensitive: false),
      greedy: true,
      alias: "string"),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(?:[rub]|br|rb)?(\"|')(?:\\\\.|(?!\\1)[^\\\\\\r\\n])*\\1",
          caseSensitive: false),
      greedy: true),
  GrammarToken("function",
      compileHighlightPattern("((?:^|\\s)def[ \\t]+)[a-zA-Z_]\\w*(?=\\s*\\()"),
      lookbehind: true),
  GrammarToken("class-name",
      compileHighlightPattern("(\\bclass\\s+)\\w+", caseSensitive: false),
      lookbehind: true),
  GrammarToken("decorator",
      compileHighlightPattern("(^[\\t ]*)@\\w+(?:\\.\\w+)*", multiLine: true),
      lookbehind: true, alias: "annotation", inside: () => _g3),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:_(?=\\s*:)|and|as|assert|async|await|break|case|class|continue|def|del|elif|else|except|exec|finally|for|from|global|if|import|in|is|lambda|match|nonlocal|not|or|pass|print|raise|return|try|while|with|yield)\\b")),
  GrammarToken(
      "builtin",
      compileHighlightPattern(
          "\\b(?:__import__|abs|all|any|apply|ascii|basestring|bin|bool|buffer|bytearray|bytes|callable|chr|classmethod|cmp|coerce|compile|complex|delattr|dict|dir|divmod|enumerate|eval|execfile|file|filter|float|format|frozenset|getattr|globals|hasattr|hash|help|hex|id|input|int|intern|isinstance|issubclass|iter|len|list|locals|long|map|max|memoryview|min|next|object|oct|open|ord|pow|property|range|raw_input|reduce|reload|repr|reversed|round|set|setattr|slice|sorted|staticmethod|str|sum|super|tuple|type|unichr|unicode|vars|xrange|zip)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:False|None|True)\\b")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0(?:b(?:_?[01])+|o(?:_?[0-7])+|x(?:_?[a-f0-9])+)\\b|(?:\\b\\d+(?:_\\d+)*(?:\\.(?:\\d+(?:_\\d+)*)?)?|\\B\\.\\d+(?:_\\d+)*)(?:e[+-]?\\d+(?:_\\d+)*)?j?(?!\\w)",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "[-+%=]=?|!=|:=|\\*\\*?=?|\\/\\/?=?|<[<=>]?|>[=>]?|[&|^~]")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^{])(?:\\{\\{)*)\\{(?!\\{)(?:[^{}]|\\{(?!\\{)(?:[^{}]|\\{(?!\\{)(?:[^{}])+\\})+\\})+\\}"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g2 = Grammar([
  GrammarToken("format-spec", compileHighlightPattern("(:)[^:(){}]+(?=\\}\$)"),
      lookbehind: true),
  GrammarToken("conversion-option", compileHighlightPattern("![sra](?=[:}]\$)"),
      alias: "punctuation"),
], rest: () => _g0);

final Grammar _g3 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);
