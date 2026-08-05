// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `makefile`.
///
/// Import this library only when you need `makefile` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightMakefile {
  /// The grammar for `makefile`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "(^|[^\\\\])#(?:\\\\(?:\\r\\n|[\\s\\S])|[^\\\\\\r\\n])*"),
      lookbehind: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "([\"'])(?:\\\\(?:\\r\\n|[\\s\\S])|(?!\\1)[^\\\\\\r\\n])*\\1"),
      greedy: true),
  GrammarToken("builtin-target",
      compileHighlightPattern("\\.[A-Z][^:#=\\s]+(?=\\s*:(?!=))"),
      alias: "builtin"),
  GrammarToken(
      "target",
      compileHighlightPattern("^(?:[^:=\\s]|[ \\t]+(?![\\s:]))+(?=\\s*:(?!=))",
          multiLine: true),
      alias: "symbol",
      inside: () => _g1),
  GrammarToken(
      "variable",
      compileHighlightPattern(
          "\\\$+(?:(?!\\\$)[^(){}:#=\\s]+|\\([@*%<^+?][DF]\\)|(?=[({]))")),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "-include\\b|\\b(?:define|else|endef|endif|export|ifn?def|ifn?eq|include|override|private|sinclude|undefine|unexport|vpath)\\b")),
  GrammarToken(
      "function",
      compileHighlightPattern(
          "(\\()(?:abspath|addsuffix|and|basename|call|dir|error|eval|file|filter(?:-out)?|findstring|firstword|flavor|foreach|guile|if|info|join|lastword|load|notdir|or|origin|patsubst|realpath|shell|sort|strip|subst|suffix|value|warning|wildcard|word(?:list|s)?)(?=[ \\t])"),
      lookbehind: true),
  GrammarToken("operator", compileHighlightPattern("(?:::|[?:+!])?=|[|@]")),
  GrammarToken("punctuation", compileHighlightPattern("[:;(){}]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("variable",
      compileHighlightPattern("\\\$+(?:(?!\\\$)[^(){}:#=\\s]+|(?=[({]))")),
]);
