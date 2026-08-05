// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `c`.
///
/// Import this library only when you need `c` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightC {
  /// The grammar for `c`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "\\/\\/(?:[^\\r\\n\\\\]|\\\\(?:\\r\\n?|\\n|(?![\\r\\n])))*|\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      greedy: true),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n]){0,32}'"),
      greedy: true),
  GrammarToken(
      "macro",
      compileHighlightPattern(
          "(^[\\t ]*)#\\s*[a-z](?:[^\\r\\n\\\\/]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|\\\\(?:\\r\\n|[\\s\\S]))*",
          caseSensitive: false,
          multiLine: true),
      lookbehind: true,
      greedy: true,
      alias: "property",
      inside: () => _g1),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\""),
      greedy: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:enum|struct)\\s+(?:__attribute__\\s*\\(\\([\\s\\S]*?\\)\\)\\s*)?)\\w+|\\b[a-z]\\w*_t\\b"),
      lookbehind: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:_Alignas|_Alignof|_Atomic|_Bool|_Complex|_Generic|_Imaginary|_Noreturn|_Static_assert|_Thread_local|__attribute__|asm|auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto|if|inline|int|long|register|return|short|signed|sizeof|static|struct|switch|typedef|typeof|union|unsigned|void|volatile|while)\\b")),
  GrammarToken(
      "constant",
      compileHighlightPattern(
          "\\b(?:EOF|NULL|SEEK_CUR|SEEK_END|SEEK_SET|__DATE__|__FILE__|__LINE__|__TIMESTAMP__|__TIME__|__func__|stderr|stdin|stdout)\\b")),
  GrammarToken(
      "function",
      compileHighlightPattern("\\b[a-z_]\\w*(?=\\s*\\()",
          caseSensitive: false)),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "(?:\\b0x(?:[\\da-f]+(?:\\.[\\da-f]*)?|\\.[\\da-f]+)(?:p[+-]?\\d+)?|(?:\\b\\d+(?:\\.\\d*)?|\\B\\.\\d+)(?:e[+-]?\\d+)?)[ful]{0,4}",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          ">>=?|<<=?|->|([-+&|:])\\1|[?:~]|[-+*/%&|^!=<>]=?")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("string", compileHighlightPattern("^(#\\s*include\\s*)<[^>]+>"),
      lookbehind: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\""),
      greedy: true),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n]){0,32}'"),
      greedy: true),
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "\\/\\/(?:[^\\r\\n\\\\]|\\\\(?:\\r\\n?|\\n|(?![\\r\\n])))*|\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      greedy: true),
  GrammarToken(
      "macro-name",
      compileHighlightPattern("(^#\\s*define\\s+)\\w+\\b(?!\\()",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken(
      "macro-name",
      compileHighlightPattern("(^#\\s*define\\s+)\\w+\\b(?=\\()",
          caseSensitive: false),
      lookbehind: true,
      alias: "function"),
  GrammarToken("directive", compileHighlightPattern("^(#\\s*)[a-z]+"),
      lookbehind: true, alias: "keyword"),
  GrammarToken("directive-hash", compileHighlightPattern("^#")),
  GrammarToken("punctuation", compileHighlightPattern("##|\\\\(?=[\\r\\n])")),
  GrammarToken("expression", compileHighlightPattern("\\S[\\s\\S]*"),
      inside: () => _g0),
]);
