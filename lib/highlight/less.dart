// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `less`.
///
/// Import this library only when you need `less` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightLess {
  /// The grammar for `less`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("\\/\\*[\\s\\S]*?\\*\\/")),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\])\\/\\/.*"),
      lookbehind: true),
  GrammarToken(
      "atrule",
      compileHighlightPattern(
          "@[\\w-](?:\\((?:[^(){}]|\\([^(){}]*\\))*\\)|[^(){};\\s]|\\s+(?!\\s))*?(?=\\s*\\{)"),
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
          "(?:@\\{[\\w-]+\\}|[^{};\\s@])(?:@\\{[\\w-]+\\}|\\((?:[^(){}]|\\([^(){}]*\\))*\\)|[^(){};@\\s]|\\s+(?!\\s))*?(?=\\s*\\{)"),
      inside: () => _g3),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*')"),
      greedy: true),
  GrammarToken("variable", compileHighlightPattern("@[\\w-]+\\s*:"),
      inside: () => _g4),
  GrammarToken("variable", compileHighlightPattern("@@?[\\w-]+")),
  GrammarToken("mixin-usage",
      compileHighlightPattern("([{;]\\s*)[.#](?!\\d)[\\w-].*?(?=[(;])"),
      lookbehind: true, alias: "function"),
  GrammarToken("property",
      compileHighlightPattern("(?:@\\{[\\w-]+\\}|[\\w-])+(?:\\+_?)?(?=\\s*:)")),
  GrammarToken("important",
      compileHighlightPattern("!important\\b", caseSensitive: false)),
  GrammarToken(
      "function",
      compileHighlightPattern("(^|[^-a-z0-9])[-a-z0-9]+(?=\\()",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken("punctuation", compileHighlightPattern("[(){};:,]")),
  GrammarToken("operator", compileHighlightPattern("[+\\-*\\/]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("[:()]")),
]);

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

final Grammar _g3 = Grammar([
  GrammarToken("variable", compileHighlightPattern("@+[\\w-]+")),
]);

final Grammar _g4 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern(":")),
]);
