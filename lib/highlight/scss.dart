// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `scss`.
///
/// Import this library only when you need `scss` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightScss {
  /// The grammar for `scss`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])(?:\\/\\*[\\s\\S]*?\\*\\/|\\/\\/.*)"),
      lookbehind: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "@(?:content|debug|each|else(?: if)?|extend|for|forward|function|if|import|include|mixin|return|use|warn|while)\\b",
          caseSensitive: false)),
  GrammarToken("keyword", compileHighlightPattern("( )(?:from|through)(?= )"),
      lookbehind: true),
  GrammarToken(
      "atrule",
      compileHighlightPattern(
          "@[\\w-](?:\\([^()]+\\)|[^()\\s]|\\s+(?!\\s))*?(?=\\s+[{;])"),
      inside: () => _g1),
  GrammarToken("url",
      compileHighlightPattern("(?:[-a-z]+-)?url(?=\\()", caseSensitive: false)),
  GrammarToken(
      "selector",
      compileHighlightPattern(
          "(?=\\S)[^@;{}()]?(?:[^@;{}()\\s]|\\s+(?!\\s)|#\\{\\\$[-\\w]+\\})+(?=\\s*\\{(?:\\}|\\s|[^}][^:{}]*[:{][^}]))"),
      inside: () => _g2),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*')"),
      greedy: true),
  GrammarToken(
      "property",
      compileHighlightPattern(
          "(?:[-\\w]|\\\$[-\\w]|#\\{\\\$[-\\w]+\\})+(?=\\s*:)"),
      inside: () => _g3),
  GrammarToken(
      "variable", compileHighlightPattern("\\\$[-\\w]+|#\\{\\\$[-\\w]+\\}")),
  GrammarToken("important",
      compileHighlightPattern("!important\\b", caseSensitive: false)),
  GrammarToken(
      "module-modifier",
      compileHighlightPattern("\\b(?:as|hide|show|with)\\b",
          caseSensitive: false),
      alias: "keyword"),
  GrammarToken("placeholder", compileHighlightPattern("%[-\\w]+"),
      alias: "selector"),
  GrammarToken(
      "statement",
      compileHighlightPattern("\\B!(?:default|optional)\\b",
          caseSensitive: false),
      alias: "keyword"),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("null", compileHighlightPattern("\\bnull\\b"), alias: "keyword"),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "(\\s)(?:[-+*\\/%]|[=!]=|<=?|>=?|and|not|or)(?=\\s)"),
      lookbehind: true),
  GrammarToken(
      "function",
      compileHighlightPattern("(^|[^-a-z0-9])[-a-z0-9]+(?=\\()",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken("punctuation", compileHighlightPattern("[(){};:,]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("rule", compileHighlightPattern("@[\\w-]+")),
], rest: () => _g0);

final Grammar _g2 = Grammar([
  GrammarToken("parent", compileHighlightPattern("&"), alias: "important"),
  GrammarToken("placeholder", compileHighlightPattern("%[-\\w]+")),
  GrammarToken(
      "variable", compileHighlightPattern("\\\$[-\\w]+|#\\{\\\$[-\\w]+\\}")),
]);

final Grammar _g3 = Grammar([
  GrammarToken(
      "variable", compileHighlightPattern("\\\$[-\\w]+|#\\{\\\$[-\\w]+\\}")),
]);
