import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'markdown.dart';
import 'nodes.dart';

/// Decodes Markdown formatted strings
/// into a list of [MD$Block] objects.
const Converter<String, Markdown> markdownDecoder = MarkdownDecoder();

// ============================================================================
// Line State for Streaming
// ============================================================================

/// State of a parsed line in streaming context.
enum LineState {
  /// Line is not yet confirmed closed, may receive more content
  /// or belongs to an unclosed block.
  open,

  /// Line belongs to a closed block and will not change.
  closed,
}

/// A line with its parsing state for streaming context.
class ParsedLine {
  /// Creates a new parsed line.
  ParsedLine(this.text, {this.state = LineState.open});

  /// The text content of the line.
  String text;

  /// The parsing state of this line.
  LineState state;

  @override
  String toString() => 'ParsedLine($text, $state)';
}

// ============================================================================
// Shared Parsing Logic
// ============================================================================

/// Regular expression pattern to match empty lines.
final RegExp _emptyPattern = RegExp(r'^(?:[ \t]*)$');

/// Leading `#` define atx-style headers (1-6 levels).
final RegExp _headerPattern = RegExp(r'^(#{1,6})');

/// Pattern to match list items (ordered and unordered).
final RegExp _listPattern = RegExp(
    r'^(?<indent>[ \t]{0,8})(?<marker>(\d{1,9})[\.)]|[*+-])(?<text>[ \t]+(.*))?$');

/// Callback type for when a block is closed (lines [start] to [end] exclusive).
typedef OnBlockClosed = void Function(int start, int end);

/// Callback type for when a code block is found but not closed.
/// Returns true to continue parsing, false to break.
typedef OnCodeBlockOpen = bool Function(int startLine, String language);

/// Result of parsing markdown lines.
class _ParseResult {
  const _ParseResult({
    required this.blocks,
    required this.nextIndex,
    this.hasOpenCodeBlock = false,
  });

  final List<MD$Block> blocks;
  final int nextIndex;
  final bool hasOpenCodeBlock;
}

/// Core parsing function shared by both [MarkdownDecoder] and
/// [StreamingMarkdownDecoder].
///
/// Parameters:
/// - [length]: Total number of lines
/// - [lineAt]: Function to get line text at index
/// - [startIndex]: Index to start parsing from
/// - [existingBlocks]: Optional existing blocks to append to
/// - [onBlockClosed]: Optional callback when a block is closed
/// - [onCodeBlockOpen]: Optional callback when code block is open (not closed)
_ParseResult _parseMarkdownLines({
  required int length,
  required String Function(int index) lineAt,
  int startIndex = 0,
  List<MD$Block>? existingBlocks,
  OnBlockClosed? onBlockClosed,
  OnCodeBlockOpen? onCodeBlockOpen,
}) {
  final blocks = existingBlocks ?? <MD$Block>[];
  final paragraph = StringBuffer();
  var hasOpenCodeBlock = false;

  void maybeCommitParagraph() {
    if (paragraph.isEmpty) return;
    final text = paragraph.toString();
    paragraph.clear();
    blocks.add(MD$Paragraph(
      text: text,
      spans: _parseInlineSpans(text),
    ));
  }

  void pushBlock(MD$Block block) {
    maybeCommitParagraph();
    blocks.add(block);
  }

  var i = startIndex;
  for (; i < length; i++) {
    final line = lineAt(i);

    // --- Empty lines / Spacer ---
    if (line.isEmpty || _emptyPattern.hasMatch(line)) {
      var j = i + 1;
      for (; j < length && _emptyPattern.hasMatch(lineAt(j)); j++) continue;
      final count = j - i;

      if (j < length) {
        onBlockClosed?.call(i, j);
      }

      pushBlock(MD$Spacer(count: count));
      if (i + count == length) break;
      i = j - 1;
      continue;
    }

    // --- Horizontal rule ---
    if (line.startsWith('---')) {
      if (i + 1 < length) {
        onBlockClosed?.call(i, i + 1);
      }
      pushBlock(const MD$Divider());
      continue;
    }

    // --- Heading ---
    if (line.startsWith('#')) {
      final level =
          _headerPattern.firstMatch(line)?.group(0)?.length.clamp(1, 6) ?? 1;
      final text = line.substring(level).trim();

      if (i + 1 < length) {
        onBlockClosed?.call(i, i + 1);
      }

      pushBlock(MD$Heading(
        level: level,
        text: text,
        spans: _parseInlineSpans(text),
      ));
      continue;
    }

    // --- Quote ---
    if (line.startsWith('>')) {
      final buffer = StringBuffer()..write(line.substring(1).trim());
      var j = i + 1;
      for (; j < length && lineAt(j).startsWith('>'); j++) {
        buffer
          ..writeln()
          ..write(lineAt(j).substring(1).trim());
      }
      final text = buffer.toString();
      final count = j - i;

      if (j < length) {
        onBlockClosed?.call(i, j);
      }

      pushBlock(MD$Quote(
        indent: 1,
        text: text,
        spans: _parseInlineSpans(text),
      ));

      if (i + count == length) break;
      i = j - 1;
      continue;
    }

    // --- Code block ---
    if (line.startsWith('```')) {
      final language = line.length > 3 ? line.substring(3).trim() : '';
      var j = i + 1;
      for (; j < length && !lineAt(j).startsWith('```'); j++) continue;

      final foundClosing = j < length;

      if (foundClosing) {
        onBlockClosed?.call(i, j + 1);
        final codeLines = <String>[];
        for (var k = i + 1; k < j; k++) {
          codeLines.add(lineAt(k));
        }
        pushBlock(MD$Code(text: codeLines.join('\n'), language: language));

        if (j == length - 1) break;
        i = j;
      } else {
        // Code block not closed
        hasOpenCodeBlock = true;
        if (onCodeBlockOpen != null) {
          final shouldContinue = onCodeBlockOpen(i, language);
          if (!shouldContinue) {
            // Add partial code block and break
            final codeLines = <String>[];
            for (var k = i + 1; k < length; k++) {
              codeLines.add(lineAt(k));
            }
            pushBlock(MD$Code(text: codeLines.join('\n'), language: language));
            i = length;
            break;
          }
        } else {
          // Default behavior: treat as complete (for non-streaming)
          final codeLines = <String>[];
          for (var k = i + 1; k < length; k++) {
            codeLines.add(lineAt(k));
          }
          pushBlock(MD$Code(text: codeLines.join('\n'), language: language));
          i = length - 1;
        }
      }
      continue;
    }

    // --- List ---
    if (_listPattern.firstMatch(line) case RegExpMatch match
        when match.namedGroup('indent')?.isEmpty == true) {
      final marker = match.namedGroup('marker') ?? '*';
      final list = <({int intent, String marker, String text})>[
        (
          intent: 0,
          marker: marker,
          text: match.namedGroup('text')?.trim() ?? '',
        )
      ];

      var j = i + 1;
      for (; j < length; j++) {
        final listLine = lineAt(j);
        final listMatch = _listPattern.firstMatch(listLine);
        final indent = listMatch?.namedGroup('indent')?.length;
        if (indent == null) break;
        list.add((
          intent: indent,
          marker: listMatch?.namedGroup('marker') ?? '*',
          text: listMatch?.namedGroup('text')?.trim() ?? '',
        ));
      }

      // Convert to tree structure
      var offset = 0;
      List<MD$ListItem> traverse({int indent = 0}) {
        final items = <MD$ListItem>[];
        for (; offset < list.length; offset++) {
          final item = list[offset];
          if (item.intent == indent) {
            items.add(MD$ListItem(
              text: item.text,
              marker: item.marker,
              spans: _parseInlineSpans(item.text),
              indent: item.intent,
            ));
          } else if (item.intent > indent) {
            final children = traverse(indent: item.intent);
            if (items.isNotEmpty) {
              items.last = items.last.copyWith(
                  children: List<MD$ListItem>.unmodifiable(children));
            } else {
              items.add(MD$ListItem(
                marker: item.marker,
                text: item.text,
                spans: _parseInlineSpans(item.text),
                indent: item.intent,
                children: children,
              ));
            }
          } else {
            offset--;
            break;
          }
        }
        return items.isEmpty ? const <MD$ListItem>[] : items;
      }

      final count = j - i;
      final listLines = <String>[];
      for (var k = i; k < j && k < length; k++) {
        listLines.add(lineAt(k));
      }

      if (j < length) {
        onBlockClosed?.call(i, j);
      }

      pushBlock(MD$List(text: listLines.join('\n'), items: traverse()));

      if (i + count == length) break;
      i = j - 1;
      continue;
    }

    // --- Table ---
    if (line.startsWith('|')) {
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
      final separator = length > i + 1
          ? RegExp(r'^\|[ -:]+[ -|:]*\|$').hasMatch(lineAt(i + 1))
          : false;
      final rows = <MD$TableRow>[];
      var j = i + 2;
      for (; j < length && lineAt(j).startsWith('|'); j++) {
        rows.add(textToRow(lineAt(j)));
      }

      final columns = header.cells.length;
      if (columns > 0 &&
          separator &&
          rows.every((row) => row.cells.length == columns)) {
        final tableLines = <String>[];
        for (var k = i; k < j && k < length; k++) {
          tableLines.add(lineAt(k));
        }

        if (j < length) {
          onBlockClosed?.call(i, j);
        }

        pushBlock(MD$Table(
          text: tableLines.join('\n'),
          header: header,
          rows: List<MD$TableRow>.unmodifiable(rows),
        ));
      } else {
        // Malformed table, treat as paragraph
        if (paragraph.isNotEmpty) paragraph.writeln();
        paragraph.write(line);
        continue;
      }

      final count = j - i;
      if (i + count == length) break;
      i = j - 1;
      continue;
    }

    // --- Paragraph (default) ---
    if (paragraph.isNotEmpty) paragraph.writeln();
    paragraph.write(line);

    // Check if paragraph can be closed
    if (onBlockClosed != null && i + 1 < length) {
      final nextLine = lineAt(i + 1);
      if (nextLine.isEmpty ||
          _emptyPattern.hasMatch(nextLine) ||
          nextLine.startsWith('#') ||
          nextLine.startsWith('>') ||
          nextLine.startsWith('```') ||
          nextLine.startsWith('---') ||
          nextLine.startsWith('|') ||
          (_listPattern.firstMatch(nextLine)?.namedGroup('indent')?.isEmpty ==
              true)) {
        onBlockClosed(i, i + 1);
        maybeCommitParagraph();
      }
    }
  }

  maybeCommitParagraph();

  return _ParseResult(
    blocks: blocks,
    nextIndex: i,
    hasOpenCodeBlock: hasOpenCodeBlock,
  );
}

// ============================================================================
// MarkdownDecoder
// ============================================================================

/// {@template markdown_decoder}
/// A [Converter] that decodes Markdown formatted strings
/// into list of [MD$Block] objects.
/// This class is designed to parse Markdown syntax
/// and convert it into a structured format.
/// {@endtemplate}
class MarkdownDecoder extends Converter<String, Markdown> {
  /// Creates a new instance of [MarkdownDecoder].
  /// {@macro markdown_decoder}
  const MarkdownDecoder();

  @override
  Markdown convert(String input) {
    final lines = LineSplitter.split(input).toList(growable: false);
    if (lines.isEmpty) return const Markdown.empty();

    final result = _parseMarkdownLines(
      length: lines.length,
      lineAt: (i) => lines[i],
    );

    return Markdown(
      markdown: input,
      blocks: List<MD$Block>.unmodifiable(result.blocks),
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

List<MD$Span> _parseInlineSpans(String text) {
  if (text.isEmpty) return const <MD$Span>[];

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

      // Create a link or image span
      final parts = text.substring(urlIdx + 1, urlEnd).split(' ');
      final src = parts.firstOrNull ?? '';
      var alt = parts.length > 1 ? parts.skip(1).join(' ') : null;
      if (alt != null && alt.startsWith('"') && alt.endsWith('"')) {
        // Remove quotes from alt text
        alt = alt.substring(1, alt.length - 1);
      }
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

        final span = links[skip[i] - 1];
        spans.add(span);
        i = span.end - 1; // -1 because the loop will increment i
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
      late final isDouble = i + 1 < length && codes[i + 1] == ch;

      // Find the style for this marker
      switch (ch) {
        case 42: // '*'
          // Can be used for italic (single) or bold (double)
          if (isDouble) {
            maybePushSpan(i);
            // Bold (double)
            mask ^= MD$Style.bold;
            start = i + 2;
          } else {
            maybePushSpan(i);
            // Italic (single)
            mask ^= MD$Style.italic;
            start = i + 1;
          }
        case 61: // '='
          // Highlight (double)
          if (isDouble) {
            maybePushSpan(i);
            // Highlight
            mask ^= MD$Style.highlight;
            start = i + 2;
          } else {
            // This is just a single `=` character, so we skip it
            continue;
          }
        case 95: // '_'
          // Underline (double)
          if (isDouble) {
            maybePushSpan(i);
            // Underline (double)
            mask ^= MD$Style.underline;
            start = i + 2;
          } else {
            maybePushSpan(i);
            // Italic (single)
            mask ^= MD$Style.italic;
            start = i + 1;
          }
        case 96: // '`'
          // Monospace (single)
          if (isDouble) {
            // This is a double backtick, we should skip as it is not valid
            i++; // skip next character
            continue;
          } else {
            maybePushSpan(i);
            // Monospace
            mask ^= MD$Style.monospace;
            start = i + 1;
          }
        case 124: // '|'
          // Spoiler (double)
          if (isDouble) {
            maybePushSpan(i);
            // Spoiler
            mask ^= MD$Style.spoiler;
            start = i + 2;
          } else {
            // Single - this is just a single `|` character, so we skip it
            continue;
          }
        case 126: // '~'
          // Strikethrough (double)
          if (isDouble) {
            maybePushSpan(i);
            // Strikethrough
            mask ^= MD$Style.strikethrough;
            start = i + 2;
          } else {
            // Single - this is just a single `~` character, so we skip it
            continue;
          }
        default:
          // Here we would handle any other inline markers,
          // such as custom markers or any other special symbols.
          continue; // Skip unknown markers
      }

      if (isDouble) i++; // if it's a double marker, skip the next character
    }
    // If we have any remaining text after the last marker, add it as a span
    maybePushSpan(length);
  }

  // This function would parse inline spans like bold, italic, links, etc.
  // For now, it returns an empty list as a placeholder.
  return spans;
}

// ============================================================================
// Streaming Markdown Decoder
// ============================================================================

/// {@template streaming_markdown_decoder}
/// A streaming Markdown decoder optimized for LLM output scenarios.
///
/// Unlike [MarkdownDecoder] which parses the entire input on each call,
/// this decoder maintains state across multiple [append] calls and only
/// re-parses lines that are still open (not yet closed).
///
/// Uses the same core parsing logic as [MarkdownDecoder] via
/// [_parseMarkdownLines], but with line state tracking.
///
/// Usage:
/// ```dart
/// final decoder = StreamingMarkdownDecoder();
/// decoder.append('# Hello');
/// decoder.append(' World\n\nSome text');
/// final markdown = decoder.build();
/// ```
/// {@endtemplate}
class StreamingMarkdownDecoder {
  /// Creates a new streaming Markdown decoder.
  /// {@macro streaming_markdown_decoder}
  StreamingMarkdownDecoder();

  /// Parsed lines with their states.
  /// The last line is always the "pending line" that may receive more content.
  final List<ParsedLine> _lines = [];

  /// Accumulated blocks from parsing.
  final List<MD$Block> _blocks = [];

  /// Index of the first open line, used to skip closed lines during parsing.
  int _firstOpenIndex = 0;

  /// Returns the current list of parsed blocks.
  List<MD$Block> get blocks => List.unmodifiable(_blocks);

  /// Returns the current number of lines.
  int get lineCount => _lines.length;

  /// Returns the index of the first open line.
  int get firstOpenIndex => _firstOpenIndex;

  /// Appends a chunk of text and triggers incremental parsing.
  ///
  /// The chunk may contain partial lines (no newline at the end),
  /// which will be buffered until a newline is received.
  Markdown append(String chunk) {
    if (chunk.isEmpty) {
      return Markdown(
        markdown: _lines.map((l) => l.text).join('\n'),
        blocks: List.unmodifiable(_blocks),
      );
    }

    _processChunk(chunk);
    _parse();

    return Markdown(
      markdown: _lines.map((l) => l.text).join('\n'),
      blocks: List.unmodifiable(_blocks),
    );
  }

  /// Processes a chunk of text, splitting into lines.
  void _processChunk(String chunk) {
    // Ensure we have a pending line to append to
    if (_lines.isEmpty || _lines.last.state == LineState.closed) {
      _lines.add(ParsedLine('', state: LineState.open));
    }

    // Append chunk to the pending line (last line)
    final pendingIndex = _lines.length - 1;
    final pending = _lines[pendingIndex];
    final combined = pending.text + chunk;

    // Use LineSplitter to split the combined text
    final split = LineSplitter.split(combined).toList(growable: false);

    if (split.length > 1) {
      // Multiple lines: we have newline characters
      _lines[pendingIndex] = ParsedLine(split[0], state: LineState.open);

      for (var i = 1; i < split.length; i++) {
        _lines.add(ParsedLine(split[i], state: LineState.open));
      }

      // If combined ends with newline, add empty pending line
      if (combined.endsWith('\n') || combined.endsWith('\r')) {
        _lines.add(ParsedLine('', state: LineState.open));
      }
    } else {
      _lines[pendingIndex] = ParsedLine(combined, state: LineState.open);
    }
  }

  /// Marks lines from [start] to [end] (exclusive) as closed.
  void _closeLines(int start, int end) {
    for (var k = start; k < end && k < _lines.length; k++) {
      _lines[k].state = LineState.closed;
    }
    if (end <= _lines.length) {
      _firstOpenIndex = end;
    }
  }

  /// Main parsing method using the shared [_parseMarkdownLines] function.
  void _parse() {
    // Remove blocks from _firstOpenIndex onwards (need to re-parse)
    _truncateBlocks();

    // Skip already closed lines
    while (_firstOpenIndex < _lines.length &&
        _lines[_firstOpenIndex].state == LineState.closed) {
      _firstOpenIndex++;
    }

    final result = _parseMarkdownLines(
      length: _lines.length,
      lineAt: (i) => _lines[i].text,
      startIndex: _firstOpenIndex,
      existingBlocks: _blocks,
      onBlockClosed: _closeLines,
      onCodeBlockOpen: (startLine, language) {
        // Don't continue parsing, break to wait for more input
        return false;
      },
    );

    // Update _firstOpenIndex based on parse result
    if (result.nextIndex > _firstOpenIndex && !result.hasOpenCodeBlock) {
      // If we parsed some lines and no open code block, update index
      for (var i = _firstOpenIndex;
          i < result.nextIndex && i < _lines.length;
          i++) {
        if (_lines[i].state == LineState.closed) {
          _firstOpenIndex = i + 1;
        }
      }
    }
  }

  /// Truncates blocks that need to be re-parsed.
  void _truncateBlocks() {
    // Count closed blocks by estimating line consumption
    var count = 0;
    var lineIdx = 0;

    for (final block in _blocks) {
      if (lineIdx >= _firstOpenIndex) break;
      final linesInBlock = _estimateBlockLines(block);
      if (lineIdx + linesInBlock <= _firstOpenIndex) {
        count++;
        lineIdx += linesInBlock;
      } else {
        break;
      }
    }

    if (count < _blocks.length) {
      _blocks.removeRange(count, _blocks.length);
    }
  }

  /// Estimates how many lines a block consumes.
  int _estimateBlockLines(MD$Block block) {
    return block.map(
      paragraph: (p) => p.text.split('\n').length,
      heading: (_) => 1,
      quote: (q) => q.text.split('\n').length,
      code: (c) => c.text.split('\n').length + 2,
      list: (l) => l.text.split('\n').length,
      divider: (_) => 1,
      table: (t) => t.text.split('\n').length,
      spacer: (s) => s.count,
    );
  }

  /// Resets the decoder to its initial state.
  void reset() {
    _lines.clear();
    _blocks.clear();
    _firstOpenIndex = 0;
  }

  /// Builds the final Markdown result.
  Markdown build() {
    return Markdown(
      markdown: _lines.map((l) => l.text).join('\n'),
      blocks: List.unmodifiable(_blocks),
    );
  }
}
