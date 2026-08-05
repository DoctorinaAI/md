// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `java`.
///
/// Import this library only when you need `java` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightJava {
  /// The grammar for `java`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "triple-quoted-string",
      compileHighlightPattern(
          "\"\"\"[ \\t]*[\\r\\n](?:(?:\"|\"\")?(?:\\\\.|[^\"\\\\]))*\"\"\""),
      greedy: true,
      alias: "string"),
  GrammarToken(
      "char", compileHighlightPattern("'(?:\\\\.|[^'\\\\\\r\\n]){1,6}'"),
      greedy: true),
  GrammarToken("string",
      compileHighlightPattern("(^|[^\\\\])\"(?:\\\\.|[^\"\\\\\\r\\n])*\""),
      lookbehind: true, greedy: true),
  GrammarToken("annotation",
      compileHighlightPattern("(^|[^.])@\\w+(?:\\s*\\.\\s*\\w+)*"),
      lookbehind: true, alias: "punctuation"),
  GrammarToken(
      "generics",
      compileHighlightPattern(
          "<(?:[\\w\\s,.?]|&(?!&)|<(?:[\\w\\s,.?]|&(?!&)|<(?:[\\w\\s,.?]|&(?!&)|<(?:[\\w\\s,.?]|&(?!&))*>)*>)*>)*>"),
      inside: () => _g1),
  GrammarToken(
      "import",
      compileHighlightPattern(
          "(\\bimport\\s+)(?:[a-z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*|\\*)(?=\\s*;)"),
      lookbehind: true,
      inside: () => _g4),
  GrammarToken(
      "import",
      compileHighlightPattern(
          "(\\bimport\\s+static\\s+)(?:[a-z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*\\s*\\.\\s*)*(?:\\w+|\\*)(?=\\s*;)"),
      lookbehind: true,
      alias: "static",
      inside: () => _g5),
  GrammarToken(
      "namespace",
      compileHighlightPattern(
          "(\\b(?:exports|import(?:\\s+static)?|module|open|opens|package|provides|requires|to|transitive|uses|with)\\s+)(?!\\b(?:abstract|assert|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|enum|exports|extends|final|finally|float|for|goto|if|implements|import|instanceof|int|interface|long|module|native|new|non-sealed|null|open|opens|package|permits|private|protected|provides|public|record(?!\\s*[(){}[\\]<>=%~.:,;?+\\-*/&|^])|requires|return|sealed|short|static|strictfp|super|switch|synchronized|this|throw|throws|to|transient|transitive|try|uses|var|void|volatile|while|with|yield)\\b)[a-z]\\w*(?:\\.[a-z]\\w*)*\\.?"),
      lookbehind: true,
      inside: () => _g6),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(^|[^\\w.])(?:[a-z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*\\s*\\.\\s*)*[A-Z](?:[\\d_A-Z]*[a-z]\\w*)?\\b"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(^|[^\\w.])(?:[a-z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*\\s*\\.\\s*)*[A-Z]\\w*(?=\\s+\\w+\\s*[;,=()]|\\s*(?:\\[[\\s,]*\\]\\s*)?::\\s*new\\b)"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:class|enum|extends|implements|instanceof|interface|new|record|throws)\\s+)(?:[a-z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*\\s*\\.\\s*)*[A-Z]\\w*\\b"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:abstract|assert|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|enum|exports|extends|final|finally|float|for|goto|if|implements|import|instanceof|int|interface|long|module|native|new|non-sealed|null|open|opens|package|permits|private|protected|provides|public|record(?!\\s*[(){}[\\]<>=%~.:,;?+\\-*/&|^])|requires|return|sealed|short|static|strictfp|super|switch|synchronized|this|throw|throws|to|transient|transitive|try|uses|var|void|volatile|while|with|yield)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("function", compileHighlightPattern("\\b\\w+(?=\\()")),
  GrammarToken("function", compileHighlightPattern("(::\\s*)[a-z_]\\w*"),
      lookbehind: true),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0b[01][01_]*L?\\b|\\b0x(?:\\.[\\da-f_p+-]+|[\\da-f_]+(?:\\.[\\da-f_p+-]+)?)\\b|(?:\\b\\d[\\d_]*(?:\\.[\\d_]*)?|\\B\\.\\d[\\d_]*)(?:e[+-]?\\d[\\d_]*)?[dfl]?",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "(^|[^.])(?:<<=?|>>>?=?|->|--|\\+\\+|&&|\\|\\||::|[?:~]|[-+*/%&|^!=<>]=?)",
          multiLine: true),
      lookbehind: true),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
  GrammarToken("constant", compileHighlightPattern("\\b[A-Z][A-Z_\\d]+\\b")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(^|[^\\w.])(?:[a-z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*\\s*\\.\\s*)*[A-Z](?:[\\d_A-Z]*[a-z]\\w*)?\\b"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:abstract|assert|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|enum|exports|extends|final|finally|float|for|goto|if|implements|import|instanceof|int|interface|long|module|native|new|non-sealed|null|open|opens|package|permits|private|protected|provides|public|record(?!\\s*[(){}[\\]<>=%~.:,;?+\\-*/&|^])|requires|return|sealed|short|static|strictfp|super|switch|synchronized|this|throw|throws|to|transient|transitive|try|uses|var|void|volatile|while|with|yield)\\b")),
  GrammarToken("punctuation", compileHighlightPattern("[<>(),.:]")),
  GrammarToken("operator", compileHighlightPattern("[?&|]")),
]);

final Grammar _g2 = Grammar([
  GrammarToken(
      "namespace",
      compileHighlightPattern(
          "^[a-z]\\w*(?:\\s*\\.\\s*[a-z]\\w*)*(?:\\s*\\.)?"),
      inside: () => _g3),
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);

final Grammar _g3 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);

final Grammar _g4 = Grammar([
  GrammarToken(
      "namespace",
      compileHighlightPattern(
          "^[a-z]\\w*(?:\\s*\\.\\s*[a-z]\\w*)*(?:\\s*\\.)?"),
      inside: () => _g3),
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
  GrammarToken("operator", compileHighlightPattern("\\*")),
  GrammarToken("class-name", compileHighlightPattern("\\w+")),
]);

final Grammar _g5 = Grammar([
  GrammarToken(
      "namespace",
      compileHighlightPattern(
          "^[a-z]\\w*(?:\\s*\\.\\s*[a-z]\\w*)*(?:\\s*\\.)?"),
      inside: () => _g3),
  GrammarToken("static", compileHighlightPattern("\\b\\w+\$")),
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
  GrammarToken("operator", compileHighlightPattern("\\*")),
  GrammarToken("class-name", compileHighlightPattern("\\w+")),
]);

final Grammar _g6 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);
