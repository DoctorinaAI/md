// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';
import 'markdown.dart';

/// Syntax grammar for `graphql`.
///
/// Import this library only when you need `graphql` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightGraphql {
  /// The grammar for `graphql`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("#.*")),
  GrammarToken(
      "description",
      compileHighlightPattern(
          "(?:\"\"\"(?:[^\"]|(?!\"\"\")\")*\"\"\"|\"(?:\\\\.|[^\\\\\"\\r\\n])*\")(?=\\s*[a-z_])",
          caseSensitive: false),
      greedy: true,
      alias: "string",
      inside: () => _g1),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\"\"\"(?:[^\"]|(?!\"\"\")\")*\"\"\"|\"(?:\\\\.|[^\\\\\"\\r\\n])*\""),
      greedy: true),
  GrammarToken(
      "number",
      compileHighlightPattern("(?:\\B-|\\b)\\d+(?:\\.\\d+)?(?:e[+-]?\\d+)?\\b",
          caseSensitive: false)),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("variable",
      compileHighlightPattern("\\\$[a-z_]\\w*", caseSensitive: false)),
  GrammarToken(
      "directive", compileHighlightPattern("@[a-z_]\\w*", caseSensitive: false),
      alias: "function"),
  GrammarToken(
      "attr-name",
      compileHighlightPattern(
          "\\b[a-z_]\\w*(?=\\s*(?:\\((?:[^()\"]|\"(?:\\\\.|[^\\\\\"\\r\\n])*\")*\\))?:)",
          caseSensitive: false),
      greedy: true),
  GrammarToken("atom-input", compileHighlightPattern("\\b[A-Z]\\w*Input\\b"),
      alias: "class-name"),
  GrammarToken("scalar",
      compileHighlightPattern("\\b(?:Boolean|Float|ID|Int|String)\\b")),
  GrammarToken("constant", compileHighlightPattern("\\b[A-Z][A-Z_\\d]*\\b")),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:enum|implements|interface|on|scalar|type|union)\\s+|&\\s*|:\\s*|\\[)[A-Z_]\\w*"),
      lookbehind: true),
  GrammarToken(
      "fragment",
      compileHighlightPattern(
          "(\\bfragment\\s+|\\.{3}\\s*(?!on\\b))[a-zA-Z_]\\w*"),
      lookbehind: true,
      alias: "function"),
  GrammarToken("definition-mutation",
      compileHighlightPattern("(\\bmutation\\s+)[a-zA-Z_]\\w*"),
      lookbehind: true, alias: "function"),
  GrammarToken("definition-query",
      compileHighlightPattern("(\\bquery\\s+)[a-zA-Z_]\\w*"),
      lookbehind: true, alias: "function"),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:directive|enum|extend|fragment|implements|input|interface|mutation|on|query|repeatable|scalar|schema|subscription|type|union)\\b")),
  GrammarToken("operator", compileHighlightPattern("[!=|&]|\\.{3}")),
  GrammarToken("property-query", compileHighlightPattern("\\w+(?=\\s*\\()")),
  GrammarToken("object", compileHighlightPattern("\\w+(?=\\s*\\{)")),
  GrammarToken("punctuation", compileHighlightPattern("[!(){}\\[\\]:=,]")),
  GrammarToken("property", compileHighlightPattern("\\w+")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("language-markdown",
      compileHighlightPattern("(^\"(?:\"\")?)(?!\\1)[\\s\\S]+(?=\\1\$)"),
      lookbehind: true, inside: () => HighlightMarkdown.grammar),
]);
