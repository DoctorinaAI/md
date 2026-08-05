// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `dart`.
///
/// Import this library only when you need `dart` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightDart {
  /// The grammar for `dart`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "string-literal",
      compileHighlightPattern(
          "r?(?:(\"\"\"|''')[\\s\\S]*?\\1|([\"'])(?:\\\\.|(?!\\2)[^\\\\\\r\\n])*\\2(?!\\2))"),
      greedy: true,
      inside: () => _g1),
  GrammarToken("metadata", compileHighlightPattern("@\\w+"), alias: "function"),
  GrammarToken(
      "generics",
      compileHighlightPattern(
          "<(?:[\\w\\s,.&?]|<(?:[\\w\\s,.&?]|<(?:[\\w\\s,.&?]|<[\\w\\s,.&?]*>)*>)*>)*>"),
      inside: () => _g3),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(^|[^\\w.])(?:[a-z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*\\s*\\.\\s*)*[A-Z](?:[\\d_A-Z]*[a-z]\\w*)?\\b"),
      lookbehind: true,
      inside: () => _g4),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(^|[^\\w.])(?:[a-z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*\\s*\\.\\s*)*[A-Z]\\w*(?=\\s+\\w+\\s*[;,=()])"),
      lookbehind: true,
      inside: () => _g4),
  GrammarToken(
      "keyword", compileHighlightPattern("\\b(?:async|sync|yield)\\*")),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:abstract|assert|async|await|break|case|catch|class|const|continue|covariant|default|deferred|do|dynamic|else|enum|export|extends|extension|external|factory|final|finally|for|get|hide|if|implements|import|in|interface|library|mixin|new|null|on|operator|part|rethrow|return|set|show|static|super|switch|sync|this|throw|try|typedef|var|void|while|with|yield)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("function", compileHighlightPattern("\\b\\w+(?=\\()")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0x[\\da-f]+\\b|(?:\\b\\d+(?:\\.\\d*)?|\\B\\.\\d+)(?:e[+-]?\\d+)?",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "\\bis!|\\b(?:as|is)\\b|\\+\\+|--|&&|\\|\\||<<=?|>>=?|~(?:\\/=?)?|[+\\-*\\/%&^|=!<>]=?|\\?")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\{2})*)\\\$(?:\\w+|\\{(?:[^{}]|\\{[^{}]*\\})*\\})"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g2 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("^\\\$\\{?|\\}\$")),
  GrammarToken("expression", compileHighlightPattern("[\\s\\S]+"),
      inside: () => _g0),
]);

final Grammar _g3 = Grammar([
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(^|[^\\w.])(?:[a-z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*\\s*\\.\\s*)*[A-Z](?:[\\d_A-Z]*[a-z]\\w*)?\\b"),
      lookbehind: true,
      inside: () => _g4),
  GrammarToken(
      "keyword", compileHighlightPattern("\\b(?:async|sync|yield)\\*")),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:abstract|assert|async|await|break|case|catch|class|const|continue|covariant|default|deferred|do|dynamic|else|enum|export|extends|extension|external|factory|final|finally|for|get|hide|if|implements|import|in|interface|library|mixin|new|null|on|operator|part|rethrow|return|set|show|static|super|switch|sync|this|throw|try|typedef|var|void|while|with|yield)\\b")),
  GrammarToken("punctuation", compileHighlightPattern("[<>(),.:]")),
  GrammarToken("operator", compileHighlightPattern("[?&|]")),
]);

final Grammar _g4 = Grammar([
  GrammarToken(
      "namespace",
      compileHighlightPattern(
          "^[a-z]\\w*(?:\\s*\\.\\s*[a-z]\\w*)*(?:\\s*\\.)?"),
      inside: () => _g5),
]);

final Grammar _g5 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);
