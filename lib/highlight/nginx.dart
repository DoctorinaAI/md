// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `nginx`.
///
/// Import this library only when you need `nginx` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightNginx {
  /// The grammar for `nginx`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("(^|[\\s{};])#.*"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "directive",
      compileHighlightPattern(
          "(^|\\s)\\w(?:[^;{}\"'\\\\\\s]|\\\\.|\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*'|\\s+(?:#.*(?!.)|(?![#\\s])))*?(?=\\s*[;{])"),
      lookbehind: true,
      greedy: true,
      inside: () => _g1),
  GrammarToken("punctuation", compileHighlightPattern("[{};]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "string",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\\\\\)*)(?:\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*')"),
      lookbehind: true,
      greedy: true,
      inside: () => _g2),
  GrammarToken("comment", compileHighlightPattern("(\\s)#.*"),
      lookbehind: true, greedy: true),
  GrammarToken("keyword", compileHighlightPattern("^\\S+"), greedy: true),
  GrammarToken("boolean", compileHighlightPattern("(\\s)(?:off|on)(?!\\S)"),
      lookbehind: true),
  GrammarToken("number",
      compileHighlightPattern("(\\s)\\d+[a-z]*(?!\\S)", caseSensitive: false),
      lookbehind: true),
  GrammarToken(
      "variable",
      compileHighlightPattern(
          "\\\$(?:\\w[a-z\\d]*(?:_[^\\x00-\\x1F\\s\"'\\\\()\$]*)?|\\{[^}\\s\"'\\\\]+\\})",
          caseSensitive: false)),
]);

final Grammar _g2 = Grammar([
  GrammarToken("escape", compileHighlightPattern("\\\\[\"'\\\\nrt]"),
      alias: "entity"),
  GrammarToken(
      "variable",
      compileHighlightPattern(
          "\\\$(?:\\w[a-z\\d]*(?:_[^\\x00-\\x1F\\s\"'\\\\()\$]*)?|\\{[^}\\s\"'\\\\]+\\})",
          caseSensitive: false)),
]);
