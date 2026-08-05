// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `lua`.
///
/// Import this library only when you need `lua` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightLua {
  /// The grammar for `lua`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "comment",
      compileHighlightPattern("^#!.+|--(?:\\[(=*)\\[[\\s\\S]*?\\]\\1\\]|.*)",
          multiLine: true)),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "([\"'])(?:(?!\\1)[^\\\\\\r\\n]|\\\\z(?:\\r\\n|\\s)|\\\\(?:\\r\\n|[^z]))*\\1|\\[(=*)\\[[\\s\\S]*?\\]\\2\\]"),
      greedy: true),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0x[a-f\\d]+(?:\\.[a-f\\d]*)?(?:p[+-]?\\d+)?\\b|\\b\\d+(?:\\.\\B|(?:\\.\\d*)?(?:e[+-]?\\d+)?\\b)|\\B\\.\\d+(?:e[+-]?\\d+)?\\b",
          caseSensitive: false)),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:and|break|do|else|elseif|end|false|for|function|goto|if|in|local|nil|not|or|repeat|return|then|true|until|while)\\b")),
  GrammarToken(
      "function", compileHighlightPattern("(?!\\d)\\w+(?=\\s*(?:[({]))")),
  GrammarToken("operator",
      compileHighlightPattern("[-+*%^&|#]|\\/\\/?|<[<=]?|>[>=]?|[=~]=?")),
  GrammarToken("operator", compileHighlightPattern("(^|[^.])\\.\\.(?!\\.)"),
      lookbehind: true),
  GrammarToken(
      "punctuation", compileHighlightPattern("[\\[\\](){},;]|\\.+|:+")),
]);
