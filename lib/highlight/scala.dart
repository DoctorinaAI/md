// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `scala`.
///
/// Import this library only when you need `scala` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightScala {
  /// The grammar for `scala`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "string-interpolation",
      compileHighlightPattern(
          "\\b[a-z]\\w*(?:\"\"\"(?:[^\$]|\\\$(?:[^{]|\\{(?:[^{}]|\\{[^{}]*\\})*\\}))*?\"\"\"|\"(?:[^\$\"\\r\\n]|\\\$(?:[^{]|\\{(?:[^{}]|\\{[^{}]*\\})*\\}))*\")",
          caseSensitive: false),
      greedy: true,
      inside: () => _g1),
  GrammarToken(
      "triple-quoted-string", compileHighlightPattern("\"\"\"[\\s\\S]*?\"\"\""),
      greedy: true, alias: "string"),
  GrammarToken(
      "char", compileHighlightPattern("'(?:\\\\.|[^'\\\\\\r\\n]){1,6}'"),
      greedy: true),
  GrammarToken("string",
      compileHighlightPattern("(\"|')(?:\\\\.|(?!\\1)[^\\\\\\r\\n])*\\1"),
      greedy: true),
  GrammarToken("annotation",
      compileHighlightPattern("(^|[^.])@\\w+(?:\\s*\\.\\s*\\w+)*"),
      lookbehind: true, alias: "punctuation"),
  GrammarToken(
      "generics",
      compileHighlightPattern(
          "<(?:[\\w\\s,.?]|&(?!&)|<(?:[\\w\\s,.?]|&(?!&)|<(?:[\\w\\s,.?]|&(?!&)|<(?:[\\w\\s,.?]|&(?!&))*>)*>)*>)*>"),
      inside: () => _g3),
  GrammarToken(
      "import",
      compileHighlightPattern(
          "(\\bimport\\s+)(?:[a-z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*|\\*)(?=\\s*;)"),
      lookbehind: true,
      inside: () => _g6),
  GrammarToken(
      "import",
      compileHighlightPattern(
          "(\\bimport\\s+static\\s+)(?:[a-z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*\\s*\\.\\s*)*(?:\\w+|\\*)(?=\\s*;)"),
      lookbehind: true,
      alias: "static",
      inside: () => _g7),
  GrammarToken(
      "namespace",
      compileHighlightPattern(
          "(\\b(?:exports|import(?:\\s+static)?|module|open|opens|package|provides|requires|to|transitive|uses|with)\\s+)(?!\\b(?:abstract|assert|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|enum|exports|extends|final|finally|float|for|goto|if|implements|import|instanceof|int|interface|long|module|native|new|non-sealed|null|open|opens|package|permits|private|protected|provides|public|record(?!\\s*[(){}[\\]<>=%~.:,;?+\\-*/&|^])|requires|return|sealed|short|static|strictfp|super|switch|synchronized|this|throw|throws|to|transient|transitive|try|uses|var|void|volatile|while|with|yield)\\b)[a-z]\\w*(?:\\.[a-z]\\w*)*\\.?"),
      lookbehind: true,
      inside: () => _g8),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "<-|=>|\\b(?:abstract|case|catch|class|def|derives|do|else|enum|extends|extension|final|finally|for|forSome|given|if|implicit|import|infix|inline|lazy|match|new|null|object|opaque|open|override|package|private|protected|return|sealed|self|super|this|throw|trait|transparent|try|type|using|val|var|while|with|yield)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0x(?:[\\da-f]*\\.)?[\\da-f]+|(?:\\b\\d+(?:\\.\\d*)?|\\B\\.\\d+)(?:e\\d+)?[dfl]?",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "(^|[^.])(?:<<=?|>>>?=?|->|--|\\+\\+|&&|\\|\\||::|[?:~]|[-+*/%&|^!=<>]=?)",
          multiLine: true),
      lookbehind: true),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
  GrammarToken(
      "builtin",
      compileHighlightPattern(
          "\\b(?:Any|AnyRef|AnyVal|Boolean|Byte|Char|Double|Float|Int|Long|Nothing|Short|String|Unit)\\b")),
  GrammarToken("symbol", compileHighlightPattern("'[^\\d\\s\\\\]\\w*")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("id", compileHighlightPattern("^\\w+"),
      greedy: true, alias: "function"),
  GrammarToken("escape", compileHighlightPattern("\\\\\\\$\"|\\\$[\$\"]"),
      greedy: true, alias: "symbol"),
  GrammarToken("interpolation",
      compileHighlightPattern("\\\$(?:\\w+|\\{(?:[^{}]|\\{[^{}]*\\})*\\})"),
      greedy: true, inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g2 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("^\\\$\\{?|\\}\$")),
  GrammarToken("expression", compileHighlightPattern("[\\s\\S]+"),
      inside: () => _g0),
]);

final Grammar _g3 = Grammar([
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(^|[^\\w.])(?:[a-z]\\w*\\s*\\.\\s*)*(?:[A-Z]\\w*\\s*\\.\\s*)*[A-Z](?:[\\d_A-Z]*[a-z]\\w*)?\\b"),
      lookbehind: true,
      inside: () => _g4),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:abstract|assert|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|enum|exports|extends|final|finally|float|for|goto|if|implements|import|instanceof|int|interface|long|module|native|new|non-sealed|null|open|opens|package|permits|private|protected|provides|public|record(?!\\s*[(){}[\\]<>=%~.:,;?+\\-*/&|^])|requires|return|sealed|short|static|strictfp|super|switch|synchronized|this|throw|throws|to|transient|transitive|try|uses|var|void|volatile|while|with|yield)\\b")),
  GrammarToken("punctuation", compileHighlightPattern("[<>(),.:]")),
  GrammarToken("operator", compileHighlightPattern("[?&|]")),
]);

final Grammar _g4 = Grammar([
  GrammarToken(
      "namespace",
      compileHighlightPattern(
          "^[a-z]\\w*(?:\\s*\\.\\s*[a-z]\\w*)*(?:\\s*\\.)?"),
      inside: () => _g5),
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);

final Grammar _g5 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);

final Grammar _g6 = Grammar([
  GrammarToken(
      "namespace",
      compileHighlightPattern(
          "^[a-z]\\w*(?:\\s*\\.\\s*[a-z]\\w*)*(?:\\s*\\.)?"),
      inside: () => _g5),
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
  GrammarToken("operator", compileHighlightPattern("\\*")),
  GrammarToken("class-name", compileHighlightPattern("\\w+")),
]);

final Grammar _g7 = Grammar([
  GrammarToken(
      "namespace",
      compileHighlightPattern(
          "^[a-z]\\w*(?:\\s*\\.\\s*[a-z]\\w*)*(?:\\s*\\.)?"),
      inside: () => _g5),
  GrammarToken("static", compileHighlightPattern("\\b\\w+\$")),
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
  GrammarToken("operator", compileHighlightPattern("\\*")),
  GrammarToken("class-name", compileHighlightPattern("\\w+")),
]);

final Grammar _g8 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);
