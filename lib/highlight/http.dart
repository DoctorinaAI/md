// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';
import 'css.dart';
import 'html.dart';
import 'js.dart';
import 'json.dart';
import 'plain.dart';
import 'xml.dart';

/// Syntax grammar for `http`.
///
/// Import this library only when you need `http` highlighting; unused
/// languages are dropped from the build.
abstract final class HighlightHttp {
  /// The grammar for `http`.
  static final Grammar grammar = _g0;
}

final Grammar _g0 = Grammar([
  GrammarToken(
      "request-line",
      compileHighlightPattern(
          "^(?:CONNECT|DELETE|GET|HEAD|OPTIONS|PATCH|POST|PRI|PUT|SEARCH|TRACE)\\s(?:https?:\\/\\/|\\/)\\S*\\sHTTP\\/[\\d.]+",
          multiLine: true),
      inside: () => _g1),
  GrammarToken("response-status",
      compileHighlightPattern("^HTTP\\/[\\d.]+ \\d+ .+", multiLine: true),
      inside: () => _g2),
  GrammarToken(
      "application-javascript",
      compileHighlightPattern(
          "(content-type:\\s*application\\/javascript(?:(?:\\r\\n?|\\n)[\\w-].*)*(?:\\r(?:\\n|(?!\\n))|\\n))[^ \\t\\w-][\\s\\S]*",
          caseSensitive: false),
      lookbehind: true,
      inside: () => HighlightJs.grammar),
  GrammarToken(
      "application-json",
      compileHighlightPattern(
          "(content-type:\\s*(?:application\\/json|\\w+\\/(?:[\\w.-]+\\+)+json(?![+\\w.-]))(?:(?:\\r\\n?|\\n)[\\w-].*)*(?:\\r(?:\\n|(?!\\n))|\\n))[^ \\t\\w-][\\s\\S]*",
          caseSensitive: false),
      lookbehind: true,
      inside: () => HighlightJson.grammar),
  GrammarToken(
      "application-xml",
      compileHighlightPattern(
          "(content-type:\\s*(?:application\\/xml|\\w+\\/(?:[\\w.-]+\\+)+xml(?![+\\w.-]))(?:(?:\\r\\n?|\\n)[\\w-].*)*(?:\\r(?:\\n|(?!\\n))|\\n))[^ \\t\\w-][\\s\\S]*",
          caseSensitive: false),
      lookbehind: true,
      inside: () => HighlightXml.grammar),
  GrammarToken(
      "text-xml",
      compileHighlightPattern(
          "(content-type:\\s*text\\/xml(?:(?:\\r\\n?|\\n)[\\w-].*)*(?:\\r(?:\\n|(?!\\n))|\\n))[^ \\t\\w-][\\s\\S]*",
          caseSensitive: false),
      lookbehind: true,
      inside: () => HighlightXml.grammar),
  GrammarToken(
      "text-html",
      compileHighlightPattern(
          "(content-type:\\s*text\\/html(?:(?:\\r\\n?|\\n)[\\w-].*)*(?:\\r(?:\\n|(?!\\n))|\\n))[^ \\t\\w-][\\s\\S]*",
          caseSensitive: false),
      lookbehind: true,
      inside: () => HighlightHtml.grammar),
  GrammarToken(
      "text-css",
      compileHighlightPattern(
          "(content-type:\\s*text\\/css(?:(?:\\r\\n?|\\n)[\\w-].*)*(?:\\r(?:\\n|(?!\\n))|\\n))[^ \\t\\w-][\\s\\S]*",
          caseSensitive: false),
      lookbehind: true,
      inside: () => HighlightCss.grammar),
  GrammarToken(
      "text-plain",
      compileHighlightPattern(
          "(content-type:\\s*text\\/plain(?:(?:\\r\\n?|\\n)[\\w-].*)*(?:\\r(?:\\n|(?!\\n))|\\n))[^ \\t\\w-][\\s\\S]*",
          caseSensitive: false),
      lookbehind: true,
      inside: () => HighlightPlain.grammar),
  GrammarToken(
      "header",
      compileHighlightPattern("^[\\w-]+:.+(?:(?:\\r\\n?|\\n)[ \\t].+)*",
          multiLine: true),
      inside: () => _g3),
]);

final Grammar _g1 = Grammar([
  GrammarToken("method", compileHighlightPattern("^[A-Z]+\\b"),
      alias: "property"),
  GrammarToken("request-target",
      compileHighlightPattern("^(\\s)(?:https?:\\/\\/|\\/)\\S*(?=\\s)"),
      lookbehind: true, alias: "url"),
  GrammarToken("http-version", compileHighlightPattern("^(\\s)HTTP\\/[\\d.]+"),
      lookbehind: true, alias: "property"),
]);

final Grammar _g2 = Grammar([
  GrammarToken("http-version", compileHighlightPattern("^HTTP\\/[\\d.]+"),
      alias: "property"),
  GrammarToken("status-code", compileHighlightPattern("^(\\s)\\d+(?=\\s)"),
      lookbehind: true, alias: "number"),
  GrammarToken("reason-phrase", compileHighlightPattern("^(\\s).+"),
      lookbehind: true, alias: "string"),
]);

final Grammar _g3 = Grammar([
  GrammarToken(
      "header-value",
      compileHighlightPattern(
          "(^(?:Content-Security-Policy):[ \t]*(?![ \t]))[^]+",
          caseSensitive: false),
      lookbehind: true,
      alias: "csp"),
  GrammarToken(
      "header-value",
      compileHighlightPattern(
          "(^(?:Public-Key-Pins(?:-Report-Only)?):[ \t]*(?![ \t]))[^]+",
          caseSensitive: false),
      lookbehind: true,
      alias: "hpkp"),
  GrammarToken(
      "header-value",
      compileHighlightPattern(
          "(^(?:Strict-Transport-Security):[ \t]*(?![ \t]))[^]+",
          caseSensitive: false),
      lookbehind: true,
      alias: "hsts"),
  GrammarToken(
      "header-value",
      compileHighlightPattern("(^(?:[^:]+):[ \t]*(?![ \t]))[^]+",
          caseSensitive: false),
      lookbehind: true),
  GrammarToken("header-name", compileHighlightPattern("^[^:]+"),
      alias: "keyword"),
  GrammarToken("punctuation", compileHighlightPattern("^:")),
]);
