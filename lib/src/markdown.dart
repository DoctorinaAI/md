import 'package:meta/meta.dart';

import 'nodes.dart';
import 'parser.dart' show markdownDecoder;

/// {@template markdown}
/// Markdown entity.
/// {@endtemplate}
@immutable
final class Markdown {
  /// Creates a [Markdown] instance with the given text and blocks.
  /// {@macro markdown}
  const Markdown({
    required this.markdown,
    required this.blocks,
  });

  /// Empty markdown.
  /// {@macro markdown}
  const Markdown.empty()
      : markdown = '',
        blocks = const <MD$Block>[];

  /// Creates a [Markdown] instance from a markdown string.
  /// This method uses the [markdownDecoder] to parse the string
  /// and convert it into a list of [MD$Block] objects.
  /// {@macro markdown}
  factory Markdown.fromString(String markdown) =>
      markdownDecoder.convert(markdown);

  /// Plain text representation of the markdown.
  ///
  /// WARNING: This is not the same as the original markdown string
  /// and relatively expensive to compute.
  String get text {
    if (blocks.isEmpty) return markdown;
    final buffer = StringBuffer();
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (i > 0) buffer.writeln();
      switch (block) {
        case MD$Paragraph(:List<MD$Span> spans):
          for (final span in spans) buffer.write(span.text);
        case MD$Heading(:List<MD$Span> spans):
          for (final span in spans) buffer.write(span.text);
        case MD$Quote(:List<MD$Span> spans):
          for (final span in spans) buffer.write(span.text);
        case MD$Code(:String text):
          buffer.write(text);
        case MD$List(:List<MD$ListItem> items):
          for (var i = 0; i < items.length; i++) {
            if (i > 0) buffer.writeln();
            final item = items[i];
            for (final span in item.spans) buffer.write(span.text);
          }
        case MD$Table(:List<MD$TableRow> rows):
          for (var i = 0; i < rows.length; i++) {
            if (i > 0) buffer.writeln();
            final row = rows[i];
            for (var j = 0; j < row.cells.length; j++) {
              //if (j > 0) buffer.write(' | ');
              final spans = row.cells[j];
              for (final span in spans) buffer.write(span.text);
            }
          }
        case MD$Divider():
          buffer.write('---');
        case MD$Spacer():
          break;
      }
    }
    return buffer.toString();
  }

  /// The original markdown string.
  final String markdown;

  /// List of blocks in the markdown.
  final List<MD$Block> blocks;

  @override
  String toString() => markdown;
}
