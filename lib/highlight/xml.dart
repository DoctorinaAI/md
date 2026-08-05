// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `xml`.
///
/// Import this library only when you need `xml` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightXml {
  /// The grammar for `xml`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "comment", compileHighlightPattern("<!--(?:(?!<!--)[\\s\\S])*?-->"),
      greedy: true),
  GrammarToken("prolog", compileHighlightPattern("<\\?[\\s\\S]+?\\?>"),
      greedy: true),
  GrammarToken(
      "doctype",
      compileHighlightPattern(
          "<!DOCTYPE(?:[^>\"'[\\]]|\"[^\"]*\"|'[^']*')+(?:\\[(?:[^<\"'\\]]|\"[^\"]*\"|'[^']*'|<(?!!--)|<!--(?:[^-]|-(?!->))*-->)*\\]\\s*)?>",
          caseSensitive: false),
      greedy: true,
      inside: () => _g1),
  GrammarToken(
      "cdata",
      compileHighlightPattern("<!\\[CDATA\\[[\\s\\S]*?\\]\\]>",
          caseSensitive: false),
      greedy: true),
  GrammarToken(
      "tag",
      compileHighlightPattern(
          "<\\/?(?!\\d)[^\\s>\\/=\$<%]+(?:\\s(?:\\s*[^\\s>\\/=]+(?:\\s*=\\s*(?:\"[^\"]*\"|'[^']*'|[^\\s'\">=]+(?=[\\s>]))|(?=[\\s/>])))+)?\\s*\\/?>"),
      greedy: true,
      inside: () => _g2),
  GrammarToken("entity",
      compileHighlightPattern("&[\\da-z]{1,8};", caseSensitive: false),
      alias: "named-entity"),
  GrammarToken("entity",
      compileHighlightPattern("&#x?[\\da-f]{1,8};", caseSensitive: false)),
]);

final Grammar _g1 = Grammar([
  GrammarToken("internal-subset",
      compileHighlightPattern("(^[^\\[]*\\[)[\\s\\S]+(?=\\]>\$)"),
      lookbehind: true, greedy: true, inside: () => _g0),
  GrammarToken("string", compileHighlightPattern("\"[^\"]*\"|'[^']*'"),
      greedy: true),
  GrammarToken("punctuation", compileHighlightPattern("^<!|>\$|[[\\]]")),
  GrammarToken(
      "doctype-tag", compileHighlightPattern("^DOCTYPE", caseSensitive: false)),
  GrammarToken("name", compileHighlightPattern("[^\\s<>'\"]+")),
]);

final Grammar _g2 = Grammar([
  GrammarToken("tag", compileHighlightPattern("^<\\/?[^\\s>\\/]+"),
      inside: () => _g3),
  GrammarToken("attr-value",
      compileHighlightPattern("=\\s*(?:\"[^\"]*\"|'[^']*'|[^\\s'\">=]+)"),
      inside: () => _g4),
  GrammarToken("punctuation", compileHighlightPattern("\\/?>")),
  GrammarToken("attr-name", compileHighlightPattern("[^\\s>\\/]+"),
      inside: () => _g5),
]);

final Grammar _g3 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("^<\\/?")),
  GrammarToken("namespace", compileHighlightPattern("^[^\\s>\\/:]+:")),
]);

final Grammar _g4 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("^="),
      alias: "attr-equals"),
  GrammarToken("punctuation", compileHighlightPattern("^(\\s*)[\"']|[\"']\$"),
      lookbehind: true),
  GrammarToken("entity",
      compileHighlightPattern("&[\\da-z]{1,8};", caseSensitive: false),
      alias: "named-entity"),
  GrammarToken("entity",
      compileHighlightPattern("&#x?[\\da-f]{1,8};", caseSensitive: false)),
]);

final Grammar _g5 = Grammar([
  GrammarToken("namespace", compileHighlightPattern("^[^\\s>\\/:]+:")),
]);
