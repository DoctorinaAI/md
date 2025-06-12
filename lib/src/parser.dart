import 'dart:convert';

/// {@template markdown_decoder}
/// A [Converter] that decodes Markdown formatted strings into node tree.
/// {@endtemplate}
class MarkdownDecoder extends Converter<String, String> {
  const MarkdownDecoder();

  @override
  String convert(String input) {
    // This is a placeholder for actual Markdown parsing logic.
    // In a real implementation, you would use a Markdown parser library.
    return input.replaceAll('#', '<h1>').replaceAll('\n', '<br>');
  }
}
