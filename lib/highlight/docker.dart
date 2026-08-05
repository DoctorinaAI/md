// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';

/// Syntax grammar for `docker`.
///
/// Import this library only when you need `docker` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightDocker {
  /// The grammar for `docker`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "instruction",
      compileHighlightPattern(
          "(^[ \\t]*)(?:ADD|ARG|CMD|COPY|ENTRYPOINT|ENV|EXPOSE|FROM|HEALTHCHECK|LABEL|MAINTAINER|ONBUILD|RUN|SHELL|STOPSIGNAL|USER|VOLUME|WORKDIR)(?=\\s)(?:\\\\.|[^\\r\\n\\\\])*(?:\\\\\$(?:\\s|#.*\$)*(?![\\s#])(?:\\\\.|[^\\r\\n\\\\])*)*",
          caseSensitive: false,
          multiLine: true),
      lookbehind: true,
      greedy: true,
      inside: () => _g1),
  GrammarToken(
      "comment", compileHighlightPattern("(^[ \\t]*)#.*", multiLine: true),
      lookbehind: true, greedy: true),
]);

final Grammar _g1 = Grammar([
  GrammarToken(
      "options",
      compileHighlightPattern(
          "(^(?:ONBUILD(?:[ \\t]+(?![ \\t])(?:\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))?|\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n])))?\\w+(?:[ \\t]+(?![ \\t])(?:\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))?|\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n])))--[\\w-]+=(?:\"(?:[^\"\\\\\\r\\n]|\\\\(?:\\r\\n|[\\s\\S]))*\"|'(?:[^'\\\\\\r\\n]|\\\\(?:\\r\\n|[\\s\\S]))*'|(?![\"'])(?:[^\\s\\\\]|\\\\.)+)(?:(?:[ \\t]+(?![ \\t])(?:\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))?|\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))--[\\w-]+=(?:\"(?:[^\"\\\\\\r\\n]|\\\\(?:\\r\\n|[\\s\\S]))*\"|'(?:[^'\\\\\\r\\n]|\\\\(?:\\r\\n|[\\s\\S]))*'|(?![\"'])(?:[^\\s\\\\]|\\\\.)+))*",
          caseSensitive: false),
      lookbehind: true,
      greedy: true,
      inside: () => _g2),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(^(?:ONBUILD(?:[ \\t]+(?![ \\t])(?:\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))?|\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n])))?HEALTHCHECK(?:[ \\t]+(?![ \\t])(?:\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))?|\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))(?:--[\\w-]+=(?:\"(?:[^\"\\\\\\r\\n]|\\\\(?:\\r\\n|[\\s\\S]))*\"|'(?:[^'\\\\\\r\\n]|\\\\(?:\\r\\n|[\\s\\S]))*'|(?![\"'])(?:[^\\s\\\\]|\\\\.)+)(?:[ \\t]+(?![ \\t])(?:\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))?|\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n])))*)(?:CMD|NONE)\\b",
          caseSensitive: false),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(^(?:ONBUILD(?:[ \\t]+(?![ \\t])(?:\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))?|\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n])))?FROM(?:[ \\t]+(?![ \\t])(?:\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))?|\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))(?:--[\\w-]+=(?:\"(?:[^\"\\\\\\r\\n]|\\\\(?:\\r\\n|[\\s\\S]))*\"|'(?:[^'\\\\\\r\\n]|\\\\(?:\\r\\n|[\\s\\S]))*'|(?![\"'])(?:[^\\s\\\\]|\\\\.)+)(?:[ \\t]+(?![ \\t])(?:\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))?|\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n])))*(?!--)[^ \\t\\\\]+(?:[ \\t]+(?![ \\t])(?:\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))?|\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n])))AS",
          caseSensitive: false),
      lookbehind: true,
      greedy: true),
  GrammarToken(
      "keyword",
      compileHighlightPattern(
          "(^ONBUILD(?:[ \\t]+(?![ \\t])(?:\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n]))?|\\\\[\\r\\n](?:\\s|\\\\[\\r\\n]|#.*(?!.))*(?![\\s#]|\\\\[\\r\\n])))\\w+",
          caseSensitive: false),
      lookbehind: true,
      greedy: true),
  GrammarToken("keyword", compileHighlightPattern("^\\w+"), greedy: true),
  GrammarToken(
      "comment", compileHighlightPattern("(^[ \\t]*)#.*", multiLine: true),
      lookbehind: true, greedy: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\"(?:[^\"\\\\\\r\\n]|\\\\(?:\\r\\n|[\\s\\S]))*\"|'(?:[^'\\\\\\r\\n]|\\\\(?:\\r\\n|[\\s\\S]))*'"),
      greedy: true),
  GrammarToken(
      "variable", compileHighlightPattern("\\\$(?:\\w+|\\{[^{}\"'\\\\]*\\})")),
  GrammarToken("operator", compileHighlightPattern("\\\\\$", multiLine: true)),
]);

final Grammar _g2 = Grammar([
  GrammarToken("property", compileHighlightPattern("(^|\\s)--[\\w-]+"),
      lookbehind: true),
  GrammarToken(
      "string",
      compileHighlightPattern(
          "\"(?:[^\"\\\\\\r\\n]|\\\\(?:\\r\\n|[\\s\\S]))*\"|'(?:[^'\\\\\\r\\n]|\\\\(?:\\r\\n|[\\s\\S]))*'"),
      greedy: true),
  GrammarToken(
      "string", compileHighlightPattern("(=)(?![\"'])(?:[^\\s\\\\]|\\\\.)+"),
      lookbehind: true),
  GrammarToken("operator", compileHighlightPattern("\\\\\$", multiLine: true)),
  GrammarToken("punctuation", compileHighlightPattern("=")),
]);
