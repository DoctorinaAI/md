import 'dart:collection';
import 'dart:convert';

import 'nodes.dart';

/// Decodes Markdown formatted strings
/// into a list of [MD$Block] objects.
const Converter<String, List<MD$Block>> mdDecoder = MarkdownDecoder();

/// {@template markdown_decoder}
/// A [Converter] that decodes Markdown formatted strings
/// into list of [MD$Block] objects.
/// This class is designed to parse Markdown syntax
/// and convert it into a structured format
/// {@endtemplate}
class MarkdownDecoder extends Converter<String, List<MD$Block>> {
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
  List<MD$Block> convert(String input) {
    final lines = LineSplitter.split(input).toList(growable: false);
    if (lines.isEmpty) return const <MD$Block>[];
    final result = Queue<MD$Block>();
    final length = lines.length;

    final paragraph = StringBuffer(); // To accumulate lines for paragraphs

    @pragma('vm:prefer-inline')
    void maybeCommitParagraph() {
      if (paragraph.isEmpty) return;
      final text = paragraph.toString();
      paragraph.clear();
      result.addLast(MD$Paragraph(
        text: text,
        spans: _parseInlineSpans(text),
      ));
    }

    void pushBlock(MD$Block block) {
      maybeCommitParagraph();
      result.addLast(block);
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
        final buffer = StringBuffer()..writeln(line.substring(1).trim());
        var j = i + 1;
        for (; j < length && lines[j].startsWith('>'); j++)
          buffer.writeln(lines[j].substring(1).trim());
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
        List<MD$ListItem> traverse({required int start, int indent = 0}) {
          final items = <MD$ListItem>[];
          for (var k = start; k < list.length; k++) {
            final item = list[k];
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
              final children = traverse(start: k, indent: item.intent);
              if (items.isNotEmpty) {
                // If we have a parent item, add children to it
                items.last = items.last.copyWith(children: children);
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
              break;
            }
          }
          if (items.isEmpty) return const <MD$ListItem>[];
          return items; // Return the list of items at this level
        }

        // Create the list block with the items
        pushBlock(MD$List(
          text: lines.sublist(i, j).join('\n'),
          items: traverse(start: 0),
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
          pushBlock(MD$Table(
            text: lines.sublist(i, j).join('\n'),
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
        paragraph.writeln(line);
        continue;
      }
      // TODO(plugfox): Implement tables
      // Mike Matiunin <plugfox@gmail.com>, 12 June 2025

      // TODO(plugfox): Implement images
      // Mike Matiunin <plugfox@gmail.com>, 12 June 2025
    }

    return List<MD$Block>.unmodifiable(result);
  }
}

List<MD$Span> _parseInlineSpans(String text) {
  // This function would parse inline spans like bold, italic, links, etc.
  // For now, it returns an empty list as a placeholder.
  return text
      .split(' ')
      .map<MD$Span>((word) => MD$Span(text: word))
      .toList(growable: false);
}
