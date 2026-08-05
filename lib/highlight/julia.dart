// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `julia`.
///
/// Import this library only when you need `julia` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightJulia {
  /// The grammar for `julia`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "(^|[^\\\\])(?:#=(?:[^#=]|=(?!#)|#(?!=)|#=(?:[^#=]|=(?!#)|#(?!=))*=#)*=#|#.*)"),
      lookbehind: true),
  GrammarToken("regex",
      compileHighlightPattern("r\"(?:\\\\.|[^\"\\\\\\r\\n])*\"[imsx]{0,4}"),
      greedy: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\"\"\"[\\s\\S]+?\"\"\"|(?:\\b\\w+)?\"(?:\\\\.|[^\"\\\\\\r\\n])*\"|`(?:[^\\\\`\\r\\n]|\\\\.)*`"),
      greedy: true),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "(^|[^\\w'])'(?:\\\\[^\\r\\n][^'\\r\\n]*|[^\\\\\\r\\n])'"),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:abstract|baremodule|begin|bitstype|break|catch|ccall|const|continue|do|else|elseif|end|export|finally|for|function|global|if|immutable|import|importall|in|let|local|macro|module|print|println|quote|return|struct|try|type|typealias|using|while)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "(?:\\b(?=\\d)|\\B(?=\\.))(?:0[box])?(?:[\\da-f]+(?:_[\\da-f]+)*(?:\\.(?:\\d+(?:_\\d+)*)?)?|\\.\\d+(?:_\\d+)*)(?:[efp][+-]?\\d+(?:_\\d+)*)?j?",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "&&|\\|\\||[-+*^%÷⊻&\$\\\\]=?|\\/[\\/=]?|!=?=?|\\|[=>]?|<(?:<=?|[=:|])?|>(?:=|>>?=?)?|==?=?|[~≠≤≥'√∛]")),
  GrammarToken("punctuation", compileHighlightPattern("::?|[{}[\\]();,.?]")),
  GrammarToken("constant",
      compileHighlightPattern("\\b(?:(?:Inf|NaN)(?:16|32|64)?|im|pi)\\b|[πℯ]")),
]);
