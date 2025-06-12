import 'dart:collection';
import 'dart:convert';

import 'nodes.dart';

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

  @override
  List<MD$Block> convert(String input) {
    final result = Queue<MD$Block>();
    final lines = LineSplitter.split(input).iterator;

    while (lines.moveNext()) {
      final line = lines.current.trimRight();
      // Here you would implement the logic to parse the line
      // and create the appropriate MD$Block instances.
      // This is a placeholder for demonstration purposes.
      if (line.isEmpty) {
        /// Parse empty lines
      } else if (line.startsWith('---')) {
        // Parse horizontal rules
      } else if (line.startsWith('#')) {
        // Parse headings
        // You would need to implement the actual parsing logic.
        continue;
      } else if (line.startsWith('>')) {
        // Parse quotes
        // You would need to implement the actual parsing logic.
        continue;
      } else if (line.startsWith('```')) {
        // Parse code blocks
        // You would need to implement the actual parsing logic.
        continue;
      } else {
        // Parse paragraphs or other blocks
        // You would need to implement the actual parsing logic.
        continue;
      }
    }

    return result.toList(growable: false);
  }
}
