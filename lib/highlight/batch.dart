// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `batch`.
///
/// Import this library only when you need `batch` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightBatch {
  /// The grammar for `batch`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("^::.*", multiLine: true)),
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "((?:^|[&(])[ \\t]*)rem\\b(?:[^^&)\\r\\n]|\\^(?:\\r\\n|[\\s\\S]))*",
          caseSensitive: false,
          multiLine: true),
      lookbehind: true),
  GrammarToken("label", compileHighlightPattern("^:.*", multiLine: true),
      alias: "property"),
  GrammarToken(
      "command",
      compileHighlightPattern(
          "((?:^|[&(])[ \\t]*)for(?: \\/[a-z?](?:[ :](?:\"[^\"]*\"|[^\\s\"/]\\S*))?)* \\S+ in \\([^)]+\\) do",
          caseSensitive: false,
          multiLine: true),
      lookbehind: true,
      inside: () => _g1),
  GrammarToken(
      "command",
      compileHighlightPattern(
          "((?:^|[&(])[ \\t]*)if(?: \\/[a-z?](?:[ :](?:\"[^\"]*\"|[^\\s\"/]\\S*))?)* (?:not )?(?:cmdextversion \\d+|defined \\w+|errorlevel \\d+|exist \\S+|(?:\"[^\"]*\"|(?!\")(?:(?!==)\\S)+)?(?:==| (?:equ|geq|gtr|leq|lss|neq) )(?:\"[^\"]*\"|[^\\s\"]\\S*))",
          caseSensitive: false,
          multiLine: true),
      lookbehind: true,
      inside: () => _g3),
  GrammarToken(
      "command",
      compileHighlightPattern("((?:^|[&()])[ \\t]*)else\\b",
          caseSensitive: false, multiLine: true),
      lookbehind: true,
      inside: () => _g4),
  GrammarToken(
      "command",
      compileHighlightPattern(
          "((?:^|[&(])[ \\t]*)set(?: \\/[a-z](?:[ :](?:\"[^\"]*\"|[^\\s\"/]\\S*))?)* (?:[^^&)\\r\\n]|\\^(?:\\r\\n|[\\s\\S]))*",
          caseSensitive: false,
          multiLine: true),
      lookbehind: true,
      inside: () => _g5),
  GrammarToken(
      "command",
      compileHighlightPattern(
          "((?:^|[&(])[ \\t]*@?)\\w+\\b(?:\"(?:[\\\\\"]\"|[^\"])*\"(?!\")|[^\"^&)\\r\\n]|\\^(?:\\r\\n|[\\s\\S]))*",
          multiLine: true),
      lookbehind: true,
      inside: () => _g6),
  GrammarToken("operator", compileHighlightPattern("[&@]")),
  GrammarToken("punctuation", compileHighlightPattern("[()']")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("keyword",
      compileHighlightPattern("\\b(?:do|in)\\b|^for\\b", caseSensitive: false)),
  GrammarToken(
      "string", compileHighlightPattern("\"(?:[\\\\\"]\"|[^\"])*\"(?!\")")),
  GrammarToken(
      "parameter",
      compileHighlightPattern("\\/[a-z?]+(?=[ :]|\$):?|-[a-z]\\b|--[a-z-]+\\b",
          caseSensitive: false, multiLine: true),
      alias: "attr-name",
      inside: () => _g2),
  GrammarToken("variable", compileHighlightPattern("%%?[~:\\w]+%?|!\\S+!")),
  GrammarToken("number", compileHighlightPattern("(?:\\b|-)\\d+\\b")),
  GrammarToken("punctuation", compileHighlightPattern("[()',]")),
]);

final Grammar _g2 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern(":")),
]);

final Grammar _g3 = Grammar([
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:cmdextversion|defined|errorlevel|exist|not)\\b|^if\\b",
          caseSensitive: false)),
  GrammarToken(
      "string", compileHighlightPattern("\"(?:[\\\\\"]\"|[^\"])*\"(?!\")")),
  GrammarToken(
      "parameter",
      compileHighlightPattern("\\/[a-z?]+(?=[ :]|\$):?|-[a-z]\\b|--[a-z-]+\\b",
          caseSensitive: false, multiLine: true),
      alias: "attr-name",
      inside: () => _g2),
  GrammarToken("variable", compileHighlightPattern("%%?[~:\\w]+%?|!\\S+!")),
  GrammarToken("number", compileHighlightPattern("(?:\\b|-)\\d+\\b")),
  GrammarToken(
      "operator",
      compileHighlightPattern("\\^|==|\\b(?:equ|geq|gtr|leq|lss|neq)\\b",
          caseSensitive: false)),
]);

final Grammar _g4 = Grammar([
  GrammarToken(
      "keyword", compileHighlightPattern("^else\\b", caseSensitive: false)),
]);

final Grammar _g5 = Grammar([
  GrammarToken(
      "keyword", compileHighlightPattern("^set\\b", caseSensitive: false)),
  GrammarToken(
      "string", compileHighlightPattern("\"(?:[\\\\\"]\"|[^\"])*\"(?!\")")),
  GrammarToken(
      "parameter",
      compileHighlightPattern("\\/[a-z?]+(?=[ :]|\$):?|-[a-z]\\b|--[a-z-]+\\b",
          caseSensitive: false, multiLine: true),
      alias: "attr-name",
      inside: () => _g2),
  GrammarToken("variable", compileHighlightPattern("%%?[~:\\w]+%?|!\\S+!")),
  GrammarToken("variable",
      compileHighlightPattern("\\w+(?=(?:[*\\/%+\\-&^|]|<<|>>)?=)")),
  GrammarToken("number", compileHighlightPattern("(?:\\b|-)\\d+\\b")),
  GrammarToken(
      "operator", compileHighlightPattern("[*\\/%+\\-&^|]=?|<<=?|>>=?|[!~_=]")),
  GrammarToken("punctuation", compileHighlightPattern("[()',]")),
]);

final Grammar _g6 = Grammar([
  GrammarToken("keyword", compileHighlightPattern("^\\w+\\b")),
  GrammarToken(
      "string", compileHighlightPattern("\"(?:[\\\\\"]\"|[^\"])*\"(?!\")")),
  GrammarToken(
      "parameter",
      compileHighlightPattern("\\/[a-z?]+(?=[ :]|\$):?|-[a-z]\\b|--[a-z-]+\\b",
          caseSensitive: false, multiLine: true),
      alias: "attr-name",
      inside: () => _g2),
  GrammarToken(
      "label", compileHighlightPattern("(^\\s*):\\S+", multiLine: true),
      lookbehind: true, alias: "property"),
  GrammarToken("variable", compileHighlightPattern("%%?[~:\\w]+%?|!\\S+!")),
  GrammarToken("number", compileHighlightPattern("(?:\\b|-)\\d+\\b")),
  GrammarToken("operator", compileHighlightPattern("\\^")),
]);
