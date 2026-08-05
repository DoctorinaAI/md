// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `git`.
///
/// Import this library only when you need `git` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightGit {
  /// The grammar for `git`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("^#.*", multiLine: true)),
  GrammarToken("deleted", compileHighlightPattern("^[-–].*", multiLine: true)),
  GrammarToken("inserted", compileHighlightPattern("^\\+.*", multiLine: true)),
  GrammarToken("string",
      compileHighlightPattern("(\"|')(?:\\\\.|(?!\\1)[^\\\\\\r\\n])*\\1")),
  GrammarToken(
      "command", compileHighlightPattern("^.*\\\$ git .*\$", multiLine: true),
      inside: () => _g1),
  GrammarToken("coord", compileHighlightPattern("^@@.*@@\$", multiLine: true)),
  GrammarToken("commit-sha1",
      compileHighlightPattern("^commit \\w{40}\$", multiLine: true)),
]);

final Grammar _g1 = Grammar([
  GrammarToken("parameter", compileHighlightPattern("\\s--?\\w+")),
]);
