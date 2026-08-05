// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';
import 'js.dart';

/// Syntax grammar for `coffeescript`.
///
/// Import this library only when you need `coffeescript` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightCoffeescript {
  /// The grammar for `coffeescript`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("multiline-comment", compileHighlightPattern("###[\\s\\S]+?###"),
      alias: "comment"),
  GrammarToken("block-regex", compileHighlightPattern("\\/{3}[\\s\\S]*?\\/{3}"),
      alias: "regex", inside: () => _g1),
  GrammarToken("comment", compileHighlightPattern("#(?!\\{).+")),
  GrammarToken("hashbang", compileHighlightPattern("^#!.*"),
      greedy: true, alias: "comment"),
  GrammarToken(
      "string-property",
      compileHighlightPattern(
          "((?:^|[,{])[ \\t]*)([\"'])(?:\\\\(?:\\r\\n|[\\s\\S])|(?!\\2)[^\\\\\\r\\n])*\\2(?=\\s*:)",
          multiLine: true),
      lookbehind: true,
      greedy: true,
      alias: "property"),
  GrammarToken("inline-javascript",
      compileHighlightPattern("`(?:\\\\[\\s\\S]|[^\\\\`])*`"),
      inside: () => _g2),
  GrammarToken("multiline-string", compileHighlightPattern("'''[\\s\\S]*?'''"),
      greedy: true, alias: "string"),
  GrammarToken(
      "multiline-string", compileHighlightPattern("\"\"\"[\\s\\S]*?\"\"\""),
      greedy: true, alias: "string", inside: () => _g3),
  GrammarToken(
      "string", compileHighlightPattern("'(?:\\\\[\\s\\S]|[^\\\\'])*'"),
      greedy: true),
  GrammarToken(
      "string", compileHighlightPattern("\"(?:\\\\[\\s\\S]|[^\\\\\"])*\""),
      greedy: true, inside: () => _g4),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:class|extends|implements|instanceof|interface|new)\\s+)[\\w.\\\\]+"),
      lookbehind: true,
      inside: () => _g5),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(^|[^\$\\w\\xA0-\\uFFFF])(?!\\s)[_\$A-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*(?=\\.(?:constructor|prototype))"),
      lookbehind: true),
  GrammarToken(
      "regex",
      compileHighlightPattern(
          "((?:^|[^\$\\w\\xA0-\\uFFFF.\"'\\])\\s]|\\b(?:return|yield))\\s*)\\/(?:(?:\\[(?:[^\\]\\\\\\r\\n]|\\\\.)*\\]|\\\\.|[^/\\\\\\[\\r\\n])+\\/[dgimyus]{0,7}|(?:\\[(?:[^[\\]\\\\\\r\\n]|\\\\.|\\[(?:[^[\\]\\\\\\r\\n]|\\\\.|\\[(?:[^[\\]\\\\\\r\\n]|\\\\.)*\\])*\\])*\\]|\\\\.|[^/\\\\\\[\\r\\n])+\\/[dgimyus]{0,7}v[dgimyus]{0,7})(?=(?:\\s|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/)*(?:\$|[\\r\\n,.;:})\\]]|\\/\\/))"),
      lookbehind: true,
      greedy: true,
      inside: () => _g6),
  GrammarToken(
      "function-variable",
      compileHighlightPattern(
          "#?(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*(?=\\s*[=:]\\s*(?:async\\s*)?(?:\\bfunction\\b|(?:\\((?:[^()]|\\([^()]*\\))*\\)|(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*)\\s*=>))"),
      alias: "function"),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "(function(?:\\s+(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*)?\\s*\\(\\s*)(?!\\s)(?:[^()\\s]|\\s+(?![\\s)])|\\([^()]*\\))+(?=\\s*\\))"),
      lookbehind: true,
      inside: () => _g0),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "(^|[^\$\\w\\xA0-\\uFFFF])(?!\\s)[_\$a-z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*(?=\\s*=>)",
          caseSensitive: false),
      lookbehind: true,
      inside: () => _g0),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "(\\(\\s*)(?!\\s)(?:[^()\\s]|\\s+(?![\\s)])|\\([^()]*\\))+(?=\\s*\\)\\s*=>)"),
      lookbehind: true,
      inside: () => _g0),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "((?:\\b|\\s|^)(?!(?:as|async|await|break|case|catch|class|const|continue|debugger|default|delete|do|else|enum|export|extends|finally|for|from|function|get|if|implements|import|in|instanceof|interface|let|new|null|of|package|private|protected|public|return|set|static|super|switch|this|throw|try|typeof|undefined|var|void|while|with|yield)(?![\$\\w\\xA0-\\uFFFF]))(?:(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*\\s*)\\(\\s*|\\]\\s*\\(\\s*)(?!\\s)(?:[^()\\s]|\\s+(?![\\s)])|\\([^()]*\\))+(?=\\s*\\)\\s*\\{)"),
      lookbehind: true,
      inside: () => _g0),
  GrammarToken(
      "constant", compileHighlightPattern("\\b[A-Z](?:[A-Z_]|\\dx?)*\\b")),
  GrammarToken(
      "property", compileHighlightPattern("(?!\\d)\\w+(?=\\s*:(?!:))")),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:and|break|by|catch|class|continue|debugger|delete|do|each|else|extend|extends|false|finally|for|if|in|instanceof|is|isnt|let|loop|namespace|new|no|not|null|of|off|on|or|own|return|super|switch|then|this|throw|true|try|typeof|undefined|unless|until|when|while|window|with|yes|yield)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken(
      "function",
      compileHighlightPattern(
          "#?(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*(?=\\s*(?:\\.\\s*(?:apply|bind|call)\\s*)?\\()")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "(^|[^\\w\$])(?:NaN|Infinity|0[bB][01]+(?:_[01]+)*n?|0[oO][0-7]+(?:_[0-7]+)*n?|0[xX][\\dA-Fa-f]+(?:_[\\dA-Fa-f]+)*n?|\\d+(?:_\\d+)*n|(?:\\d+(?:_\\d+)*(?:\\.(?:\\d+(?:_\\d+)*)?)?|\\.\\d+(?:_\\d+)*)(?:[Ee][+-]?\\d+(?:_\\d+)*)?)(?![\\w\$])"),
      lookbehind: true),
  GrammarToken(
      "literal-property",
      compileHighlightPattern(
          "((?:^|[,{])[ \\t]*)(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*(?=\\s*:)",
          multiLine: true),
      lookbehind: true,
      alias: "property"),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "--|\\+\\+|\\*\\*=?|=>|&&=?|\\|\\|=?|[!=]==|<<=?|>>>?=?|[-+*/%&|^!=<>]=?|\\.{3}|\\?\\?=?|\\?\\.?|[~:]")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
  GrammarToken("class-member", compileHighlightPattern("@(?!\\d)\\w+"),
      alias: "variable"),
]);

final Grammar _g1 = Grammar([
  GrammarToken("comment", compileHighlightPattern("#(?!\\{).+")),
  GrammarToken("interpolation", compileHighlightPattern("#\\{[^}]+\\}"),
      alias: "variable"),
]);

final Grammar _g2 = Grammar([
  GrammarToken("delimiter", compileHighlightPattern("^`|`\$"),
      alias: "punctuation"),
  GrammarToken("script", compileHighlightPattern("[\\s\\S]+"),
      alias: "language-javascript", inside: () => HighlightJs.grammar),
]);

final Grammar _g3 = Grammar([
  GrammarToken("interpolation", compileHighlightPattern("#\\{[^}]+\\}"),
      alias: "variable"),
]);

final Grammar _g4 = Grammar([
  GrammarToken("interpolation", compileHighlightPattern("#\\{[^}]+\\}"),
      alias: "variable"),
]);

final Grammar _g5 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("[.\\\\]")),
]);

final Grammar _g6 = Grammar([
  GrammarToken(
      "regex-source", compileHighlightPattern("^(\\/)[\\s\\S]+(?=\\/[a-z]*\$)"),
      lookbehind: true, alias: "language-regex", inside: () => _g7),
  GrammarToken("regex-delimiter", compileHighlightPattern("^\\/|\\/\$")),
  GrammarToken("regex-flags", compileHighlightPattern("^[a-z]+\$")),
]);

final Grammar _g7 = Grammar([
  GrammarToken(
      "char-class",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\\\\\)*)\\[(?:[^\\\\\\]]|\\\\[\\s\\S])*\\]"),
      lookbehind: true,
      inside: () => _g8),
  GrammarToken(
      "special-escape", compileHighlightPattern("\\\\[\\\\(){}[\\]^\$+*?|.]"),
      alias: "escape"),
  GrammarToken(
      "char-set",
      compileHighlightPattern("\\.|\\\\[wsd]|\\\\p\\{[^{}]+\\}",
          caseSensitive: false),
      alias: "class-name"),
  GrammarToken(
      "backreference", compileHighlightPattern("\\\\(?![123][0-7]{2})[1-9]"),
      alias: "keyword"),
  GrammarToken("backreference", compileHighlightPattern("\\\\k<[^<>']+>"),
      alias: "keyword", inside: () => _g10),
  GrammarToken("anchor", compileHighlightPattern("[\$^]|\\\\[ABbGZz]"),
      alias: "function"),
  GrammarToken(
      "escape",
      compileHighlightPattern(
          "\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.)")),
  GrammarToken(
      "group",
      compileHighlightPattern(
          "\\((?:\\?(?:<[^<>']+>|'[^<>']+'|[>:]|<?[=!]|[idmnsuxU]+(?:-[idmnsuxU]+)?:?))?"),
      alias: "punctuation",
      inside: () => _g11),
  GrammarToken("group", compileHighlightPattern("\\)"), alias: "punctuation"),
  GrammarToken("quantifier",
      compileHighlightPattern("(?:[+*?]|\\{\\d+(?:,\\d*)?\\})[?+]?"),
      alias: "number"),
  GrammarToken("alternation", compileHighlightPattern("\\|"), alias: "keyword"),
]);

final Grammar _g8 = Grammar([
  GrammarToken("char-class-negation", compileHighlightPattern("(^\\[)\\^"),
      lookbehind: true, alias: "operator"),
  GrammarToken("char-class-punctuation", compileHighlightPattern("^\\[|\\]\$"),
      alias: "punctuation"),
  GrammarToken(
      "range",
      compileHighlightPattern(
          "(?:[^\\\\-]|\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.))-(?:[^\\\\-]|\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.))"),
      inside: () => _g9),
  GrammarToken(
      "special-escape", compileHighlightPattern("\\\\[\\\\(){}[\\]^\$+*?|.]"),
      alias: "escape"),
  GrammarToken(
      "char-set",
      compileHighlightPattern("\\\\[wsd]|\\\\p\\{[^{}]+\\}",
          caseSensitive: false),
      alias: "class-name"),
  GrammarToken(
      "escape",
      compileHighlightPattern(
          "\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.)")),
]);

final Grammar _g9 = Grammar([
  GrammarToken(
      "escape",
      compileHighlightPattern(
          "\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.)")),
  GrammarToken("range-punctuation", compileHighlightPattern("-"),
      alias: "operator"),
]);

final Grammar _g10 = Grammar([
  GrammarToken("group-name", compileHighlightPattern("(<|')[^<>']+(?=[>']\$)"),
      lookbehind: true, alias: "variable"),
]);

final Grammar _g11 = Grammar([
  GrammarToken("group-name", compileHighlightPattern("(<|')[^<>']+(?=[>']\$)"),
      lookbehind: true, alias: "variable"),
]);
