// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `yaml`.
///
/// Import this library only when you need `yaml` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightYaml {
  /// The grammar for `yaml`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "scalar",
      compileHighlightPattern(
          "([\\-:]\\s*(?:\\s(?:!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?(?:[ \t]+[*&][^\\s[\\]{},]+)?|[*&][^\\s[\\]{},]+(?:[ \t]+!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?)?)[ \\t]+)?[|>])[ \\t]*(?:((?:\\r?\\n|\\r)[ \\t]+)\\S[^\\r\\n]*(?:\\2[^\\r\\n]+)*)"),
      lookbehind: true,
      alias: "string"),
  GrammarToken("comment", compileHighlightPattern("#.*")),
  GrammarToken(
      "key",
      compileHighlightPattern(
          "((?:^|[:\\-,[{\\r\\n?])[ \\t]*(?:(?:!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?(?:[ \t]+[*&][^\\s[\\]{},]+)?|[*&][^\\s[\\]{},]+(?:[ \t]+!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?)?)[ \\t]+)?)(?:(?:[^\\s\\x00-\\x08\\x0e-\\x1f!\"#%&'*,\\-:>?@[\\]`{|}\\x7f-\\x84\\x86-\\x9f\\ud800-\\udfff\\ufffe\\uffff]|[?:-][^\\s\\x00-\\x08\\x0e-\\x1f,[\\]{}\\x7f-\\x84\\x86-\\x9f\\ud800-\\udfff\\ufffe\\uffff])(?:[ \\t]*(?:(?![#:])[^\\s\\x00-\\x08\\x0e-\\x1f,[\\]{}\\x7f-\\x84\\x86-\\x9f\\ud800-\\udfff\\ufffe\\uffff]|:[^\\s\\x00-\\x08\\x0e-\\x1f,[\\]{}\\x7f-\\x84\\x86-\\x9f\\ud800-\\udfff\\ufffe\\uffff]))*|\"(?:[^\"\\\\\\r\\n]|\\\\.)*\"|'(?:[^'\\\\\\r\\n]|\\\\.)*')(?=\\s*:\\s)"),
      lookbehind: true,
      greedy: true,
      alias: "atrule"),
  GrammarToken(
      "directive", compileHighlightPattern("(^[ \\t]*)%.+", multiLine: true),
      lookbehind: true, alias: "important"),
  GrammarToken(
      "datetime",
      compileHighlightPattern(
          "([:\\-,[{]\\s*(?:\\s(?:!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?(?:[ \t]+[*&][^\\s[\\]{},]+)?|[*&][^\\s[\\]{},]+(?:[ \t]+!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?)?)[ \\t]+)?)(?:\\d{4}-\\d\\d?-\\d\\d?(?:[tT]|[ \\t]+)\\d\\d?:\\d{2}:\\d{2}(?:\\.\\d*)?(?:[ \\t]*(?:Z|[-+]\\d\\d?(?::\\d{2})?))?|\\d{4}-\\d{2}-\\d{2}|\\d\\d?:\\d{2}(?::\\d{2}(?:\\.\\d*)?)?)(?=[ \\t]*(?:\$|,|\\]|\\}|(?:[\\r\\n]\\s*)?#))",
          multiLine: true),
      lookbehind: true,
      alias: "number"),
  GrammarToken(
      "boolean",
      compileHighlightPattern(
          "([:\\-,[{]\\s*(?:\\s(?:!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?(?:[ \t]+[*&][^\\s[\\]{},]+)?|[*&][^\\s[\\]{},]+(?:[ \t]+!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?)?)[ \\t]+)?)(?:false|true)(?=[ \\t]*(?:\$|,|\\]|\\}|(?:[\\r\\n]\\s*)?#))",
          caseSensitive: false,
          multiLine: true),
      lookbehind: true,
      alias: "important"),
  GrammarToken(
      "null",
      compileHighlightPattern(
          "([:\\-,[{]\\s*(?:\\s(?:!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?(?:[ \t]+[*&][^\\s[\\]{},]+)?|[*&][^\\s[\\]{},]+(?:[ \t]+!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?)?)[ \\t]+)?)(?:null|~)(?=[ \\t]*(?:\$|,|\\]|\\}|(?:[\\r\\n]\\s*)?#))",
          caseSensitive: false,
          multiLine: true),
      lookbehind: true,
      alias: "important"),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "([:\\-,[{]\\s*(?:\\s(?:!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?(?:[ \t]+[*&][^\\s[\\]{},]+)?|[*&][^\\s[\\]{},]+(?:[ \t]+!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?)?)[ \\t]+)?)(?:\"(?:[^\"\\\\\\r\\n]|\\\\.)*\"|'(?:[^'\\\\\\r\\n]|\\\\.)*')(?=[ \\t]*(?:\$|,|\\]|\\}|(?:[\\r\\n]\\s*)?#))",
          multiLine: true),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "([:\\-,[{]\\s*(?:\\s(?:!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?(?:[ \t]+[*&][^\\s[\\]{},]+)?|[*&][^\\s[\\]{},]+(?:[ \t]+!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?)?)[ \\t]+)?)(?:[+-]?(?:0x[\\da-f]+|0o[0-7]+|(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:e[+-]?\\d+)?|\\.inf|\\.nan))(?=[ \\t]*(?:\$|,|\\]|\\}|(?:[\\r\\n]\\s*)?#))",
          caseSensitive: false,
          multiLine: true),
      lookbehind: true),
  GrammarToken(
      "tag",
      compileHighlightPattern(
          "!(?:<[\\w\\-%#;/?:@&=+\$,.!~*'()[\\]]+>|(?:[a-zA-Z\\d-]*!)?[\\w\\-%#;/?:@&=+\$.~*'()]+)?")),
  GrammarToken("important", compileHighlightPattern("[*&][^\\s[\\]{},]+")),
  GrammarToken(
      "punctuation", compileHighlightPattern("---|[:[\\]{}\\-,|>?]|\\.\\.\\.")),
]);
