// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `jsx`.
///
/// Import this library only when you need `jsx` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightJsx {
  /// The grammar for `jsx`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
  GrammarToken("prolog", compileHighlightPattern("<\\?[\\s\\S]+?\\?>"),
      greedy: true),
  GrammarToken(
      "doctype",
      compileHighlightPattern(
          "<!DOCTYPE(?:[^>\"'[\\]]|\"[^\"]*\"|'[^']*')+(?:\\[(?:[^<\"'\\]]|\"[^\"]*\"|'[^']*'|<(?!!--)|<!--(?:[^-]|-(?!->))*-->)*\\]\\s*)?>",
          caseSensitive: false),
      greedy: true,
      inside: () => _g1),
  GrammarToken(
      "style",
      compileHighlightPattern(
          "(<style[^>]*>)(?:<!\\[CDATA\\[(?:[^\\]]|\\](?!\\]>))*\\]\\]>|(?!<!\\[CDATA\\[)[\\s\\S])*?(?=<\\/style>)",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      inside: () => _g2),
  GrammarToken(
      "script",
      compileHighlightPattern(
          "(<script[^>]*>)(?:<!\\[CDATA\\[(?:[^\\]]|\\](?!\\]>))*\\]\\]>|(?!<!\\[CDATA\\[)[\\s\\S])*?(?=<\\/script>)",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      inside: () => _g7),
  GrammarToken(
      "cdata",
      compileHighlightPattern("<!\\[CDATA\\[[\\s\\S]*?\\]\\]>",
          caseSensitive: false),
      greedy: true),
  GrammarToken(
      "tag",
      compileHighlightPattern(
          "<\\/?(?:[\\w.:-]+(?:(?:\\s|\\/\\/.*(?!.)|\\/\\*(?:[^*]|\\*(?!\\/))\\*\\/)+(?:[\\w.:\$-]+(?:=(?:\"(?:\\\\[\\s\\S]|[^\\\\\"])*\"|'(?:\\\\[\\s\\S]|[^\\\\'])*'|[^\\s{'\"/>=]+|(?:\\{(?:\\{(?:\\{[^{}]*\\}|[^{}])*\\}|[^{}])*\\})))?|(?:\\{(?:\\s|\\/\\/.*(?!.)|\\/\\*(?:[^*]|\\*(?!\\/))\\*\\/)*\\.{3}(?:[^{}]|(?:\\{(?:\\{(?:\\{[^{}]*\\}|[^{}])*\\}|[^{}])*\\}))*\\})))*(?:\\s|\\/\\/.*(?!.)|\\/\\*(?:[^*]|\\*(?!\\/))\\*\\/)*\\/?)?>"),
      greedy: true,
      inside: () => _g19),
  GrammarToken("entity",
      compileHighlightPattern("&[\\da-z]{1,8};", caseSensitive: false),
      alias: "named-entity"),
  GrammarToken("entity",
      compileHighlightPattern("&#x?[\\da-f]{1,8};", caseSensitive: false)),
  GrammarToken("hashbang", compileHighlightPattern("^#!.*"),
      greedy: true, alias: "comment"),
  GrammarToken(
      "template-string",
      compileHighlightPattern(
          "`(?:\\\\[\\s\\S]|\\\$\\{(?:[^{}]|\\{(?:[^{}]|\\{[^}]*\\})*\\})+\\}|(?!\\\$\\{)[^\\\\`])*`"),
      greedy: true,
      inside: () => _g28),
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
          "(\\b(?:class|extends|implements|instanceof|interface|new)\\s+)[\\w.\\\\]+"),
      lookbehind: true,
      inside: () => _g31),
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
      inside: () => _g32),
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
      inside: () => _g30),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "(^|[^\$\\w\\xA0-\\uFFFF])(?!\\s)[_\$a-z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*(?=\\s*=>)",
          caseSensitive: false),
      lookbehind: true,
      inside: () => _g30),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "(\\(\\s*)(?!\\s)(?:[^()\\s]|\\s+(?![\\s)])|\\([^()]*\\))+(?=\\s*\\)\\s*=>)"),
      lookbehind: true,
      inside: () => _g30),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "((?:\\b|\\s|^)(?!(?:as|async|await|break|case|catch|class|const|continue|debugger|default|delete|do|else|enum|export|extends|finally|for|from|function|get|if|implements|import|in|instanceof|interface|let|new|null|of|package|private|protected|public|return|set|static|super|switch|this|throw|try|typeof|undefined|var|void|while|with|yield)(?![\$\\w\\xA0-\\uFFFF]))(?:(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*\\s*)\\(\\s*|\\]\\s*\\(\\s*)(?!\\s)(?:[^()\\s]|\\s+(?![\\s)])|\\([^()]*\\))+(?=\\s*\\)\\s*\\{)"),
      lookbehind: true,
      inside: () => _g30),
  GrammarToken(
      "constant", compileHighlightPattern("\\b[A-Z](?:[A-Z_]|\\dx?)*\\b")),
  GrammarToken("keyword", compileHighlightPattern("((?:^|\\})\\s*)catch\\b"),
      lookbehind: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(^|[^.]|\\.\\.\\.\\s*)\\b(?:as|assert(?=\\s*\\{)|async(?=\\s*(?:function\\b|\\(|[\$\\w\\xA0-\\uFFFF]|\$))|await|break|case|class|const|continue|debugger|default|delete|do|else|enum|export|extends|finally(?=\\s*(?:\\{|\$))|for|from(?=\\s*(?:['\"]|\$))|function|(?:get|set)(?=\\s*(?:[#\\[\$\\w\\xA0-\\uFFFF]|\$))|if|implements|import|in|instanceof|interface|let|new|null|of|package|private|protected|public|return|static|super|switch|this|throw|try|typeof|undefined|var|void|while|with|yield)\\b"),
      lookbehind: true),
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
]);

final Grammar _g1 = Grammar([
  GrammarToken("internal-subset",
      compileHighlightPattern("(^[^\\[]*\\[)[\\s\\S]+(?=\\]>\$)"),
      lookbehind: true, greedy: true, inside: () => _g0),
  GrammarToken("string", compileHighlightPattern("\"[^\"]*\"|'[^']*'"),
      greedy: true),
  GrammarToken("punctuation", compileHighlightPattern("^<!|>\$|[[\\]]")),
  GrammarToken(
      "doctype-tag", compileHighlightPattern("^DOCTYPE", caseSensitive: false)),
  GrammarToken("name", compileHighlightPattern("[^\\s<>'\"]+")),
]);

final Grammar _g2 = Grammar([
  GrammarToken(
      "included-cdata",
      compileHighlightPattern("<!\\[CDATA\\[[\\s\\S]*?\\]\\]>",
          caseSensitive: false),
      inside: () => _g3),
  GrammarToken("language-css", compileHighlightPattern("[\\s\\S]+"),
      inside: () => _g4),
]);

final Grammar _g3 = Grammar([
  GrammarToken(
      "language-css",
      compileHighlightPattern("(^<!\\[CDATA\\[)[\\s\\S]+?(?=\\]\\]>\$)",
          caseSensitive: false),
      lookbehind: true,
      inside: () => _g4),
  GrammarToken(
      "cdata",
      compileHighlightPattern("^<!\\[CDATA\\[|\\]\\]>\$",
          caseSensitive: false)),
]);

final Grammar _g4 = Grammar([
  GrammarToken("comment", compileHighlightPattern("\\/\\*[\\s\\S]*?\\*\\/")),
  GrammarToken(
      "atrule",
      compileHighlightPattern(
          "@[\\w-](?:[^;{\\s\"']|\\s+(?!\\s)|(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*'))*?(?:;|(?=\\s*\\{))"),
      inside: () => _g5),
  GrammarToken(
      "url",
      compileHighlightPattern(
          "\\burl\\((?:(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*')|(?:[^\\\\\\r\\n()\"']|\\\\[\\s\\S])*)\\)",
          caseSensitive: false),
      greedy: true,
      inside: () => _g6),
  GrammarToken(
      "selector",
      compileHighlightPattern(
          "(^|[{}\\s])[^{}\\s](?:[^{};\"'\\s]|\\s+(?![\\s{])|(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*'))*(?=\\s*\\{)"),
      lookbehind: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*')"),
      greedy: true),
  GrammarToken(
      "property",
      compileHighlightPattern(
          "(^|[^-\\w\\xA0-\\uFFFF])(?!\\s)[-_a-z\\xA0-\\uFFFF](?:(?!\\s)[-\\w\\xA0-\\uFFFF])*(?=\\s*:)",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken("important",
      compileHighlightPattern("!important\\b", caseSensitive: false)),
  GrammarToken(
      "function",
      compileHighlightPattern("(^|[^-a-z0-9])[-a-z0-9]+(?=\\()",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken("punctuation", compileHighlightPattern("[(){};:,]")),
]);

final Grammar _g5 = Grammar([
  GrammarToken("rule", compileHighlightPattern("^@[\\w-]+")),
  GrammarToken(
      "selector-function-argument",
      compileHighlightPattern(
          "(\\bselector\\s*\\(\\s*(?![\\s)]))(?:[^()\\s]|\\s+(?![\\s)])|\\((?:[^()]|\\([^()]*\\))*\\))+(?=\\s*\\))"),
      lookbehind: true,
      alias: "selector"),
  GrammarToken("keyword",
      compileHighlightPattern("(^|[^\\w-])(?:and|not|only|or)(?![\\w-])"),
      lookbehind: true),
], rest: () => _g4);

final Grammar _g6 = Grammar([
  GrammarToken(
      "function", compileHighlightPattern("^url", caseSensitive: false)),
  GrammarToken("punctuation", compileHighlightPattern("^\\(|\\)\$")),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "^(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n])*')\$"),
      alias: "url"),
]);

final Grammar _g7 = Grammar([
  GrammarToken(
      "included-cdata",
      compileHighlightPattern("<!\\[CDATA\\[[\\s\\S]*?\\]\\]>",
          caseSensitive: false),
      inside: () => _g8),
  GrammarToken("language-javascript", compileHighlightPattern("[\\s\\S]+"),
      inside: () => _g9),
]);

final Grammar _g8 = Grammar([
  GrammarToken(
      "language-javascript",
      compileHighlightPattern("(^<!\\[CDATA\\[)[\\s\\S]+?(?=\\]\\]>\$)",
          caseSensitive: false),
      lookbehind: true,
      inside: () => _g9),
  GrammarToken(
      "cdata",
      compileHighlightPattern("^<!\\[CDATA\\[|\\]\\]>\$",
          caseSensitive: false)),
]);

final Grammar _g9 = Grammar([
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
      inside: () => _g10),
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
          "(\\b(?:class|extends|implements|instanceof|interface|new)\\s+)[\\w.\\\\]+"),
      lookbehind: true,
      inside: () => _g12),
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
      inside: () => _g13),
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
      inside: () => _g9),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "(^|[^\$\\w\\xA0-\\uFFFF])(?!\\s)[_\$a-z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*(?=\\s*=>)",
          caseSensitive: false),
      lookbehind: true,
      inside: () => _g9),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "(\\(\\s*)(?!\\s)(?:[^()\\s]|\\s+(?![\\s)])|\\([^()]*\\))+(?=\\s*\\)\\s*=>)"),
      lookbehind: true,
      inside: () => _g9),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "((?:\\b|\\s|^)(?!(?:as|async|await|break|case|catch|class|const|continue|debugger|default|delete|do|else|enum|export|extends|finally|for|from|function|get|if|implements|import|in|instanceof|interface|let|new|null|of|package|private|protected|public|return|set|static|super|switch|this|throw|try|typeof|undefined|var|void|while|with|yield)(?![\$\\w\\xA0-\\uFFFF]))(?:(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*\\s*)\\(\\s*|\\]\\s*\\(\\s*)(?!\\s)(?:[^()\\s]|\\s+(?![\\s)])|\\([^()]*\\))+(?=\\s*\\)\\s*\\{)"),
      lookbehind: true,
      inside: () => _g9),
  GrammarToken(
      "constant", compileHighlightPattern("\\b[A-Z](?:[A-Z_]|\\dx?)*\\b")),
  GrammarToken("keyword", compileHighlightPattern("((?:^|\\})\\s*)catch\\b"),
      lookbehind: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(^|[^.]|\\.\\.\\.\\s*)\\b(?:as|assert(?=\\s*\\{)|async(?=\\s*(?:function\\b|\\(|[\$\\w\\xA0-\\uFFFF]|\$))|await|break|case|class|const|continue|debugger|default|delete|do|else|enum|export|extends|finally(?=\\s*(?:\\{|\$))|for|from(?=\\s*(?:['\"]|\$))|function|(?:get|set)(?=\\s*(?:[#\\[\$\\w\\xA0-\\uFFFF]|\$))|if|implements|import|in|instanceof|interface|let|new|null|of|package|private|protected|public|return|static|super|switch|this|throw|try|typeof|undefined|var|void|while|with|yield)\\b"),
      lookbehind: true),
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
]);

final Grammar _g10 = Grammar([
  GrammarToken("template-punctuation", compileHighlightPattern("^`|`\$"),
      alias: "string"),
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\{2})*)\\\$\\{(?:[^{}]|\\{(?:[^{}]|\\{[^}]*\\})*\\})+\\}"),
      lookbehind: true,
      inside: () => _g11),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g11 = Grammar([
  GrammarToken(
      "interpolation-punctuation", compileHighlightPattern("^\\\$\\{|\\}\$"),
      alias: "punctuation"),
], rest: () => _g9);

final Grammar _g12 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("[.\\\\]")),
]);

final Grammar _g13 = Grammar([
  GrammarToken(
      "regex-source", compileHighlightPattern("^(\\/)[\\s\\S]+(?=\\/[a-z]*\$)"),
      lookbehind: true, alias: "language-regex", inside: () => _g14),
  GrammarToken("regex-delimiter", compileHighlightPattern("^\\/|\\/\$")),
  GrammarToken("regex-flags", compileHighlightPattern("^[a-z]+\$")),
]);

final Grammar _g14 = Grammar([
  GrammarToken(
      "char-class",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\\\\\)*)\\[(?:[^\\\\\\]]|\\\\[\\s\\S])*\\]"),
      lookbehind: true,
      inside: () => _g15),
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
      alias: "keyword", inside: () => _g17),
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
      inside: () => _g18),
  GrammarToken("group", compileHighlightPattern("\\)"), alias: "punctuation"),
  GrammarToken("quantifier",
      compileHighlightPattern("(?:[+*?]|\\{\\d+(?:,\\d*)?\\})[?+]?"),
      alias: "number"),
  GrammarToken("alternation", compileHighlightPattern("\\|"), alias: "keyword"),
]);

final Grammar _g15 = Grammar([
  GrammarToken("char-class-negation", compileHighlightPattern("(^\\[)\\^"),
      lookbehind: true, alias: "operator"),
  GrammarToken("char-class-punctuation", compileHighlightPattern("^\\[|\\]\$"),
      alias: "punctuation"),
  GrammarToken(
      "range",
      compileHighlightPattern(
          "(?:[^\\\\-]|\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.))-(?:[^\\\\-]|\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.))"),
      inside: () => _g16),
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

final Grammar _g16 = Grammar([
  GrammarToken(
      "escape",
      compileHighlightPattern(
          "\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.)")),
  GrammarToken("range-punctuation", compileHighlightPattern("-"),
      alias: "operator"),
]);

final Grammar _g17 = Grammar([
  GrammarToken("group-name", compileHighlightPattern("(<|')[^<>']+(?=[>']\$)"),
      lookbehind: true, alias: "variable"),
]);

final Grammar _g18 = Grammar([
  GrammarToken("group-name", compileHighlightPattern("(<|')[^<>']+(?=[>']\$)"),
      lookbehind: true, alias: "variable"),
]);

final Grammar _g19 = Grammar([
  GrammarToken("tag", compileHighlightPattern("^<\\/?[^\\s>\\/]*"),
      inside: () => _g20),
  GrammarToken(
      "script",
      compileHighlightPattern(
          "=(?:\\{(?:\\{(?:\\{[^{}]*\\}|[^{}])*\\}|[^{}])*\\})"),
      alias: "language-javascript",
      inside: () => _g21),
  GrammarToken(
      "special-attr",
      compileHighlightPattern(
          "(^|[\"'\\s])(?:style)\\s*=\\s*(?:\"[^\"]*\"|'[^']*'|[^\\s'\">=]+(?=[\\s>]))",
          caseSensitive: false),
      lookbehind: true,
      inside: () => _g22),
  GrammarToken(
      "special-attr",
      compileHighlightPattern(
          "(^|[\"'\\s])(?:on(?:abort|blur|change|click|composition(?:end|start|update)|dblclick|error|focus(?:in|out)?|key(?:down|up)|load|mouse(?:down|enter|leave|move|out|over|up)|reset|resize|scroll|select|slotchange|submit|unload|wheel))\\s*=\\s*(?:\"[^\"]*\"|'[^']*'|[^\\s'\">=]+(?=[\\s>]))",
          caseSensitive: false),
      lookbehind: true,
      inside: () => _g24),
  GrammarToken(
      "attr-value",
      compileHighlightPattern(
          "=(?!\\{)(?:\"(?:\\\\[\\s\\S]|[^\\\\\"])*\"|'(?:\\\\[\\s\\S]|[^\\\\'])*'|[^\\s'\">]+)"),
      inside: () => _g26),
  GrammarToken("punctuation", compileHighlightPattern("\\/?>")),
  GrammarToken(
      "spread",
      compileHighlightPattern(
          "(?:\\{(?:\\s|\\/\\/.*(?!.)|\\/\\*(?:[^*]|\\*(?!\\/))\\*\\/)*\\.{3}(?:[^{}]|(?:\\{(?:\\{(?:\\{[^{}]*\\}|[^{}])*\\}|[^{}])*\\}))*\\})"),
      inside: () => _g0),
  GrammarToken("attr-name", compileHighlightPattern("[^\\s>\\/]+"),
      inside: () => _g27),
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
]);

final Grammar _g20 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("^<\\/?")),
  GrammarToken("namespace", compileHighlightPattern("^[^\\s>\\/:]+:")),
  GrammarToken(
      "class-name", compileHighlightPattern("^[A-Z]\\w*(?:\\.[A-Z]\\w*)*\$")),
]);

final Grammar _g21 = Grammar([
  GrammarToken("script-punctuation", compileHighlightPattern("^=(?=\\{)"),
      alias: "punctuation"),
], rest: () => _g0);

final Grammar _g22 = Grammar([
  GrammarToken("attr-name", compileHighlightPattern("^[^\\s=]+")),
  GrammarToken("attr-value", compileHighlightPattern("=[\\s\\S]+"),
      inside: () => _g23),
]);

final Grammar _g23 = Grammar([
  GrammarToken("value",
      compileHighlightPattern("(^=\\s*([\"']|(?![\"'])))\\S[\\s\\S]*(?=\\2\$)"),
      lookbehind: true, alias: "css", inside: () => _g4),
  GrammarToken("punctuation", compileHighlightPattern("^="),
      alias: "attr-equals"),
  GrammarToken("punctuation", compileHighlightPattern("\"|'")),
]);

final Grammar _g24 = Grammar([
  GrammarToken("attr-name", compileHighlightPattern("^[^\\s=]+")),
  GrammarToken("attr-value", compileHighlightPattern("=[\\s\\S]+"),
      inside: () => _g25),
]);

final Grammar _g25 = Grammar([
  GrammarToken("value",
      compileHighlightPattern("(^=\\s*([\"']|(?![\"'])))\\S[\\s\\S]*(?=\\2\$)"),
      lookbehind: true, alias: "javascript", inside: () => _g9),
  GrammarToken("punctuation", compileHighlightPattern("^="),
      alias: "attr-equals"),
  GrammarToken("punctuation", compileHighlightPattern("\"|'")),
]);

final Grammar _g26 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("^="),
      alias: "attr-equals"),
  GrammarToken("punctuation", compileHighlightPattern("^(\\s*)[\"']|[\"']\$"),
      lookbehind: true),
  GrammarToken("entity",
      compileHighlightPattern("&[\\da-z]{1,8};", caseSensitive: false),
      alias: "named-entity"),
  GrammarToken("entity",
      compileHighlightPattern("&#x?[\\da-f]{1,8};", caseSensitive: false)),
]);

final Grammar _g27 = Grammar([
  GrammarToken("namespace", compileHighlightPattern("^[^\\s>\\/:]+:")),
]);

final Grammar _g28 = Grammar([
  GrammarToken("template-punctuation", compileHighlightPattern("^`|`\$"),
      alias: "string"),
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\{2})*)\\\$\\{(?:[^{}]|\\{(?:[^{}]|\\{[^}]*\\})*\\})+\\}"),
      lookbehind: true,
      inside: () => _g29),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g29 = Grammar([
  GrammarToken(
      "interpolation-punctuation", compileHighlightPattern("^\\\$\\{|\\}\$"),
      alias: "punctuation"),
], rest: () => _g30);

final Grammar _g30 = Grammar([
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
      inside: () => _g28),
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
          "(\\b(?:class|extends|implements|instanceof|interface|new)\\s+)[\\w.\\\\]+"),
      lookbehind: true,
      inside: () => _g31),
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
      inside: () => _g32),
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
      inside: () => _g30),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "(^|[^\$\\w\\xA0-\\uFFFF])(?!\\s)[_\$a-z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*(?=\\s*=>)",
          caseSensitive: false),
      lookbehind: true,
      inside: () => _g30),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "(\\(\\s*)(?!\\s)(?:[^()\\s]|\\s+(?![\\s)])|\\([^()]*\\))+(?=\\s*\\)\\s*=>)"),
      lookbehind: true,
      inside: () => _g30),
  GrammarToken(
      "parameter",
      compileHighlightPattern(
          "((?:\\b|\\s|^)(?!(?:as|async|await|break|case|catch|class|const|continue|debugger|default|delete|do|else|enum|export|extends|finally|for|from|function|get|if|implements|import|in|instanceof|interface|let|new|null|of|package|private|protected|public|return|set|static|super|switch|this|throw|try|typeof|undefined|var|void|while|with|yield)(?![\$\\w\\xA0-\\uFFFF]))(?:(?!\\s)[_\$a-zA-Z\\xA0-\\uFFFF](?:(?!\\s)[\$\\w\\xA0-\\uFFFF])*\\s*)\\(\\s*|\\]\\s*\\(\\s*)(?!\\s)(?:[^()\\s]|\\s+(?![\\s)])|\\([^()]*\\))+(?=\\s*\\)\\s*\\{)"),
      lookbehind: true,
      inside: () => _g30),
  GrammarToken(
      "constant", compileHighlightPattern("\\b[A-Z](?:[A-Z_]|\\dx?)*\\b")),
  GrammarToken("keyword", compileHighlightPattern("((?:^|\\})\\s*)catch\\b"),
      lookbehind: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(^|[^.]|\\.\\.\\.\\s*)\\b(?:as|assert(?=\\s*\\{)|async(?=\\s*(?:function\\b|\\(|[\$\\w\\xA0-\\uFFFF]|\$))|await|break|case|class|const|continue|debugger|default|delete|do|else|enum|export|extends|finally(?=\\s*(?:\\{|\$))|for|from(?=\\s*(?:['\"]|\$))|function|(?:get|set)(?=\\s*(?:[#\\[\$\\w\\xA0-\\uFFFF]|\$))|if|implements|import|in|instanceof|interface|let|new|null|of|package|private|protected|public|return|static|super|switch|this|throw|try|typeof|undefined|var|void|while|with|yield)\\b"),
      lookbehind: true),
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
]);

final Grammar _g31 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("[.\\\\]")),
]);

final Grammar _g32 = Grammar([
  GrammarToken(
      "regex-source", compileHighlightPattern("^(\\/)[\\s\\S]+(?=\\/[a-z]*\$)"),
      lookbehind: true, alias: "language-regex", inside: () => _g33),
  GrammarToken("regex-delimiter", compileHighlightPattern("^\\/|\\/\$")),
  GrammarToken("regex-flags", compileHighlightPattern("^[a-z]+\$")),
]);

final Grammar _g33 = Grammar([
  GrammarToken(
      "char-class",
      compileHighlightPattern(
          "((?:^|[^\\\\])(?:\\\\\\\\)*)\\[(?:[^\\\\\\]]|\\\\[\\s\\S])*\\]"),
      lookbehind: true,
      inside: () => _g34),
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
      alias: "keyword", inside: () => _g36),
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
      inside: () => _g37),
  GrammarToken("group", compileHighlightPattern("\\)"), alias: "punctuation"),
  GrammarToken("quantifier",
      compileHighlightPattern("(?:[+*?]|\\{\\d+(?:,\\d*)?\\})[?+]?"),
      alias: "number"),
  GrammarToken("alternation", compileHighlightPattern("\\|"), alias: "keyword"),
]);

final Grammar _g34 = Grammar([
  GrammarToken("char-class-negation", compileHighlightPattern("(^\\[)\\^"),
      lookbehind: true, alias: "operator"),
  GrammarToken("char-class-punctuation", compileHighlightPattern("^\\[|\\]\$"),
      alias: "punctuation"),
  GrammarToken(
      "range",
      compileHighlightPattern(
          "(?:[^\\\\-]|\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.))-(?:[^\\\\-]|\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.))"),
      inside: () => _g35),
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

final Grammar _g35 = Grammar([
  GrammarToken(
      "escape",
      compileHighlightPattern(
          "\\\\(?:x[\\da-fA-F]{2}|u[\\da-fA-F]{4}|u\\{[\\da-fA-F]+\\}|0[0-7]{0,2}|[123][0-7]{2}|c[a-zA-Z]|.)")),
  GrammarToken("range-punctuation", compileHighlightPattern("-"),
      alias: "operator"),
]);

final Grammar _g36 = Grammar([
  GrammarToken("group-name", compileHighlightPattern("(<|')[^<>']+(?=[>']\$)"),
      lookbehind: true, alias: "variable"),
]);

final Grammar _g37 = Grammar([
  GrammarToken("group-name", compileHighlightPattern("(<|')[^<>']+(?=[>']\$)"),
      lookbehind: true, alias: "variable"),
]);
