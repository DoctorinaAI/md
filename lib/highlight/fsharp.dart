// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `fsharp`.
///
/// Import this library only when you need `fsharp` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightFsharp {
  /// The grammar for `fsharp`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])\\(\\*(?!\\))[\\s\\S]*?\\*\\)"),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
  GrammarToken("annotation", compileHighlightPattern("\\[<.+?>\\]"),
      greedy: true, inside: () => _g1),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "'(?:[^\\\\']|\\\\(?:.|\\d{3}|x[a-fA-F\\d]{2}|u[a-fA-F\\d]{4}|U[a-fA-F\\d]{8}))'B?"),
      greedy: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(?:\"\"\"[\\s\\S]*?\"\"\"|@\"(?:\"\"|[^\"])*\"|\"(?:\\\\[\\s\\S]|[^\\\\\"])*\")B?"),
      greedy: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:exception|inherit|interface|new|of|type)\\s+|\\w\\s*:\\s*|\\s:\\??>\\s*)[.\\w]+\\b(?:\\s*(?:->|\\*)\\s*[.\\w]+\\b)*(?!\\s*[:.])"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken(
      "preprocessor", compileHighlightPattern("(^[\\t ]*)#.*", multiLine: true),
      lookbehind: true, alias: "property", inside: () => _g3),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:let|return|use|yield)(?:!\\B|\\b)|\\b(?:abstract|and|as|asr|assert|atomic|base|begin|break|checked|class|component|const|constraint|constructor|continue|default|delegate|do|done|downcast|downto|eager|elif|else|end|event|exception|extern|external|false|finally|fixed|for|fun|function|functor|global|if|in|include|inherit|inline|interface|internal|land|lazy|lor|lsl|lsr|lxor|match|member|method|mixin|mod|module|mutable|namespace|new|not|null|object|of|open|or|override|parallel|private|process|protected|public|pure|rec|sealed|select|sig|static|struct|tailcall|then|to|trait|true|try|type|upcast|val|virtual|void|volatile|when|while|with)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("function", compileHighlightPattern("\\b\\w+(?=\\()")),
  GrammarToken(
      "number", compileHighlightPattern("\\b0x[\\da-fA-F]+(?:LF|lf|un)?\\b")),
  GrammarToken("number", compileHighlightPattern("\\b0b[01]+(?:uy|y)?\\b")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "(?:\\b\\d+(?:\\.\\d*)?|\\B\\.\\d+)(?:[fm]|e[+-]?\\d+)?\\b",
          caseSensitive: false)),
  GrammarToken(
      "number", compileHighlightPattern("\\b\\d+(?:[IlLsy]|UL|u[lsy]?)?\\b")),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "([<>~&^])\\1\\1|([*.:<>&])\\2|<-|->|[!=:]=|<?\\|{1,3}>?|\\??(?:<=|>=|<>|[-+*/%=<>])\\??|[!?^&]|~[+~-]|:>|:\\?>?")),
  GrammarToken("computation-expression",
      compileHighlightPattern("\\b[_a-z]\\w*(?=\\s*\\{)", caseSensitive: false),
      alias: "keyword"),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("^\\[<|>\\]\$")),
  GrammarToken("class-name",
      compileHighlightPattern("^\\w+\$|(^|;\\s*)[A-Z]\\w*(?=\\()"),
      lookbehind: true),
  GrammarToken("annotation-content", compileHighlightPattern("[\\s\\S]+"),
      inside: () => _g0),
]);

final Grammar _g2 = Grammar([
  GrammarToken("operator", compileHighlightPattern("->|\\*")),
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);

final Grammar _g3 = Grammar([
  GrammarToken("directive",
      compileHighlightPattern("(^#)\\b(?:else|endif|if|light|line|nowarn)\\b"),
      lookbehind: true, alias: "keyword"),
]);
