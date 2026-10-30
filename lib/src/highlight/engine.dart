import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// {@template highlight_grammar}
/// A syntax grammar: an ordered list of [GrammarToken] rules applied to source
/// text to produce styled spans.
///
/// Grammars are tree-shakeable: each language lives in its own library (e.g.
/// `highlight/dart.dart`) exposing a single grammar, so importing one never
/// references the others and unused languages are dropped by the compiler.
/// {@endtemplate}
final class Grammar {
  /// {@macro highlight_grammar}
  Grammar(this.tokens, {Grammar Function()? rest}) : _rest = rest;

  /// The token rules, applied in order. Earlier rules claim their text first
  /// (this ordering is what lets strings and comments swallow characters that
  /// later rules would otherwise match).
  final List<GrammarToken> tokens;

  final Grammar Function()? _rest;

  /// An additional grammar whose rules are applied after [tokens] (used by
  /// templating languages to fall back to a host grammar). Stored as a thunk so
  /// it can reference other languages without cycles.
  Grammar? get rest => _rest?.call();
}

/// Compiles a highlighting pattern. If the source uses a regex feature Dart's
/// engine rejects, returns a never-matching pattern so a single bad rule
/// disables itself instead of breaking the whole language.
RegExp compileHighlightPattern(
  String source, {
  bool caseSensitive = true,
  bool multiLine = false,
  bool dotAll = false,
  bool unicode = false,
}) {
  try {
    return RegExp(
      source,
      caseSensitive: caseSensitive,
      multiLine: multiLine,
      dotAll: dotAll,
      unicode: unicode,
    );
  } on FormatException {
    return _never;
  }
}

/// A pattern that matches nothing (no character is both `\s` and `\S`).
final RegExp _never = RegExp(r'[^\s\S]');

/// {@template highlight_grammar_token}
/// One rule of a [Grammar]: a [pattern] whose matches are tagged with [type]
/// (and optionally re-tagged via [alias]), with optional nested highlighting
/// via [inside].
/// {@endtemplate}
final class GrammarToken {
  /// {@macro highlight_grammar_token}
  GrammarToken(
    this.type,
    this.pattern, {
    this.lookbehind = false,
    this.greedy = false,
    this.alias,
    Grammar Function()? inside,
  }) : _inside = inside;

  /// The token type (the grammar key), used to look up a style in the theme.
  final String type;

  /// The pattern whose matches become tokens of this [type].
  final RegExp pattern;

  /// A "lookbehind" flag: when `true`, capture group 1 of [pattern] is treated
  /// as an unstyled prefix and excluded from the emitted token (it is *not* a
  /// regex look-behind assertion).
  final bool lookbehind;

  /// Whether this rule matches across tokens claimed by earlier rules (Prism
  /// `greedy`). A greedy match that starts in plain text swallows the tokens
  /// it overlaps, and the plain remainder is re-tokenized by the earlier
  /// rules: a string containing `#` or `//` stays a string even though the
  /// comment rule ran first. A non-greedy rule only matches within plain text.
  final bool greedy;

  /// An alternative type name that takes precedence over [type] when resolving
  /// a style (e.g. Dart's `metadata` is aliased to `function`).
  final String? alias;

  final Grammar Function()? _inside;

  /// The nested grammar used to tokenize this rule's matched text, or `null`.
  ///
  /// Stored as a thunk so grammars can reference themselves or each other
  /// without initialization cycles.
  Grammar? get inside => _inside?.call();
}

/// A theme that maps token types to text styles for code highlighting.
///
/// Implemented as a `switch` per theme (rather than a shared map or enum) so an
/// unused theme is dropped entirely by the compiler.
abstract interface class CodeHighlightTheme {
  /// The background color for the code block surface, or `null` to keep the
  /// ambient Markdown surface color.
  Color? get background;

  /// The default foreground color for untokenized code, or `null` to keep the
  /// ambient text color. Needed so a dark theme stays legible when the ambient
  /// Markdown text color is dark.
  Color? get foreground;

  /// The style for a given [tokenType], or `null` to inherit the base style.
  TextStyle? styleFor(String tokenType);
}

/// Turns the text of a fenced code block into styled [InlineSpan]s.
///
/// Assign an instance to [MarkdownThemeData.highlighter] to enable syntax
/// highlighting. The default (no highlighter) paints code as plain text.
abstract interface class SyntaxHighlighter {
  /// Returns the spans for [code], tagged for [language]. Implementations must
  /// preserve text exactly: the concatenation of the returned spans' text must
  /// equal [code], so selection and copy stay aligned. [baseStyle] is the code
  /// block's base (monospace) style, already applied to the enclosing span.
  List<InlineSpan> highlight(
      String code, String? language, TextStyle baseStyle);

  /// The background color to use for [language]'s code block, or `null` to keep
  /// the ambient surface color.
  Color? backgroundFor(String? language);

  /// The base style for [language]'s code, derived from [fallback] (the code
  /// block's monospace style). Used to apply the theme's default foreground so
  /// untokenized code stays legible on the theme background.
  TextStyle baseStyleFor(String? language, TextStyle fallback);
}

/// A [SyntaxHighlighter] driven by [Grammar]s.
///
/// The caller supplies the exact set of [languages] to support, so only the
/// grammars named here are retained; every other language is dropped by
/// tree-shaking.
///
/// ```dart
/// MarkdownHighlighter(
///   languages: {'dart': HighlightDart.grammar, 'json': HighlightJson.grammar},
///   theme: HighlightThemes.githubDark,
/// )
/// ```
final class MarkdownHighlighter implements SyntaxHighlighter {
  /// Creates a highlighter for the given [languages], styled by [theme].
  ///
  /// [languages] keys are matched case-insensitively against the fenced code
  /// block's language tag; unknown languages fall back to plain text.
  MarkdownHighlighter({
    required Map<String, Grammar> languages,
    required this.theme,
  }) : _languages = {
          for (final MapEntry<String, Grammar>(:key, :value)
              in languages.entries)
            key.toLowerCase(): value,
        };

  final Map<String, Grammar> _languages;

  /// The theme used to color tokens.
  final CodeHighlightTheme theme;

  /// The latest results, oldest first, holding at most [_maxCachedLength] code
  /// units of code. Block painters are rebuilt whenever a list item scrolls
  /// back into view and, under some themes, on every streamed chunk, for code
  /// that has not changed.
  final Map<(String, String, TextStyle), List<InlineSpan>> _cache =
      <(String, String, TextStyle), List<InlineSpan>>{};
  int _cachedLength = 0;
  static const int _maxCachedLength = 1 << 18;

  @override
  Color? backgroundFor(String? language) => theme.background;

  @override
  TextStyle baseStyleFor(String? language, TextStyle fallback) =>
      theme.foreground == null
          ? fallback
          : fallback.copyWith(color: theme.foreground);

  @override
  List<InlineSpan> highlight(
    String code,
    String? language,
    TextStyle baseStyle,
  ) {
    final grammar =
        language == null ? null : _languages[language.toLowerCase()];
    if (grammar == null) return <InlineSpan>[TextSpan(text: code)];
    final key = (language!.toLowerCase(), code, baseStyle);
    final cached = _cache.remove(key);
    if (cached != null) return _cache[key] = cached;
    final spans = _spansFor(_tokenize(code, grammar), theme, baseStyle);
    if (code.length > _maxCachedLength) return spans;
    _cache[key] = spans;
    _cachedLength += code.length;
    while (_cachedLength > _maxCachedLength) {
      final oldest = _cache.keys.first;
      _cachedLength -= oldest.$2.length;
      _cache.remove(oldest);
    }
    return spans;
  }
}

// ===========================================================================
// Tokenizer: an ordered-rule matcher. Each rule partitions the remaining plain
// text into typed spans; earlier rules (strings, comments) claim their text
// first, and nested `inside`/`rest` grammars are applied recursively.
// ===========================================================================

/// A node of the tokenized tree: either raw [_Text] or a typed [_Span].
sealed class _Node {}

final class _Text extends _Node {
  _Text(this.text);
  final String text;
}

final class _Span extends _Node {
  _Span(this.type, this.alias, this.children);
  final String type;
  final String? alias;
  final List<_Node> children;

  /// The length of the token's text (its children never change).
  late final int length = children.fold(0, (n, c) => n + _lengthOf(c));
}

/// Guards against pathological self-referential grammars.
const int _maxDepth = 24;

/// Tokenizes [text] against [grammar], returning a flat/nested node list whose
/// concatenated text equals [text] (it only partitions, never edits).
List<_Node> _tokenize(String text, Grammar grammar, [int depth = 0]) {
  final nodes = <_Node>[_Text(text)];
  if (depth < _maxDepth) _applyGrammar(nodes, grammar, depth);
  return nodes;
}

/// Applies [grammar]'s rules (then its [Grammar.rest]) across [nodes] in place.
void _applyGrammar(List<_Node> nodes, Grammar grammar, int depth) {
  _applyRules(nodes, grammar.tokens, grammar.tokens.length, depth);
  final rest = grammar.rest;
  if (rest != null && depth < _maxDepth) _applyGrammar(nodes, rest, depth + 1);
}

/// Applies the first [count] of [rules] across [nodes] in place.
void _applyRules(
  List<_Node> nodes,
  List<GrammarToken> rules,
  int count,
  int depth,
) {
  for (var r = 0; r < count; r++) {
    final rule = rules[r];
    if (rule.greedy) {
      _applyGreedy(nodes, rules, r, depth);
    } else {
      _applyPlain(nodes, rule, depth, 0);
    }
  }
}

/// Applies the non-greedy [rule] to every plain node of `nodes[from..]`, in
/// place. Builds the result in one pass (splicing per match would be
/// quadratic in the node count).
void _applyPlain(List<_Node> nodes, GrammarToken rule, int depth, int from) {
  List<_Node>? out;
  for (var i = from; i < nodes.length; i++) {
    final node = nodes[i];
    final replacement =
        node is _Text ? _applyRule(node.text, rule, depth) : null;
    if (replacement == null) {
      out?.add(node);
      continue;
    }
    out ??= nodes.sublist(0, i);
    out.addAll(replacement);
  }
  if (out != null) {
    nodes
      ..clear()
      ..addAll(out);
  }
}

/// The text length of [node].
int _lengthOf(_Node node) => switch (node) {
      _Text(:final text) => text.length,
      _Span(:final length) => length,
    };

/// How many matches a greedy rule may discard (they start inside another
/// token) before it falls back to matching plain text only: each discard
/// re-searches the rest of the text, so pathological input would turn
/// quadratic.
const int _maxGreedySkips = 256;

/// Applies the greedy rule `rules[r]` across [nodes] (Prism's `greedy`): it
/// matches the whole text, so a match may span tokens claimed by earlier
/// rules. A match must start in plain text; it replaces the nodes it
/// overlaps, plus the plain text right after them, with the new token and the
/// plain text around it. When it swallowed a token, that leftover text is
/// re-tokenized by the rules before `r`.
void _applyGreedy(
  List<_Node> nodes,
  List<GrammarToken> rules,
  int r,
  int depth,
) {
  final rule = rules[r];
  final full = StringBuffer();
  for (final node in nodes) {
    _write(node, full);
  }
  final text = full.toString();
  // `nodes[i..]` is the unprocessed input (starting at text offset
  // `nodeStart`); [out] collects the result.
  final out = <_Node>[];
  var i = 0, nodeStart = 0, from = 0, skips = 0;
  var changed = false;
  while (i < nodes.length && from < text.length) {
    final match = rule.pattern.allMatches(text, from).firstOrNull;
    if (match == null) break;
    var start = match.start;
    if (rule.lookbehind && match.groupCount >= 1) {
      start += match.group(1)?.length ?? 0;
    }
    final end = match.end;
    if (start >= end || start < nodeStart) {
      from = end > match.start ? end : match.start + 1;
      continue;
    }
    // The node holding the match start.
    while (i < nodes.length && nodeStart + _lengthOf(nodes[i]) <= start) {
      nodeStart += _lengthOf(nodes[i]);
      out.add(nodes[i++]);
    }
    if (i >= nodes.length) break;
    if (nodes[i] is _Span) {
      // Starts inside another token: not a match here.
      from = nodeStart + _lengthOf(nodes[i]);
      if (++skips > _maxGreedySkips) break;
      continue;
    }
    // The nodes the match overlaps, then any plain text right after them.
    var j = i, stop = nodeStart + _lengthOf(nodes[i]);
    var swallowed = false;
    while (j + 1 < nodes.length && (stop < end || nodes[j + 1] is _Text)) {
      j++;
      swallowed = swallowed || nodes[j] is _Span;
      stop += _lengthOf(nodes[j]);
    }
    final matched = text.substring(start, end);
    final inside = rule.inside;
    if (start > nodeStart) out.add(_Text(text.substring(nodeStart, start)));
    out.add(_Span(
      rule.type,
      rule.alias,
      inside == null
          ? <_Node>[_Text(matched)]
          : _tokenize(matched, inside, depth + 1),
    ));
    changed = true;
    final after = <_Node>[
      if (end < stop) _Text(text.substring(end, stop)),
    ];
    if (swallowed && after.isNotEmpty) _applyRules(after, rules, r, depth);
    // The leftover is still input for this rule: put it back in front of
    // `nodes[j + 1..]`, reusing the consumed slots when they suffice.
    final k = j + 1 - after.length;
    if (k >= i) {
      nodes.setRange(k, j + 1, after);
      i = k;
    } else {
      nodes.replaceRange(i, j + 1, after);
    }
    nodeStart = end;
    from = end;
  }
  if (!changed) {
    // Nothing matched (or every match started inside a token).
    if (skips > _maxGreedySkips) _applyPlain(nodes, rule, depth, 0);
    return;
  }
  final rest = nodes.sublist(i);
  if (skips > _maxGreedySkips) _applyPlain(rest, rule, depth, 0);
  nodes
    ..clear()
    ..addAll(out)
    ..addAll(rest);
}

/// Writes the text of [node] to [out].
void _write(_Node node, StringBuffer out) {
  switch (node) {
    case _Text(:final text):
      out.write(text);
    case _Span(:final children):
      for (final child in children) {
        _write(child, out);
      }
  }
}

/// Applies a single [rule] to a plain [text] segment. Returns `null` when the
/// rule does not match (so the caller can leave the segment untouched).
List<_Node>? _applyRule(String text, GrammarToken rule, int depth) {
  List<_Node>? out;
  var pos = 0;
  for (final match in rule.pattern.allMatches(text)) {
    var start = match.start;
    var matched = match.group(0)!;
    if (rule.lookbehind) {
      final group = match.groupCount >= 1 ? match.group(1) : null;
      // A group inside a lookahead can outrun the match.
      final lead = math.min(group?.length ?? 0, matched.length);
      start += lead;
      matched = matched.substring(lead);
    }
    if (matched.isEmpty) continue;
    out ??= <_Node>[];
    if (start > pos) out.add(_Text(text.substring(pos, start)));
    final inside = rule.inside;
    out.add(_Span(
      rule.type,
      rule.alias,
      inside == null
          ? <_Node>[_Text(matched)]
          : _tokenize(matched, inside, depth + 1),
    ));
    pos = start + matched.length;
  }
  if (out == null) return null;
  if (pos < text.length) out.add(_Text(text.substring(pos)));
  return out;
}

/// The style of a token at some depth of the tree, resolved once per path of
/// token types: a code block has thousands of tokens but few distinct paths.
final class _Resolved {
  _Resolved(this.style, {required TextStyle base})
      : plain = style == null || base.merge(style) == base,
        colorOnly = style == null ||
            (style.foreground == null &&
                base.foreground == null &&
                base.merge(style).copyWith(color: base.color) == base);

  /// The style relative to the code block's base, `null` at the root.
  final TextStyle? style;

  /// Whether this paints exactly like the base style.
  final bool plain;

  /// Whether this differs from the base by color at most, so white space
  /// painted in it looks the same as in any other such style.
  final bool colorOnly;

  final Map<String, _Resolved> _children = <String, _Resolved>{};

  _Resolved child(_Span span, CodeHighlightTheme theme, TextStyle base) =>
      _children[span.alias == null
          ? span.type
          : '${span.type} ${span.alias}'] ??= () {
        final own = (span.alias == null ? null : theme.styleFor(span.alias!)) ??
            theme.styleFor(span.type);
        final parent = style;
        return _Resolved(
          parent == null || own == null ? parent ?? own : parent.merge(own),
          base: base,
        );
      }();
}

/// Whether [text] holds only spaces and line breaks.
bool _isBlank(String text) {
  for (var i = 0; i < text.length; i++) {
    switch (text.codeUnitAt(i)) {
      case 0x20 || 0x09 || 0x0A || 0x0D:
        continue;
      default:
        return false;
    }
  }
  return true;
}

/// Converts the tokenized tree into a flat list of [TextSpan]s with one span
/// per run of text painted alike. Every span pushes a style into the paragraph
/// and paints separately, so tokens that do not change what is on screen
/// (punctuation in the foreground color, the blanks between two words) must not
/// cost a span.
List<InlineSpan> _spansFor(
  List<_Node> nodes,
  CodeHighlightTheme theme,
  TextStyle base,
) {
  final out = <InlineSpan>[];
  final run = StringBuffer();
  var runBlank = true;
  _Resolved? runStyle;

  void flush() {
    if (run.isEmpty) return;
    final style = runStyle;
    out.add(TextSpan(
      text: run.toString(),
      style: style == null || style.plain ? null : style.style,
    ));
    run.clear();
    runBlank = true;
  }

  void write(String text, _Resolved resolved) {
    if (text.isEmpty) return;
    final blank = _isBlank(text);
    final current = runStyle;
    if (current == null) {
      runStyle = resolved;
    } else if (!identical(current, resolved) &&
        !(current.plain && resolved.plain) &&
        current.style != resolved.style) {
      // Blanks show no color: they join the run on the left, and a run of them
      // takes the color of what follows.
      if (resolved.colorOnly && current.colorOnly) {
        if (blank) {
          run.write(text);
          return;
        }
        if (runBlank) {
          runStyle = resolved;
          runBlank = false;
          run.write(text);
          return;
        }
      }
      flush();
      runStyle = resolved;
    }
    runBlank = runBlank && blank;
    run.write(text);
  }

  final root = _Resolved(null, base: base);
  void visit(List<_Node> nodes, _Resolved parent) {
    for (final node in nodes) {
      switch (node) {
        case _Text(:final text):
          write(text, parent);
        case _Span(:final children):
          visit(children, parent.child(node, theme, base));
      }
    }
  }

  visit(nodes, root);
  flush();
  return out;
}
