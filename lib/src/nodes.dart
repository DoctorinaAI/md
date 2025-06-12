import 'package:meta/meta.dart';

/// {@template markdown_style}
/// A bitmask representing the style of Markdown inline text.
/// This can include styles like bold, italic, underline, etc.
/// You can combine multiple styles using bitwise operations.
/// For example, to create a bold and italic style,
/// you can use `MD$Style.bold | MD$Style.italic`.
/// {@endtemplate}
extension type const MD$Style(int value) implements int {
  /// No style applied to the text.
  static const MD$Style none = MD$Style(0);

  /// Bold text style.
  static const MD$Style bold = MD$Style(1 << 0);

  /// Italic text style.
  static const MD$Style italic = MD$Style(1 << 1);

  /// Underline text style.
  static const MD$Style underline = MD$Style(1 << 2);

  /// Strikethrough text style.
  static const MD$Style strikethrough = MD$Style(1 << 3);

  /// Monospace text style, typically used for code.
  static const MD$Style monospace = MD$Style(1 << 4);

  /// Link text style, used for hyperlinks.
  static const MD$Style link = MD$Style(1 << 5);

  /// Highlight text style, used for emphasizing text.
  static const MD$Style highlight = MD$Style(1 << 6);

  /// Check if the style contains a specific flag.
  /// This is useful for checking if a specific style is applied to the text.
  bool contains(MD$Style flag) => (value & flag.value) != 0;

  /// Add a style flag to the current style.
  MD$Style add(MD$Style flag) => MD$Style(value | flag.value);

  /// Remove a style flag from the current style.
  MD$Style remove(MD$Style flag) => MD$Style(value & ~flag.value);

  /// Returns a set of style flags that are currently applied to the text.
  /// Useful for debugging or displaying the styles applied to the text.
  ///
  /// For example:
  /// ```dart
  /// print(span.style.styles.join('|'));
  /// ```
  Set<String> get styles => <String>{
        if (contains(MD$Style.bold)) 'bold',
        if (contains(MD$Style.italic)) 'italic',
        if (contains(MD$Style.underline)) 'underline',
        if (contains(MD$Style.strikethrough)) 'strikethrough',
        if (contains(MD$Style.monospace)) 'monospace',
        if (contains(MD$Style.link)) 'link',
        if (contains(MD$Style.highlight)) 'highlight',
      };
}

/// {@template markdown_span}
/// Markdown inline text representation.
/// {@endtemplate}
final class MD$Span {
  /// Creates a new instance of [MD$Span].
  /// The [text] is the content of the inline text,
  /// and [style] is the text style applied to it.
  /// {@macro markdown_span}
  const MD$Span({required this.text, this.style = 0, this.extra});

  /// The text content of the inline text.
  final String text;

  /// The style applied to the inline text.
  /// This can include font size, color, weight, etc.
  /// Using bitmasking, you can combine multiple styles.
  /// For example, you can have both bold and italic styles applied.
  /// This is an optional property that can be used to set the text style.
  final int style;

  /// Extra properties for the inline text.
  /// This can include additional metadata or attributes.
  /// For example, you can use it to store links or color information.
  final Map<int, Object?>? extra;

  @override
  String toString() => text;
}

/// {@template markdown_block}
/// A base class for all Markdown blocks.
/// {@endtemplate}
sealed class MD$Block {
  /// {@macro markdown_block}
  const MD$Block();

  /// Text content of the block.
  abstract final String text;

  @override
  String toString() => text;
}

/// A block representing a paragraph in Markdown.
/// Contains inline text spans that can have different styles.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$Paragraph extends MD$Block {
  /// Creates a new instance of [MD$Paragraph].
  /// {@macro markdown_block}
  MD$Paragraph({required this.text, required this.spans});

  @override
  final String text;

  /// The inline text spans within the paragraph.
  /// Each span can have its own style.
  final List<MD$Span> spans;
}

/// A block representing a heading in Markdown.
/// Contains a level (1-6) indicating the heading's importance.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$Heading extends MD$Block {
  /// Creates a new instance of [MD$Heading].
  /// {@macro markdown_block}
  MD$Heading({required this.text, required this.level, required this.spans});

  @override
  final String text;

  /// The level of the heading (1-6).
  final int level;

  /// The inline text spans within the heading.
  final List<MD$Span> spans;
}

/// A block representing a quote in Markdown.
/// Contains inline text spans that can have different styles.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$Quote extends MD$Block {
  /// Creates a new instance of [MD$Quote].
  /// {@macro markdown_block}
  MD$Quote({required this.text, required this.spans});

  @override
  final String text;

  /// The inline text spans within the quote.
  final List<MD$Span> spans;
}

/// A block representing a code block in Markdown.
/// Contains the code text and an optional programming language.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$Code extends MD$Block {
  /// Creates a new instance of [MD$Code].
  /// {@macro markdown_block}
  MD$Code({required this.text, required this.language});

  @override
  final String text;

  /// The programming language of the code block.
  final String? language;
}

/// A block representing a list in Markdown.
/// Contains a list of items, each represented as a list of inline text spans.
/// The [indent] property indicates the indentation level of the list.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$List extends MD$Block {
  /// Creates a new instance of [MD$List].
  /// {@macro markdown_block}
  MD$List({
    required this.text,
    required this.items,
    this.indent = 0,
  });

  @override
  final String text;

  /// The indent of the list block in the document.
  /// This is used to determine the indentation level of the list.
  final int indent;

  /// The list items in the list block.
  final List<List<MD$Span>> items;
}

/// A block representing a horizontal rule in Markdown.
/// A horizontal rule is a thematic break that separates content.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$Divider extends MD$Block {
  /// Creates a new instance of [MD$Divider].
  /// {@macro markdown_block}
  @literal
  const MD$Divider();

  @override
  final String text = '---'; // Represents a horizontal rule.
}

/// A block representing a table in Markdown.
/// Contains a header row and a list of rows,
/// each represented as a list of inline text spans.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$Table extends MD$Block {
  /// Creates a new instance of [MD$Table].
  /// {@macro markdown_block}
  MD$Table({required this.text, required this.header, required this.rows});

  @override
  final String text;

  /// The header row of the table.
  final List<MD$Span> header;

  /// The rows of the table.
  final List<List<MD$Span>> rows;
}

/// A block representing an image in Markdown.
/// Contains the image source URL, an optional title,
/// and inline text spans for the alt text.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$Image extends MD$Block {
  /// Creates a new instance of [MD$Image].
  /// {@macro markdown_block}
  MD$Image({
    required this.text,
    required this.src,
    required this.spans,
    this.title,
  });

  @override
  final String text;

  /// The source URL of the image.
  final String src;

  /// An optional title for the image.
  final String? title;

  /// The inline text spans for the alt text of the image.
  final List<MD$Span> spans;
}
