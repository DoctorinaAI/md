import 'package:meta/meta.dart';

/// {@template markdown_style}
/// A bitmask representing the style of Markdown inline text.
/// This can include styles like bold, italic, underline, etc.
/// You can combine multiple styles using bitwise operations.
/// For example, to create a bold and italic style,
/// you can use `MD$Style.bold | MD$Style.italic`.
/// {@endtemplate}
@immutable
extension type const MD$Style(int value) implements int {
  /// No style applied to the text.
  static const MD$Style none = MD$Style(0);

  /// Italic text style.
  /// Symbol: `*text*`.
  static const MD$Style italic = MD$Style(1 << 0);

  /// Bold text style.
  /// Symbol: `**text**`.
  static const MD$Style bold = MD$Style(1 << 1);

  /// Underline text style.
  /// Symbol: `__text__` (double underscore).
  static const MD$Style underline = MD$Style(1 << 2);

  /// Strikethrough text style.
  /// Symbol: `~~text~~`.
  static const MD$Style strikethrough = MD$Style(1 << 3);

  /// Monospace text style, typically used for code.
  /// Symbol: `` `text` `` (backticks).
  static const MD$Style monospace = MD$Style(1 << 4);

  /// Link text style, used for hyperlinks.
  /// Symbol: `[text](url)` or `<url>`.
  static const MD$Style link = MD$Style(1 << 5);

  /// Inline image text style, used for images within text.
  /// Symbol: `![alt text](image_url)` or `![alt text](image_url "title")`.
  static const MD$Style image = MD$Style(1 << 6);

  /// Highlight text style, used for emphasizing text.
  /// Symbol: `==text==`.
  static const MD$Style highlight = MD$Style(1 << 7);

  /// Spoiler text style, used for hiding text until revealed.
  /// Symbol: `||text||`.
  static const MD$Style spoiler = MD$Style(1 << 8);

  // --- Can be expanded up to 1 << 31 --- //

  /// A list of all styles available in the MD$Style enum.
  /// This is useful for iterating over styles or checking if a style exists.
  static const List<MD$Style> values = <MD$Style>[
    none,
    italic,
    bold,
    underline,
    strikethrough,
    monospace,
    link,
    image,
    highlight,
    spoiler,
  ];

  /// Check if the style contains a specific flag.
  /// This is useful for checking if a specific style is applied to the text.
  bool contains(MD$Style flag) => (value & flag.value) != 0;

  /// Add a style flag to the current style.
  MD$Style add(MD$Style flag) => MD$Style(value | flag.value);

  /// Remove a style flag from the current style.
  MD$Style remove(MD$Style flag) => MD$Style(value & ~flag.value);

  /// Toggle a style flag in the current style.
  MD$Style toggle(MD$Style flag) => MD$Style(value ^ flag.value);

  /// Check if the style is empty (no styles applied).
  bool get isEmpty => value == 0;

  /// Check if the style is not empty (at least one style is applied).
  bool get isNotEmpty => value != 0;

  /// Returns a set of style flags that are currently applied to the text.
  /// Useful for debugging or displaying the styles applied to the text.
  ///
  /// For example:
  /// print(span.style.styles.join('|'));
  Set<String> get styles => value == 0
      ? const <String>{}
      : <String>{
          if (contains(MD$Style.italic)) 'italic',
          if (contains(MD$Style.bold)) 'bold',
          if (contains(MD$Style.underline)) 'underline',
          if (contains(MD$Style.strikethrough)) 'strikethrough',
          if (contains(MD$Style.monospace)) 'monospace',
          if (contains(MD$Style.link)) 'link',
          if (contains(MD$Style.image)) 'image',
          if (contains(MD$Style.highlight)) 'highlight',
          if (contains(MD$Style.spoiler)) 'spoiler',
        };

  /// Toggle a style flag in the current style.
  MD$Style operator ^(MD$Style other) => MD$Style(value ^ other.value);
}

/// {@template markdown_span}
/// Markdown inline text representation.
/// {@endtemplate}
@immutable
final class MD$Span {
  /// Creates a new instance of [MD$Span].
  /// The [text] is the content of the inline text,
  /// and [style] is the text style applied to it.
  /// {@macro markdown_span}
  const MD$Span({
    required this.start,
    required this.end,
    required this.text,
    this.style = MD$Style.none,
    this.extra,
  });

  /// The start index of the inline text in the parent block.
  final int start;

  /// The end index of the inline text in the parent block.
  final int end;

  /// The text content of the inline text.
  final String text;

  /// The style applied to the inline text.
  /// This can include font size, color, weight, etc.
  /// Using bitmasking, you can combine multiple styles.
  /// For example, you can have both bold and italic styles applied.
  /// This is an optional property that can be used to set the text style.
  final MD$Style style;

  /// Extra properties for the inline text.
  /// This can include additional metadata or attributes.
  /// For example, you can use it to store links or color information.
  final Map<String, Object?>? extra;

  @override
  String toString() => text;
}

/// {@template markdown_block}
/// A base class for all Markdown blocks.
/// {@endtemplate}
@immutable
sealed class MD$Block {
  /// {@macro markdown_block}
  const MD$Block();

  /// The type of the block.
  abstract final String type;

  /// Text content of the block.
  abstract final String text;

  /// Pattern for matching the block type.
  /// This is used to identify the block type in the Markdown tree.
  T map<T>({
    required T Function(MD$Paragraph p) paragraph,
    required T Function(MD$Heading h) heading,
    required T Function(MD$Quote q) quote,
    required T Function(MD$Code c) code,
    required T Function(MD$List l) list,
    required T Function(MD$Divider d) divider,
    required T Function(MD$Table t) table,
    required T Function(MD$Spacer s) spacer,
  });

  /// Maps the block to a specific type based on its type.
  /// This is useful for handling different block types in a type-safe manner.
  T maybeMap<T>({
    T Function(MD$Paragraph p)? paragraph,
    T Function(MD$Heading h)? heading,
    T Function(MD$Quote q)? quote,
    T Function(MD$Code c)? code,
    T Function(MD$List l)? list,
    T Function(MD$Divider d)? divider,
    T Function(MD$Table t)? table,
    T Function(MD$Spacer s)? spacer,
    required T Function(MD$Block b) orElse,
  }) =>
      map(
        paragraph: paragraph ?? orElse,
        heading: heading ?? orElse,
        quote: quote ?? orElse,
        code: code ?? orElse,
        list: list ?? orElse,
        divider: divider ?? orElse,
        table: table ?? orElse,
        spacer: spacer ?? orElse,
      );

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
  const MD$Paragraph({
    required this.text,
    required this.spans,
  });

  @override
  String get type => 'paragraph';

  @override
  final String text;

  /// The inline text spans within the paragraph.
  /// Each span can have its own style.
  final List<MD$Span> spans;

  @override
  T map<T>({
    required T Function(MD$Paragraph p) paragraph,
    required T Function(MD$Heading h) heading,
    required T Function(MD$Quote q) quote,
    required T Function(MD$Code c) code,
    required T Function(MD$List l) list,
    required T Function(MD$Divider d) divider,
    required T Function(MD$Table t) table,
    required T Function(MD$Spacer s) spacer,
  }) =>
      paragraph(this);
}

/// A block representing a heading in Markdown.
/// Contains a level (1-6) indicating the heading's importance.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$Heading extends MD$Block {
  /// Creates a new instance of [MD$Heading].
  /// {@macro markdown_block}
  const MD$Heading({
    required this.text,
    required this.level,
    required this.spans,
  });

  @override
  String get type => 'heading';

  @override
  final String text;

  /// The level of the heading (1-6).
  final int level;

  /// The inline text spans within the heading.
  final List<MD$Span> spans;

  @override
  T map<T>({
    required T Function(MD$Paragraph p) paragraph,
    required T Function(MD$Heading h) heading,
    required T Function(MD$Quote q) quote,
    required T Function(MD$Code c) code,
    required T Function(MD$List l) list,
    required T Function(MD$Divider d) divider,
    required T Function(MD$Table t) table,
    required T Function(MD$Spacer s) spacer,
  }) =>
      heading(this);
}

/// A block representing a quote in Markdown.
/// Contains inline text spans that can have different styles.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$Quote extends MD$Block {
  /// Creates a new instance of [MD$Quote].
  /// {@macro markdown_block}
  const MD$Quote({
    required this.indent,
    required this.text,
    required this.spans,
  });

  @override
  String get type => 'quote';

  /// The indent of the quote block in the document.
  /// For example, a quote with an indent of 2 would be represented as:
  /// >> This is a quote.
  final int indent;

  @override
  final String text;

  /// The inline text spans within the quote.
  final List<MD$Span> spans;

  @override
  T map<T>({
    required T Function(MD$Paragraph p) paragraph,
    required T Function(MD$Heading h) heading,
    required T Function(MD$Quote q) quote,
    required T Function(MD$Code c) code,
    required T Function(MD$List l) list,
    required T Function(MD$Divider d) divider,
    required T Function(MD$Table t) table,
    required T Function(MD$Spacer s) spacer,
  }) =>
      quote(this);
}

/// A block representing a code block in Markdown.
/// Contains the code text and an optional programming language.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$Code extends MD$Block {
  /// Creates a new instance of [MD$Code].
  /// {@macro markdown_block}
  const MD$Code({
    required this.language,
    required this.text,
  });

  @override
  String get type => 'code';

  /// The programming language of the code block.
  final String? language;

  @override
  final String text;

  @override
  T map<T>({
    required T Function(MD$Paragraph p) paragraph,
    required T Function(MD$Heading h) heading,
    required T Function(MD$Quote q) quote,
    required T Function(MD$Code c) code,
    required T Function(MD$List l) list,
    required T Function(MD$Divider d) divider,
    required T Function(MD$Table t) table,
    required T Function(MD$Spacer s) spacer,
  }) =>
      code(this);
}

/// {@template list_item}
/// A items of a list in Markdown.
/// Each item can have its own text and inline text spans.
/// It can also have nested items, allowing for hierarchical lists.
/// {@endtemplate}
@immutable
final class MD$ListItem {
  /// Creates a new instance of [MD$ListItem].
  /// {@macro list_item}
  const MD$ListItem({
    required this.marker,
    required this.text,
    required this.spans,
    this.indent = 0,
    this.children = const <MD$ListItem>[],
  });

  /// The indent of the list block in the document.
  /// This is used to determine the indentation level of the list.
  final int indent;

  /// The marker used for the list item.
  final String marker;

  /// The text content of the list item.
  final String text;

  /// The inline text spans within the list item.
  final List<MD$Span> spans;

  /// The sub-items of the list item.
  /// This is used to represent nested lists within the list item.
  final List<MD$ListItem> children;

  /// Returns a copy of the list item with modified properties.
  /// This is useful for creating a new instance with some properties changed,
  MD$ListItem copyWith({
    String? marker,
    String? text,
    List<MD$Span>? spans,
    int? indent,
    List<MD$ListItem>? children,
  }) =>
      MD$ListItem(
        marker: marker ?? this.marker,
        text: text ?? this.text,
        spans: spans ?? this.spans,
        indent: indent ?? this.indent,
        children: children ?? this.children,
      );

  @override
  String toString() {
    if (children.isEmpty) return text;

    final buffer = StringBuffer(text);

    void traverse(List<MD$ListItem> items) {
      for (final item in items) {
        buffer.writeln('\n${'  ' * (item.indent - indent)}${item.text}');
        if (item.children.isNotEmpty) traverse(item.children);
      }
    }

    traverse(children);

    return buffer.toString();
  }
}

/// A block representing a list in Markdown.
/// Contains a list of items, each represented as a list of inline text spans.
/// The [indent] property indicates the indentation level of the list.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$List extends MD$Block {
  /// Creates a new instance of [MD$List].
  /// {@macro markdown_block}
  const MD$List({
    required this.text,
    required this.items,
  });

  @override
  String get type => 'list';

  @override
  final String text;

  /// The list items in the list block.
  final List<MD$ListItem> items;

  @override
  T map<T>({
    required T Function(MD$Paragraph p) paragraph,
    required T Function(MD$Heading h) heading,
    required T Function(MD$Quote q) quote,
    required T Function(MD$Code c) code,
    required T Function(MD$List l) list,
    required T Function(MD$Divider d) divider,
    required T Function(MD$Table t) table,
    required T Function(MD$Spacer s) spacer,
  }) =>
      list(this);
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
  String get type => 'divider';

  @override
  final String text = '---'; // Represents a horizontal rule.

  @override
  T map<T>({
    required T Function(MD$Paragraph p) paragraph,
    required T Function(MD$Heading h) heading,
    required T Function(MD$Quote q) quote,
    required T Function(MD$Code c) code,
    required T Function(MD$List l) list,
    required T Function(MD$Divider d) divider,
    required T Function(MD$Table t) table,
    required T Function(MD$Spacer s) spacer,
  }) =>
      divider(this);
}

/// {@template table_row}
/// A row in a Markdown table.
/// Each row contains text and a list of inline text spans for each cell.
/// {@endtemplate}
@immutable
final class MD$TableRow {
  /// Creates a new instance of [MD$TableRow].
  /// The [text] is the content of the row,
  /// and [cells] are the inline text spans within the row.
  /// {@macro table_row}
  const MD$TableRow({
    required this.text,
    required this.cells,
  });

  /// The text content of the row.
  final String text;

  /// The inline text spans within the row's cells.
  final List<List<MD$Span>> cells;

  @override
  String toString() => text;
}

/// A block representing a table in Markdown.
/// Contains a header row and a list of rows,
/// each represented as a list of inline text spans.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$Table extends MD$Block {
  /// Creates a new instance of [MD$Table].
  /// {@macro markdown_block}
  const MD$Table({
    required this.text,
    required this.header,
    required this.rows,
  });

  @override
  String get type => 'table';

  @override
  final String text;

  /// The header row of the table.
  final MD$TableRow header;

  /// The rows of the table.
  final List<MD$TableRow> rows;

  @override
  T map<T>({
    required T Function(MD$Paragraph p) paragraph,
    required T Function(MD$Heading h) heading,
    required T Function(MD$Quote q) quote,
    required T Function(MD$Code c) code,
    required T Function(MD$List l) list,
    required T Function(MD$Divider d) divider,
    required T Function(MD$Table t) table,
    required T Function(MD$Spacer s) spacer,
  }) =>
      table(this);
}

/* /// A block representing an image in Markdown.
/// Contains the image source URL, an optional title,
/// and inline text spans for the alt text.
/// Always a leaf node in the Markdown tree.
/// {@macro markdown_block}
final class MD$Image extends MD$Block {
  /// Creates a new instance of [MD$Image].
  /// {@macro markdown_block}
  const MD$Image({
    required this.text,
    required this.src,
    required this.spans,
    this.title,
  });

  @override
  String get type => 'image';

  @override
  final String text;

  /// The source URL of the image.
  final String src;

  /// An optional title for the image.
  final String? title;

  /// The inline text spans for the alt text of the image.
  final List<MD$Span> spans;

  @override
  T map<T>({
    required T Function(MD$Paragraph p) paragraph,
    required T Function(MD$Heading h) heading,
    required T Function(MD$Quote q) quote,
    required T Function(MD$Code c) code,
    required T Function(MD$List l) list,
    required T Function(MD$Divider d) divider,
    required T Function(MD$Table t) table,
    required T Function(MD$Image i) image,
    required T Function(MD$Spacer s) spacer,
  }) =>
      image(this);
} */

/// A block representing an empty row in Markdown.
/// This is used to represent a block that has no content.
/// It can be used to create spacing or separation in the document.
class MD$Spacer extends MD$Block {
  /// Creates a new instance of [MD$Spacer].
  /// {@macro markdown_block}
  const MD$Spacer({
    this.count = 1,
  }) : text = '\n' * count;

  @override
  String get type => 'spacer';

  @override
  final String text;

  /// The number of empty rows to create.
  /// This is used to create spacing in the document.
  final int count;

  @override
  T map<T>({
    required T Function(MD$Paragraph p) paragraph,
    required T Function(MD$Heading h) heading,
    required T Function(MD$Quote q) quote,
    required T Function(MD$Code c) code,
    required T Function(MD$List l) list,
    required T Function(MD$Divider d) divider,
    required T Function(MD$Table t) table,
    required T Function(MD$Spacer s) spacer,
  }) =>
      spacer(this);
}
