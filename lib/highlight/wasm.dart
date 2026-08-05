// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `wasm`.
///
/// Import this library only when you need `wasm` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightWasm {
  /// The grammar for `wasm`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("\\(;[\\s\\S]*?;\\)")),
  GrammarToken("comment", compileHighlightPattern(";;.*"), greedy: true),
  GrammarToken(
      "string", compileHighlightPattern("\"(?:\\\\[\\s\\S]|[^\"\\\\])*\""),
      greedy: true),
  GrammarToken("keyword", compileHighlightPattern("\\b(?:align|offset)="),
      inside: () => _g1),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:(?:f32|f64|i32|i64)(?:\\.(?:abs|add|and|ceil|clz|const|convert_[su]\\/i(?:32|64)|copysign|ctz|demote\\/f64|div(?:_[su])?|eqz?|extend_[su]\\/i32|floor|ge(?:_[su])?|gt(?:_[su])?|le(?:_[su])?|load(?:(?:8|16|32)_[su])?|lt(?:_[su])?|max|min|mul|neg?|nearest|or|popcnt|promote\\/f32|reinterpret\\/[fi](?:32|64)|rem_[su]|rot[lr]|shl|shr_[su]|sqrt|store(?:8|16|32)?|sub|trunc(?:_[su]\\/f(?:32|64))?|wrap\\/i64|xor))?|memory\\.(?:grow|size))\\b"),
      inside: () => _g2),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:anyfunc|block|br(?:_if|_table)?|call(?:_indirect)?|data|drop|elem|else|end|export|func|get_(?:global|local)|global|if|import|local|loop|memory|module|mut|nop|offset|param|result|return|select|set_(?:global|local)|start|table|tee_local|then|type|unreachable)\\b")),
  GrammarToken("variable",
      compileHighlightPattern("\\\$[\\w!#\$%&'*+\\-./:<=>?@\\\\^`|~]+")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "[+-]?\\b(?:\\d(?:_?\\d)*(?:\\.\\d(?:_?\\d)*)?(?:[eE][+-]?\\d(?:_?\\d)*)?|0x[\\da-fA-F](?:_?[\\da-fA-F])*(?:\\.[\\da-fA-F](?:_?[\\da-fA-D])*)?(?:[pP][+-]?\\d(?:_?\\d)*)?)\\b|\\binf\\b|\\bnan(?::0x[\\da-fA-F](?:_?[\\da-fA-D])*)?\\b")),
  GrammarToken("punctuation", compileHighlightPattern("[()]")),
]);

final Grammar _g1 = Grammar([
  GrammarToken("operator", compileHighlightPattern("=")),
]);

final Grammar _g2 = Grammar([
  GrammarToken("punctuation", compileHighlightPattern("\\.")),
]);
