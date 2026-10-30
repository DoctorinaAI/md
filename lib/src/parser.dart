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
  ///
  /// Set [inlineMath] to `true` to convert simple `$...$` inline LaTeX math to
  /// Unicode (disabled by default). Provide [mathReplacements] to override the
  /// built-in command table ([kMarkdownMathCommands]); when omitted, the
  /// defaults are used.
  /// {@macro markdown_decoder}
  const MarkdownDecoder({
    this.inlineMath = false,
    this.mathReplacements,
  });

  /// Whether to convert simple `$...$` inline LaTeX math (e.g. `$\alpha$`,
  /// `$x^2$`, `$H_2O$`) to Unicode.
  ///
  /// Disabled by default so that literal dollar signs — prices (`$5`), shell
  /// variables (`$HOME`), and the like — are never altered. Enable it with
  /// `const MarkdownDecoder(inlineMath: true)` or via
  /// `Markdown.fromString(text, inlineMath: true)`.
  final bool inlineMath;

  /// Optional override for the LaTeX command → Unicode table used when
  /// [inlineMath] is enabled. Defaults to [kMarkdownMathCommands].
  ///
  /// To extend rather than replace the defaults, spread them:
  /// `mathReplacements: {...kMarkdownMathCommands, r'\R': 'ℝ'}`.
  final Map<String, String>? mathReplacements;

  /// Whether [line] is blank (empty or only spaces/tabs). Replaces a regular
  /// expression on the hot path of the block loop, since blank-line detection
  /// runs for every line of the document.
  static bool _isBlank(String line) {
    for (var i = 0; i < line.length; i++) {
      final c = line.codeUnitAt(i);
      if (c != 0x20 && c != 0x09) return false;
    }
    return true;
  }

  /// How many quote levels are re-parsed as nested blocks. A deeper quote body
  /// is inline text, like one without a fence: every level re-parses the whole
  /// body, and the recursion would otherwise follow the input's depth.
  static const int _maxQuoteDepth = 32;

  /// Parses an ATX heading [line] into its level and text, or returns `null`
  /// when the line is not a heading.
  ///
  /// Starts with 1-6 `#` characters which must be followed by a space/tab or
  /// the end of the line (so `#hashtag` and 7+ `#` are not headings). Trailing
  /// whitespace and an optional closing run of `#` are stripped. A hand-rolled
  /// scan, because the equivalent regular expressions backtrack over a run of
  /// spaces inside the text: 32 KB of them took more than 15 seconds.
  static ({int level, String text})? _parseHeading(String line) {
    final len = line.length;
    var level = 0;
    while (level < len && line.codeUnitAt(level) == 0x23 /* # */) {
      if (++level > 6) return null;
    }
    // Headings hold a single line, and these are line terminators to `.` too.
    for (var k = level; k < len; k++) {
      final c = line.codeUnitAt(k);
      if (c == 0x0A || c == 0x0D || c == 0x2028 || c == 0x2029) return null;
    }
    if (level == len) return (level: level, text: '');
    if (!_isHeadingSpace(line.codeUnitAt(level))) return null;
    var start = level + 1, end = len;
    while (start < end && _isHeadingSpace(line.codeUnitAt(start))) start++;
    while (end > start && _isHeadingSpace(line.codeUnitAt(end - 1))) end--;
    // A closing run counts only when whitespace separates it from the text.
    var hash = end;
    while (hash > start && line.codeUnitAt(hash - 1) == 0x23 /* # */) hash--;
    if (hash < end &&
        hash > start &&
        _isHeadingSpace(line.codeUnitAt(hash - 1))) {
      end = hash - 1;
      while (end > start && _isHeadingSpace(line.codeUnitAt(end - 1))) end--;
    }
    return (level: level, text: line.substring(start, end));
  }

  /// Whether [c] separates a heading's markers from its text (space or tab).
  static bool _isHeadingSpace(int c) => c == 0x20 || c == 0x09;

  /// Parses a list-item [line] into its indent width, marker, and trailing
  /// text, or returns `null` when the line is not a list item.
  ///
  /// This is a hand-rolled replacement for the named-group regular expression
  /// `^([ \t]{0,8})((\d{1,9})[.)]|[*+-])([ \t]+.*)?$`, which previously ran for
  /// every candidate line (once to open a list, then once per line to find its
  /// end). The returned [text] still includes leading whitespace, matching the
  /// old capture group; callers trim it as before.
  static ({int indent, String marker, String text})? _parseListLine(
      String line) {
    final len = line.length;
    // Leading indent: at most 8 spaces or tabs.
    var i = 0;
    while (i < len &&
        i < 8 &&
        (line.codeUnitAt(i) == 0x20 || line.codeUnitAt(i) == 0x09)) {
      i++;
    }
    if (i >= len) return null;
    final indent = i;
    final c = line.codeUnitAt(i);
    final String marker;
    final int textStart;
    if (c >= 0x30 && c <= 0x39) {
      // Ordered marker: 1-9 digits followed by '.' or ')'.
      var d = i;
      while (d < len &&
          d - i < 9 &&
          line.codeUnitAt(d) >= 0x30 &&
          line.codeUnitAt(d) <= 0x39) {
        d++;
      }
      if (d >= len) return null;
      final delim = line.codeUnitAt(d);
      if (delim != 0x2E /* . */ && delim != 0x29 /* ) */) return null;
      marker = line.substring(i, d + 1);
      textStart = d + 1;
    } else if (c == 0x2A /* * */ || c == 0x2B /* + */ || c == 0x2D /* - */) {
      marker = line.substring(i, i + 1);
      textStart = i + 1;
    } else {
      return null;
    }
    if (textStart >= len) return (indent: indent, marker: marker, text: '');
    // The marker must be followed by whitespace (or the end of the line).
    final nc = line.codeUnitAt(textStart);
    if (nc != 0x20 && nc != 0x09) return null;
    return (indent: indent, marker: marker, text: line.substring(textStart));
  }

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

  /// A regular expression pattern to match one table delimiter cell: dashes
  /// with an optional leading and/or trailing `:`, e.g. `---`, `:-:`, `--:`.
  static final RegExp _tableDelimiterCellPattern = RegExp(r'^:?-+:?$');

  /// Strips a single leading `>` (and one optional following space) from a
  /// blockquote line, matching the historical trim behavior.
  static String _stripQuoteMarker(String line) => line.substring(1).trim();

  /// Strips a single leading `>` and at most one following space, keeping the
  /// rest of the line verbatim. Unlike [_stripQuoteMarker], this preserves
  /// indentation, so a body re-parsed as nested blocks keeps the leading
  /// whitespace of fenced code lines.
  static String _stripQuoteMarkerRaw(String line) =>
      line.length > 1 && line.codeUnitAt(1) == 0x20 /* space */
          ? line.substring(2)
          : line.substring(1);

  /// The fence (` ``` ` / `~~~` run) [line] opens, or null. Up to three
  /// spaces of indentation are allowed — or a single tab, which is how a
  /// `>\t```` quote line reads once its marker is stripped. A backtick fence
  /// with another backtick after it (` ```a``` b `) is inline code, not a
  /// fence (CommonMark).
  static ({int indent, String fence})? _openingFence(String line) {
    var k = 0;
    if (line.startsWith('\t')) {
      k = 1;
    } else {
      while (k < line.length && k < 4 && line.codeUnitAt(k) == 0x20) {
        k++;
      }
      if (k > 3) return null;
    }
    final c = k < line.length ? line.codeUnitAt(k) : 0;
    if (c != 0x60 /* ` */ && c != 0x7E /* ~ */) return null;
    var e = k;
    while (e < line.length && line.codeUnitAt(e) == c) {
      e++;
    }
    if (e - k < 3) return null;
    if (c == 0x60 && line.indexOf('`', e) >= 0 && k > 0) return null;
    return (indent: k, fence: line.substring(k, e));
  }

  /// Joins `lines[from..to)` with their quote markers stripped by
  /// [_stripQuoteMarkerRaw] — the body a quote or alert re-parses as nested
  /// blocks. The block parser only knows fences at column 0, so an indented
  /// opening fence, and the indented fence that closes it, lose their
  /// indentation; every other line (code content included) stays verbatim.
  static String _rawQuoteBody(List<String> lines, int from, int to) {
    final buffer = StringBuffer();
    String? open; // The fence of the code block being read, if any.
    for (var k = from; k < to; k++) {
      if (k > from) buffer.writeln();
      var line = _stripQuoteMarkerRaw(lines[k]);
      final fence = _openingFence(line);
      if (open == null) {
        if (fence != null) {
          open = fence.fence;
          line = line.substring(fence.indent);
        }
      } else if (line.startsWith(open.substring(0, 3))) {
        open = null; // Closes at column 0, as in the block parser.
      } else if (fence != null &&
          fence.fence.codeUnitAt(0) == open.codeUnitAt(0) &&
          fence.fence.length >= open.length &&
          line.substring(fence.indent + fence.fence.length).trim().isEmpty) {
        open = null; // An indented closing fence (CommonMark).
        line = line.substring(fence.indent);
      }
      buffer.write(line);
    }
    return buffer.toString();
  }

  /// Whether any quote line `lines[from..to)` opens (or closes) a fenced code
  /// block (` ``` ` / `~~~`), at any quote depth. Used to decide when a
  /// quote/alert body must be re-parsed as nested blocks instead of being fed
  /// to [_parseInlineSpans].
  static bool _linesContainFence(List<String> lines, int from, int to) {
    for (var k = from; k < to; k++) {
      // Walk the markers by index: stripping them one substring at a time is
      // quadratic in the depth of the line.
      final line = lines[k];
      var from = 0;
      while (from < line.length && line.codeUnitAt(from) == 0x3E /* > */) {
        from++;
        if (from < line.length && line.codeUnitAt(from) == 0x20) from++;
      }
      // A fence needs a backtick or tilde after its indent: skip the copy.
      var first = from;
      while (first < line.length &&
          (line.codeUnitAt(first) == 0x20 || line.codeUnitAt(first) == 0x09)) {
        first++;
      }
      if (first == line.length) continue;
      final c = line.codeUnitAt(first);
      if (c != 0x60 /* ` */ && c != 0x7E /* ~ */) continue;
      if (_openingFence(line.substring(from)) != null) return true;
    }
    return false;
  }

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
      if (!_tableDelimiterCellPattern.hasMatch(cell)) return null;
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
  Markdown convert(String input) => _convert(input, 0);

  /// Parses [input], the body of a quote nested [depth] levels deep.
  Markdown _convert(String input, int depth) {
    final lines = LineSplitter.split(input).toList(growable: false);
    if (lines.isEmpty) return const Markdown.empty();
    final blocks = Queue<MD$Block>(); // Queue to accumulate blocks
    final length = lines.length;
    _TableRuns? tableRuns; // Built on the first valid delimiter row, if any.

    // Resolve the inline-math replacement table once; `null` disables math and
    // keeps `_parseInlineSpans` from touching it at all.
    final math =
        inlineMath ? (mathReplacements ?? kMarkdownMathCommands) : null;

    final paragraph = StringBuffer(); // To accumulate lines for paragraphs

    void maybeCommitParagraph() {
      if (paragraph.isEmpty) return;
      final text = paragraph.toString();
      paragraph.clear();
      blocks.addLast(MD$Paragraph(
        text: text,
        spans: _parseInlineSpans(text, math: math),
      ));
    }

    void pushBlock(MD$Block block) {
      maybeCommitParagraph();
      blocks.addLast(block);
    }

    for (var i = 0; i < length; i++) {
      final line = lines[i];

      if (_isBlank(line)) {
        // Parse empty lines and combine them into a spacing block.
        var j = i + 1;
        for (; j < length && _isBlank(lines[j]); j++) continue;
        final count = j - i;
        pushBlock(MD$Spacer(count: count));
        if (i + count == length) break; // Last line is empty
        i = j - 1; // Skip the empty lines
        continue;
      }

      // The first code unit cheaply gates the block-type checks below, so a
      // plain paragraph line runs no regular expressions at all.
      final c0 = line.codeUnitAt(0);

      if ((c0 == 0x20 /* space */ ||
              c0 == 0x2D /* - */ ||
              c0 == 0x2A /* * */ ||
              c0 == 0x5F /* _ */) &&
          _thematicBreakPattern.hasMatch(line)) {
        // Parse thematic breaks (horizontal rules): ---, ***, ___, - - -, etc.
        pushBlock(const MD$Divider());
        continue;
      } else if (c0 == 0x23 /* # */) {
        // Parse ATX headings (1-6 `#` followed by a space or end of line).
        final heading = _parseHeading(line);
        if (heading == null) {
          // Not a valid heading (e.g. "#hashtag" or 7+ `#`); treat as text.
          if (paragraph.isNotEmpty) paragraph.writeln();
          paragraph.write(line);
          continue;
        }
        final text = heading.text;
        pushBlock(MD$Heading(
            level: heading.level,
            text: text,
            spans: _parseInlineSpans(text, math: math)));
        continue;
      } else if (c0 == 0x3E /* > */) {
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
          final bodyLines = quoteLines.skip(1).toList(growable: false);
          final body = bodyLines.join('\n').trim();
          // Fenced code inside alerts must be nested blocks — feeding the
          // body to [_parseInlineSpans] pairs fence backticks as monospace.
          if (depth < _maxQuoteDepth && _linesContainFence(lines, i + 1, j)) {
            var nested =
                _convert(_rawQuoteBody(lines, i + 1, j), depth + 1).blocks;
            // Blank `>` lines around the body are not gaps (the inline body
            // is trimmed too).
            var from = 0, to = nested.length;
            while (from < to && nested[from] is MD$Spacer) from++;
            while (to > from && nested[to - 1] is MD$Spacer) to--;
            if (from > 0 || to < nested.length) {
              nested = nested.sublist(from, to);
            }
            pushBlock(MD$Alert(
              alert: alertType,
              text: body,
              spans: const <MD$Span>[],
              blocks: nested,
            ));
          } else {
            pushBlock(MD$Alert(
              alert: alertType,
              text: body,
              spans: _parseInlineSpans(body, math: math),
            ));
          }
        } else {
          final text = quoteLines.join('\n');
          // TODO(plugfox): Implement indentation for quotes
          // Mike Matiunin <plugfox@gmail.com>, 16 June 2025
          // CommonMark/GFM: strip `>` then re-parse the body as blocks so a
          // fenced code block inside a quote stays a code block — not inline
          // ``monospace`` from backtick pairing in [_parseInlineSpans].
          if (depth < _maxQuoteDepth && _linesContainFence(lines, i, j)) {
            final nested =
                _convert(_rawQuoteBody(lines, i, j), depth + 1).blocks;
            pushBlock(MD$Quote(
              indent: 1,
              text: text,
              spans: const <MD$Span>[],
              blocks: nested,
            ));
          } else {
            pushBlock(MD$Quote(
              indent: 1, // Indentation level for quotes
              text: text,
              spans: _parseInlineSpans(text, math: math),
            ));
          }
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
      } else if ((c0 >= 0x30 && c0 <= 0x39) /* 0-9 */ ||
          c0 == 0x2A /* * */ ||
          c0 == 0x2B /* + */ ||
          c0 == 0x2D /* - */) {
        final first = _parseListLine(line);
        if (first == null || first.indent != 0) {
          // A marker-like first character that is not actually a top-level
          // list item (e.g. "-> arrow", "*emphasis*"); treat it as paragraph.
          if (paragraph.isNotEmpty) paragraph.writeln();
          paragraph.write(line);
          continue;
        }
        final firstTask = _parseTask(first.text.trim());
        final list =
            <({int intent, String marker, String text, bool? checked})>[
          (
            intent: 0,
            marker: first.marker,
            text: firstTask.text,
            checked: firstTask.checked,
          )
        ];
        var j = i + 1;
        for (; j < length; j++) {
          final parsed = _parseListLine(lines[j]);
          if (parsed == null) break;
          final task = _parseTask(parsed.text.trim());
          list.add((
            intent: parsed.indent,
            marker: parsed.marker,
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
                spans: _parseInlineSpans(item.text, math: math),
                indent: item.intent,
                checked: item.checked,
              ));
            } else if (item.intent > indent) {
              // If the current item's indent is greater,
              // we continue traversing deeper into the list.
              final children = traverse(indent: item.intent);
              if (items.isNotEmpty) {
                // If we have a parent item, add children to it (after any it
                // already has: `- a` / `    - b` / `  - c` nests both).
                final parent = items.last;
                items.last = parent.copyWith(
                    children: List<MD$ListItem>.unmodifiable(
                        <MD$ListItem>[...parent.children, ...children]));
              } else {
                // If this is the first item, just add children
                items.add(MD$ListItem(
                  marker: item.marker, // '•',
                  text: item.text,
                  spans: _parseInlineSpans(item.text, math: math),
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
      } else if (c0 == 0x7C /* | */) {
        // Parse tables
        MD$TableRow textToRow(String text) {
          final cells = text.split('|');
          return MD$TableRow(
            text: text,
            cells: List<List<MD$Span>>.unmodifiable(cells
                .sublist(1, cells.length - 1)
                .map((cell) => cell.trim())
                .map((cell) => _parseInlineSpans(cell, math: math))),
          );
        }

        // The delimiter row also carries per-column alignment.
        final alignments =
            lines.length > i + 1 ? _parseTableAlignments(lines[i + 1]) : null;
        // Without a delimiter row this is not a table; most `|` lines stop here
        // and the document's cell counts are never computed.
        if (alignments == null) {
          if (paragraph.isNotEmpty) paragraph.writeln();
          paragraph.write(line);
          continue;
        }
        // Validate on cell counts before formatting any cell: a rejected
        // table hands its first line to the paragraph and the next line is
        // tried as a table again, so per-candidate work must stay O(1).
        final runs = tableRuns ??= _TableRuns(lines);
        final columns = runs.cells[i];
        final j = runs.rowsEnd(i + 2); // Skip the header and separator line
        if (columns > 0 && runs.allCellsEqual(i + 2, j, columns)) {
          // All rows have the same number of cells as the header
          final header = textToRow(line);
          final rows = <MD$TableRow>[
            for (var k = i + 2; k < j; k++) textToRow(lines[k]),
          ];
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

/// Lookup table of code units that can start an inline construct: emphasis
/// markers (`* _ ~ = | ` `` ` ``), a link/image label (`[`), or an escape
/// (`\`). Used by [_parseInlineSpans] to take a fast path for plain text that
/// contains none of them — by far the most common case for prose.
final Uint8List _special = Uint8List(128)
  ..[0x2A] = 1 // *
  ..[0x5F] = 1 // _
  ..[0x7E] = 1 // ~
  ..[0x3D] = 1 // =
  ..[0x7C] = 1 // |
  ..[0x60] = 1 // `
  ..[0x5B] = 1 // [
  ..[0x5C] = 1; // \

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
  ..[36] = 1 // $ Dollar sign (so `\$` is a literal dollar / opts out of math)
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

/// The default mapping of common LaTeX inline-math commands to their Unicode
/// equivalents, used when [MarkdownDecoder.inlineMath] is enabled and no custom
/// [MarkdownDecoder.mathReplacements] is provided.
///
/// Spread it to extend rather than replace the defaults:
/// `{...kMarkdownMathCommands, r'\R': 'ℝ'}`.
const Map<String, String> kMarkdownMathCommands = <String, String>{
  // Arrows
  r'\to': '→', r'\rightarrow': '→', r'\gets': '←',
  r'\leftarrow': '←', r'\leftrightarrow': '↔',
  r'\Rightarrow': '⇒', r'\Leftarrow': '⇐',
  r'\Leftrightarrow': '⇔', r'\uparrow': '↑',
  r'\downarrow': '↓', r'\mapsto': '↦',
  r'\implies': '⟹', r'\iff': '⟺', r'\longrightarrow': '⟶',
  r'\longleftarrow': '⟵', r'\hookrightarrow': '↪',
  // Relations & operators
  r'\leq': '≤', r'\le': '≤', r'\geq': '≥', r'\ge': '≥',
  r'\neq': '≠', r'\ne': '≠', r'\approx': '≈',
  r'\equiv': '≡', r'\sim': '∼', r'\simeq': '≃',
  r'\cong': '≅', r'\propto': '∝', r'\asymp': '≍',
  r'\ll': '≪', r'\gg': '≫',
  r'\times': '×', r'\div': '÷', r'\pm': '±', r'\mp': '∓',
  r'\cdot': '⋅', r'\ast': '∗', r'\star': '⋆',
  r'\circ': '∘', r'\bullet': '∙', r'\oplus': '⊕',
  r'\otimes': '⊗', r'\odot': '⊙', r'\setminus': '∖',
  r'\perp': '⊥', r'\parallel': '∥', r'\mid': '∣',
  // Set theory & logic
  r'\in': '∈', r'\notin': '∉', r'\ni': '∋',
  r'\subset': '⊂', r'\subseteq': '⊆', r'\supset': '⊃',
  r'\supseteq': '⊇', r'\cup': '∪', r'\cap': '∩',
  r'\emptyset': '∅', r'\varnothing': '∅',
  r'\forall': '∀', r'\exists': '∃', r'\nexists': '∄',
  r'\neg': '¬', r'\lnot': '¬', r'\land': '∧', r'\wedge': '∧',
  r'\lor': '∨', r'\vee': '∨', r'\top': '⊤', r'\bot': '⊥',
  r'\models': '⊨', r'\vdash': '⊢', r'\therefore': '∴',
  r'\because': '∵',
  // Big operators & calculus
  r'\sum': '∑', r'\prod': '∏', r'\int': '∫',
  r'\oint': '∮', r'\iint': '∬',
  r'\infty': '∞', r'\partial': '∂', r'\nabla': '∇',
  r'\sqrt': '√', r'\angle': '∠', r'\degree': '°',
  r'\prime': '′', r'\hbar': 'ℏ', r'\ell': 'ℓ',
  r'\Re': 'ℜ', r'\Im': 'ℑ', r'\aleph': 'ℵ',
  // Dots
  r'\ldots': '…', r'\cdots': '⋯', r'\dots': '…', r'\vdots': '⋮',
  // Greek lowercase
  r'\alpha': 'α', r'\beta': 'β', r'\gamma': 'γ',
  r'\delta': 'δ', r'\epsilon': 'ε', r'\varepsilon': 'ε',
  r'\zeta': 'ζ', r'\eta': 'η', r'\theta': 'θ',
  r'\vartheta': 'ϑ', r'\iota': 'ι', r'\kappa': 'κ',
  r'\lambda': 'λ', r'\mu': 'μ', r'\nu': 'ν', r'\xi': 'ξ',
  r'\pi': 'π', r'\varpi': 'ϖ', r'\rho': 'ρ', r'\varrho': 'ϱ',
  r'\sigma': 'σ', r'\varsigma': 'ς', r'\tau': 'τ',
  r'\upsilon': 'υ', r'\phi': 'φ', r'\varphi': 'ϕ',
  r'\chi': 'χ', r'\psi': 'ψ', r'\omega': 'ω',
  // Greek uppercase
  r'\Gamma': 'Γ', r'\Delta': 'Δ', r'\Theta': 'Θ',
  r'\Lambda': 'Λ', r'\Xi': 'Ξ', r'\Pi': 'Π',
  r'\Sigma': 'Σ', r'\Upsilon': 'Υ', r'\Phi': 'Φ',
  r'\Psi': 'Ψ', r'\Omega': 'Ω',
};

/// Superscript code-unit map (base character → Unicode superscript), used for
/// `$x^2$`-style math. Characters without a mapping are left as-is.
const Map<int, int> _superscripts = <int, int>{
  0x30: 0x2070, 0x31: 0x00B9, 0x32: 0x00B2, 0x33: 0x00B3, // 0 1 2 3
  0x34: 0x2074, 0x35: 0x2075, 0x36: 0x2076, 0x37: 0x2077, // 4 5 6 7
  0x38: 0x2078, 0x39: 0x2079, // 8 9
  0x2B: 0x207A, 0x2D: 0x207B, 0x3D: 0x207C, // + - =
  0x28: 0x207D, 0x29: 0x207E, // ( )
  0x69: 0x2071, 0x6E: 0x207F, // i n
};

/// Subscript code-unit map (base character → Unicode subscript), used for
/// `$H_2O$`-style math. Characters without a mapping are left as-is.
const Map<int, int> _subscripts = <int, int>{
  0x30: 0x2080, 0x31: 0x2081, 0x32: 0x2082, 0x33: 0x2083, // 0 1 2 3
  0x34: 0x2084, 0x35: 0x2085, 0x36: 0x2086, 0x37: 0x2087, // 4 5 6 7
  0x38: 0x2088, 0x39: 0x2089, // 8 9
  0x2B: 0x208A, 0x2D: 0x208B, 0x3D: 0x208C, // + - =
  0x28: 0x208D, 0x29: 0x208E, // ( )
  0x61: 0x2090, 0x65: 0x2091, 0x6F: 0x2092, 0x78: 0x2093, // a e o x
  0x68: 0x2095, 0x6B: 0x2096, 0x6C: 0x2097, 0x6D: 0x2098, // h k l m
  0x6E: 0x2099, 0x70: 0x209A, 0x73: 0x209B, 0x74: 0x209C, // n p s t
  0x69: 0x1D62, 0x72: 0x1D63, 0x75: 0x1D64, 0x76: 0x1D65, // i r u v
  0x6A: 0x2C7C, // j
};

/// Matches a run of `$...$` inline math with tight delimiters (no space right
/// after the opening `$` or right before the closing `$`) and no `$` inside.
/// The opening `$` must not be backslash-escaped, so `\$5` never starts math.
final RegExp _inlineMathPattern = RegExp(r'(?<!\\)\$(\S(?:[^$]*\S)?)\$');

/// Matches a LaTeX command such as `\alpha` or `\rightarrow`.
final RegExp _mathCommandPattern = RegExp(r'\\[a-zA-Z]+');

/// Converts recognized LaTeX commands and super/subscripts within [content] to
/// Unicode, using [replacements] for the command table. Returns `null` when
/// nothing was converted, so callers can leave the original `$...$` text
/// untouched (avoiding false positives like currency).
String? _convertMathContent(String content, Map<String, String> replacements) {
  var replaced = false;
  var result = content.replaceAllMapped(_mathCommandPattern, (match) {
    final unicode = replacements[match.group(0)];
    if (unicode == null) return match.group(0)!;
    replaced = true;
    return unicode;
  });
  final scripted = _applyScripts(result);
  if (scripted != null) {
    result = scripted;
    replaced = true;
  }
  return replaced ? result : null;
}

/// Converts `^`/`_` super/subscripts in already-command-substituted math
/// [content] to Unicode, supporting a single character (`x^2`, `a_i`) or a
/// braced group (`x^{10}`, `H_{2}O`). Returns `null` when nothing changed.
/// A script run whose characters are not all mappable is left untouched.
String? _applyScripts(String content) {
  if (!content.contains('^') && !content.contains('_')) return null;
  final length = content.length;
  StringBuffer? buffer;
  var last = 0; // Start of the not-yet-copied tail.
  var i = 0;
  // The first `}` at or after the last brace looked up, or [length] if none:
  // each `^{` reuses it instead of searching the rest of the content again.
  var close = -1;
  while (i < length) {
    final c = content.codeUnitAt(i);
    if (c != 0x5E /* ^ */ && c != 0x5F /* _ */) {
      i++;
      continue;
    }
    final table = c == 0x5E ? _superscripts : _subscripts;
    final String? mapped;
    final int next; // Index just past the consumed script expression.
    if (i + 1 < length && content.codeUnitAt(i + 1) == 0x7B /* { */) {
      if (close < i + 2) {
        close = content.indexOf('}', i + 2);
        if (close == -1) close = length;
      }
      if (close == length) {
        i++;
        continue;
      }
      mapped = _mapScriptRun(content, i + 2, close, table);
      next = close + 1;
    } else if (i + 1 < length) {
      final m = table[content.codeUnitAt(i + 1)];
      mapped = m == null ? null : String.fromCharCode(m);
      next = i + 2;
    } else {
      break;
    }
    if (mapped == null) {
      i++;
      continue;
    }
    (buffer ??= StringBuffer()).write(content.substring(last, i));
    buffer.write(mapped);
    last = next;
    i = next;
  }
  if (buffer == null) return null;
  buffer.write(content.substring(last));
  return buffer.toString();
}

/// Maps every code unit in `content[start..end)` through [table], returning
/// `null` if any character has no mapping.
String? _mapScriptRun(String content, int start, int end, Map<int, int> table) {
  final out = StringBuffer();
  for (var k = start; k < end; k++) {
    final mapped = table[content.codeUnitAt(k)];
    if (mapped == null) return null;
    out.writeCharCode(mapped);
  }
  return out.toString();
}

/// Replaces `$...$` inline math with Unicode equivalents, leaving inline code
/// spans (delimited by backticks) untouched. Only segments that contain at
/// least one recognized LaTeX command are converted; everything else — such as
/// currency (`$5`) — is preserved verbatim.
String _applyInlineMath(String text, Map<String, String> replacements) {
  // A `$...$` span can only convert if it contains a command (`\`) or a
  // super/subscript (`^`/`_`). Text with none of those — e.g. prices like
  // `$5` — skips the scan entirely.
  if (!text.contains(r'$')) return text;
  if (!text.contains(r'\') && !text.contains('^') && !text.contains('_')) {
    return text;
  }

  String convertSegment(String segment) =>
      segment.replaceAllMapped(_inlineMathPattern, (match) {
        final converted = _convertMathContent(match.group(1)!, replacements);
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
    // Find the first whitespace separating the URL from an optional title.
    // A manual scan avoids allocating and compiling a RegExp on every call.
    var space = -1;
    for (var k = 0; k < rest.length; k++) {
      final ch = rest.codeUnitAt(k);
      if (ch == 0x20 || ch == 0x09) {
        space = k;
        break;
      }
    }
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

/// The index of the first non-escaped closing backtick at or after [from], or
/// -1. [from] must be at least 1.
int _nextClosingBacktick(List<int> codes, int length, int from) {
  for (var j = from; j < length; j++) {
    if (codes[j] == 0x60 /* ` */ && codes[j - 1] != 0x5C /* \ */) return j;
  }
  return -1;
}

/// The index of the first valid closing emphasis delimiter for [ch] (of run
/// length [markerLen]) at or after [from], or -1. A closer must be
/// right-flanking (preceded by a non-space); underscore closers must also be
/// at a word boundary. Escaped characters are skipped.
///
/// The caller keeps the result per marker and only scans again from past it,
/// so all the openers of a text scan it once (rescanning from each opener is
/// quadratic for runs of markers that never close). [from] follows a marker,
/// which is never a backslash, so a scan from any earlier opener reads the
/// same escapes and finds the same closers.
///
/// Right-flanking is a property of the whole delimiter *run*, not the
/// individual marker character: the deciding character is the one immediately
/// before the run, skipping consecutive same-marker delimiters. We therefore
/// only accept a closer at the run boundary (`codes[j - 1] != ch`). A run
/// whose boundary is not right-flanking cannot close from any of its inner
/// delimiters either, so e.g. `a **bold ** x` (the closing `**` follows a
/// space) stays literal instead of degrading into a lopsided italic.
int _nextEmphasisCloser(
    List<int> codes, int length, int from, int ch, int markerLen) {
  for (var j = from; j < length; j++) {
    if (codes[j] == 0x5C /* \ */) {
      j++; // Skip the escaped character.
      continue;
    }
    if (codes[j] != ch) continue;
    if (markerLen == 2) {
      if (j + 1 < length && codes[j + 1] == ch) {
        if (j > 0 && !_isInlineSpace(codes[j - 1]) && codes[j - 1] != ch)
          return j;
        j++; // Consume the delimiter pair.
      }
    } else if (j > 0 && !_isInlineSpace(codes[j - 1]) && codes[j - 1] != ch) {
      // Underscore: also require a word boundary after the closer.
      final after = j + 1;
      if (ch != 0x5F /* _ */ || after >= length || !_isWordChar(codes[after]))
        return j;
    }
  }
  return -1;
}

/// Validates an emphasis marker occurrence against CommonMark-inspired
/// flanking and word-boundary rules. Returns `true` when the marker may
/// toggle the style; `false` leaves it as literal text. An opener must also
/// have a closer ahead, which the caller checks via [_nextEmphasisCloser].
bool _emphasisValid(
    List<int> codes, int length, int i, int ch, int markerLen, bool isOpen) {
  if (isOpen) {
    // Left-flanking: a non-space must immediately follow the marker run.
    final after = i + markerLen;
    if (after >= length || _isInlineSpace(codes[after])) return false;
    // Underscore cannot open inside a word (e.g. snake_case).
    if (ch == 0x5F /* _ */ && i > 0 && _isWordChar(codes[i - 1])) return false;
    return true;
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

List<MD$Span> _parseInlineSpans(String text, {Map<String, String>? math}) {
  if (text.isEmpty) return const <MD$Span>[];

  // Resolve simple `$...$` inline math to Unicode before span parsing, but
  // only when enabled (a non-null replacement table is supplied).
  if (math != null) text = _applyInlineMath(text, math);

  // Convert the text to a list of code units for easier processing
  // This allows us to handle UTF-16 characters correctly.
  final codes = text.codeUnits;
  final length = codes.length;

  // Fast path: text without any inline markers, links, or escapes is a single
  // unstyled span. Detect that with one early-terminating scan and skip both
  // the link-extraction and emphasis passes (and their allocations).
  var hasSpecial = false;
  for (var i = 0; i < length; i++) {
    final c = codes[i];
    if (c < 128 && _special[c] != 0) {
      hasSpecial = true;
      break;
    }
  }
  if (!hasSpecial) {
    return <MD$Span>[
      MD$Span(start: 0, end: length, text: text),
    ];
  }

  /// Escaped characters in Markdown
  const int esc = 0x5C; // '\'

  // Phase 1: Extract links and images.
  //
  // Only run when a label bracket is actually present, and allocate the
  // `links` list lazily on the first match, so text with emphasis
  // but no links (a common case) pays neither the scan nor the allocation.
  List<MD$Span>? links;
  if (text.contains('[')) {
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
      // Without a '(' this is not a link. Every '[' before [labelEnd] would
      // find the same ']' and fail the same way, so resume after it rather
      // than rescanning the label once per '['.
      final urlIdx = labelEnd + 1;
      if (urlIdx >= codes.length || codes[urlIdx] != url$start) {
        i = labelEnd;
        continue;
      }

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
      links ??= <MD$Span>[];
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

      // jump past the processed link
      i = urlEnd;
    }
  }

  // Phase 2: Parse inline spans
  // This is a simplified version that only handles basic inline styles.
  var start = 0; // Start index for the current span
  var mask = MD$Style.none; // Current style mask
  final spans = <MD$Span>[];

  // The closer ahead of the last opener that looked for one, per marker: 0 when
  // not looked up yet (a closer is never at 0), -1 when none is left. Openers
  // only move forward, so each scan resumes past the previous closer.
  var nextBacktick = 0;
  Int32List? nextCloser; // Indexed by the emphasis `slot` below.
  // The first link or image that does not start before the current index, and
  // its start ([length] when none is left), checked for every character.
  var nextLink = 0;
  var nextLinkStart = links == null ? length : links.first.start;

  var hasExcluded = false; // Flag to check if we have excluded characters
  // Backslash indices to drop from the current span, in ascending order. This
  // is cleared after every pushed span, so it only ever holds the escapes of
  // the span currently being built. Allocated lazily on the first escape.
  late final excluded = <int>[];
  {
    // Add span to the list of spans
    void maybePushSpan(int end) {
      if (start >= end) return; // No valid span to push
      if (hasExcluded) {
        // Rebuild the span text without the excluded backslash characters by
        // copying the ranges between them. Because the indices are already
        // sorted, this avoids both a hash-set lookup per character and an
        // intermediate code-unit buffer.
        final removed = excluded.length;
        final spanLength = end - start - removed;
        if (spanLength > 0) {
          final buffer = StringBuffer();
          var segmentStart = start;
          for (var e = 0; e < excluded.length; e++) {
            final idx = excluded[e];
            if (idx > segmentStart)
              buffer.write(text.substring(segmentStart, idx));
            segmentStart = idx + 1;
          }
          if (segmentStart < end)
            buffer.write(text.substring(segmentStart, end));
          spans.add(
            MD$Span(
              start: start,
              end: end - removed,
              text: buffer.toString(),
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
      if (i >= nextLinkStart) {
        // Links can start inside a code span, which passes over them.
        final all = links!;
        while (nextLink < all.length && all[nextLink].start < i) nextLink++;
        nextLinkStart = nextLink < all.length ? all[nextLink].start : length;
      }
      if (i == nextLinkStart) {
        // Finish the current span if it exists
        maybePushSpan(i);

        final link = links![nextLink];
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
        if (nextBacktick != -1 && nextBacktick <= i)
          nextBacktick = _nextClosingBacktick(codes, length, i + 1);
        if (nextBacktick == -1) continue; // literal `
        maybePushSpan(i);
        mask ^= MD$Style.monospace;
        start = i + 1;
        continue;
      }

      // Resolve the emphasis style, marker length and closer slot.
      final MD$Style style;
      final int markerLen, slot;
      switch (ch) {
        case 42: // '*'
          style = isDouble ? MD$Style.bold : MD$Style.italic;
          markerLen = isDouble ? 2 : 1;
          slot = isDouble ? 1 : 0;
        case 95: // '_'
          style = isDouble ? MD$Style.underline : MD$Style.italic;
          markerLen = isDouble ? 2 : 1;
          slot = isDouble ? 3 : 2;
        case 126 when isDouble: // '~~'
          style = MD$Style.strikethrough;
          markerLen = 2;
          slot = 4;
        case 61 when isDouble: // '=='
          style = MD$Style.highlight;
          markerLen = 2;
          slot = 5;
        case 124 when isDouble: // '||'
          style = MD$Style.spoiler;
          markerLen = 2;
          slot = 6;
        default:
          continue; // Lone =, |, ~ (and unknown markers) are literal.
      }

      // Validate the marker against flanking / word-boundary rules and require
      // a matching closer, so stray or unterminated markers stay literal
      // instead of leaking their style to the end of the line.
      final isOpen = !mask.contains(style);
      if (!_emphasisValid(codes, length, i, ch, markerLen, isOpen)) continue;
      if (isOpen) {
        final closers = nextCloser ??= Int32List(7);
        final after = i + markerLen;
        var closer = closers[slot];
        if (closer != -1 && closer < after) {
          closers[slot] =
              closer = _nextEmphasisCloser(codes, length, after, ch, markerLen);
        }
        if (closer == -1) continue; // No closer ahead: literal marker.
      }

      maybePushSpan(i);
      mask ^= style;
      start = i + markerLen;
      if (markerLen == 2) i++; // Skip the second marker character.
    }
    // If we have any remaining text after the last marker, add it as a span
    maybePushSpan(length);
  }

  // This function would parse inline spans like bold, italic, links, etc.
  // For now, it returns an empty list as a placeholder.
  return spans;
}

/// Table cell counts for every line of a document, so checking whether a
/// candidate table's rows all match its header costs O(1). Without it, a run
/// of `|` lines that keeps failing validation re-reads every following row
/// once per line (quadratic).
class _TableRuns {
  _TableRuns(List<String> lines)
      : cells = Int32List(lines.length),
        _sameEnd = Int32List(lines.length),
        _rowsEnd = Int32List(lines.length) {
    final length = lines.length;
    for (var k = 0; k < length; k++) {
      final line = lines[k];
      if (!line.startsWith('|')) {
        cells[k] = -1;
        continue;
      }
      // `line.split('|')` yields pipes + 1 parts; the outer two are not cells.
      var pipes = 0;
      for (var c = 0; c < line.length; c++) {
        if (line.codeUnitAt(c) == 0x7C /* | */) pipes++;
      }
      cells[k] = pipes - 1;
    }
    for (var k = length - 1; k >= 0; k--) {
      final next = k + 1 < length;
      _sameEnd[k] = next && cells[k + 1] == cells[k] ? _sameEnd[k + 1] : k + 1;
      _rowsEnd[k] = cells[k] < 0 ? k : (next ? _rowsEnd[k + 1] : length);
    }
  }

  /// The cell count of each line, or -1 when it does not start with `|`.
  final Int32List cells;

  /// For each line, the index just past its run of lines with equal [cells].
  final Int32List _sameEnd;

  /// For each line, the index of the first line at or after it not starting
  /// with `|`.
  final Int32List _rowsEnd;

  /// The index of the first line at or after [from] not starting with `|`.
  int rowsEnd(int from) => from < cells.length ? _rowsEnd[from] : cells.length;

  /// Whether every line in `[from, to)` has exactly [count] cells.
  bool allCellsEqual(int from, int to, int count) =>
      from >= to || (cells[from] == count && _sameEnd[from] >= to);
}

// =============================================================================
// Streaming (incremental) parser
// =============================================================================

/// {@template streaming_markdown_parser}
/// Incremental Markdown parser for streaming sources such as LLM token output.
///
/// A plain [MarkdownDecoder] re-parses the whole document on every call, so
/// feeding it an `N`-line message one token at a time costs `O(N²)`. This
/// parser keeps the accumulated source and only re-parses the still-growing
/// *tail* of the document: once a run of blocks is provably complete —
/// terminated by a blank line and not sitting inside an open code fence — it is
/// *frozen* and never parsed again.
///
/// The result of [add] / [current] is always identical, block for block, to
/// `Markdown.fromString(everythingAddedSoFar)` (using the same [decoder]) — the
/// incremental path is a pure performance optimization, never a behavioral one.
/// Blocks whose type still depends on input that has not arrived yet — an
/// unterminated code fence, a table header still missing its delimiter row, a
/// list or block quote that might continue — deliberately stay in the live tail
/// and are re-evaluated on every [add], so they never freeze into the wrong
/// shape.
///
/// ```dart
/// final parser = StreamingMarkdownParser();
/// llmTokenStream.listen((token) {
///   final markdown = parser.add(token); // cheap, incremental
///   setState(() => _message = markdown);
/// });
/// ```
///
/// For a [Stream] of chunks, prefer the [MarkdownStreamParsing.toMarkdown]
/// extension, which wires an instance of this class into a transform.
///
/// The parser is stateful and single-conversation: call [reset] to reuse the
/// instance for a new document.
/// {@endtemplate}
class StreamingMarkdownParser {
  /// Creates a streaming parser.
  ///
  /// [decoder] performs the actual parsing of each tail; pass a configured
  /// [MarkdownDecoder] (e.g. `MarkdownDecoder(inlineMath: true)`) to match the
  /// options you would use with [Markdown.fromString]. Defaults to a plain
  /// [MarkdownDecoder].
  /// {@macro streaming_markdown_parser}
  StreamingMarkdownParser({MarkdownDecoder decoder = const MarkdownDecoder()})
      : _decoder = decoder;

  /// The decoder used to (re)parse frozen prefixes and the live tail.
  final MarkdownDecoder _decoder;

  /// Source of the frozen prefix (`== ` everything up to [_stableOffset]). Kept
  /// as a materialized string so [current] can expose the full source without
  /// re-joining lines; only grows when a prefix is frozen.
  String _frozen = '';

  /// The still-mutable remainder of the source (everything after the frozen
  /// prefix). Re-parsed on every [add].
  String _tail = '';

  /// Blocks parsed from [_frozen]. Never re-parsed once appended.
  final List<MD$Block> _stableBlocks = <MD$Block>[];

  /// Blocks parsed from the current [_tail]. Rebuilt on every [add].
  List<MD$Block> _tailBlocks = const <MD$Block>[];

  /// The full Markdown source accumulated so far.
  String get source => _tail.isEmpty ? _frozen : '$_frozen$_tail';

  /// Number of blocks already frozen (exposed for diagnostics / benchmarks).
  int get stableBlockCount => _stableBlocks.length;

  /// Appends a chunk of streamed Markdown text and returns the updated
  /// [Markdown]. The chunk may end mid-line; the partial line is buffered and
  /// completed by later chunks.
  Markdown add(String chunk) {
    if (chunk.isNotEmpty) {
      _tail = _tail.isEmpty ? chunk : '$_tail$chunk';
      _freezeCompletedPrefix();
      _tailBlocks =
          _tail.isEmpty ? const <MD$Block>[] : _decoder.convert(_tail).blocks;
    }
    return current;
  }

  /// The current parsed [Markdown] (frozen prefix + live tail) without adding
  /// anything. Equivalent, block for block, to `Markdown.fromString(source)`.
  Markdown get current => _build();

  /// Freezes any newly-completed leading blocks so they are never re-parsed.
  ///
  /// Finds the largest safe boundary in [_tail] (via [_safeCutOffset]),
  /// converts the prefix up to it once, moves it into [_frozen] /
  /// [_stableBlocks], and leaves the remainder as the live tail.
  void _freezeCompletedPrefix() {
    final cut = _safeCutOffset(_tail);
    if (cut <= 0) return;
    final prefix = _tail.substring(0, cut);
    // Safe by construction: [cut] sits at a hard block boundary outside any
    // open fence, so converting the prefix in isolation yields exactly the
    // blocks it would contribute to a full-document parse.
    _stableBlocks.addAll(_decoder.convert(prefix).blocks);
    _frozen = _frozen.isEmpty ? prefix : '$_frozen$prefix';
    _tail = _tail.substring(cut);
  }

  /// Resets the parser to its initial empty state so the instance can be reused
  /// for a new document.
  void reset() {
    _frozen = '';
    _tail = '';
    _stableBlocks.clear();
    _tailBlocks = const <MD$Block>[];
  }

  /// Builds the combined [Markdown] view (frozen prefix + live tail).
  Markdown _build() {
    final src = source;
    if (src.isEmpty) return const Markdown.empty();
    final blocks = <MD$Block>[..._stableBlocks, ..._tailBlocks];
    return Markdown(
      markdown: src,
      blocks: List<MD$Block>.unmodifiable(blocks),
    );
  }
}

/// Returns the offset within [tail] at which the still-mutable remainder of the
/// document begins: everything before it forms complete blocks that no future
/// input can change and may be frozen. Returns `0` when nothing new can be
/// frozen yet.
///
/// A cut is placed at the start of a **complete, non-blank line whose preceding
/// complete line is blank**, provided that position is not inside an open code
/// fence. Because this block grammar has no lazy continuation across a blank
/// line (a blank line terminates paragraphs, quotes, lists and tables, and only
/// an open code fence swallows blanks), such a position is a hard boundary:
/// parsing the prefix and the suffix separately yields exactly the same blocks
/// as parsing the whole. The last such boundary in [tail] is returned so as
/// much as possible is frozen.
int _safeCutOffset(String tail) {
  final len = tail.length;
  var cut = 0;
  var inFence = false;
  var fence =
      0; // active fence marker code unit (0x60 ``` / 0x7E ~~~), 0 = none
  var prevBlank = false; // the previous *complete* line was blank
  var havePrev = false; // there is a previous complete line
  var start = 0;

  for (var i = 0; i <= len; i++) {
    // A line ends at each '\n' and at end-of-string. The final segment
    // (i == len) is the still-growing pending line and is never itself frozen.
    if (i != len && tail.codeUnitAt(i) != 0x0A /* \n */) continue;
    final complete = i < len;

    // Evaluate a cut at this line's start, using the fence/blank state that
    // holds *before* this line is folded in.
    if (havePrev && prevBlank && !inFence && !_segIsBlank(tail, start, i)) {
      cut = start;
    }

    if (complete) {
      final marker = _fenceMarker(tail, start, i);
      if (!inFence) {
        if (marker != 0) {
          inFence = true;
          fence = marker;
        }
      } else if (marker == fence) {
        inFence = false;
        fence = 0;
      }
      prevBlank = _segIsBlank(tail, start, i);
      havePrev = true;
      start = i + 1;
    }
  }
  return cut;
}

/// Whether the line segment `s[start..end)` is blank — only spaces, tabs, or a
/// trailing carriage return (so CRLF blank lines are recognized). Mirrors
/// [MarkdownDecoder]'s blank-line rule for the streaming boundary scan.
bool _segIsBlank(String s, int start, int end) {
  for (var k = start; k < end; k++) {
    final c = s.codeUnitAt(k);
    if (c != 0x20 /* space */ && c != 0x09 /* tab */ && c != 0x0D /* CR */) {
      return false;
    }
  }
  return true;
}

/// Returns the fence marker code unit (0x60 for ```` ``` ````, 0x7E for `~~~`)
/// when `s[start..end)` opens or closes a fenced code block, else `0`. Matches
/// the `startsWith('```') || startsWith('~~~')` test in [MarkdownDecoder].
int _fenceMarker(String s, int start, int end) {
  if (end - start < 3) return 0;
  final c = s.codeUnitAt(start);
  if (c != 0x60 /* ` */ && c != 0x7E /* ~ */) return 0;
  return (s.codeUnitAt(start + 1) == c && s.codeUnitAt(start + 2) == c) ? c : 0;
}

/// Incremental Markdown parsing for a stream of text chunks.
extension MarkdownStreamParsing on Stream<String> {
  /// Parses this stream of Markdown text chunks incrementally, emitting the
  /// growing [Markdown] after each chunk.
  ///
  /// A single [StreamingMarkdownParser] is threaded through the stream, so
  /// closed blocks are parsed once and only the live tail is re-parsed as
  /// tokens arrive. Pass a configured [decoder] (e.g. for `inlineMath`) to
  /// match [Markdown.fromString]. The last emitted value equals
  /// `Markdown.fromString(concatenationOfAllChunks)`.
  ///
  /// ```dart
  /// llmTokenStream.toMarkdown().listen((md) => setState(() => _message = md));
  /// ```
  Stream<Markdown> toMarkdown({
    MarkdownDecoder decoder = const MarkdownDecoder(),
  }) {
    final parser = StreamingMarkdownParser(decoder: decoder);
    return map(parser.add);
  }
}
