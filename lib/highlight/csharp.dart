// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `csharp`.
///
/// Import this library only when you need `csharp` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightCsharp {
  /// The grammar for `csharp`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment",
      compileHighlightPattern("(^|[^\\\\])\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      lookbehind: true, greedy: true),
  GrammarToken("comment", compileHighlightPattern("(^|[^\\\\:])\\/\\/.*"),
      lookbehind: true, greedy: true),
  GrammarToken(
      "interpolation-string",
      compileHighlightPattern(
          "(^|[^\\\\])(?:\\\$@|@\\\$)\"(?:\"\"|\\\\[\\s\\S]|\\{\\{|(?:\\{(?!\\{)(?:(?![}:])(?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\([^\\s\\S]*\\))*\\))*\\))*\\)))*(?::[^}\\r\\n]+)?\\})|[^\\\\{\"])*\""),
      lookbehind: true,
      greedy: true,
      inside: () => _g1),
  GrammarToken(
      "interpolation-string",
      compileHighlightPattern(
          "(^|[^@\\\\])\\\$\"(?:\\\\.|\\{\\{|(?:\\{(?!\\{)(?:(?![}:])(?:[^\"'/()]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})')|\\((?:[^\"'/()]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})')|\\((?:[^\"'/()]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})')|\\((?:[^\"'/()]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})')|\\([^\\s\\S]*\\))*\\))*\\))*\\)))*(?::[^}\\r\\n]+)?\\})|[^\\\\\"{])*\""),
      lookbehind: true,
      greedy: true,
      inside: () => _g4),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'"),
      greedy: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(^|[^\$\\\\])(?:@\"(?:\"\"|\\\\[\\s\\S]|[^\\\\\"])*\"(?!\"))"),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "(^|[^@\$\\\\])(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\")"),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "namespace",
      compileHighlightPattern(
          "(\\b(?:namespace|using)\\s+)(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*\\.\\s*(?:@?\\b[A-Za-z_]\\w*\\b))*(?=\\s*[;{])"),
      lookbehind: true,
      inside: () => _g7),
  GrammarToken(
      "type-expression",
      compileHighlightPattern(
          "(\\b(?:default|sizeof|typeof)\\s*\\(\\s*(?!\\s))(?:[^()\\s]|\\s(?!\\s)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\)))*(?=\\s*\\))"),
      lookbehind: true,
      alias: "class-name",
      inside: () => _g8),
  GrammarToken(
      "return-type",
      compileHighlightPattern(
          "(?:(?:(?:\\((?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+(?:,(?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+)+\\))|(?:(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*))(?:\\s*(?:\\?\\s*)?(?:\\[\\s*(?:,\\s*)*\\]))*(?:\\s*\\?)?)(?=\\s+(?:(?:(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*)\\s*(?:=>|[({]|\\.\\s*this\\s*\\[)|this\\s*\\[))"),
      alias: "class-name",
      inside: () => _g8),
  GrammarToken(
      "constructor-invocation",
      compileHighlightPattern(
          "(\\bnew\\s+)(?:(?:(?:\\((?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+(?:,(?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+)+\\))|(?:(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*))(?:\\s*(?:\\?\\s*)?(?:\\[\\s*(?:,\\s*)*\\]))*(?:\\s*\\?)?)(?=\\s*[[({])"),
      lookbehind: true,
      alias: "class-name",
      inside: () => _g8),
  GrammarToken(
      "generic-method",
      compileHighlightPattern(
          "(?:@?\\b[A-Za-z_]\\w*\\b)\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)(?=\\s*\\()"),
      inside: () => _g9),
  GrammarToken(
      "type-list",
      compileHighlightPattern(
          "\\b((?:(?:\\b(?:class|enum|interface|record|struct)\\b)\\s+(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)|record\\s+(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)\\s*(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|where\\s+(?:@?\\b[A-Za-z_]\\w*\\b))\\s*:\\s*)(?:(?:(?:(?:\\((?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+(?:,(?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+)+\\))|(?:(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*))(?:\\s*(?:\\?\\s*)?(?:\\[\\s*(?:,\\s*)*\\]))*(?:\\s*\\?)?)|(?:\\b(?:bool|byte|char|decimal|double|dynamic|float|int|long|object|sbyte|short|string|uint|ulong|ushort|var|void|class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b)|(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)\\s*(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\bnew\\s*\\(\\s*\\)))(?:\\s*,\\s*(?:(?:(?:(?:\\((?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+(?:,(?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+)+\\))|(?:(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*))(?:\\s*(?:\\?\\s*)?(?:\\[\\s*(?:,\\s*)*\\]))*(?:\\s*\\?)?)|(?:\\b(?:bool|byte|char|decimal|double|dynamic|float|int|long|object|sbyte|short|string|uint|ulong|ushort|var|void|class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b)|(?:\\bnew\\s*\\(\\s*\\))))*(?=\\s*(?:where|[{;]|=>|\$))"),
      lookbehind: true,
      inside: () => _g10),
  GrammarToken(
      "preprocessor", compileHighlightPattern("(^[\\t ]*)#.*", multiLine: true),
      lookbehind: true, alias: "property", inside: () => _g11),
  GrammarToken(
      "attribute",
      compileHighlightPattern(
          "((?:^|[^\\s\\w>)?])\\s*\\[\\s*)(?:(?:\\b(?:assembly|event|field|method|module|param|property|return|type)\\b)\\s*:\\s*)?(?:(?:(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*)(?:\\s*\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\([^\\s\\S]*\\))*\\))*\\))*\\))*\\))?)(?:\\s*,\\s*(?:(?:(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*)(?:\\s*\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\([^\\s\\S]*\\))*\\))*\\))*\\))*\\))?))*(?=\\s*\\])"),
      lookbehind: true,
      greedy: true,
      inside: () => _g12),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\busing\\s+static\\s+)(?:(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*)(?=\\s*;)"),
      lookbehind: true,
      inside: () => _g8),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\busing\\s+(?:@?\\b[A-Za-z_]\\w*\\b)\\s*=\\s*)(?:(?:(?:\\((?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+(?:,(?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+)+\\))|(?:(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*))(?:\\s*(?:\\?\\s*)?(?:\\[\\s*(?:,\\s*)*\\]))*(?:\\s*\\?)?)(?=\\s*;)"),
      lookbehind: true,
      inside: () => _g8),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\busing\\s+)(?:@?\\b[A-Za-z_]\\w*\\b)(?=\\s*=)"),
      lookbehind: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:\\b(?:class|enum|interface|record|struct)\\b)\\s+)(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)"),
      lookbehind: true,
      inside: () => _g8),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\bcatch\\s*\\(\\s*)(?:(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*)"),
      lookbehind: true,
      inside: () => _g8),
  GrammarToken("class-name",
      compileHighlightPattern("(\\bwhere\\s+)(?:@?\\b[A-Za-z_]\\w*\\b)"),
      lookbehind: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:is(?:\\s+not)?|as)\\s+)(?:(?:(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*)(?:\\s*(?:\\?\\s*)?(?:\\[\\s*(?:,\\s*)*\\]))*(?:\\s*\\?)?)"),
      lookbehind: true,
      inside: () => _g8),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "\\b(?:(?:(?:\\((?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+(?:,(?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+)+\\))|(?:(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*))(?:\\s*(?:\\?\\s*)?(?:\\[\\s*(?:,\\s*)*\\]))*(?:\\s*\\?)?)(?=\\s+(?!(?:\\b(?:bool|byte|char|decimal|double|dynamic|float|int|long|object|sbyte|short|string|uint|ulong|ushort|var|void|class|enum|interface|record|struct|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b)|with\\s*\\{)(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*[=,;:{)\\]]|\\s+(?:in|when)\\b))"),
      inside: () => _g8),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:bool|byte|char|decimal|double|dynamic|float|int|long|object|sbyte|short|string|uint|ulong|ushort|var|void|class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
  GrammarToken("function", compileHighlightPattern("\\b\\w+(?=\\()")),
  GrammarToken("range", compileHighlightPattern("\\.\\."), alias: "operator"),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "(?:\\b0(?:x[\\da-f_]*[\\da-f]|b[01_]*[01])|(?:\\B\\.\\d+(?:_+\\d+)*|\\b\\d+(?:_+\\d+)*(?:\\.\\d+(?:_+\\d+)*)?)(?:e[-+]?\\d+(?:_+\\d+)*)?)(?:[dflmu]|lu|ul)?\\b",
          caseSensitive: false)),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          ">>=?|<<=?|[-=]>|([-+&|])\\1|~|\\?\\?=?|[-+*/%&|^!=<>]=?")),
  GrammarToken("named-parameter",
      compileHighlightPattern("([(,]\\s*)(?:@?\\b[A-Za-z_]\\w*\\b)(?=\\s*:)"),
      lookbehind: true, alias: "punctuation"),
  GrammarToken(
      "punctuation", compileHighlightPattern("\\?\\.?|::|[{}[\\];(),.:]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^{])(?:\\{\\{)*)(?:\\{(?!\\{)(?:(?![}:])(?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\([^\\s\\S]*\\))*\\))*\\))*\\)))*(?::[^}\\r\\n]+)?\\})"),
      lookbehind: true,
      inside: () => _g2),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g2 = Grammar([
  GrammarToken(
      "format-string",
      compileHighlightPattern(
          "(^\\{(?:(?![}:])(?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\([^\\s\\S]*\\))*\\))*\\))*\\)))*)(?::[^}\\r\\n]+)(?=\\}\$)"),
      lookbehind: true,
      inside: () => _g3),
  GrammarToken("punctuation", compileHighlightPattern("^\\{|\\}\$")),
  GrammarToken("expression", compileHighlightPattern("[\\s\\S]+"),
      alias: "language-csharp", inside: () => _g0),
]);

final Grammar _g3 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("^:")),
]);

final Grammar _g4 = Grammar([
  GrammarToken(
      "interpolation",
      compileHighlightPattern(
          "((?:^|[^{])(?:\\{\\{)*)(?:\\{(?!\\{)(?:(?![}:])(?:[^\"'/()]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})')|\\((?:[^\"'/()]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})')|\\((?:[^\"'/()]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})')|\\((?:[^\"'/()]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})')|\\([^\\s\\S]*\\))*\\))*\\))*\\)))*(?::[^}\\r\\n]+)?\\})"),
      lookbehind: true,
      inside: () => _g5),
  GrammarToken("string", compileHighlightPattern("[\\s\\S]+")),
]);

final Grammar _g5 = Grammar([
  GrammarToken(
      "format-string",
      compileHighlightPattern(
          "(^\\{(?:(?![}:])(?:[^\"'/()]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})')|\\((?:[^\"'/()]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})')|\\((?:[^\"'/()]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})')|\\((?:[^\"'/()]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})')|\\([^\\s\\S]*\\))*\\))*\\))*\\)))*)(?::[^}\\r\\n]+)(?=\\}\$)"),
      lookbehind: true,
      inside: () => _g6),
  GrammarToken("punctuation", compileHighlightPattern("^\\{|\\}\$")),
  GrammarToken("expression", compileHighlightPattern("[\\s\\S]+"),
      alias: "language-csharp", inside: () => _g0),
]);

final Grammar _g6 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("^:")),
]);

final Grammar _g7 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);

final Grammar _g8 = Grammar([
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:bool|byte|char|decimal|double|dynamic|float|int|long|object|sbyte|short|string|uint|ulong|ushort|var|void|class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b")),
  GrammarToken("punctuation", compileHighlightPattern("[<>()?,.:[\\]]")),
]);

final Grammar _g9 = Grammar([
  GrammarToken(
      "function", compileHighlightPattern("^(?:@?\\b[A-Za-z_]\\w*\\b)")),
  GrammarToken(
      "generic",
      compileHighlightPattern(
          "<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>"),
      alias: "class-name",
      inside: () => _g8),
]);

final Grammar _g10 = Grammar([
  GrammarToken(
      "record-arguments",
      compileHighlightPattern(
          "(^(?!new\\s*\\()(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)\\s*)(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))"),
      lookbehind: true,
      greedy: true,
      inside: () => _g0),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:bool|byte|char|decimal|double|dynamic|float|int|long|object|sbyte|short|string|uint|ulong|ushort|var|void|class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b")),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(?:(?:\\((?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+(?:,(?:[^,()<>[\\];=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>)|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|(?:\\((?:[^()]|[^\\s\\S])*\\)))*\\)))*\\)))*\\))|(?:\\[\\s*(?:,\\s*)*\\]))+)+\\))|(?:(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*))(?:\\s*(?:\\?\\s*)?(?:\\[\\s*(?:,\\s*)*\\]))*(?:\\s*\\?)?"),
      greedy: true,
      inside: () => _g8),
  GrammarToken("punctuation", compileHighlightPattern("[,()]")),
]);

final Grammar _g11 = Grammar([
  GrammarToken(
      "directive",
      compileHighlightPattern(
          "(#)\\b(?:define|elif|else|endif|endregion|error|if|line|nullable|pragma|region|undef|warning)\\b"),
      lookbehind: true,
      alias: "keyword"),
]);

final Grammar _g12 = Grammar([
  GrammarToken(
      "target",
      compileHighlightPattern(
          "^(?:\\b(?:assembly|event|field|method|module|param|property|return|type)\\b)(?=\\s*:)"),
      alias: "keyword"),
  GrammarToken(
      "attribute-arguments",
      compileHighlightPattern(
          "\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\((?:[^\"'/()]|(?:\\/(?![*/])|\\/\\/[^\\r\\n]*[\\r\\n]|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|(?:\"(?:\\\\.|[^\\\\\"\\r\\n])*\"|'(?:[^\\r\\n'\\\\]|\\\\.|\\\\[Uux][\\da-fA-F]{1,8})'))|\\([^\\s\\S]*\\))*\\))*\\))*\\))*\\)"),
      inside: () => _g0),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(?!(?:\\b(?:class|enum|interface|record|struct|add|alias|and|ascending|async|await|by|descending|from(?=\\s*(?:\\w|\$))|get|global|group|into|init(?=\\s*;)|join|let|nameof|not|notnull|on|or|orderby|partial|remove|select|set|unmanaged|value|when|where|with(?=\\s*{)|abstract|as|base|break|case|catch|checked|const|continue|default|delegate|do|else|event|explicit|extern|finally|fixed|for|foreach|goto|if|implicit|in|internal|is|lock|namespace|new|null|operator|out|override|params|private|protected|public|readonly|ref|return|sealed|sizeof|stackalloc|static|switch|this|throw|try|typeof|unchecked|unsafe|using|virtual|volatile|while|yield)\\b))(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?)(?:\\s*\\.\\s*(?:(?:@?\\b[A-Za-z_]\\w*\\b)(?:\\s*(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|(?:<(?:[^<>;=+\\-*/%&|^]|[^\\s\\S])*>))*>))*>))*>))?))*"),
      inside: () => _g13),
  GrammarToken("punctuation", compileHighlightPattern("[:,]")),
]);

final Grammar _g13 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);
