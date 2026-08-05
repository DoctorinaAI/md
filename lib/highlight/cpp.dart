// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `cpp`.
///
/// Import this library only when you need `cpp` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightCpp {
  /// The grammar for `cpp`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "\\/\\/(?:[^\\r\\n\\\\]|\\\\(?:\\r\\n?|\\n|(?![\\r\\n])))*|\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      greedy: true),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n]){0,32}'"),
      greedy: true),
  GrammarToken(
      "macro",
      compileHighlightPattern(
          "(^[\\t ]*)#\\s*[a-z](?:[^\\r\\n\\\\/]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|\\\\(?:\\r\\n|[\\s\\S]))*",
          caseSensitive: false,
          multiLine: true),
      lookbehind: true,
      greedy: true,
      alias: "property",
      inside: () => _g1),
  GrammarToken(
      "module",
      compileHighlightPattern(
          "(\\b(?:import|module)\\s+)(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|<[^<>\\r\\n]*>|\\b(?!\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b)\\w+(?:\\s*\\.\\s*\\w+)*\\b(?:\\s*:\\s*\\b(?!\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b)\\w+(?:\\s*\\.\\s*\\w+)*\\b)?|:\\s*\\b(?!\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b)\\w+(?:\\s*\\.\\s*\\w+)*\\b)"),
      lookbehind: true,
      greedy: true,
      inside: () => _g2),
  GrammarToken("raw-string",
      compileHighlightPattern("R\"([^()\\\\ ]{0,16})\\([\\s\\S]*?\\)\\1\""),
      greedy: true, alias: "string"),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\""),
      greedy: true),
  GrammarToken(
      "base-clause",
      compileHighlightPattern(
          "(\\b(?:class|struct)\\s+\\w+\\s*:\\s*)[^;{}\"'\\s]+(?:\\s+[^;{}\"'\\s]+)*(?=\\s*[;{])"),
      lookbehind: true,
      greedy: true,
      inside: () => _g3),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:class|concept|enum|struct|typename)\\s+)(?!\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b)\\w+"),
      lookbehind: true),
  GrammarToken("class-name",
      compileHighlightPattern("\\b[A-Z]\\w*(?=\\s*::\\s*\\w+\\s*\\()")),
  GrammarToken(
      "class-name",
      compileHighlightPattern("\\b[A-Z_]\\w*(?=\\s*::\\s*~\\w+\\s*\\()",
          caseSensitive: false)),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "\\b\\w+(?=\\s*<(?:[^<>]|<(?:[^<>]|<[^<>]*>)*>)*>\\s*::\\s*\\w+\\s*\\()")),
  GrammarToken(
      "generic-function",
      compileHighlightPattern(
          "\\b(?!operator\\b)[a-z_]\\w*\\s*<(?:[^<>]|<[^<>]*>)*>(?=\\s*\\()",
          caseSensitive: false),
      inside: () => _g8),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b")),
  GrammarToken(
      "constant",
      compileHighlightPattern(
          "\\b(?:EOF|NULL|SEEK_CUR|SEEK_END|SEEK_SET|__DATE__|__FILE__|__LINE__|__TIMESTAMP__|__TIME__|__func__|stderr|stdin|stdout)\\b")),
  GrammarToken(
      "function",
      compileHighlightPattern("\\b[a-z_]\\w*(?=\\s*\\()",
          caseSensitive: false)),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "(?:\\b0b[01']+|\\b0x(?:[\\da-f']+(?:\\.[\\da-f']*)?|\\.[\\da-f']+)(?:p[+-]?[\\d']+)?|(?:\\b[\\d']+(?:\\.[\\d']*)?|\\B\\.[\\d']+)(?:e[+-]?[\\d']+)?)[ful]{0,4}",
          caseSensitive: false),
      greedy: true),
  GrammarToken("double-colon", compileHighlightPattern("::"),
      alias: "punctuation"),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          ">>=?|<<=?|->|--|\\+\\+|&&|\\|\\||[?:~]|<=>|[-+*/%&|^!=<>]=?|\\b(?:and|and_eq|bitand|bitor|not|not_eq|or|or_eq|xor|xor_eq)\\b")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("string", compileHighlightPattern("^(#\\s*include\\s*)<[^>]+>"),
      lookbehind: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\""),
      greedy: true),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n]){0,32}'"),
      greedy: true),
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "\\/\\/(?:[^\\r\\n\\\\]|\\\\(?:\\r\\n?|\\n|(?![\\r\\n])))*|\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      greedy: true),
  GrammarToken(
      "macro-name",
      compileHighlightPattern("(^#\\s*define\\s+)\\w+\\b(?!\\()",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken(
      "macro-name",
      compileHighlightPattern("(^#\\s*define\\s+)\\w+\\b(?=\\()",
          caseSensitive: false),
      lookbehind: true,
      alias: "function"),
  GrammarToken("directive", compileHighlightPattern("^(#\\s*)[a-z]+"),
      lookbehind: true, alias: "keyword"),
  GrammarToken("directive-hash", compileHighlightPattern("^#")),
  GrammarToken("punctuation", compileHighlightPattern("##|\\\\(?=[\\r\\n])")),
  GrammarToken("expression", compileHighlightPattern("\\S[\\s\\S]*"),
      inside: () => _g0),
]);

final Grammar _g2 = Grammar([
  GrammarToken("string", compileHighlightPattern("^[<\"][\\s\\S]+")),
  GrammarToken("operator", compileHighlightPattern(":")),
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);

final Grammar _g3 = Grammar([
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "\\/\\/(?:[^\\r\\n\\\\]|\\\\(?:\\r\\n?|\\n|(?![\\r\\n])))*|\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      greedy: true),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n]){0,32}'"),
      greedy: true),
  GrammarToken(
      "macro",
      compileHighlightPattern(
          "(^[\\t ]*)#\\s*[a-z](?:[^\\r\\n\\\\/]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|\\\\(?:\\r\\n|[\\s\\S]))*",
          caseSensitive: false,
          multiLine: true),
      lookbehind: true,
      greedy: true,
      alias: "property",
      inside: () => _g4),
  GrammarToken(
      "module",
      compileHighlightPattern(
          "(\\b(?:import|module)\\s+)(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|<[^<>\\r\\n]*>|\\b(?!\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b)\\w+(?:\\s*\\.\\s*\\w+)*\\b(?:\\s*:\\s*\\b(?!\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b)\\w+(?:\\s*\\.\\s*\\w+)*\\b)?|:\\s*\\b(?!\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b)\\w+(?:\\s*\\.\\s*\\w+)*\\b)"),
      lookbehind: true,
      greedy: true,
      inside: () => _g6),
  GrammarToken("raw-string",
      compileHighlightPattern("R\"([^()\\\\ ]{0,16})\\([\\s\\S]*?\\)\\1\""),
      greedy: true, alias: "string"),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\""),
      greedy: true),
  GrammarToken(
      "generic-function",
      compileHighlightPattern(
          "\\b(?!operator\\b)[a-z_]\\w*\\s*<(?:[^<>]|<[^<>]*>)*>(?=\\s*\\()",
          caseSensitive: false),
      inside: () => _g7),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b")),
  GrammarToken(
      "constant",
      compileHighlightPattern(
          "\\b(?:EOF|NULL|SEEK_CUR|SEEK_END|SEEK_SET|__DATE__|__FILE__|__LINE__|__TIMESTAMP__|__TIME__|__func__|stderr|stdin|stdout)\\b")),
  GrammarToken(
      "function",
      compileHighlightPattern("\\b[a-z_]\\w*(?=\\s*\\()",
          caseSensitive: false)),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "(?:\\b0b[01']+|\\b0x(?:[\\da-f']+(?:\\.[\\da-f']*)?|\\.[\\da-f']+)(?:p[+-]?[\\d']+)?|(?:\\b[\\d']+(?:\\.[\\d']*)?|\\B\\.[\\d']+)(?:e[+-]?[\\d']+)?)[ful]{0,4}",
          caseSensitive: false),
      greedy: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern("\\b[a-z_]\\w*\\b(?!\\s*::)",
          caseSensitive: false)),
  GrammarToken("double-colon", compileHighlightPattern("::"),
      alias: "punctuation"),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          ">>=?|<<=?|->|--|\\+\\+|&&|\\|\\||[?:~]|<=>|[-+*/%&|^!=<>]=?|\\b(?:and|and_eq|bitand|bitor|not|not_eq|or|or_eq|xor|xor_eq)\\b")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
]);

final Grammar _g4 = Grammar([
  GrammarToken("string", compileHighlightPattern("^(#\\s*include\\s*)<[^>]+>"),
      lookbehind: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\""),
      greedy: true),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n]){0,32}'"),
      greedy: true),
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "\\/\\/(?:[^\\r\\n\\\\]|\\\\(?:\\r\\n?|\\n|(?![\\r\\n])))*|\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      greedy: true),
  GrammarToken(
      "macro-name",
      compileHighlightPattern("(^#\\s*define\\s+)\\w+\\b(?!\\()",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken(
      "macro-name",
      compileHighlightPattern("(^#\\s*define\\s+)\\w+\\b(?=\\()",
          caseSensitive: false),
      lookbehind: true,
      alias: "function"),
  GrammarToken("directive", compileHighlightPattern("^(#\\s*)[a-z]+"),
      lookbehind: true, alias: "keyword"),
  GrammarToken("directive-hash", compileHighlightPattern("^#")),
  GrammarToken("punctuation", compileHighlightPattern("##|\\\\(?=[\\r\\n])")),
  GrammarToken("expression", compileHighlightPattern("\\S[\\s\\S]*"),
      inside: () => _g5),
]);

final Grammar _g5 = Grammar([
  GrammarToken(
      "comment",
      compileHighlightPattern(
          "\\/\\/(?:[^\\r\\n\\\\]|\\\\(?:\\r\\n?|\\n|(?![\\r\\n])))*|\\/\\*[\\s\\S]*?(?:\\*\\/|\$)"),
      greedy: true),
  GrammarToken(
      "char",
      compileHighlightPattern(
          "'(?:\\\\(?:\\r\\n|[\\s\\S])|[^'\\\\\\r\\n]){0,32}'"),
      greedy: true),
  GrammarToken(
      "macro",
      compileHighlightPattern(
          "(^[\\t ]*)#\\s*[a-z](?:[^\\r\\n\\\\/]|\\/(?!\\*)|\\/\\*(?:[^*]|\\*(?!\\/))*\\*\\/|\\\\(?:\\r\\n|[\\s\\S]))*",
          caseSensitive: false,
          multiLine: true),
      lookbehind: true,
      greedy: true,
      alias: "property",
      inside: () => _g4),
  GrammarToken(
      "module",
      compileHighlightPattern(
          "(\\b(?:import|module)\\s+)(?:\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\"|<[^<>\\r\\n]*>|\\b(?!\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b)\\w+(?:\\s*\\.\\s*\\w+)*\\b(?:\\s*:\\s*\\b(?!\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b)\\w+(?:\\s*\\.\\s*\\w+)*\\b)?|:\\s*\\b(?!\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b)\\w+(?:\\s*\\.\\s*\\w+)*\\b)"),
      lookbehind: true,
      greedy: true,
      inside: () => _g6),
  GrammarToken("raw-string",
      compileHighlightPattern("R\"([^()\\\\ ]{0,16})\\([\\s\\S]*?\\)\\1\""),
      greedy: true, alias: "string"),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\"(?:\\\\(?:\\r\\n|[\\s\\S])|[^\"\\\\\\r\\n])*\""),
      greedy: true),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "(\\b(?:class|concept|enum|struct|typename)\\s+)(?!\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b)\\w+"),
      lookbehind: true),
  GrammarToken("class-name",
      compileHighlightPattern("\\b[A-Z]\\w*(?=\\s*::\\s*\\w+\\s*\\()")),
  GrammarToken(
      "class-name",
      compileHighlightPattern("\\b[A-Z_]\\w*(?=\\s*::\\s*~\\w+\\s*\\()",
          caseSensitive: false)),
  GrammarToken(
      "class-name",
      compileHighlightPattern(
          "\\b\\w+(?=\\s*<(?:[^<>]|<(?:[^<>]|<[^<>]*>)*>)*>\\s*::\\s*\\w+\\s*\\()")),
  GrammarToken(
      "generic-function",
      compileHighlightPattern(
          "\\b(?!operator\\b)[a-z_]\\w*\\s*<(?:[^<>]|<[^<>]*>)*>(?=\\s*\\()",
          caseSensitive: false),
      inside: () => _g7),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:alignas|alignof|asm|auto|bool|break|case|catch|char|char16_t|char32_t|char8_t|class|co_await|co_return|co_yield|compl|concept|const|const_cast|consteval|constexpr|constinit|continue|decltype|default|delete|do|double|dynamic_cast|else|enum|explicit|export|extern|final|float|for|friend|goto|if|import|inline|int|int16_t|int32_t|int64_t|int8_t|long|module|mutable|namespace|new|noexcept|nullptr|operator|override|private|protected|public|register|reinterpret_cast|requires|return|short|signed|sizeof|static|static_assert|static_cast|struct|switch|template|this|thread_local|throw|try|typedef|typeid|typename|uint16_t|uint32_t|uint64_t|uint8_t|union|unsigned|using|virtual|void|volatile|wchar_t|while)\\b")),
  GrammarToken(
      "constant",
      compileHighlightPattern(
          "\\b(?:EOF|NULL|SEEK_CUR|SEEK_END|SEEK_SET|__DATE__|__FILE__|__LINE__|__TIMESTAMP__|__TIME__|__func__|stderr|stdin|stdout)\\b")),
  GrammarToken(
      "function",
      compileHighlightPattern("\\b[a-z_]\\w*(?=\\s*\\()",
          caseSensitive: false)),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "(?:\\b0b[01']+|\\b0x(?:[\\da-f']+(?:\\.[\\da-f']*)?|\\.[\\da-f']+)(?:p[+-]?[\\d']+)?|(?:\\b[\\d']+(?:\\.[\\d']*)?|\\B\\.[\\d']+)(?:e[+-]?[\\d']+)?)[ful]{0,4}",
          caseSensitive: false),
      greedy: true),
  GrammarToken("double-colon", compileHighlightPattern("::"),
      alias: "punctuation"),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          ">>=?|<<=?|->|--|\\+\\+|&&|\\|\\||[?:~]|<=>|[-+*/%&|^!=<>]=?|\\b(?:and|and_eq|bitand|bitor|not|not_eq|or|or_eq|xor|xor_eq)\\b")),
  GrammarToken("punctuation", compileHighlightPattern("[{}[\\];(),.:]")),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:false|true)\\b")),
]);

final Grammar _g6 = Grammar([
  GrammarToken("string", compileHighlightPattern("^[<\"][\\s\\S]+")),
  GrammarToken("operator", compileHighlightPattern(":")),
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);

final Grammar _g7 = Grammar([
  GrammarToken("function", compileHighlightPattern("^\\w+")),
  GrammarToken("generic", compileHighlightPattern("<[\\s\\S]+"),
      alias: "class-name", inside: () => _g5),
]);

final Grammar _g8 = Grammar([
  GrammarToken("function", compileHighlightPattern("^\\w+")),
  GrammarToken("generic", compileHighlightPattern("<[\\s\\S]+"),
      alias: "class-name", inside: () => _g0),
]);
