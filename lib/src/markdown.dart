import 'package:meta/meta.dart';

import 'nodes.dart';
import 'parser.dart' show markdownDecoder;

/// {@template markdown}
/// Markdown entity.
/// {@endtemplate}
@immutable
final class Markdown {
  /// {@macro markdown}
  const Markdown._({
    required this.text,
    required this.blocks,
  });

  /// Creates a [Markdown] instance with the given blocks.
  /// {@macro markdown}
  factory Markdown({
    required Iterable<MD$Block> blocks,
  }) {
    final list = List<MD$Block>.unmodifiable(blocks);
    final buffer = StringBuffer();
    //final styles = <MD$Style>{}; // All styles used in the markdown.
    for (final block in list) {
      buffer.writeln(block.text);
      /* switch (block) {
        case MD$Paragraph(:List<MD$Span> spans):
          for (final span in spans) styles.add(span.style);
        case MD$Heading(:List<MD$Span> spans):
          for (final span in spans) styles.add(span.style);
        case MD$Quote(:List<MD$Span> spans):
          for (final span in spans) styles.add(span.style);
        case MD$Code():
          styles.add(MD$Style.monospace);
        case MD$List(:List<MD$ListItem> items):
          for (final item in items)
            for (final span in item.spans) styles.add(span.style);
        case MD$Table():
          for (final row in block.rows)
            for (final spans in row.cells)
              for (final span in spans) styles.add(span.style);
        case MD$Divider():
          break;
        case MD$Spacer():
          break;
      } */
    }
    return Markdown._(text: buffer.toString(), blocks: list);
  }

  /// Empty markdown.
  /// {@macro markdown}
  const Markdown.empty()
      : text = '',
        blocks = const <MD$Block>[];

  /// Creates a [Markdown] instance from a markdown string.
  /// This method uses the [markdownDecoder] to parse the string
  /// and convert it into a list of [MD$Block] objects.
  /// {@macro markdown}
  factory Markdown.fromString(String markdown) =>
      markdownDecoder.convert(markdown);

  /// Plain text representation of the markdown.
  /// This is a concatenation of all block texts.
  final String text;

  /// List of blocks in the markdown.
  final List<MD$Block> blocks;

  @override
  String toString() => text;
}
