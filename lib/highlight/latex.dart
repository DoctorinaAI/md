// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `latex`.
///
/// Import this library only when you need `latex` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightLatex {
  /// The grammar for `latex`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("%.*")),
  GrammarToken(
      "cdata",
      compileHighlightPattern(
          "(\\\\begin\\{((?:lstlisting|verbatim)\\*?)\\})[\\s\\S]*?(?=\\\\end\\{\\2\\})"),
      lookbehind: true),
  GrammarToken(
      "equation",
      compileHighlightPattern(
          "\\\$\\\$(?:\\\\[\\s\\S]|[^\\\\\$])+\\\$\\\$|\\\$(?:\\\\[\\s\\S]|[^\\\\\$])+\\\$|\\\\\\([\\s\\S]*?\\\\\\)|\\\\\\[[\\s\\S]*?\\\\\\]"),
      alias: "string",
      inside: () => _g1),
  GrammarToken(
      "equation",
      compileHighlightPattern(
          "(\\\\begin\\{((?:align|eqnarray|equation|gather|math|multline)\\*?)\\})[\\s\\S]*?(?=\\\\end\\{\\2\\})"),
      lookbehind: true,
      alias: "string",
      inside: () => _g1),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(\\\\(?:begin|cite|documentclass|end|label|ref|usepackage)(?:\\[[^\\]]+\\])?\\{)[^}]+(?=\\})"),
      lookbehind: true),
  GrammarToken("url", compileHighlightPattern("(\\\\url\\{)[^}]+(?=\\})"),
      lookbehind: true),
  GrammarToken(
      "headline",
      compileHighlightPattern(
          "(\\\\(?:chapter|frametitle|paragraph|part|section|subparagraph|subsection|subsubparagraph|subsubsection|subsubsubparagraph)\\*?(?:\\[[^\\]]+\\])?\\{)[^}]+(?=\\})"),
      lookbehind: true,
      alias: "class-name"),
  GrammarToken(
      "function",
      compileHighlightPattern("\\\\(?:[^a-z()[\\]]|[a-z*]+)",
          caseSensitive: false),
      alias: "selector"),
  GrammarToken("punctuation", compileHighlightPattern("[[\\]{}&]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "equation-command",
      compileHighlightPattern("\\\\(?:[^a-z()[\\]]|[a-z*]+)",
          caseSensitive: false),
      alias: "regex"),
]);
