// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `handlebars`.
///
/// Import this library only when you need `handlebars` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightHandlebars {
  /// The grammar for `handlebars`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("\\{\\{![\\s\\S]*?\\}\\}")),
  GrammarToken("delimiter", compileHighlightPattern("^\\{\\{\\{?|\\}\\}\\}?\$"),
      alias: "punctuation"),
  GrammarToken("string",
      compileHighlightPattern("([\"'])(?:\\\\.|(?!\\1)[^\\\\\\r\\n])*\\1")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0x[\\dA-Fa-f]+\\b|(?:\\b\\d+(?:\\.\\d*)?|\\B\\.\\d+)(?:[Ee][+-]?\\d+)?")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken(
      "block",
      compileHighlightPattern(
          "^(\\s*(?:~\\s*)?)[#\\/]\\S+?(?=\\s*(?:~\\s*)?\$|\\s)"),
      lookbehind: true,
      alias: "keyword"),
  GrammarToken("brackets", compileHighlightPattern("\\[[^\\]]+\\]"),
      inside: () => _g1),
  GrammarToken("punctuation",
      compileHighlightPattern("[!\"#%&':()*+,.\\/;<=>@\\[\\\\\\]^`{|}~]")),
  GrammarToken("variable",
      compileHighlightPattern("[^!\"#%&'()*+,\\/;<=>@\\[\\\\\\]^`{|}~\\s]+")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\[|\\]")),
  GrammarToken("variable", compileHighlightPattern("[\\s\\S]+")),
]);
