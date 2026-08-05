// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';
import 'css.dart';
import 'js.dart';

/// Syntax grammar for `html`.
///
/// Import this library only when you need `html` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightHtml {
  /// The grammar for `html`.
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
      "style",
      compileHighlightPattern(
          "(<style[^>]*>)(?:<!\\[CDATA\\[(?:[^\\]]|\\](?!\\]>))*\\]\\]>|(?!<!\\[CDATA\\[)[\\s\\S])*?(?=<\\/style>)",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      inside: () => _g2),
  GrammarToken(
      "script",
      compileHighlightPattern(
          "(<script[^>]*>)(?:<!\\[CDATA\\[(?:[^\\]]|\\](?!\\]>))*\\]\\]>|(?!<!\\[CDATA\\[)[\\s\\S])*?(?=<\\/script>)",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      inside: () => _g4),
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
      inside: () => _g6),
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
  GrammarToken(
      "included-cdata",
      compileHighlightPattern("<!\\[CDATA\\[[\\s\\S]*?\\]\\]>",
          caseSensitive: false),
      inside: () => _g3),
  GrammarToken("language-css", compileHighlightPattern("[\\s\\S]+"),
      inside: () => HighlightCss.grammar),
]);

final Grammar _g3 = Grammar([
  GrammarToken(
      "language-css",
      compileHighlightPattern("(^<!\\[CDATA\\[)[\\s\\S]+?(?=\\]\\]>\$)",
          caseSensitive: false),
      lookbehind: true,
      inside: () => HighlightCss.grammar),
  GrammarToken(
      "cdata",
      compileHighlightPattern("^<!\\[CDATA\\[|\\]\\]>\$",
          caseSensitive: false)),
]);

final Grammar _g4 = Grammar([
  GrammarToken(
      "included-cdata",
      compileHighlightPattern("<!\\[CDATA\\[[\\s\\S]*?\\]\\]>",
          caseSensitive: false),
      inside: () => _g5),
  GrammarToken("language-javascript", compileHighlightPattern("[\\s\\S]+"),
      inside: () => HighlightJs.grammar),
]);

final Grammar _g5 = Grammar([
  GrammarToken(
      "language-javascript",
      compileHighlightPattern("(^<!\\[CDATA\\[)[\\s\\S]+?(?=\\]\\]>\$)",
          caseSensitive: false),
      lookbehind: true,
      inside: () => HighlightJs.grammar),
  GrammarToken(
      "cdata",
      compileHighlightPattern("^<!\\[CDATA\\[|\\]\\]>\$",
          caseSensitive: false)),
]);

final Grammar _g6 = Grammar([
  GrammarToken("tag", compileHighlightPattern("^<\\/?[^\\s>\\/]+"),
      inside: () => _g7),
  GrammarToken(
      "special-attr",
      compileHighlightPattern(
          "(^|[\"'\\s])(?:style)\\s*=\\s*(?:\"[^\"]*\"|'[^']*'|[^\\s'\">=]+(?=[\\s>]))",
          caseSensitive: false),
      lookbehind: true,
      inside: () => _g8),
  GrammarToken(
      "special-attr",
      compileHighlightPattern(
          "(^|[\"'\\s])(?:on(?:abort|blur|change|click|composition(?:end|start|update)|dblclick|error|focus(?:in|out)?|key(?:down|up)|load|mouse(?:down|enter|leave|move|out|over|up)|reset|resize|scroll|select|slotchange|submit|unload|wheel))\\s*=\\s*(?:\"[^\"]*\"|'[^']*'|[^\\s'\">=]+(?=[\\s>]))",
          caseSensitive: false),
      lookbehind: true,
      inside: () => _g10),
  GrammarToken("attr-value",
      compileHighlightPattern("=\\s*(?:\"[^\"]*\"|'[^']*'|[^\\s'\">=]+)"),
      inside: () => _g12),
  GrammarToken("punctuation", compileHighlightPattern("\\/?>")),
  GrammarToken("attr-name", compileHighlightPattern("[^\\s>\\/]+"),
      inside: () => _g13),
]);

final Grammar _g7 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("^<\\/?")),
  GrammarToken("namespace", compileHighlightPattern("^[^\\s>\\/:]+:")),
]);

final Grammar _g8 = Grammar([
  GrammarToken("attr-name", compileHighlightPattern("^[^\\s=]+")),
  GrammarToken("attr-value", compileHighlightPattern("=[\\s\\S]+"),
      inside: () => _g9),
]);

final Grammar _g9 = Grammar([
  GrammarToken("value",
      compileHighlightPattern("(^=\\s*([\"']|(?![\"'])))\\S[\\s\\S]*(?=\\2\$)"),
      lookbehind: true, alias: "css", inside: () => HighlightCss.grammar),
  GrammarToken("punctuation", compileHighlightPattern("^="),
      alias: "attr-equals"),
  GrammarToken("punctuation", compileHighlightPattern("\"|'")),
]);

final Grammar _g10 = Grammar([
  GrammarToken("attr-name", compileHighlightPattern("^[^\\s=]+")),
  GrammarToken("attr-value", compileHighlightPattern("=[\\s\\S]+"),
      inside: () => _g11),
]);

final Grammar _g11 = Grammar([
  GrammarToken("value",
      compileHighlightPattern("(^=\\s*([\"']|(?![\"'])))\\S[\\s\\S]*(?=\\2\$)"),
      lookbehind: true, alias: "javascript", inside: () => HighlightJs.grammar),
  GrammarToken("punctuation", compileHighlightPattern("^="),
      alias: "attr-equals"),
  GrammarToken("punctuation", compileHighlightPattern("\"|'")),
]);

final Grammar _g12 = Grammar([
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

final Grammar _g13 = Grammar([
  GrammarToken("namespace", compileHighlightPattern("^[^\\s>\\/:]+:")),
]);
