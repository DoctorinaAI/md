// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `r`.
///
/// Import this library only when you need `r` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightR {
  /// The grammar for `r`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken("comment", compileHighlightPattern("#.*")),
  GrammarToken("string",
      compileHighlightPattern("(['\"])(?:\\\\.|(?!\\1)[^\\\\\\r\\n])*\\1"),
      greedy: true),
  GrammarToken("percent-operator", compileHighlightPattern("%[^%\\s]*%"),
      alias: "operator"),
  GrammarToken("boolean", compileHighlightPattern("\\b(?:FALSE|TRUE)\\b")),
  GrammarToken("ellipsis", compileHighlightPattern("\\.\\.(?:\\.|\\d+)")),
  GrammarToken("number", compileHighlightPattern("\\b(?:Inf|NaN)\\b")),
  GrammarToken(
      "number",
      compileHighlightPattern(
          "(?:\\b0x[\\dA-Fa-f]+(?:\\.\\d*)?|\\b\\d+(?:\\.\\d*)?|\\B\\.\\d+)(?:[EePp][+-]?\\d+)?[iL]?")),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "\\b(?:NA|NA_character_|NA_complex_|NA_integer_|NA_real_|NULL|break|else|for|function|if|in|next|repeat|while)\\b")),
  GrammarToken(
      "operator",
      compileHighlightPattern(
          "->?>?|<(?:=|<?-)?|[>=!]=?|::?|&&?|\\|\\|?|[+*\\/^\$@~]")),
  GrammarToken("punctuation", compileHighlightPattern("[(){}\\[\\],;]")),
]);
