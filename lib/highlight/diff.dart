// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `diff`.
///
/// Import this library only when you need `diff` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightDiff {
  /// The grammar for `diff`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("coord",
      compileHighlightPattern("^(?:\\*{3}|-{3}|\\+{3}).*\$", multiLine: true)),
  GrammarToken("coord", compileHighlightPattern("^@@.*@@\$", multiLine: true)),
  GrammarToken("coord", compileHighlightPattern("^\\d.*\$", multiLine: true)),
  GrammarToken(
      "deleted-sign",
      compileHighlightPattern("^(?:[-].*(?:\\r\\n?|\\n|(?![\\s\\S])))+",
          multiLine: true),
      alias: "deleted",
      inside: () => _g1),
  GrammarToken(
      "deleted-arrow",
      compileHighlightPattern("^(?:[<].*(?:\\r\\n?|\\n|(?![\\s\\S])))+",
          multiLine: true),
      alias: "deleted",
      inside: () => _g2),
  GrammarToken(
      "inserted-sign",
      compileHighlightPattern("^(?:[+].*(?:\\r\\n?|\\n|(?![\\s\\S])))+",
          multiLine: true),
      alias: "inserted",
      inside: () => _g3),
  GrammarToken(
      "inserted-arrow",
      compileHighlightPattern("^(?:[>].*(?:\\r\\n?|\\n|(?![\\s\\S])))+",
          multiLine: true),
      alias: "inserted",
      inside: () => _g4),
  GrammarToken(
      "unchanged",
      compileHighlightPattern("^(?:[ ].*(?:\\r\\n?|\\n|(?![\\s\\S])))+",
          multiLine: true),
      inside: () => _g5),
  GrammarToken(
      "diff",
      compileHighlightPattern("^(?:[!].*(?:\\r\\n?|\\n|(?![\\s\\S])))+",
          multiLine: true),
      alias: "bold",
      inside: () => _g6),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "line", compileHighlightPattern("(.)(?=[\\s\\S]).*(?:\\r\\n?|\\n)?"),
      lookbehind: true),
  GrammarToken("prefix", compileHighlightPattern("[\\s\\S]"), alias: "deleted"),
]);

final Grammar _g2 = Grammar([
  GrammarToken(
      "line", compileHighlightPattern("(.)(?=[\\s\\S]).*(?:\\r\\n?|\\n)?"),
      lookbehind: true),
  GrammarToken("prefix", compileHighlightPattern("[\\s\\S]"), alias: "deleted"),
]);

final Grammar _g3 = Grammar([
  GrammarToken(
      "line", compileHighlightPattern("(.)(?=[\\s\\S]).*(?:\\r\\n?|\\n)?"),
      lookbehind: true),
  GrammarToken("prefix", compileHighlightPattern("[\\s\\S]"),
      alias: "inserted"),
]);

final Grammar _g4 = Grammar([
  GrammarToken(
      "line", compileHighlightPattern("(.)(?=[\\s\\S]).*(?:\\r\\n?|\\n)?"),
      lookbehind: true),
  GrammarToken("prefix", compileHighlightPattern("[\\s\\S]"),
      alias: "inserted"),
]);

final Grammar _g5 = Grammar([
  GrammarToken(
      "line", compileHighlightPattern("(.)(?=[\\s\\S]).*(?:\\r\\n?|\\n)?"),
      lookbehind: true),
  GrammarToken("prefix", compileHighlightPattern("[\\s\\S]"),
      alias: "unchanged"),
]);

final Grammar _g6 = Grammar([
  GrammarToken(
      "line", compileHighlightPattern("(.)(?=[\\s\\S]).*(?:\\r\\n?|\\n)?"),
      lookbehind: true),
  GrammarToken("prefix", compileHighlightPattern("[\\s\\S]"), alias: "diff"),
]);
