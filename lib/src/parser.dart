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
  /// Starts with 1-6 unescaped `#` characters which must not be followed by a
  /// non-space character. Line may end with any number of `#` characters,.
  static final RegExp _headerPattern = RegExp(r'^(#{1,6})');

  /// A regular expression pattern to match ordered lists.
  /// Matches lines that start with a number followed by a period
  /// or parenthesis, or with a bullet point (`*`, `+`, or `-`).
  static final RegExp _listPattern =
      RegExp(r'^(?<indent>[ ]{0,6})(?:(\d{1,9})[\.)]|[*+-])(?:[ \t]+(.*))?$');

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
        pushBlock(MD$Spacer(count: j - i));
        if (j == length - 1) break; // Last line is empty
        i = j - 1; // Skip the empty lines
        continue;
      } else if (line.startsWith('---')) {
        // Parse horizontal rules
        pushBlock(const MD$Divider());
        continue;
      } else if (line.startsWith('#')) {
        // Parse headings
        final level =
            _headerPattern.firstMatch(line)?.group(0)?.length.clamp(1, 6) ?? 1;
        final text = line.substring(level).trim();
        pushBlock(MD$Heading(
            level: level, text: text, spans: _parseInlineSpans(text)));
        continue;
      } else if (line.startsWith('>')) {
        // Parse quotes
        final buffer = StringBuffer()..write(line.substring(1).trim());
        var j = i + 1;
        for (; j < length && lines[j].startsWith('>'); j++) {
          buffer
            ..writeln()
            ..write(lines[j].substring(1).trim());
        }
        final text = buffer.toString();
        pushBlock(MD$Quote(
          text: text,
          spans: _parseInlineSpans(text),
        ));
        if (j == length - 1) break; // Last line is a quote
        i = j - 1; // Skip the empty lines
        continue;
      } else if (line.startsWith('```')) {
        // Parse code blocks
        final language = line.length > 3 ? line.substring(3).trim() : '';
        var j = i + 1;
        for (; j < length && !lines[j].startsWith('```'); j++) continue;
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
        final list = <({int intent, String text})>[
          (
            intent: 0,
            text: line.trim(),
          )
        ];
        var j = i + 1;
        for (; j < length; j++) {
          final line = lines[j];
          final indent =
              _listPattern.firstMatch(line)?.namedGroup('indent')?.length;
          if (indent == null) break;
          list.add((
            intent: indent,
            text: line.substring(indent).trim(),
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
                spans: _parseInlineSpans(item.text),
                indent: item.intent,
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
                  text: item.text,
                  spans: _parseInlineSpans(item.text),
                  indent: item.intent,
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
        final text = lines.sublist(i, j).join('\n');
        pushBlock(MD$List(
          text: text,
          items: traverse(),
        ));

        if (j == length - 1) break; // Last line is a list item
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
        final rows = <MD$TableRow>[];
        var j = i + 2; // Skip the header and separator line
        for (; j < length && lines[j].startsWith('|'); j++)
          rows.add(textToRow(lines[j]));
        // Validate
        final columns = header.cells.length;
        if (rows.every((row) => row.cells.length == columns)) {
          // All rows have the same number of cells as the header
          final text = lines.sublist(i, j).join('\n');
          pushBlock(MD$Table(
            text: text,
            header: header,
            rows: List<MD$TableRow>.unmodifiable(rows),
          ));
        } else {
          assert(
            false,
            'Table rows have different number of cells: '
            'header has $columns, but some rows have different counts.',
          );
        }

        if (j == length - 1) break; // Last line is a table row
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
final Uint8List _kind = Uint8List(128)
  ..[42] = 1 // * - italic and bold (single and double)
  ..[61] = 1 // = - highlight (double)
  ..[95] = 1 // _ - underline (double)
  ..[96] = 1 // ` - monospace (single)
  ..[124] = 1 // | - spoiler (double)
  ..[126] = 1; // ~ - strikethrough (double)

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
      for (var k = urlIdx + 1; k < codes.length; k++) {
        final ck = codes[k];
        if (ck == esc) {
          k++;
          continue;
        }
        if (ck == url$end) {
          urlEnd = k;
          break;
        }
      }

      // If there is no closing ')', there is no more links or images
      if (urlEnd == -1) break;

      // Create a link or image span
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
            'url': text.substring(urlIdx + 1, urlEnd),
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
  {
    for (var i = 0; i < length; i++) {
      final ch = codes[i];

      // Check for escaped characters
      if (ch == esc /* \ */) {
        i++; // skip next char
        continue;
      }

      // If this character is part of a link or image, skip it
      if (skip[i] != 0) {
        // Finish the current span if it exists
        if (start < i)
          spans.add(
            MD$Span(
              start: start,
              end: i,
              text: text.substring(start, i),
              style: mask,
            ),
          );

        final span = links[skip[i] - 1];
        spans.add(span);
        i = span.end - 1; // -1 because the loop will increment i
        start = i + 1;
        continue;
      }

      // If the character is not a special inline marker, continue
      if (_kind[ch] == 0) continue;

      // If we reach here, it means we have a special inline marker
      if (start < i)
        spans.add(
          MD$Span(
            start: start,
            end: i,
            text: text.substring(start, i),
            style: mask,
          ),
        );

      // Check if the next character is the same kind
      // This is used to determine if it's a single or double marker.
      final isDouble = i + 1 < length && codes[i + 1] == ch;

      // Find the style for this marker
      switch (ch) {
        case 42: // '*'
          // Can be used for italic (single) or bold (double)
          if (isDouble) {
            // Bold (double)
            mask ^= MD$Style.bold;
            start = i + 2;
          } else {
            // Italic (single)
            mask ^= MD$Style.italic;
            start = i + 1;
          }
        case 61: // '='
          // Highlight (double)
          if (isDouble) {
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
            // Underline (double)
            mask ^= MD$Style.underline;
            start = i + 2;
          } else {
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
            // Monospace
            mask ^= MD$Style.monospace;
            start = i + 1;
          }
        case 124: // '|'
          // Spoiler (double)
          if (isDouble) {
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
            // Strikethrough
            mask ^= MD$Style.strikethrough;
            start = i + 2;
          } else {
            // Single - this is just a single `~` character, so we skip it
            continue;
          }
        default:
          assert(
            false,
            'Unknown inline marker: $ch at position $i in "$text"',
          );
          continue; // Skip unknown markers
      }

      if (isDouble) i++; // if it's a double marker, skip the next character
    }
    // If we have any remaining text after the last marker, add it as a span
    if (start < length)
      spans.add(
        MD$Span(
          start: start,
          end: length,
          text: text.substring(start, length),
          style: mask,
        ),
      );
  }

  // This function would parse inline spans like bold, italic, links, etc.
  // For now, it returns an empty list as a placeholder.
  return spans;
}
