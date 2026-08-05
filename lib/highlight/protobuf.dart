// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `protobuf`.
///
/// Import this library only when you need `protobuf` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightProtobuf {
  /// The grammar for `protobuf`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "([\"'])(?:\\\\(?:\\r\\n|[\\s\\S])|(?!\\1)[^\\\\\\r\\n])*\\1"),
      greedy: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:enum|extend|message|service)\\s+)[A-Za-z_]\\w*(?=\\s*\\{)"),
      lookbehind: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:rpc\\s+\\w+|returns)\\s*\\(\\s*(?:stream\\s+)?)\\.?[A-Za-z_]\\w*(?:\\.[A-Za-z_]\\w*)*(?=\\s*\\))"),
      lookbehind: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:enum|extend|extensions|import|message|oneof|option|optional|package|public|repeated|required|reserved|returns|rpc(?=\\s+\\w)|service|stream|syntax|to)\\b(?!\\s*=\\s*\\d)")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken(
      "function",
      compileHighlightPattern("\\b[a-z_]\\w*(?=\\s*\\()",
          caseSensitive: false)),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0x[\\da-f]+\\b|(?:\\b\\d+(?:\\.\\d*)?|\\B\\.\\d+)(?:e[+-]?\\d+)?",
          caseSensitive: false)),
  GrammarToken(
      "map",
      compileHighlightPattern(
          "\\bmap<\\s*[\\w.]+\\s*,\\s*[\\w.]+\\s*>(?=\\s+[a-z_]\\w*\\s*[=;])",
          caseSensitive: false),
      alias: "class-name",
      inside: () => _g1),
  GrammarToken(
      "builtin",
      compileHighlightPattern(
          "\\b(?:bool|bytes|double|s?fixed(?:32|64)|float|[su]?int(?:32|64)|string)\\b")),
  GrammarToken(
      "positional-class-name",
      compileHighlightPattern(
          "(?:\\b|\\B\\.)[a-z_]\\w*(?:\\.[a-z_]\\w*)*(?=\\s+[a-z_]\\w*\\s*[=;])",
          caseSensitive: false),
      alias: "class-name",
      inside: () => _g2),
  GrammarToken(
      "annotation",
      compileHighlightPattern("(\\[\\s*)[a-z_]\\w*(?=\\s*=)",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "[<>]=?|[!=]=?=?|--?|\\+\\+?|&&?|\\|\\|?|[?*/~^%]")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("[<>.,]")),
  GrammarToken(
      "builtin",
      compileHighlightPattern(
          "\\b(?:bool|bytes|double|s?fixed(?:32|64)|float|[su]?int(?:32|64)|string)\\b")),
]);

final Grammar _g2 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);
