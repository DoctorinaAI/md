import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'markdown.dart';
import 'nodes.dart';

/// Decodes Markdown formatted strings
/// into a list of [MD$Block] objects.
const Converter<String, Markdown> markdownDecoder = MarkdownDecoder();

/// {@template markdown_decoder}
/// A [Converter] that decodes Markdown formatted strings
/// into list of [MD$Block] objects.
/// This class is designed to parse Markdown syntax
/// and convert it into a structured format
/// {@endtemplate}
class MarkdownDecoder extends Converter<String, Markdown> {
  /// Creates a new instance of [MarkdownDecoder].
  /// {@macro markdown_decoder}
  const MarkdownDecoder();

  /// A regular expression pattern to match empty lines.
  static final RegExp _emptyPattern = RegExp(r'^(?:[ \t]*)$');

  /// Leading (and trailing) `#` define atx-style headers.
  ///
  /// Starts with 1-6 unescaped `#` characters which must be followed by a
  /// space/tab or the end of the line (so `#hashtag` and 7+ `#` are not
  /// headings). Group 2 captures the heading text; a trailing run of `#`
  /// characters is stripped separately.
  static final RegExp _headingPattern =
      RegExp(r'^(#{1,6})(?:[ \t]+(.*?))?[ \t]*$');

  /// Matches an optional ATX closing sequence of `#` characters.
  static final RegExp _headingClosingPattern = RegExp(r'[ \t]+#+$');

  /// A regular expression pattern to match ordered lists.
  /// Matches lines that start with a number followed by a period
  /// or parenthesis, or with a bullet point (`*`, `+`, or `-`).
  static final RegExp _listPattern = RegExp(
      r'^(?<indent>[ \t]{0,8})(?<marker>(\d{1,9})[\.)]|[*+-])(?<text>[ \t]+(.*))?$');

  /// A regular expression pattern to match thematic breaks (horizontal rules).
  ///
  /// A thematic break is a line consisting of three or more matching
  /// `-`, `*`, or `_` characters, optionally separated by spaces or tabs,
  /// with up to three leading spaces and nothing else. For example:
  /// `---`, `***`, `___`, `- - -`, `* * *`.
  static final RegExp _thematicBreakPattern =
      RegExp(r'^ {0,3}([-*_])(?:[ \t]*\1){2,}[ \t]*$');

  /// A regular expression pattern to match GitHub alert markers,
  /// e.g. `[!NOTE]`, `[!WARNING]`. Matched case-insensitively against the
  /// first line of a blockquote.
  static final RegExp _alertPattern = RegExp(
      r'^\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]$',
      caseSensitive: false);

  /// A regular expression pattern to match a GitHub task-list checkbox at the
  /// start of a list item, e.g. `[ ] todo`, `[x] done`, `[X] done`.
  static final RegExp _taskPattern = RegExp(r'^\[([ xX])\](?:[ \t]+(.*))?$');

  /// Strips a single leading `>` (and one optional following space) from a
  /// blockquote line, matching the historical trim behavior.
  static String _stripQuoteMarker(String line) => line.substring(1).trim();

  /// Parses the per-column alignment from a table delimiter row such as
  /// `| :--- | :--: | ---: |`. Returns `null` when [line] is not a valid
  /// delimiter row (which is also used to reject malformed tables).
  static List<MD$TableColumnAlign>? _parseTableAlignments(String line) {
    if (!line.startsWith('|')) return null;
    final cells = line.split('|');
    if (cells.length < 3) return null; // Need at least one column: `|---|`.
    final inner = cells.sublist(1, cells.length - 1);
    final aligns = <MD$TableColumnAlign>[];
    for (final raw in inner) {
      final cell = raw.trim();
      // Each delimiter cell must be dashes with optional leading/trailing `:`.
      if (!RegExp(r'^:?-+:?$').hasMatch(cell)) return null;
      final left = cell.startsWith(':');
      final right = cell.endsWith(':');
      aligns.add(left && right
          ? MD$TableColumnAlign.center
          : right
              ? MD$TableColumnAlign.right
              : left
                  ? MD$TableColumnAlign.left
                  : MD$TableColumnAlign.none);
    }
    return aligns;
  }

  /// Detects a GitHub task-list checkbox at the start of [raw].
  /// Returns the remaining text and the checked state (`null` when not a task).
  static ({String text, bool? checked}) _parseTask(String raw) {
    final match = _taskPattern.firstMatch(raw);
    if (match == null) return (text: raw, checked: null);
    final mark = match.group(1)!;
    return (
      text: match.group(2)?.trim() ?? '',
      checked: mark == 'x' || mark == 'X',
    );
  }

  @override
  Markdown convert(String input) {
    final lines = LineSplitter.split(input).toList(growable: false);
    if (lines.isEmpty) return const Markdown.empty();
    final blocks = Queue<MD$Block>(); // Queue to accumulate blocks
    final length = lines.length;

    final paragraph = StringBuffer(); // To accumulate lines for paragraphs

    void maybeCommitParagraph() {
      if (paragraph.isEmpty) return;
      final text = paragraph.toString();
      paragraph.clear();
      blocks.addLast(MD$Paragraph(
        text: text,
        spans: _parseInlineSpans(text),
      ));
    }

    void pushBlock(MD$Block block) {
      maybeCommitParagraph();
      blocks.addLast(block);
    }

    for (var i = 0; i < length; i++) {
      // Trim trailing whitespace for consistent parsing
      final line = lines[i];

      // Here you would implement the logic to parse the line
      // and create the appropriate MD$Block instances.
      // This is a placeholder for demonstration purposes.
      if (line.isEmpty || _emptyPattern.hasMatch(line)) {
        /// Parse empty lines and combine them into a spacing block.
        var j = i + 1;
        for (; j < length && _emptyPattern.hasMatch(lines[j]); j++) continue;
        final count = j - i;
        pushBlock(MD$Spacer(count: count));
        if (i + count == length) break; // Last line is empty
        i = j - 1; // Skip the empty lines
        continue;
      } else if (_thematicBreakPattern.hasMatch(line)) {
        // Parse thematic breaks (horizontal rules): ---, ***, ___, - - -, etc.
        pushBlock(const MD$Divider());
        continue;
      } else if (line.startsWith('#')) {
        // Parse ATX headings (1-6 `#` followed by a space or end of line).
        final match = _headingPattern.firstMatch(line);
        if (match == null) {
          // Not a valid heading (e.g. "#hashtag" or 7+ `#`); treat as text.
          if (paragraph.isNotEmpty) paragraph.writeln();
          paragraph.write(line);
          continue;
        }
        final level = match.group(1)!.length;
        // Strip an optional closing sequence of `#` (e.g. "## Heading ##").
        final text =
            (match.group(2) ?? '').replaceFirst(_headingClosingPattern, '');
        pushBlock(MD$Heading(
            level: level, text: text, spans: _parseInlineSpans(text)));
        continue;
      } else if (line.startsWith('>')) {
        // Parse quotes and GitHub-style alerts.
        final quoteLines = <String>[_stripQuoteMarker(line)];
        var j = i + 1;
        for (; j < length && lines[j].startsWith('>'); j++) {
          quoteLines.add(_stripQuoteMarker(lines[j]));
        }
        final count = j - i;

        // A blockquote whose first line is `[!TYPE]` becomes an alert block.
        final alertMatch = _alertPattern.firstMatch(quoteLines.first);
        final alertType = alertMatch != null
            ? MD$AlertType.tryParse(alertMatch.group(1)!)
            : null;
        if (alertType != null) {
          // The alert body is everything after the marker line.
          final body = quoteLines.skip(1).join('\n').trim();
          pushBlock(MD$Alert(
            alert: alertType,
            text: body,
            spans: _parseInlineSpans(body),
          ));
        } else {
          final text = quoteLines.join('\n');
          // TODO(plugfox): Implement indentation for quotes
          // Mike Matiunin <plugfox@gmail.com>, 16 June 2025
          pushBlock(MD$Quote(
            indent: 1, // Indentation level for quotes
            text: text,
            spans: _parseInlineSpans(text),
          ));
        }
        if (i + count == length) break; // Last line is quote/alert
        i = j - 1; // Skip the consumed lines
        continue;
      } else if (line.startsWith('```') || line.startsWith('~~~')) {
        // Parse fenced code blocks (``` or ~~~).
        final fence = line.startsWith('~~~') ? '~~~' : '```';
        final language = line.length > 3 ? line.substring(3).trim() : '';
        var j = i + 1;
        for (; j < length && !lines[j].startsWith(fence); j++) continue;
        final codeText = lines.sublist(i + 1, j).join('\n');
        pushBlock(MD$Code(
          text: codeText,
          language: language,
        ));
        if (j == length - 1) break; // Last line is a code block
        i = j; // Skip to the end of the code block
        continue;
      } else if (_listPattern.firstMatch(line) case RegExpMatch match
          when match.namedGroup('indent')?.isEmpty == true) {
        final marker = match.namedGroup('marker') ?? '*';
        final firstTask = _parseTask(match.namedGroup('text')?.trim() ?? '');
        final list =
            <({int intent, String marker, String text, bool? checked})>[
          (
            intent: 0,
            marker: marker,
            text: firstTask.text,
            checked: firstTask.checked,
          )
        ];
        var j = i + 1;
        for (; j < length; j++) {
          final line = lines[j];
          final match = _listPattern.firstMatch(line);
          final indent = match?.namedGroup('indent')?.length;
          if (indent == null) break;
          final task = _parseTask(match?.namedGroup('text')?.trim() ?? '');
          list.add((
            intent: indent,
            marker: match?.namedGroup('marker') ?? '*',
            text: task.text,
            checked: task.checked,
          ));
        }
        // Convert to tree structure of [MD$ListItem]s
        var offset = 0;
        List<MD$ListItem> traverse({int indent = 0}) {
          final items = <MD$ListItem>[];
          for (; offset < list.length; offset++) {
            final item = list[offset];
            if (item.intent == indent) {
              // If the current item's indent matches,
              // we create a new list item at this level.
              items.add(MD$ListItem(
                text: item.text,
                marker: item.marker, // '•',
                spans: _parseInlineSpans(item.text),
                indent: item.intent,
                checked: item.checked,
              ));
            } else if (item.intent > indent) {
              // If the current item's indent is greater,
              // we continue traversing deeper into the list.
              final children = traverse(indent: item.intent);
              if (items.isNotEmpty) {
                // If we have a parent item, add children to it
                items.last = items.last.copyWith(
                    children: List<MD$ListItem>.unmodifiable(children));
              } else {
                // If this is the first item, just add children
                items.add(MD$ListItem(
                  marker: item.marker, // '•',
                  text: item.text,
                  spans: _parseInlineSpans(item.text),
                  indent: item.intent,
                  checked: item.checked,
                  children: children,
                ));
              }
            } else {
              // If the indent is less, we stop traversing
              offset--; // Step back to reprocess this item
              break;
            }
          }
          if (items.isEmpty) return const <MD$ListItem>[];
          return items; // Return the list of items at this level
        }

        // Create the list block with the items
        final count = j - i;
        final text = lines.sublist(i, j).join('\n');
        pushBlock(MD$List(
          text: text,
          items: traverse(),
        ));

        if (i + count == length) break; // Last line is a list item
        i = j - 1; // Skip the list items
        continue;
      } else if (line.startsWith('|')) {
        // Parse tables
        MD$TableRow textToRow(String text) {
          final cells = text.split('|');
          return MD$TableRow(
            text: text,
            cells: List<List<MD$Span>>.unmodifiable(cells
                .sublist(1, cells.length - 1)
                .map((cell) => cell.trim())
                .map(_parseInlineSpans)),
          );
        }

        final header = textToRow(line);
        // The delimiter row also carries per-column alignment.
        final alignments =
            lines.length > i + 1 ? _parseTableAlignments(lines[i + 1]) : null;
        final rows = <MD$TableRow>[];
        var j = i + 2; // Skip the header and separator line
        for (; j < length && lines[j].startsWith('|'); j++)
          rows.add(textToRow(lines[j]));
        // Validate
        final columns = header.cells.length;
        if (columns > 0 &&
            alignments != null &&
            rows.every((row) => row.cells.length == columns)) {
          // All rows have the same number of cells as the header
          final text = lines.sublist(i, j).join('\n');
          pushBlock(MD$Table(
            text: text,
            header: header,
            rows: List<MD$TableRow>.unmodifiable(rows),
            alignments: List<MD$TableColumnAlign>.unmodifiable(alignments),
          ));
        } else {
          // Table is malformed, treat it as a paragraph
          if (paragraph.isNotEmpty) paragraph.writeln();
          paragraph.write(line);
          continue;
        }

        final count = j - i;
        if (i + count == length) break; // Last line is a table row
        i = j - 1; // Skip the table rows
        continue;
      } else {
        // Parse paragraphs or other blocks
        if (paragraph.isNotEmpty) paragraph.writeln();
        paragraph.write(line);
        continue;
      }
    }

    // If there's any remaining text in the paragraph buffer, commit it
    maybeCommitParagraph();

    return Markdown(
      markdown: input,
      blocks: List<MD$Block>.unmodifiable(blocks),
    );
  }
}

/// Type of special inline markers
final Uint8List _kind = Uint8List(2048)
  ..[42] = 1 // * - italic and bold (single and double)
  ..[61] = 1 // = - highlight (double)
  ..[95] = 1 // _ - underline (double)
  ..[96] = 1 // ` - monospace (single)
  ..[124] = 1 // | - spoiler (double)
  ..[126] = 1; // ~ - strikethrough (double)

///  Markdown provides backslash escapes for the following characters:
final Uint8List _escapedChars = Uint8List(126)
  ..[33] = 1 // ! Exclamation mark
  ..[35] = 1 // # Hash mark
  ..[40] = 1 // ( Left parenthesis
  ..[41] = 1 // ) Right parenthesis
  ..[42] = 1 // * Asterisk
  ..[43] = 1 // + Plus sign
  ..[45] = 1 // - Minus sign (hyphen)
  ..[46] = 1 // . Period
  ..[91] = 1 // [ Left square bracket
  ..[92] = 1 // \ Backslash
  ..[93] = 1 // ] Right square bracket
  ..[95] = 1 // _ Underscore
  ..[96] = 1 // ` Backtick
  ..[123] = 1 // { Left curly brace
  ..[125] = 1; // } Right curly brace

/// A mapping of common LaTeX inline-math commands to their Unicode
/// equivalents. Used by [_applyInlineMath] to render simple `$...$` math
/// without a full LaTeX engine.
const Map<String, String> _mathReplacements = <String, String>{
  // Arrows
  r'\to': '→', r'\rightarrow': '→', r'\gets': '←',
  r'\leftarrow': '←', r'\leftrightarrow': '↔',
  r'\Rightarrow': '⇒', r'\Leftarrow': '⇐',
  r'\Leftrightarrow': '⇔', r'\uparrow': '↑',
  r'\downarrow': '↓', r'\mapsto': '↦',
  // Relations & operators
  r'\leq': '≤', r'\le': '≤', r'\geq': '≥', r'\ge': '≥',
  r'\neq': '≠', r'\ne': '≠', r'\approx': '≈',
  r'\equiv': '≡', r'\sim': '∼', r'\propto': '∝',
  r'\times': '×', r'\div': '÷', r'\pm': '±', r'\mp': '∓',
  r'\cdot': '⋅', r'\ast': '∗', r'\star': '⋆',
  r'\circ': '∘', r'\bullet': '∙',
  // Set theory & logic
  r'\in': '∈', r'\notin': '∉', r'\ni': '∋',
  r'\subset': '⊂', r'\subseteq': '⊆', r'\supset': '⊃',
  r'\supseteq': '⊇', r'\cup': '∪', r'\cap': '∩',
  r'\emptyset': '∅', r'\varnothing': '∅',
  r'\forall': '∀', r'\exists': '∃', r'\nexists': '∄',
  r'\neg': '¬', r'\land': '∧', r'\wedge': '∧',
  r'\lor': '∨', r'\vee': '∨',
  // Big operators & calculus
  r'\sum': '∑', r'\prod': '∏', r'\int': '∫',
  r'\infty': '∞', r'\partial': '∂', r'\nabla': '∇',
  r'\sqrt': '√', r'\angle': '∠', r'\degree': '°',
  // Dots
  r'\ldots': '…', r'\cdots': '⋯', r'\dots': '…',
  // Greek lowercase
  r'\alpha': 'α', r'\beta': 'β', r'\gamma': 'γ',
  r'\delta': 'δ', r'\epsilon': 'ε', r'\varepsilon': 'ε',
  r'\zeta': 'ζ', r'\eta': 'η', r'\theta': 'θ',
  r'\iota': 'ι', r'\kappa': 'κ', r'\lambda': 'λ',
  r'\mu': 'μ', r'\nu': 'ν', r'\xi': 'ξ', r'\pi': 'π',
  r'\rho': 'ρ', r'\sigma': 'σ', r'\tau': 'τ',
  r'\upsilon': 'υ', r'\phi': 'φ', r'\varphi': 'ϕ',
  r'\chi': 'χ', r'\psi': 'ψ', r'\omega': 'ω',
  // Greek uppercase
  r'\Gamma': 'Γ', r'\Delta': 'Δ', r'\Theta': 'Θ',
  r'\Lambda': 'Λ', r'\Xi': 'Ξ', r'\Pi': 'Π',
  r'\Sigma': 'Σ', r'\Phi': 'Φ', r'\Psi': 'Ψ',
  r'\Omega': 'Ω',
};

/// Matches a run of `$...$` inline math with tight delimiters (no space right
/// after the opening `$` or right before the closing `$`) and no `$` inside.
final RegExp _inlineMathPattern = RegExp(r'\$(\S(?:[^$]*\S)?)\$');

/// Matches a LaTeX command such as `\alpha` or `\rightarrow`.
final RegExp _mathCommandPattern = RegExp(r'\\[a-zA-Z]+');

/// Converts recognized LaTeX commands within [content] to Unicode.
/// Returns `null` when nothing was converted, so callers can leave the
/// original `$...$` text untouched (avoiding false positives like currency).
String? _convertMathContent(String content) {
  var replaced = false;
  final result = content.replaceAllMapped(_mathCommandPattern, (match) {
    final unicode = _mathReplacements[match.group(0)];
    if (unicode == null) return match.group(0)!;
    replaced = true;
    return unicode;
  });
  return replaced ? result : null;
}

/// Replaces `$...$` inline math with Unicode equivalents, leaving inline code
/// spans (delimited by backticks) untouched. Only segments that contain at
/// least one recognized LaTeX command are converted; everything else — such as
/// currency (`$5`) — is preserved verbatim.
String _applyInlineMath(String text) {
  if (!text.contains(r'$')) return text;

  String convertSegment(String segment) =>
      segment.replaceAllMapped(_inlineMathPattern, (match) {
        final converted = _convertMathContent(match.group(1)!);
        return converted ?? match.group(0)!;
      });

  // Fast path: no backticks, convert the whole string.
  if (!text.contains('`')) return convertSegment(text);

  // Otherwise, protect inline code spans while converting the rest.
  final buffer = StringBuffer();
  var segmentStart = 0;
  var i = 0;
  final length = text.length;
  while (i < length) {
    if (text.codeUnitAt(i) == 0x60 /* ` */) {
      buffer.write(convertSegment(text.substring(segmentStart, i)));
      final close = text.indexOf('`', i + 1);
      if (close == -1) {
        segmentStart = i; // Unterminated code span: treat the rest as text.
        break;
      }
      buffer.write(text.substring(i, close + 1)); // Verbatim code span.
      i = close + 1;
      segmentStart = i;
    } else {
      i++;
    }
  }
  buffer.write(convertSegment(text.substring(segmentStart)));
  return buffer.toString();
}

/// Parses a link/image destination into its URL and optional title.
///
/// Supports angle-bracketed URLs (`<url with spaces>`) and titles wrapped in
/// double quotes, single quotes, or parentheses, e.g. `url "title"`,
/// `url 'title'`, `url (title)`.
({String url, String? title}) _parseLinkTarget(String raw) {
  var rest = raw.trim();
  String url;
  if (rest.startsWith('<')) {
    final close = rest.indexOf('>');
    if (close != -1) {
      url = rest.substring(1, close);
      rest = rest.substring(close + 1).trim();
    } else {
      url = rest.substring(1);
      rest = '';
    }
  } else {
    final space = rest.indexOf(RegExp(r'[ \t]'));
    if (space == -1) {
      url = rest;
      rest = '';
    } else {
      url = rest.substring(0, space);
      rest = rest.substring(space + 1).trim();
    }
  }
  if (rest.isEmpty) return (url: url, title: null);
  // Strip a matching pair of title delimiters when present.
  final first = rest[0], last = rest[rest.length - 1];
  final quoted = rest.length >= 2 &&
      ((first == '"' && last == '"') ||
          (first == "'" && last == "'") ||
          (first == '(' && last == ')'));
  return (url: url, title: quoted ? rest.substring(1, rest.length - 1) : rest);
}

/// Whether [c] is an inline whitespace code unit (space, tab, CR, LF).
bool _isInlineSpace(int c) => c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D;

/// Whether [c] is a "word" code unit: ASCII alphanumeric or any non-ASCII
/// code unit (letters, digits, emoji). Used for intraword `_` detection.
bool _isWordChar(int c) =>
    (c >= 0x30 && c <= 0x39) || // 0-9
    (c >= 0x41 && c <= 0x5A) || // A-Z
    (c >= 0x61 && c <= 0x7A) || // a-z
    c >= 0x80; // Treat non-ASCII (Cyrillic, CJK, emoji, ...) as word chars.

/// Whether there is a non-escaped closing backtick at or after [from].
bool _hasClosingBacktick(List<int> codes, int length, int from) {
  for (var j = from; j < length; j++) {
    if (codes[j] == 0x60 /* ` */ && codes[j - 1] != 0x5C /* \ */) return true;
  }
  return false;
}

/// Whether a valid closing emphasis delimiter for [ch] (of run length
/// [markerLen]) exists at or after [from]. A closer must be right-flanking
/// (preceded by a non-space); underscore closers must also be at a word
/// boundary. Escaped characters are skipped.
bool _hasEmphasisCloser(
    List<int> codes, int length, int from, int ch, int markerLen) {
  for (var j = from; j < length; j++) {
    if (codes[j] == 0x5C /* \ */) {
      j++; // Skip the escaped character.
      continue;
    }
    if (codes[j] != ch) continue;
    if (markerLen == 2) {
      if (j + 1 < length && codes[j + 1] == ch) {
        if (j > 0 && !_isInlineSpace(codes[j - 1])) return true;
        j++; // Consume the delimiter pair.
      }
    } else if (j > 0 && !_isInlineSpace(codes[j - 1])) {
      if (ch != 0x5F /* _ */) return true;
      // Underscore: also require a word boundary after the closer.
      final after = j + 1;
      if (after >= length || !_isWordChar(codes[after])) return true;
    }
  }
  return false;
}

/// Validates an emphasis marker occurrence against CommonMark-inspired
/// flanking and word-boundary rules. Returns `true` when the marker should
/// toggle the style; `false` leaves it as literal text.
bool _emphasisValid(
    List<int> codes, int length, int i, int ch, int markerLen, bool isOpen) {
  if (isOpen) {
    // Left-flanking: a non-space must immediately follow the marker run.
    final after = i + markerLen;
    if (after >= length || _isInlineSpace(codes[after])) return false;
    // Underscore cannot open inside a word (e.g. snake_case).
    if (ch == 0x5F /* _ */ && i > 0 && _isWordChar(codes[i - 1])) return false;
    // Require a matching closer somewhere ahead.
    return _hasEmphasisCloser(codes, length, after, ch, markerLen);
  } else {
    // Right-flanking: a non-space must immediately precede the marker.
    if (i == 0 || _isInlineSpace(codes[i - 1])) return false;
    // Underscore cannot close inside a word.
    final after = i + markerLen;
    if (ch == 0x5F /* _ */ && after < length && _isWordChar(codes[after]))
      return false;
    return true;
  }
}

List<MD$Span> _parseInlineSpans(String text) {
  if (text.isEmpty) return const <MD$Span>[];

  // Resolve simple `$...$` inline math to Unicode before span parsing.
  text = _applyInlineMath(text);

  // Convert the text to a list of code units for easier processing
  // This allows us to handle UTF-16 characters correctly.
  final codes = text.codeUnits;
  final length = codes.length;

  /// Escaped characters in Markdown
  const int esc = 0x5C; // '\'

  // Phase 1: Extract links and images
  final links = <MD$Span>[];
  final skip = Uint16List(length); // Skip links during inline parsing
  {
    const img$symbol = 0x21, // '!' (33)
        label$start = 0x5B, // '[' (91)
        label$end = 0x5D, // ']' (93)
        url$start = 0x28, // '(' (40)
        url$end = 0x29; // ')' (41)
    for (var i = 0; i < length; i++) {
      final ch = codes[i];

      // Check for escaped characters
      if (ch == esc /* \ */) {
        i++; // skip next char
        continue;
      }

      // Check for links and images
      if (ch != label$start) continue;

      // Check if it's an image or a link
      final img = i > 0 && codes[i - 1] == img$symbol;

      // find closing ']' to determine the end of the label text
      var labelEnd = -1;
      for (var j = i + 1; j < codes.length; j++) {
        final cj = codes[j];
        if (cj == esc /* \ */) {
          j++; // skip escaped char
          continue;
        }
        if (cj == label$end) {
          labelEnd = j;
          break;
        }
      }

      // If there is no closing ']', there is no more links or images
      if (labelEnd == -1) break;

      // Check if the next character is a '(' for the URL
      final urlIdx = labelEnd + 1;
      if (urlIdx >= codes.length || codes[urlIdx] != url$start) continue;

      // find closing ')'
      var urlEnd = -1;
      for (var k = urlIdx + 1, opens = 0; k < codes.length; k++) {
        final ck = codes[k];
        if (ck == esc) {
          k++;
          continue; // skip escaped char
        }
        if (ck == url$start) {
          opens++; // count opening '('
        } else if (ck == url$end) {
          if (opens > 0) {
            opens--; // count closing ')'
          } else {
            urlEnd = k; // found the closing ')'
            break;
          }
        }
      }

      // If there is no closing ')', there is no more links or images
      if (urlEnd == -1) break;

      // Create a link or image span.
      final target = _parseLinkTarget(text.substring(urlIdx + 1, urlEnd));
      final src = target.url;
      final alt = target.title;
      links.add(
        MD$Span(
          start: img ? i - 1 : i, // include the '!' for images
          end: urlEnd + 1, // include the closing ')'
          text: text.substring(i + 1, labelEnd),
          style: img
              ? MD$Style.image // image style
              : MD$Style.link, // link style
          extra: <String, Object?>{
            'type': img ? 'image' : 'link',
            if (img) 'src': src else 'href': src,
            'url': src,
            if (alt != null) 'alt': alt,
          },
        ),
      );

      // Index of the link/image within `links` array.
      // This is used to skip the link/image during inline parsing.
      skip[img ? i - 1 : i] = links.length;

      // jump past the processed link
      i = urlEnd;
    }
  }

  // Phase 2: Parse inline spans
  // This is a simplified version that only handles basic inline styles.
  var start = 0; // Start index for the current span
  var mask = MD$Style.none; // Current style mask
  final spans = <MD$Span>[];

  var hasExcluded = false; // Flag to check if we have excluded characters
  late final excluded = HashSet<int>(); // Set of excluded indices
  {
    // Add span to the list of spans
    void maybePushSpan(int end) {
      if (start >= end) return; // No valid span to push
      if (hasExcluded) {
        // If we have excluded characters, we should create a new span
        // from the bytes that are not excluded.
        final spanLength = end - start - excluded.length;
        if (spanLength > 0) {
          // If the span has any valid text
          final bytes = Uint16List(spanLength);
          var j = 0; // Index for the new bytes array
          for (var i = start; i < end; i++) {
            if (excluded.contains(i)) continue; // Skip excluded indices
            bytes[j++] = codes[i]; // Copy the character to the new array
          }
          final txt = String.fromCharCodes(bytes);
          spans.add(
            MD$Span(
              start: start,
              end: end - excluded.length,
              text: txt,
              style: mask,
            ),
          );
        }
        excluded.clear(); // Clear excluded indices for the next span
        hasExcluded = false; // Reset the flag
      } else {
        // If there are no excluded characters, we can directly create the span
        // from the original text as substring.
        //final txt = String.fromCharCodes(codes, start, end);
        final txt = text.substring(start, end);
        spans.add(
          MD$Span(
            start: start,
            end: end,
            text: txt,
            style: mask,
          ),
        );
      }
    }

    for (var i = 0; i < length; i++) {
      final ch = codes[i];

      // If we are inside a monospace block, we should only look
      // for the closing backtick.
      if (mask.contains(MD$Style.monospace)) {
        if (ch == 96 /* ` */ && i > 0 && codes[i - 1] != esc /* ignore \` */) {
          // Found closing backtick
          maybePushSpan(i);
          mask ^= MD$Style.monospace;
          start = i + 1;
        }
        // We continue to the next character, ignoring any other
        // special markers.
        continue;
      }

      // If this character is part of a link or image, skip it
      if (skip[i] != 0) {
        // Finish the current span if it exists
        maybePushSpan(i);

        final link = links[skip[i] - 1];
        // Combine any active emphasis (bold/italic/...) with the link style.
        spans.add(mask.isEmpty
            ? link
            : MD$Span(
                start: link.start,
                end: link.end,
                text: link.text,
                style: MD$Style(link.style.value | mask.value),
                extra: link.extra,
              ));
        i = link.end - 1; // -1 because the loop will increment i
        start = i + 1;
        continue;
      }

      // Check for escaped characters
      if (ch == esc /* \ */ && i != length - 1) {
        final nextChar = codes[i + 1];
        // Check if the next character is an escaped character
        if (_escapedChars.length > nextChar && _escapedChars[nextChar] == 1) {
          hasExcluded = true; // We have an escaped character
          excluded.add(i); // Exclude this character as it is escaped
          i++; // skip next char

          continue;
        }
      }

      // If the character is not a special inline marker, continue
      if (_kind.length > ch && _kind[ch] == 0) continue;

      // Check if the next character is the same kind
      // This is used to determine if it's a single or double marker.
      final isDouble = i + 1 < length && codes[i + 1] == ch;

      // Monospace is handled separately: it opens only when a matching
      // closing backtick exists later on the line, otherwise the backtick is
      // treated as literal text (so unterminated code does not leak).
      if (ch == 96 /* ` */) {
        if (isDouble) {
          i++; // Double backtick is not supported; skip the next character.
          continue;
        }
        if (!_hasClosingBacktick(codes, length, i + 1)) continue; // literal `
        maybePushSpan(i);
        mask ^= MD$Style.monospace;
        start = i + 1;
        continue;
      }

      // Resolve the emphasis style and marker length for this marker.
      final ({MD$Style style, int len})? emphasis = switch (ch) {
        42 => (
            style: isDouble ? MD$Style.bold : MD$Style.italic,
            len: isDouble ? 2 : 1,
          ), // '*'
        95 => (
            style: isDouble ? MD$Style.underline : MD$Style.italic,
            len: isDouble ? 2 : 1,
          ), // '_'
        126 when isDouble => (style: MD$Style.strikethrough, len: 2), // '~~'
        61 when isDouble => (style: MD$Style.highlight, len: 2), // '=='
        124 when isDouble => (style: MD$Style.spoiler, len: 2), // '||'
        _ => null, // Lone =, |, ~ (and unknown markers) are literal.
      };
      if (emphasis == null) continue;

      // Validate the marker against flanking / word-boundary rules and require
      // a matching closer, so stray or unterminated markers stay literal
      // instead of leaking their style to the end of the line.
      final isOpen = !mask.contains(emphasis.style);
      if (!_emphasisValid(codes, length, i, ch, emphasis.len, isOpen)) continue;

      maybePushSpan(i);
      mask ^= emphasis.style;
      start = i + emphasis.len;
      if (emphasis.len == 2) i++; // Skip the second marker character.
    }
    // If we have any remaining text after the last marker, add it as a span
    maybePushSpan(length);
  }

  // This function would parse inline spans like bold, italic, links, etc.
  // For now, it returns an empty list as a placeholder.
  return spans;
}
