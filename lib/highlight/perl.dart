// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `perl`.
///
/// Import this library only when you need `perl` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightPerl {
  /// The grammar for `perl`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^\\s*)=\\w[\\s\\S]*?=cut.*", multiLine: true),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\\$])#.*"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\\b(?:q|qq|qw|qx)(?![a-zA-Z0-9])\\s*(?:([^a-zA-Z0-9\\s{(\\[<])(?:(?!\\1)[^\\\\]|\\\\[\\s\\S])*\\1|([a-zA-Z0-9])(?:(?!\\2)[^\\\\]|\\\\[\\s\\S])*\\2|(?:\\((?:[^()\\\\]|\\\\[\\s\\S])*\\)|\\{(?:[^{}\\\\]|\\\\[\\s\\S])*\\}|\\[(?:[^[\\]\\\\]|\\\\[\\s\\S])*\\]|<(?:[^<>\\\\]|\\\\[\\s\\S])*>))"),
      greedy: true),
  GrammarToken("string",
      compileHighlightPattern("(\"|`)(?:(?!\\1)[^\\\\]|\\\\[\\s\\S])*\\1"),
      greedy: true),
  GrammarToken("string", compileHighlightPattern("'(?:[^'\\\\\\r\\n]|\\\\.)*'"),
      greedy: true),
  GrammarToken(
      "regex",
      compileHighlightPattern(
          "\\b(?:m|qr)(?![a-zA-Z0-9])\\s*(?:([^a-zA-Z0-9\\s{(\\[<])(?:(?!\\1)[^\\\\]|\\\\[\\s\\S])*\\1|([a-zA-Z0-9])(?:(?!\\2)[^\\\\]|\\\\[\\s\\S])*\\2|(?:\\((?:[^()\\\\]|\\\\[\\s\\S])*\\)|\\{(?:[^{}\\\\]|\\\\[\\s\\S])*\\}|\\[(?:[^[\\]\\\\]|\\\\[\\s\\S])*\\]|<(?:[^<>\\\\]|\\\\[\\s\\S])*>))[msixpodualngc]*"),
      greedy: true),
  GrammarToken(
      "regex",
      compileHighlightPattern(
          "(^|[^-])\\b(?:s|tr|y)(?![a-zA-Z0-9])\\s*(?:([^a-zA-Z0-9\\s{(\\[<])(?:(?!\\2)[^\\\\]|\\\\[\\s\\S])*\\2(?:(?!\\2)[^\\\\]|\\\\[\\s\\S])*\\2|([a-zA-Z0-9])(?:(?!\\3)[^\\\\]|\\\\[\\s\\S])*\\3(?:(?!\\3)[^\\\\]|\\\\[\\s\\S])*\\3|(?:\\((?:[^()\\\\]|\\\\[\\s\\S])*\\)|\\{(?:[^{}\\\\]|\\\\[\\s\\S])*\\}|\\[(?:[^[\\]\\\\]|\\\\[\\s\\S])*\\]|<(?:[^<>\\\\]|\\\\[\\s\\S])*>)\\s*(?:\\((?:[^()\\\\]|\\\\[\\s\\S])*\\)|\\{(?:[^{}\\\\]|\\\\[\\s\\S])*\\}|\\[(?:[^[\\]\\\\]|\\\\[\\s\\S])*\\]|<(?:[^<>\\\\]|\\\\[\\s\\S])*>))[msixpodualngcer]*"),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "regex",
      compileHighlightPattern(
          "\\/(?:[^\\/\\\\\\r\\n]|\\\\.)*\\/[msixpodualngc]*(?=\\s*(?:\$|[\\r\\n,.;})&|\\-+*~<>!?^]|(?:and|cmp|eq|ge|gt|le|lt|ne|not|or|x|xor)\\b))"),
      greedy: true),
  GrammarToken("variable", compileHighlightPattern("[&*\$@%]\\{\\^[A-Z]+\\}")),
  GrammarToken("variable", compileHighlightPattern("[&*\$@%]\\^[A-Z_]")),
  GrammarToken("variable", compileHighlightPattern("[&*\$@%]#?(?=\\{)")),
  GrammarToken(
      "variable",
      compileHighlightPattern(
          "[&*\$@%]#?(?:(?:::)*'?(?!\\d)[\\w\$]+(?![\\w\$]))+(?:::)*")),
  GrammarToken("variable", compileHighlightPattern("[&*\$@%]\\d+")),
  GrammarToken(
      "variable",
      compileHighlightPattern(
          "(?!%=)[\$@%][!\"#\$%&'()*+,\\-.\\/:;<=>?@[\\\\\\]^_`{|}~]")),
  GrammarToken("filehandle", compileHighlightPattern("<(?![<=])\\S*?>|\\b_\\b"),
      alias: "symbol"),
  GrammarToken("v-string",
      compileHighlightPattern("v\\d+(?:\\.\\d+)*|\\d+(?:\\.\\d+){2,}"),
      alias: "string"),
  GrammarToken("function", compileHighlightPattern("(\\bsub[ \\t]+)\\w+"),
      lookbehind: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:any|break|continue|default|delete|die|do|else|elsif|eval|for|foreach|given|goto|if|last|local|my|next|our|package|print|redo|require|return|say|state|sub|switch|undef|unless|until|use|when|while)\\b")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b(?:0x[\\dA-Fa-f](?:_?[\\dA-Fa-f])*|0b[01](?:_?[01])*|(?:(?:\\d(?:_?\\d)*)?\\.)?\\d(?:_?\\d)*(?:[Ee][+-]?\\d+)?)\\b")),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "-[rwxoRWXOezsfdlpSbctugkTBMAC]\\b|\\+[+=]?|-[-=>]?|\\*\\*?=?|\\/\\/?=?|=[=~>]?|~[~=]?|\\|\\|?=?|&&?=?|<(?:=>?|<=?)?|>>?=?|![~=]?|[%^]=?|\\.(?:=|\\.\\.?)?|[\\\\?]|\\bx(?:=|\\b)|\\b(?:and|cmp|eq|ge|gt|le|lt|ne|not|or|xor)\\b")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),:]")),
]);
