// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `ruby`.
///
/// Import this library only when you need `ruby` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightRuby {
  /// The grammar for `ruby`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("#.*|^=begin\\s[\\s\\S]*?^=end", multiLine: true),
      greedy: true),
  GrammarToken(
      "string-literal",
      compileHighlightPattern(
          "%[qQiIwWs]?(?:([^a-zA-Z0-9\\s{(\\[<=])(?:(?!\\1)[^\\\\]|\\\\[\\s\\S])*\\1|\\((?:[^()\\\\]|\\\\[\\s\\S]|\\((?:[^()\\\\]|\\\\[\\s\\S])*\\))*\\)|\\{(?:[^{}\\\\]|\\\\[\\s\\S]|\\{(?:[^{}\\\\]|\\\\[\\s\\S])*\\})*\\}|\\[(?:[^\\[\\]\\\\]|\\\\[\\s\\S]|\\[(?:[^\\[\\]\\\\]|\\\\[\\s\\S])*\\])*\\]|<(?:[^<>\\\\]|\\\\[\\s\\S]|<(?:[^<>\\\\]|\\\\[\\s\\S])*>)*>)"),
      greedy: true,
      inside: () => _g1),
  GrammarToken(
      "string-literal",
      compileHighlightPattern(
          "(\"|')(?:#\\{[^}]+\\}|#(?!\\{)|\\\\(?:\\r\\n|[\\s\\S])|(?!\\1)[^\\\\#\\r\\n])*\\1"),
      greedy: true,
      inside: () => _g3),
  GrammarToken(
      "string-literal",
      compileHighlightPattern(
          "<<[-~]?([a-z_]\\w*)[\\r\\n](?:.*[\\r\\n])*?[\\t ]*\\1",
          caseSensitive: false),
      greedy: true,
      alias: "heredoc-string",
      inside: () => _g4),
  GrammarToken(
      "string-literal",
      compileHighlightPattern(
          "<<[-~]?'([a-z_]\\w*)'[\\r\\n](?:.*[\\r\\n])*?[\\t ]*\\1",
          caseSensitive: false),
      greedy: true,
      alias: "heredoc-string",
      inside: () => _g6),
  GrammarToken(
      "command-literal",
      compileHighlightPattern(
          "%x(?:([^a-zA-Z0-9\\s{(\\[<=])(?:(?!\\1)[^\\\\]|\\\\[\\s\\S])*\\1|\\((?:[^()\\\\]|\\\\[\\s\\S]|\\((?:[^()\\\\]|\\\\[\\s\\S])*\\))*\\)|\\{(?:[^{}\\\\]|\\\\[\\s\\S]|\\{(?:[^{}\\\\]|\\\\[\\s\\S])*\\})*\\}|\\[(?:[^\\[\\]\\\\]|\\\\[\\s\\S]|\\[(?:[^\\[\\]\\\\]|\\\\[\\s\\S])*\\])*\\]|<(?:[^<>\\\\]|\\\\[\\s\\S]|<(?:[^<>\\\\]|\\\\[\\s\\S])*>)*>)"),
      greedy: true,
      inside: () => _g8),
  GrammarToken(
      "command-literal",
      compileHighlightPattern(
          "`(?:#\\{[^}]+\\}|#(?!\\{)|\\\\(?:\\r\\n|[\\s\\S])|[^\\\\`#\\r\\n])*`"),
      greedy: true,
      inside: () => _g9),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:class|module)\\s+|\\bcatch\\s+\\()[\\w.\\\\]+|\\b[A-Z_]\\w*(?=\\s*\\.\\s*new\\b)"),
      lookbehind: true,
      inside: () => _g10),
  GrammarToken(
      "regex-literal",
      compileHighlightPattern(
          "%r(?:([^a-zA-Z0-9\\s{(\\[<=])(?:(?!\\1)[^\\\\]|\\\\[\\s\\S])*\\1|\\((?:[^()\\\\]|\\\\[\\s\\S]|\\((?:[^()\\\\]|\\\\[\\s\\S])*\\))*\\)|\\{(?:[^{}\\\\]|\\\\[\\s\\S]|\\{(?:[^{}\\\\]|\\\\[\\s\\S])*\\})*\\}|\\[(?:[^\\[\\]\\\\]|\\\\[\\s\\S]|\\[(?:[^\\[\\]\\\\]|\\\\[\\s\\S])*\\])*\\]|<(?:[^<>\\\\]|\\\\[\\s\\S]|<(?:[^<>\\\\]|\\\\[\\s\\S])*>)*>)[egimnosux]{0,6}"),
      greedy: true,
      inside: () => _g11),
  GrammarToken(
      "regex-literal",
      compileHighlightPattern(
          "(^|[^/])\\/(?!\\/)(?:\\[[^\\r\\n\\]]+\\]|\\\\.|[^[/\\\\\\r\\n])+\\/[egimnosux]{0,6}(?=\\s*(?:\$|[\\r\\n,.;})#]))"),
      lookbehind: true,
      greedy: true,
      inside: () => _g12),
  GrammarToken(
      "variable", compileHighlightPattern("[@\$]+[a-zA-Z_]\\w*(?:[?!]|\\b)")),
  GrammarToken(
      "symbol",
      compileHighlightPattern(
          "(^|[^:]):(?:\"(?:\\\\.|[^\"\\\\\\r\\n])*\"|(?:\\b[a-zA-Z_]\\w*|[^\\s\\0-\\x7F]+)[?!]?|\\\$.)"),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "symbol",
      compileHighlightPattern(
          "([\\r\\n{(,][ \\t]*)(?:\"(?:\\\\.|[^\"\\\\\\r\\n])*\"|(?:\\b[a-zA-Z_]\\w*|[^\\s\\0-\\x7F]+)[?!]?|\\\$.)(?=:(?!:))"),
      lookbehind: true,
      greedy: true),
  GrammarToken("method-definition",
      compileHighlightPattern("(\\bdef\\s+)\\w+(?:\\s*\\.\\s*\\w+)?"),
      lookbehind: true, inside: () => _g13),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:BEGIN|END|alias|and|begin|break|case|class|def|define_method|defined|do|each|else|elsif|end|ensure|extend|for|if|in|include|module|new|next|nil|not|or|prepend|private|protected|public|raise|redo|require|rescue|retry|return|self|super|then|throw|undef|unless|until|when|while|yield)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken(
      "builtin",
      compileHighlightPattern(
          "\\b(?:Array|Bignum|Binding|Class|Continuation|Dir|Exception|FalseClass|File|Fixnum|Float|Hash|IO|Integer|MatchData|Method|Module|NilClass|Numeric|Object|Proc|Range|Regexp|Stat|String|Struct|Symbol|TMS|Thread|ThreadGroup|Time|TrueClass)\\b")),
  GrammarToken(
      "constant", compileHighlightPattern("\\b[A-Z][A-Z0-9_]*(?:[?!]|\\b)")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0x[\\da-f]+\\b|(?:\\b\\d+(?:\\.\\d*)?|\\B\\.\\d+)(?:e[+-]?\\d+)?",
          caseSensitive: false)),
  GrammarToken("double-colon", compileHighlightPattern("::"),
      alias: "punctuation"),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "\\.{2,3}|&\\.|===|<?=>|[!=]?~|(?:&&|\\|\\||<<|>>|\\*\\*|[+\\-*/%<>!^&|=])=?|[?:]")),
  GrammarToken("punctuation", compileHighlightPattern("[(){}[\\].,;]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\{2})*)#\\{(?:[^{}]|\\{[^{}]*\\})*\\}"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g2 = Grammar([
  GrammarToken("content", compileHighlightPattern("^(#\\{)[\\s\\S]+(?=\\}\$)"),
      lookbehind: true, inside: () => _g0),
  GrammarToken("delimiter", compileHighlightPattern("^#\\{|\\}\$"),
      alias: "punctuation"),
]);

final Grammar _g3 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\{2})*)#\\{(?:[^{}]|\\{[^{}]*\\})*\\}"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g4 = Grammar([
  GrammarToken(
      "delimiter",
      compileHighlightPattern("^<<[-~]?[a-z_]\\w*|\\b[a-z_]\\w*\$",
          caseSensitive: false),
      inside: () => _g5),
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\{2})*)#\\{(?:[^{}]|\\{[^{}]*\\})*\\}"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g5 = Grammar([
  GrammarToken("symbol", compileHighlightPattern("\\b\\w+")),
  GrammarToken("punctuation", compileHighlightPattern("^<<[-~]?")),
]);

final Grammar _g6 = Grammar([
  GrammarToken(
      "delimiter",
      compileHighlightPattern("^<<[-~]?'[a-z_]\\w*'|\\b[a-z_]\\w*\$",
          caseSensitive: false),
      inside: () => _g7),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g7 = Grammar([
  GrammarToken("symbol", compileHighlightPattern("\\b\\w+")),
  GrammarToken("punctuation", compileHighlightPattern("^<<[-~]?'|'\$")),
]);

final Grammar _g8 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\{2})*)#\\{(?:[^{}]|\\{[^{}]*\\})*\\}"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken("command", compileHighlightPattern("[\\s\\S]+"),
      alias: "string"),
]);

final Grammar _g9 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\{2})*)#\\{(?:[^{}]|\\{[^{}]*\\})*\\}"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken("command", compileHighlightPattern("[\\s\\S]+"),
      alias: "string"),
]);

final Grammar _g10 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("[.\\\\]")),
]);

final Grammar _g11 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\{2})*)#\\{(?:[^{}]|\\{[^{}]*\\})*\\}"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken("regex", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g12 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\{2})*)#\\{(?:[^{}]|\\{[^{}]*\\})*\\}"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken("regex", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g13 = Grammar([
  GrammarToken("function", compileHighlightPattern("\\b\\w+\$")),
  GrammarToken("keyword", compileHighlightPattern("^self\\b")),
  GrammarToken("class-name", compileHighlightPattern("^\\w+")),
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);
