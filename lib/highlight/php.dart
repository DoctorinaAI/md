// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `php`.
///
/// Import this library only when you need `php` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightPhp {
  /// The grammar for `php`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "delimiter",
      compileHighlightPattern("\\?>\$|^<\\?(?:php(?=\\s)|=)?",
          caseSensitive: false),
      alias: "important"),
  GrammarToken("comment",
      compileHighlightPattern("\\/\\*[\\s\\S]*?\\*\\/|\\/\\/.*|#(?!\\[).*")),
  GrammarToken("string",
      compileHighlightPattern("<<<'([^']+)'[\\r\\n](?:.*[\\r\\n])*?\\1;"),
      greedy: true, alias: "nowdoc-string", inside: () => _g1),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "<<<(?:\"([^\"]+)\"[\\r\\n](?:.*[\\r\\n])*?\\1;|([a-z_]\\w*)[\\r\\n](?:.*[\\r\\n])*?\\2;)",
          caseSensitive: false),
      greedy: true,
      alias: "heredoc-string",
      inside: () => _g3),
  GrammarToken(
      "string", compileHighlightPattern("`(?:\\\\[\\s\\S]|[^\\\\`])*`"),
      greedy: true, alias: "backtick-quoted-string"),
  GrammarToken(
      "string", compileHighlightPattern("'(?:\\\\[\\s\\S]|[^\\\\'])*'"),
      greedy: true, alias: "single-quoted-string"),
  GrammarToken(
      "string", compileHighlightPattern("\"(?:\\\\[\\s\\S]|[^\\\\\"])*\""),
      greedy: true, alias: "double-quoted-string", inside: () => _g5),
  GrammarToken(
      "attribute",
      compileHighlightPattern(
          "#\\[(?:[^\"'\\/#]|\\/(?![*/])|\\/\\/.*\$|#(?!\\[).*\$|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|\"(?:\\\\[\\s\\S]|[^\\\\\"])*\"|'(?:\\\\[\\s\\S]|[^\\\\'])*')+\\](?=\\s*[a-z\$#])",
          caseSensitive: false,
          multiLine: true),
      greedy: true,
      inside: () => _g6),
  GrammarToken("variable", compileHighlightPattern("\\\$+(?:\\w+\\b|(?=\\{))")),
  GrammarToken(
      "package",
      compileHighlightPattern(
          "(namespace\\s+|use\\s+(?:function\\s+)?)(?:\\\\?\\b[a-z_]\\w*)+\\b(?!\\\\)",
          caseSensitive: false),
      lookbehind: true,
      inside: () => _g9),
  GrammarToken(
      "class-name-definition",
      compileHighlightPattern(
          "(\\b(?:class|enum|interface|trait)\\s+)\\b[a-z_]\\w*(?!\\\\)\\b",
          caseSensitive: false),
      lookbehind: true,
      alias: "class-name"),
  GrammarToken(
      "function-definition",
      compileHighlightPattern("(\\bfunction\\s+)[a-z_]\\w*(?=\\s*\\()",
          caseSensitive: false),
      lookbehind: true,
      alias: "function"),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(\\(\\s*)\\b(?:array|bool|boolean|float|int|integer|object|string)\\b(?=\\s*\\))",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      alias: "type-casting"),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "([(,?]\\s*)\\b(?:array(?!\\s*\\()|bool|callable|(?:false|null)(?=\\s*\\|)|float|int|iterable|mixed|object|self|static|string)\\b(?=\\s*\\\$)",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      alias: "type-hint"),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(\\)\\s*:\\s*(?:\\?\\s*)?)\\b(?:array(?!\\s*\\()|bool|callable|(?:false|null)(?=\\s*\\|)|float|int|iterable|mixed|never|object|self|static|string|void)\\b",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      alias: "return-type"),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:array(?!\\s*\\()|bool|float|int|iterable|mixed|object|string|void)\\b",
          caseSensitive: false),
      greedy: true,
      alias: "type-declaration"),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(\\|\\s*)(?:false|null)\\b|\\b(?:false|null)(?=\\s*\\|)",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      alias: "type-declaration"),
  GrammarToken(
      "keyword",
      compileHighlightPattern("\\b(?:parent|self|static)(?=\\s*::)",
          caseSensitive: false),
      greedy: true,
      alias: "static-context"),
  GrammarToken("keyword",
      compileHighlightPattern("(\\byield\\s+)from\\b", caseSensitive: false),
      lookbehind: true),
  GrammarToken(
      "keyword", compileHighlightPattern("\\bclass\\b", caseSensitive: false)),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "((?:^|[^\\s>:]|(?:^|[^-])>|(?:^|[^:]):)\\s*)\\b(?:abstract|and|array|as|break|callable|case|catch|clone|const|continue|declare|default|die|do|echo|else|elseif|empty|enddeclare|endfor|endforeach|endif|endswitch|endwhile|enum|eval|exit|extends|final|finally|fn|for|foreach|function|global|goto|if|implements|include|include_once|instanceof|insteadof|interface|isset|list|match|namespace|never|new|or|parent|print|private|protected|public|readonly|require|require_once|return|self|static|switch|throw|trait|try|unset|use|var|while|xor|yield|__halt_compiler)\\b",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken(
      "argument-name",
      compileHighlightPattern("([(,]\\s*)\\b[a-z_]\\w*(?=\\s*:(?!:))",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:extends|implements|instanceof|new(?!\\s+self|\\s+static))\\s+|\\bcatch\\s*\\()\\b[a-z_]\\w*(?!\\\\)\\b",
          caseSensitive: false),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern("(\\|\\s*)\\b[a-z_]\\w*(?!\\\\)\\b",
          caseSensitive: false),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern("\\b[a-z_]\\w*(?!\\\\)\\b(?=\\s*\\|)",
          caseSensitive: false),
      greedy: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern("(\\|\\s*)(?:\\\\?\\b[a-z_]\\w*)+\\b",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      alias: "class-name-fully-qualified",
      inside: () => _g10),
  GrammarToken(
      "class-name",
      compileHighlightPattern("(?:\\\\?\\b[a-z_]\\w*)+\\b(?=\\s*\\|)",
          caseSensitive: false),
      greedy: true,
      alias: "class-name-fully-qualified",
      inside: () => _g11),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:extends|implements|instanceof|new(?!\\s+self\\b|\\s+static\\b))\\s+|\\bcatch\\s*\\()(?:\\\\?\\b[a-z_]\\w*)+\\b(?!\\\\)",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      alias: "class-name-fully-qualified",
      inside: () => _g12),
  GrammarToken(
      "class-name",
      compileHighlightPattern("\\b[a-z_]\\w*(?=\\s*\\\$)",
          caseSensitive: false),
      greedy: true,
      alias: "type-declaration"),
  GrammarToken(
      "class-name",
      compileHighlightPattern("(?:\\\\?\\b[a-z_]\\w*)+(?=\\s*\\\$)",
          caseSensitive: false),
      greedy: true,
      alias: "class-name-fully-qualified",
      inside: () => _g13),
  GrammarToken("class-name",
      compileHighlightPattern("\\b[a-z_]\\w*(?=\\s*::)", caseSensitive: false),
      greedy: true, alias: "static-context"),
  GrammarToken(
      "class-name",
      compileHighlightPattern("(?:\\\\?\\b[a-z_]\\w*)+(?=\\s*::)",
          caseSensitive: false),
      greedy: true,
      alias: "class-name-fully-qualified",
      inside: () => _g14),
  GrammarToken(
      "class-name",
      compileHighlightPattern("([(,?]\\s*)[a-z_]\\w*(?=\\s*\\\$)",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      alias: "type-hint"),
  GrammarToken(
      "class-name",
      compileHighlightPattern("([(,?]\\s*)(?:\\\\?\\b[a-z_]\\w*)+(?=\\s*\\\$)",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      alias: "class-name-fully-qualified",
      inside: () => _g15),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\)\\s*:\\s*(?:\\?\\s*)?)\\b[a-z_]\\w*(?!\\\\)\\b",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      alias: "return-type"),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\)\\s*:\\s*(?:\\?\\s*)?)(?:\\\\?\\b[a-z_]\\w*)+\\b(?!\\\\)",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      alias: "class-name-fully-qualified",
      inside: () => _g16),
  GrammarToken("constant",
      compileHighlightPattern("\\b(?:false|true)\\b", caseSensitive: false),
      alias: "boolean"),
  GrammarToken(
      "constant",
      compileHighlightPattern("(::\\s*)\\b[a-z_]\\w*\\b(?!\\s*\\()",
          caseSensitive: false),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "constant",
      compileHighlightPattern(
          "(\\b(?:case|const)\\s+)\\b[a-z_]\\w*(?=\\s*[;=])",
          caseSensitive: false),
      lookbehind: true,
      greedy: true),
  GrammarToken("constant",
      compileHighlightPattern("\\b(?:null)\\b", caseSensitive: false)),
  GrammarToken(
      "constant", compileHighlightPattern("\\b[A-Z_][A-Z0-9_]*\\b(?!\\s*\\()")),
  GrammarToken(
      "function",
      compileHighlightPattern(
          "(^|[^\\\\\\w])\\\\?[a-z_](?:[\\w\\\\]*\\w)?(?=\\s*\\()",
          caseSensitive: false),
      lookbehind: true,
      inside: () => _g17),
  GrammarToken("property", compileHighlightPattern("(->\\s*)\\w+"),
      lookbehind: true),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0b[01]+(?:_[01]+)*\\b|\\b0o[0-7]+(?:_[0-7]+)*\\b|\\b0x[\\da-f]+(?:_[\\da-f]+)*\\b|(?:\\b\\d+(?:_\\d+)*\\.?(?:\\d+(?:_\\d+)*)?|\\B\\.\\d+)(?:e[+-]?\\d+)?",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "<?=>|\\?\\?=?|\\.{3}|\\??->|[!=]=?=?|::|\\*\\*=?|--|\\+\\+|&&|\\|\\||<<|>>|[?~]|[/^|%*&<>.+-]=?")),
  GrammarToken("punctuation", compileHighlightPattern("[{}\\[\\](),:;]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "delimiter",
      compileHighlightPattern("^<<<'[^']+'|[a-z_]\\w*;\$",
          caseSensitive: false),
      alias: "symbol",
      inside: () => _g2),
]);

final Grammar _g2 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("^<<<'?|[';]\$")),
]);

final Grammar _g3 = Grammar([
  GrammarToken(
      "delimiter",
      compileHighlightPattern("^<<<(?:\"[^\"]+\"|[a-z_]\\w*)|[a-z_]\\w*;\$",
          caseSensitive: false),
      alias: "symbol",
      inside: () => _g4),
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "\\{\\\$(?:\\{(?:\\{[^{}]+\\}|[^{}]+)\\}|[^{}])+\\}|(^|[^\\\\{])\\\$+(?:\\w+(?:\\[[^\\r\\n\\[\\]]+\\]|->\\w+)?)"),
      lookbehind: true,
      inside: () => _g0),
]);

final Grammar _g4 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("^<<<\"?|[\";]\$")),
]);

final Grammar _g5 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "\\{\\\$(?:\\{(?:\\{[^{}]+\\}|[^{}]+)\\}|[^{}])+\\}|(^|[^\\\\{])\\\$+(?:\\w+(?:\\[[^\\r\\n\\[\\]]+\\]|->\\w+)?)"),
      lookbehind: true,
      inside: () => _g0),
]);

final Grammar _g6 = Grammar([
  GrammarToken(
      "attribute-content", compileHighlightPattern("^(#\\[)[\\s\\S]+(?=\\]\$)"),
      lookbehind: true, inside: () => _g7),
  GrammarToken("delimiter", compileHighlightPattern("^#\\[|\\]\$"),
      alias: "punctuation"),
]);

final Grammar _g7 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("\\/\\*[\\s\\S]*?\\*\\/|\\/\\/.*|#(?!\\[).*")),
  GrammarToken("string",
      compileHighlightPattern("<<<'([^']+)'[\\r\\n](?:.*[\\r\\n])*?\\1;"),
      greedy: true, alias: "nowdoc-string", inside: () => _g1),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "<<<(?:\"([^\"]+)\"[\\r\\n](?:.*[\\r\\n])*?\\1;|([a-z_]\\w*)[\\r\\n](?:.*[\\r\\n])*?\\2;)",
          caseSensitive: false),
      greedy: true,
      alias: "heredoc-string",
      inside: () => _g3),
  GrammarToken(
      "string", compileHighlightPattern("`(?:\\\\[\\s\\S]|[^\\\\`])*`"),
      greedy: true, alias: "backtick-quoted-string"),
  GrammarToken(
      "string", compileHighlightPattern("'(?:\\\\[\\s\\S]|[^\\\\'])*'"),
      greedy: true, alias: "single-quoted-string"),
  GrammarToken(
      "string", compileHighlightPattern("\"(?:\\\\[\\s\\S]|[^\\\\\"])*\""),
      greedy: true, alias: "double-quoted-string", inside: () => _g5),
  GrammarToken(
      "attribute-class-name",
      compileHighlightPattern("([^:]|^)\\b[a-z_]\\w*(?!\\\\)\\b",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      alias: "class-name"),
  GrammarToken(
      "attribute-class-name",
      compileHighlightPattern("([^:]|^)(?:\\\\?\\b[a-z_]\\w*)+",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      alias: "class-name",
      inside: () => _g8),
  GrammarToken("constant",
      compileHighlightPattern("\\b(?:false|true)\\b", caseSensitive: false),
      alias: "boolean"),
  GrammarToken(
      "constant",
      compileHighlightPattern("(::\\s*)\\b[a-z_]\\w*\\b(?!\\s*\\()",
          caseSensitive: false),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "constant",
      compileHighlightPattern(
          "(\\b(?:case|const)\\s+)\\b[a-z_]\\w*(?=\\s*[;=])",
          caseSensitive: false),
      lookbehind: true,
      greedy: true),
  GrammarToken("constant",
      compileHighlightPattern("\\b(?:null)\\b", caseSensitive: false)),
  GrammarToken(
      "constant", compileHighlightPattern("\\b[A-Z_][A-Z0-9_]*\\b(?!\\s*\\()")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "\\b0b[01]+(?:_[01]+)*\\b|\\b0o[0-7]+(?:_[0-7]+)*\\b|\\b0x[\\da-f]+(?:_[\\da-f]+)*\\b|(?:\\b\\d+(?:_\\d+)*\\.?(?:\\d+(?:_\\d+)*)?|\\B\\.\\d+)(?:e[+-]?\\d+)?",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "<?=>|\\?\\?=?|\\.{3}|\\??->|[!=]=?=?|::|\\*\\*=?|--|\\+\\+|&&|\\|\\||<<|>>|[?~]|[/^|%*&<>.+-]=?")),
  GrammarToken("punctuation", compileHighlightPattern("[{}\\[\\](),:;]")),
]);

final Grammar _g8 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\\\")),
]);

final Grammar _g9 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\\\")),
]);

final Grammar _g10 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\\\")),
]);

final Grammar _g11 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\\\")),
]);

final Grammar _g12 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\\\")),
]);

final Grammar _g13 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\\\")),
]);

final Grammar _g14 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\\\")),
]);

final Grammar _g15 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\\\")),
]);

final Grammar _g16 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\\\")),
]);

final Grammar _g17 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\\\")),
]);
