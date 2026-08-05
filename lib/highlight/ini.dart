// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `ini`.
///
/// Import this library only when you need `ini` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightIni {
  /// The grammar for `ini`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "comment",
      compileHighlightPattern("(^[ \\f\\t\\v]*)[#;][^\\n\\r]*",
          multiLine: true),
      lookbehind: true),
  GrammarToken(
      "section",
      compileHighlightPattern("(^[ \\f\\t\\v]*)\\[[^\\n\\r\\]]*\\]?",
          multiLine: true),
      lookbehind: true,
      inside: () => _g1),
  GrammarToken(
      "key",
      compileHighlightPattern(
          "(^[ \\f\\t\\v]*)[^ \\f\\n\\r\\t\\v=]+(?:[ \\f\\t\\v]+[^ \\f\\n\\r\\t\\v=]+)*(?=[ \\f\\t\\v]*=)",
          multiLine: true),
      lookbehind: true,
      alias: "attr-name"),
  GrammarToken(
      "value",
      compileHighlightPattern(
          "(=[ \\f\\t\\v]*)[^ \\f\\n\\r\\t\\v]+(?:[ \\f\\t\\v]+[^ \\f\\n\\r\\t\\v]+)*"),
      lookbehind: true,
      alias: "attr-value",
      inside: () => _g2),
  GrammarToken("punctuation", compileHighlightPattern("=")),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "section-name",
      compileHighlightPattern(
          "(^\\[[ \\f\\t\\v]*)[^ \\f\\t\\v\\]]+(?:[ \\f\\t\\v]+[^ \\f\\t\\v\\]]+)*"),
      lookbehind: true,
      alias: "selector"),
  GrammarToken("punctuation", compileHighlightPattern("\\[|\\]")),
]);

final Grammar _g2 = Grammar([
  GrammarToken("inner-value", compileHighlightPattern("^(\"|').+(?=\\1\$)"),
      lookbehind: true),
]);
