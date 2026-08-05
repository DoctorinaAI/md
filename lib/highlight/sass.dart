// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `sass`.
///
/// Import this library only when you need `sass` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightSass {
  /// The grammar for `sass`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "^([ \\t]*)\\/[\\/*].*(?:(?:\\r?\\n|\\r)\\1[ \\t].+)*",
          multiLine: true),
      lookbehind: true,
      greedy: true),
  GrammarToken("atrule-line",
      compileHighlightPattern("^(?:[ \\t]*)[@+=].+", multiLine: true),
      greedy: true, inside: () => _g1),
  GrammarToken(
      "url",
      compileHighlightPattern(
          "\\burl\\((?:(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*')|(?:[^\\\\\\r\\n()\"']|\\\\[\\s\\S])*)\\)",
          caseSensitive: false),
      greedy: true,
      inside: () => _g2),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*')"),
      greedy: true),
  GrammarToken("variable-line",
      compileHighlightPattern("^[ \\t]*\\\$.+", multiLine: true),
      greedy: true, inside: () => _g3),
  GrammarToken(
      "property-line",
      compileHighlightPattern("^[ \\t]*(?:[^:\\s]+ *:.*|:[^:\\s].*)",
          multiLine: true),
      greedy: true,
      inside: () => _g4),
  GrammarToken(
      "function",
      compileHighlightPattern("(^|[^-a-z0-9])[-a-z0-9]+(?=\\()",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken(
      "selector",
      compileHighlightPattern(
          "^([ \\t]*)\\S(?:,[^,\\r\\n]+|[^,\\r\\n]*)(?:,[^,\\r\\n]+)*(?:,(?:\\r?\\n|\\r)\\1[ \\t]+\\S(?:,[^,\\r\\n]+|[^,\\r\\n]*)(?:,[^,\\r\\n]+)*)*",
          multiLine: true),
      lookbehind: true,
      greedy: true),
  GrammarToken("punctuation", compileHighlightPattern("[(){};:,]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("atrule", compileHighlightPattern("(?:@[\\w-]+|[+=])")),
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
  GrammarToken("punctuation", compileHighlightPattern(":")),
  GrammarToken(
      "variable", compileHighlightPattern("\\\$[-\\w]+|#\\{\\\$[-\\w]+\\}")),
  GrammarToken("operator",
      compileHighlightPattern("[+*\\/%]|[=!]=|<=?|>=?|\\b(?:and|not|or)\\b")),
  GrammarToken("operator", compileHighlightPattern("(\\s)-(?=\\s)"),
      lookbehind: true),
]);

final Grammar _g4 = Grammar([
  GrammarToken("property", compileHighlightPattern("[^:\\s]+(?=\\s*:)")),
  GrammarToken("property", compileHighlightPattern("(:)[^:\\s]+"),
      lookbehind: true),
  GrammarToken("punctuation", compileHighlightPattern(":")),
  GrammarToken(
      "variable", compileHighlightPattern("\\\$[-\\w]+|#\\{\\\$[-\\w]+\\}")),
  GrammarToken("operator",
      compileHighlightPattern("[+*\\/%]|[=!]=|<=?|>=?|\\b(?:and|not|or)\\b")),
  GrammarToken("operator", compileHighlightPattern("(\\s)-(?=\\s)"),
      lookbehind: true),
  GrammarToken("important",
      compileHighlightPattern("!important\\b", caseSensitive: false)),
]);
