// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `groovy`.
///
/// Import this library only when you need `groovy` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightGroovy {
  /// The grammar for `groovy`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
  GrammarToken("shebang", compileHighlightPattern("#!.+"),
      greedy: true, alias: "comment"),
  GrammarToken(
      "interpolation-string",
      compileHighlightPattern(
          "\"\"\"(?:[^\\\\]|\\\\[\\s\\S])*?\"\"\"|([\"/])(?:\\\\.|(?!\\1)[^\\\\\\r\\n])*\\1|\\\$\\/(?:[^/\$]|\\\$(?:[/\$]|(?![/\$]))|\\/(?!\\\$))*\\/\\\$"),
      greedy: true,
      inside: () => _g1),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "'''(?:[^\\\\]|\\\\[\\s\\S])*?'''|'(?:\\\\.|[^\\\\'\\r\\n])*'"),
      greedy: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:class|extends|implements|instanceof|interface|new)\\s+)[\\w.\\\\]+"),
      lookbehind: true,
      inside: () => _g3),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:abstract|as|assert|boolean|break|byte|case|catch|char|class|const|continue|def|default|do|double|else|enum|extends|final|finally|float|for|goto|if|implements|import|in|instanceof|int|interface|long|native|new|package|private|protected|public|return|short|static|strictfp|super|switch|synchronized|this|throw|throws|trait|transient|try|void|volatile|while)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("annotation", compileHighlightPattern("(^|[^.])@\\w+"),
      lookbehind: true, alias: "punctuation"),
  GrammarToken("function", compileHighlightPattern("\\b\\w+(?=\\()")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b(?:0b[01_]+|0x[\\da-f_]+(?:\\.[\\da-f_p\\-]+)?|[\\d_]+(?:\\.[\\d_]+)?(?:e[+-]?\\d+)?)[glidf]?\\b",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "(^|[^.])(?:~|==?~?|\\?[.:]?|\\*(?:[.=]|\\*=?)?|\\.[@&]|\\.\\.<|\\.\\.(?!\\.)|-[-=>]?|\\+[+=]?|!=?|<(?:<=?|=>?)?|>(?:>>?=?|=)?|&[&=]?|\\|[|=]?|\\/=?|\\^=?|%=?)"),
      lookbehind: true),
  GrammarToken(
      "spock-block",
      compileHighlightPattern(
          "\\b(?:and|cleanup|expect|given|setup|then|when|where):")),
  GrammarToken("punctuation", compileHighlightPattern("\\.+|[{}[\\];(),:\$]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^\\\\\$])(?:\\\\{2})*)\\\$(?:\\w+|\\{[^{}]*\\})"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g2 = Grammar([
  GrammarToken(
      "interpolation-punctuation", compileHighlightPattern("^\\\$\\{?|\\}\$"),
      alias: "punctuation"),
  GrammarToken("expression", compileHighlightPattern("[\\s\\S]+"),
      inside: () => _g0),
]);

final Grammar _g3 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("[.\\\\]")),
]);
