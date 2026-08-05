// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `typescript`.
///
/// Import this library only when you need `typescript` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightTypescript {
  /// The grammar for `typescript`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
  GrammarToken("hashbang", compileHighlightPattern("^#!.*"),
      greedy: true, alias: "comment"),
  GrammarToken(
      "template-string",
      compileHighlightPattern(
          "`(?:\\\\[\\s\\S]|\\\$\\{(?:[^{}]|\\{(?:[^{}]|\\{[^}]*\\})*\\})+\\}|(?!\\\$\\{)[^\\\\`])*`"),
      greedy: true,
      inside: () => _g1),
  GrammarToken(
      "string-property",
      compileHighlightPattern(
          "((?:^|[,{])[ \\t]*)([\"'])(?:\\\\(?:\\r\\n|[\\s\\S])|(?!\\2)[^\\\\\\r\\n])*\\2(?=\\s*:)",
          multiLine: true),
      lookbehind: true,
      greedy: true,
      alias: "property"),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "([\"'])(?:\\\\(?:\\r\\n|[\\s\\S])|(?!\\1)[^\\\\\\r\\n])*\\1"),
      greedy: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:class|extends|implements|instanceof|interface|new|type)\\s+)(?!keyof\\b)(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*(?:\\s*<(?:[^<>]|<(?:[^<>]|<[^<>]*>)*>)*>)?"),
      lookbehind: true,
      greedy: true,
      inside: () => _g3),
  GrammarToken(
      "regex",
      compileHighlightPattern(
          "((?:^|[^\$\\w\\xA0-\\uFFFF.\"'\\])\\s]|\\b(?:return|yield))\\s*)\\/(?:(?:\\[(?:[^\\]\\\\\\r\\n]|\\\\.)*\\]|\\\\.|[^/\\\\\\[\\r\\n])+\\/[dgimyus]{0,7}|(?:\\[(?:[^[\\]\\\\\\r\\n]|\\\\.|\\[(?:[^[\\]\\\\\\r\\n]|\\\\.|\\[(?:[^[\\]\\\\\\r\\n]|\\\\.)*\\])*\\])*\\]|\\\\.|[^/\\\\\\[\\r\\n])+\\/[dgimyus]{0,7}v[dgimyus]{0,7})(?=(?:\\s|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/)*(?:\$|[\\r\\n,.;:})\\]]|\\/\\/))"),
      lookbehind: true,
      greedy: true,
      inside: () => _g12),
  GrammarToken(
      "function-variable",
      compileHighlightPattern(
          "#?(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*(?=\\s*[=:]\\s*(?:async\\s*)?(?:\\bfunction\\b|(?:\\((?:[^()]|\\([^()]*\\))*\\)|(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*)\\s*=>))"),
      alias: "function"),
  GrammarToken(
      "constant", compileHighlightPattern("\\b[A-Z](?:[A-Z_]|\\dx?)*\\b")),
  GrammarToken("keyword", compileHighlightPattern("((?:^|\\})\\s*)catch\\b"),
      lookbehind: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(^|[^.]|\\.\\.\\.\\s*)\\b(?:as|assert(?=\\s*\\{)|async(?=\\s*(?:function\\b|\\(|[\$\\w\\xA0-\\uFFFF]|\$))|await|break|case|class|const|continue|debugger|default|delete|do|else|enum|export|extends|finally(?=\\s*(?:\\{|\$))|for|from(?=\\s*(?:['\"]|\$))|function|(?:get|set)(?=\\s*(?:[#\\[\$\\w\\xA0-\\uFFFF]|\$))|if|implements|import|in|instanceof|interface|let|new|null|of|package|private|protected|public|return|static|super|switch|this|throw|try|typeof|undefined|var|void|while|with|yield)\\b"),
      lookbehind: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:abstract|declare|is|keyof|readonly|require)\\b")),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:asserts|infer|interface|module|namespace|type)\\b(?=\\s*(?:[{_\$a-zA-Z\\xA0-\\uFFFF]|\$))")),
  GrammarToken(
      "keyword", compileHighlightPattern("\\btype\\b(?=\\s*(?:[\\{*]|\$))")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("decorator", compileHighlightPattern("@[\$\\w\\xA0-\\uFFFF]+"),
      inside: () => _g18),
  GrammarToken(
      "generic-function",
      compileHighlightPattern(
          "#?(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*\\s*<(?:[^<>]|<(?:[^<>]|<[^<>]*>)*>)*>(?=\\s*\\()"),
      greedy: true,
      inside: () => _g19),
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
      "operator",
      compileHighlightPattern(
          "--|\\+\\+|\\*\\*=?|=>|&&=?|\\|\\|=?|[!=]==|<<=?|>>>?=?|[-+*/%&|^!=<>]=?|\\.{3}|\\?\\?=?|\\?\\.?|[~:]")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
  GrammarToken(
      "builtin",
      compileHighlightPattern(
          "\\b(?:Array|Function|Promise|any|boolean|console|never|number|string|symbol|unknown)\\b")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("template-punctuation", compileHighlightPattern("^`|`\$"),
      alias: "string"),
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\{2})*)\\\$\\{(?:[^{}]|\\{(?:[^{}]|\\{[^}]*\\})*\\})+\\}"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g2 = Grammar([
  GrammarToken(
      "interpolation-punctuation", compileHighlightPattern("^\\\$\\{|\\}\$"),
      alias: "punctuation"),
], rest: () => _g0);

final Grammar _g3 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
  GrammarToken("hashbang", compileHighlightPattern("^#!.*"),
      greedy: true, alias: "comment"),
  GrammarToken(
      "template-string",
      compileHighlightPattern(
          "`(?:\\\\[\\s\\S]|\\\$\\{(?:[^{}]|\\{(?:[^{}]|\\{[^}]*\\})*\\})+\\}|(?!\\\$\\{)[^\\\\`])*`"),
      greedy: true,
      inside: () => _g4),
  GrammarToken(
      "string-property",
      compileHighlightPattern(
          "((?:^|[,{])[ \\t]*)([\"'])(?:\\\\(?:\\r\\n|[\\s\\S])|(?!\\2)[^\\\\\\r\\n])*\\2(?=\\s*:)",
          multiLine: true),
      lookbehind: true,
      greedy: true,
      alias: "property"),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "([\"'])(?:\\\\(?:\\r\\n|[\\s\\S])|(?!\\1)[^\\\\\\r\\n])*\\1"),
      greedy: true),
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
      "constant", compileHighlightPattern("\\b[A-Z](?:[A-Z_]|\\dx?)*\\b")),
  GrammarToken("keyword", compileHighlightPattern("((?:^|\\})\\s*)catch\\b"),
      lookbehind: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(^|[^.]|\\.\\.\\.\\s*)\\b(?:as|assert(?=\\s*\\{)|async(?=\\s*(?:function\\b|\\(|[\$\\w\\xA0-\\uFFFF]|\$))|await|break|case|class|const|continue|debugger|default|delete|do|else|enum|export|extends|finally(?=\\s*(?:\\{|\$))|for|from(?=\\s*(?:['\"]|\$))|function|(?:get|set)(?=\\s*(?:[#\\[\$\\w\\xA0-\\uFFFF]|\$))|if|implements|import|in|instanceof|interface|let|new|null|of|package|private|protected|public|return|static|super|switch|this|throw|try|typeof|undefined|var|void|while|with|yield)\\b"),
      lookbehind: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:abstract|declare|is|keyof|readonly|require)\\b")),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:asserts|infer|interface|module|namespace|type)\\b(?=\\s*(?:[{_\$a-zA-Z\\xA0-\\uFFFF]|\$))")),
  GrammarToken(
      "keyword", compileHighlightPattern("\\btype\\b(?=\\s*(?:[\\{*]|\$))")),
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
      "operator",
      compileHighlightPattern(
          "--|\\+\\+|\\*\\*=?|=>|&&=?|\\|\\|=?|[!=]==|<<=?|>>>?=?|[-+*/%&|^!=<>]=?|\\.{3}|\\?\\?=?|\\?\\.?|[~:]")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
  GrammarToken(
      "builtin",
      compileHighlightPattern(
          "\\b(?:Array|Function|Promise|any|boolean|console|never|number|string|symbol|unknown)\\b")),
]);

final Grammar _g4 = Grammar([
  GrammarToken("template-punctuation", compileHighlightPattern("^`|`\$"),
      alias: "string"),
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\{2})*)\\\$\\{(?:[^{}]|\\{(?:[^{}]|\\{[^}]*\\})*\\})+\\}"),
      lookbehind: true,
      inside: () => _g5),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g5 = Grammar([
  GrammarToken(
      "interpolation-punctuation", compileHighlightPattern("^\\\$\\{|\\}\$"),
      alias: "punctuation"),
], rest: () => _g3);

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

final Grammar _g12 = Grammar([
  GrammarToken(
      "regex-source", compileHighlightPattern("^(\\/)[\\s\\S]+(?=\\/[a-z]*\$)"),
      lookbehind: true, alias: "language-regex", inside: () => _g13),
  GrammarToken("regex-delimiter", compileHighlightPattern("^\\/|\\/\$")),
  GrammarToken("regex-flags", compileHighlightPattern("^[a-z]+\$")),
]);

final Grammar _g13 = Grammar([
  GrammarToken(
      "char-class",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\\\\\)*)\\[(?:[^\\\\\\]]|\\\\[\\s\\S])*\\]"),
      lookbehind: true,
      inside: () => _g14),
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
      alias: "keyword", inside: () => _g16),
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
      inside: () => _g17),
  GrammarToken("group", compileHighlightPattern("\\)"), alias: "punctuation"),
  GrammarToken("quantifier",
      compileHighlightPattern("(?:[+*?]|\\{\\d+(?:,\\d*)?\\})[?+]?"),
      alias: "number"),
  GrammarToken("alternation", compileHighlightPattern("\\|"), alias: "keyword"),
]);

final Grammar _g14 = Grammar([
  GrammarToken("char-class-negation", compileHighlightPattern("(^\\[)\\^"),
      lookbehind: true, alias: "operator"),
  GrammarToken("char-class-punctuation", compileHighlightPattern("^\\[|\\]\$"),
      alias: "punctuation"),
  GrammarToken(
      "range",
      compileHighlightPattern(
          "(?:[^\\\\-]|\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.))-(?:[^\\\\-]|\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.))"),
      inside: () => _g15),
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

final Grammar _g15 = Grammar([
  GrammarToken(
      "escape",
      compileHighlightPattern(
          "\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.)")),
  GrammarToken("range-punctuation", compileHighlightPattern("-"),
      alias: "operator"),
]);

final Grammar _g16 = Grammar([
  GrammarToken("group-name", compileHighlightPattern("(<|')[^<>']+(?=[>']\$)"),
      lookbehind: true, alias: "variable"),
]);

final Grammar _g17 = Grammar([
  GrammarToken("group-name", compileHighlightPattern("(<|')[^<>']+(?=[>']\$)"),
      lookbehind: true, alias: "variable"),
]);

final Grammar _g18 = Grammar([
  GrammarToken("at", compileHighlightPattern("^@"), alias: "operator"),
  GrammarToken("function", compileHighlightPattern("^[\\s\\S]+")),
]);

final Grammar _g19 = Grammar([
  GrammarToken(
      "function",
      compileHighlightPattern(
          "^#?(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*")),
  GrammarToken("generic", compileHighlightPattern("<[\\s\\S]+"),
      alias: "class-name", inside: () => _g3),
]);
