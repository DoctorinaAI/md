// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `rust`.
///
/// Import this library only when you need `rust` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightRust {
  /// The grammar for `rust`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "(^|[^\\\\])\\/\\*(?:[^*/]|\\*(?!\\/)|\\/(?!\\*)|\\/\\*(?:[^*/]|\\*(?!\\/)|\\/(?!\\*)|\\/\\*(?:[^*/]|\\*(?!\\/)|\\/(?!\\*)|\\/\\*(?:[^*/]|\\*(?!\\/)|\\/(?!\\*)|[^\\s\\S])*\\*\\/)*\\*\\/)*\\*\\/)*\\*\\/"),
      lookbehind: true,
      greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "b?\"(?:\\\\[\\s\\S]|[^\\\\\"])*\"|b?r(#*)\"(?:[^\"]|\"(?!\\1))*\"\\1"),
      greedy: true),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "b?'(?:\\\\(?:x[0-7][\\da-fA-F]|u\\{(?:[\\da-fA-F]_*){1,6}\\}|.)|[^\\\\\\r\\n\\t'])'"),
      greedy: true),
  GrammarToken(
      "attribute",
      compileHighlightPattern(
          "#!?\\[(?:[^\\[\\]\"]|\"(?:\\\\[\\s\\S]|[^\\\\\"])*\")*\\]"),
      greedy: true,
      alias: "attr-name",
      inside: () => _g1),
  GrammarToken(
      "closure-params",
      compileHighlightPattern(
          "([=(,:]\\s*|\\bmove\\s*)\\|[^|]*\\||\\|[^|]*\\|(?=\\s*(?:\\{|->))"),
      lookbehind: true,
      greedy: true,
      inside: () => _g2),
  GrammarToken("lifetime-annotation", compileHighlightPattern("'\\w+"),
      alias: "symbol"),
  GrammarToken(
      "fragment-specifier", compileHighlightPattern("(\\\$\\w+:)[a-z]+"),
      lookbehind: true, alias: "punctuation"),
  GrammarToken("variable", compileHighlightPattern("\\\$\\w+")),
  GrammarToken(
      "function-definition", compileHighlightPattern("(\\bfn\\s+)\\w+"),
      lookbehind: true, alias: "function"),
  GrammarToken("type-definition",
      compileHighlightPattern("(\\b(?:enum|struct|trait|type|union)\\s+)\\w+"),
      lookbehind: true, alias: "class-name"),
  GrammarToken("module-declaration",
      compileHighlightPattern("(\\b(?:crate|mod)\\s+)[a-z][a-z_\\d]*"),
      lookbehind: true, alias: "namespace"),
  GrammarToken(
      "module-declaration",
      compileHighlightPattern(
          "(\\b(?:crate|self|super)\\s*)::\\s*[a-z][a-z_\\d]*\\b(?:\\s*::(?:\\s*[a-z][a-z_\\d]*\\s*::)*)?"),
      lookbehind: true,
      alias: "namespace",
      inside: () => _g3),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:Self|abstract|as|async|await|become|box|break|const|continue|crate|do|dyn|else|enum|extern|final|fn|for|if|impl|in|let|loop|macro|match|mod|move|mut|override|priv|pub|ref|return|self|static|struct|super|trait|try|type|typeof|union|unsafe|unsized|use|virtual|where|while|yield)\\b")),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:bool|char|f(?:32|64)|[ui](?:8|16|32|64|128|size)|str)\\b")),
  GrammarToken("function",
      compileHighlightPattern("\\b[a-z_]\\w*(?=\\s*(?:::\\s*<|\\())")),
  GrammarToken("macro", compileHighlightPattern("\\b\\w+!"), alias: "property"),
  GrammarToken("constant", compileHighlightPattern("\\b[A-Z_][A-Z_\\d]+\\b")),
  GrammarToken("class-name", compileHighlightPattern("\\b[A-Z]\\w*\\b")),
  GrammarToken(
      "namespace",
      compileHighlightPattern(
          "(?:\\b[a-z][a-z_\\d]*\\s*::\\s*)*\\b[a-z][a-z_\\d]*\\s*::(?!\\s*<)"),
      inside: () => _g4),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b(?:0x[\\dA-Fa-f](?:_?[\\dA-Fa-f])*|0o[0-7](?:_?[0-7])*|0b[01](?:_?[01])*|(?:(?:\\d(?:_?\\d)*)?\\.)?\\d(?:_?\\d)*(?:[Ee][+-]?\\d+)?)(?:_?(?:f32|f64|[iu](?:8|16|32|64|size)?))?\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("punctuation",
      compileHighlightPattern("->|\\.\\.=|\\.{1,3}|::|[{}[\\];(),:]")),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "[-+*\\/%!^]=?|=[=>]?|&[&=]?|\\|[|=]?|<<?=?|>>?=?|[@?]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "string",
      compileHighlightPattern(
          "b?\"(?:\\\\[\\s\\S]|[^\\\\\"])*\"|b?r(#*)\"(?:[^\"]|\"(?!\\1))*\"\\1"),
      greedy: true),
]);

final Grammar _g2 = Grammar([
  GrammarToken("closure-punctuation", compileHighlightPattern("^\\||\\|\$"),
      alias: "punctuation"),
], rest: () => _g0);

final Grammar _g3 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("::")),
]);

final Grammar _g4 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("::")),
]);
