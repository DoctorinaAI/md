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
    required this.text,
    required this.blocks,
  });

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
