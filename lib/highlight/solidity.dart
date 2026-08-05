// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `solidity`.
///
/// Import this library only when you need `solidity` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightSolidity {
  /// The grammar for `solidity`.
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
          "(\\b(?:contract|enum|interface|library|new|struct|using)\\s+)(?!\\d)[\\w\$]+"),
      lookbehind: true),
  GrammarToken(
      "builtin",
      compileHighlightPattern(
          "\\b(?:address|bool|byte|u?int(?:8|16|24|32|40|48|56|64|72|80|88|96|104|112|120|128|136|144|152|160|168|176|184|192|200|208|216|224|232|240|248|256)?|string|bytes(?:[1-9]|[12]\\d|3[0-2])?)\\b")),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:_|anonymous|as|assembly|assert|break|calldata|case|constant|constructor|continue|contract|default|delete|do|else|emit|enum|event|external|for|from|function|if|import|indexed|inherited|interface|internal|is|let|library|mapping|memory|modifier|new|payable|pragma|private|public|pure|require|returns?|revert|selfdestruct|solidity|storage|struct|suicide|switch|this|throw|using|var|view|while)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("function", compileHighlightPattern("\\b\\w+(?=\\()")),
  GrammarToken(
      "version", compileHighlightPattern("([<>]=?|\\^)\\d+\\.\\d+\\.\\d+\\b"),
      lookbehind: true, alias: "number"),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0x[\\da-f]+\\b|(?:\\b\\d+(?:\\.\\d*)?|\\B\\.\\d+)(?:e[+-]?\\d+)?",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "=>|->|:=|=:|\\*\\*|\\+\\+|--|\\|\\||&&|<<=?|>>=?|[-+*/%^&|<>!=]=?|[~?]")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
]);
