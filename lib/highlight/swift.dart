// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `swift`.
///
/// Import this library only when you need `swift` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightSwift {
  /// The grammar for `swift`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "(^|[^\\\\:])(?:\\/\\/.*|\\/\\*(?:[^/*]|\\/(?!\\*)|\\*(?!\\/)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/)*\\*\\/)"),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "string-literal",
      compileHighlightPattern(
          "(^|[^\"#])(?:\"(?:\\\\(?:\\((?:[^()]|\\([^()]*\\))*\\)|\\r\\n|[^(])|[^\\\\\\r\\n\"])*\"|\"\"\"(?:\\\\(?:\\((?:[^()]|\\([^()]*\\))*\\)|[^(])|[^\\\\\"]|\"(?!\"\"))*\"\"\")(?![\"#])"),
      lookbehind: true,
      greedy: true,
      inside: () => _g1),
  GrammarToken(
      "string-literal",
      compileHighlightPattern(
          "(^|[^\"#])(#+)(?:\"(?:\\\\(?:#+\\((?:[^()]|\\([^()]*\\))*\\)|\\r\\n|[^#])|[^\\\\\\r\\n])*?\"|\"\"\"(?:\\\\(?:#+\\((?:[^()]|\\([^()]*\\))*\\)|[^#])|[^\\\\])*?\"\"\")\\2"),
      lookbehind: true,
      greedy: true,
      inside: () => _g2),
  GrammarToken(
      "directive",
      compileHighlightPattern(
          "#(?:(?:elseif|if)\\b(?:[ \t]*(?:![ \\t]*)?(?:\\b\\w+\\b(?:[ \\t]*\\((?:[^()]|\\([^()]*\\))*\\))?|\\((?:[^()]|\\([^()]*\\))*\\))(?:[ \\t]*(?:&&|\\|\\|))?)+|(?:else|endif)\\b)"),
      alias: "property",
      inside: () => _g3),
  GrammarToken(
      "literal",
      compileHighlightPattern(
          "#(?:colorLiteral|column|dsohandle|file(?:ID|Literal|Path)?|function|imageLiteral|line)\\b"),
      alias: "constant"),
  GrammarToken("other-directive", compileHighlightPattern("#\\w+\\b"),
      alias: "property"),
  GrammarToken("attribute", compileHighlightPattern("@\\w+"), alias: "atrule"),
  GrammarToken(
      "function-definition", compileHighlightPattern("(\\bfunc\\s+)\\w+"),
      lookbehind: true, alias: "function"),
  GrammarToken(
      "label",
      compileHighlightPattern(
          "\\b(break|continue)\\s+\\w+|\\b[a-zA-Z_]\\w*(?=\\s*:\\s*(?:for|repeat|while)\\b)"),
      lookbehind: true,
      alias: "important"),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:Any|Protocol|Self|Type|actor|as|assignment|associatedtype|associativity|async|await|break|case|catch|class|continue|convenience|default|defer|deinit|didSet|do|dynamic|else|enum|extension|fallthrough|fileprivate|final|for|func|get|guard|higherThan|if|import|in|indirect|infix|init|inout|internal|is|isolated|lazy|left|let|lowerThan|mutating|none|nonisolated|nonmutating|open|operator|optional|override|postfix|precedencegroup|prefix|private|protocol|public|repeat|required|rethrows|return|right|safe|self|set|some|static|struct|subscript|super|switch|throw|throws|try|typealias|unowned|unsafe|var|weak|where|while|willSet)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("nil", compileHighlightPattern("\\bnil\\b"), alias: "constant"),
  GrammarToken("short-argument", compileHighlightPattern("\\\$\\d+\\b")),
  GrammarToken("omit", compileHighlightPattern("\\b_\\b"), alias: "keyword"),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b(?:[\\d_]+(?:\\.[\\de_]+)?|0x[a-f0-9_]+(?:\\.[a-f0-9p_]+)?|0b[01_]+|0o[0-7_]+)\\b",
          caseSensitive: false)),
  GrammarToken("class-name",
      compileHighlightPattern("\\b[A-Z](?:[A-Z_\\d]*[a-z]\\w*)?\\b")),
  GrammarToken(
      "function",
      compileHighlightPattern("\\b[a-z_]\\w*(?=\\s*\\()",
          caseSensitive: false)),
  GrammarToken("constant",
      compileHighlightPattern("\\b(?:[A-Z_]{2,}|k[A-Z][A-Za-z_]+)\\b")),
  GrammarToken("operator",
      compileHighlightPattern("[-+*/%=!<>&|^~?]+|\\.[.\\-+*/%=!<>&|^~?]+")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\]();,.:\\\\]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("interpolation",
      compileHighlightPattern("(\\\\\\()(?:[^()]|\\([^()]*\\))*(?=\\))"),
      lookbehind: true, inside: () => _g0),
  GrammarToken(
      "interpolation-punctuation", compileHighlightPattern("^\\)|\\\\\\(\$"),
      alias: "punctuation"),
  GrammarToken("punctuation", compileHighlightPattern("\\\\(?=[\\r\\n])")),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g2 = Grammar([
  GrammarToken("interpolation",
      compileHighlightPattern("(\\\\#+\\()(?:[^()]|\\([^()]*\\))*(?=\\))"),
      lookbehind: true, inside: () => _g0),
  GrammarToken(
      "interpolation-punctuation", compileHighlightPattern("^\\)|\\\\#+\\(\$"),
      alias: "punctuation"),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g3 = Grammar([
  GrammarToken("directive-name", compileHighlightPattern("^#\\w+")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("number", compileHighlightPattern("\\b\\d+(?:\\.\\d+)*\\b")),
  GrammarToken("operator", compileHighlightPattern("!|&&|\\|\\||[<>]=?")),
  GrammarToken("punctuation", compileHighlightPattern("[(),]")),
]);
