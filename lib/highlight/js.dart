// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';
import 'regex.dart';

/// Syntax grammar for `js`.
///
/// Import this library only when you need `js` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightJs {
  /// The grammar for `js`.
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
          "(\\b(?:class|extends|implements|instanceof|interface|new)\\s+)[\\w.\\\\]+"),
      lookbehind: true,
      inside: () => _g3),
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
      inside: () => _g4),
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
  GrammarToken("punctuation", compileHighlightPattern("[.\\\\]")),
]);

final Grammar _g4 = Grammar([
  GrammarToken(
      "regex-source", compileHighlightPattern("^(\\/)[\\s\\S]+(?=\\/[a-z]*\$)"),
      lookbehind: true,
      alias: "language-regex",
      inside: () => HighlightRegex.grammar),
  GrammarToken("regex-delimiter", compileHighlightPattern("^\\/|\\/\$")),
  GrammarToken("regex-flags", compileHighlightPattern("^[a-z]+\$")),
]);
