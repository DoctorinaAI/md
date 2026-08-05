// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `css`.
///
/// Import this library only when you need `css` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightCss {
  /// The grammar for `css`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("\\/\\*[\\s\\S]*?\\*\\/")),
  GrammarToken(
      "atrule",
      compileHighlightPattern(
          "@[\\w-](?:[^;{\\s\"']|\\s+(?!\\s)|(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*'))*?(?:;|(?=\\s*\\{))"),
      inside: () => _g1),
  GrammarToken(
      "url",
      compileHighlightPattern(
          "\\burl\\((?:(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*')|(?:[^\\\\\\r\\n()\"']|\\\\[\\s\\S])*)\\)",
          caseSensitive: false),
      greedy: true,
      inside: () => _g2),
  GrammarToken(
      "selector",
      compileHighlightPattern(
          "(^|[{}\\s])[^{}\\s](?:[^{};\"'\\s]|\\s+(?![\\s{])|(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*'))*(?=\\s*\\{)"),
      lookbehind: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*')"),
      greedy: true),
  GrammarToken(
      "property",
      compileHighlightPattern(
          "(^|[^-\\w\\xA0-\\uFFFF])(?!\\s)[-_a-z\\xA0-\\uFFFF](?:(?!\\s)[-\\w\\xA0-\\uFFFF])*(?=\\s*:)",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken("important",
      compileHighlightPattern("!important\\b", caseSensitive: false)),
  GrammarToken(
      "function",
      compileHighlightPattern("(^|[^-a-z0-9])[-a-z0-9]+(?=\\()",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken("punctuation", compileHighlightPattern("[(){};:,]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("rule", compileHighlightPattern("^@[\\w-]+")),
  GrammarToken(
      "selector-function-argument",
      compileHighlightPattern(
          "(\\bselector\\s*\\(\\s*(?![\\s)]))(?:[^()\\s]|\\s+(?![\\s)])|\\((?:[^()]|\\([^()]*\\))*\\))+(?=\\s*\\))"),
      lookbehind: true,
      alias: "selector"),
  GrammarToken("keyword",
      compileHighlightPattern("(^|[^\\w-])(?:and|not|only|or)(?![\\w-])"),
      lookbehind: true),
], rest: () => _g0);

final Grammar _g2 = Grammar([
  GrammarToken(
      "function", compileHighlightPattern("^url", caseSensitive: false)),
  GrammarToken("punctuation", compileHighlightPattern("^\\(|\\)\$")),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "^(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*')\$"),
      alias: "url"),
]);
