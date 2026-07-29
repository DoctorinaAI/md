// Unit tests for the node model (`nodes.dart`): the `MD$Style` bitmask helpers
// and the block/data-class `type`, `toString`, `maybeMap`, and `copyWith`
// members that the parser and renderer do not otherwise exercise.
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// A document that yields every block type once.
const String _doc = '# Heading\n'
    '\n'
    'A paragraph\n'
    '\n'
    '> A quote\n'
    '\n'
    '> [!NOTE]\n'
    '> Alert body\n'
    '\n'
    '```dart\n'
    'code();\n'
    '```\n'
    '\n'
    '- item a\n'
    '  - item b\n'
    '\n'
    '| x | y |\n'
    '| - | - |\n'
    '| 1 | 2 |\n'
    '\n'
    '---\n';

void main() {
  group('MD\$Style', () {
    test('add sets a flag', () {
      final s = MD$Style.bold.add(MD$Style.italic);
      expect(s.contains(MD$Style.bold), isTrue);
      expect(s.contains(MD$Style.italic), isTrue);
    });

    test('remove clears a flag', () {
      final s = MD$Style.bold.add(MD$Style.italic).remove(MD$Style.bold);
      expect(s.contains(MD$Style.bold), isFalse);
      expect(s.contains(MD$Style.italic), isTrue);
    });

    test('toggle flips a flag', () {
      expect(MD$Style.none.toggle(MD$Style.bold), MD$Style.bold);
      expect(MD$Style.bold.toggle(MD$Style.bold), MD$Style.none);
    });

    test('operator ^ toggles', () {
      expect(MD$Style.bold ^ MD$Style.bold, MD$Style.none);
      expect(MD$Style.none ^ MD$Style.italic, MD$Style.italic);
    });

    test('isEmpty / isNotEmpty', () {
      expect(MD$Style.none.isEmpty, isTrue);
      expect(MD$Style.none.isNotEmpty, isFalse);
      expect(MD$Style.bold.isNotEmpty, isTrue);
      expect(MD$Style.bold.isEmpty, isFalse);
    });

    test('styles names every flag and is empty for none', () {
      expect(MD$Style.none.styles, isEmpty);
      var all = MD$Style.none;
      for (final flag in MD$Style.values) {
        all = all.add(flag);
      }
      expect(
        all.styles,
        containsAll(<String>[
          'italic',
          'bold',
          'underline',
          'strikethrough',
          'monospace',
          'link',
          'image',
          'highlight',
          'spoiler',
        ]),
      );
    });
  });

  group('Block members', () {
    final blocks = markdownDecoder.convert(_doc).blocks;
    T pick<T extends MD$Block>() => blocks.whereType<T>().first;

    test('every block type is produced', () {
      expect(blocks.whereType<MD$Heading>(), isNotEmpty);
      expect(blocks.whereType<MD$Paragraph>(), isNotEmpty);
      expect(blocks.whereType<MD$Quote>(), isNotEmpty);
      expect(blocks.whereType<MD$Alert>(), isNotEmpty);
      expect(blocks.whereType<MD$Code>(), isNotEmpty);
      expect(blocks.whereType<MD$List>(), isNotEmpty);
      expect(blocks.whereType<MD$Table>(), isNotEmpty);
      expect(blocks.whereType<MD$Divider>(), isNotEmpty);
      expect(blocks.whereType<MD$Spacer>(), isNotEmpty);
    });

    test('type getters', () {
      expect(pick<MD$Heading>().type, 'heading');
      expect(pick<MD$Paragraph>().type, 'paragraph');
      expect(pick<MD$Quote>().type, 'quote');
      expect(pick<MD$Alert>().type, 'alert');
      expect(pick<MD$Code>().type, 'code');
      expect(pick<MD$List>().type, 'list');
      expect(pick<MD$Table>().type, 'table');
      expect(pick<MD$Divider>().type, 'divider');
      expect(pick<MD$Spacer>().type, 'spacer');
    });

    test('toString equals text', () {
      for (final block in blocks) {
        expect(block.toString(), block.text);
      }
    });

    test('maybeMap dispatches to the matching branch', () {
      expect(
        pick<MD$Heading>().maybeMap(heading: (h) => h.level, orElse: (_) => -1),
        1,
      );
      expect(
        pick<MD$Code>().maybeMap(code: (c) => c.language, orElse: (_) => null),
        'dart',
      );
      // Unhandled branch falls through to orElse.
      expect(
        pick<MD$Divider>().maybeMap(code: (_) => 'x', orElse: (_) => 'else'),
        'else',
      );
    });

    test('alert exposes its type and title', () {
      final alert = pick<MD$Alert>();
      expect(alert.alert, MD$AlertType.note);
      expect(alert.alert.title, 'Note');
    });

    test('divider text is a rule', () {
      expect(pick<MD$Divider>().text, '---');
    });

    test('spacer text is newlines', () {
      final spacer = pick<MD$Spacer>();
      expect(spacer.text, '\n' * spacer.count);
    });
  });

  group('MD\$AlertType', () {
    test('tryParse is case-insensitive and rejects unknowns', () {
      expect(MD$AlertType.tryParse('note'), MD$AlertType.note);
      expect(MD$AlertType.tryParse('Warning'), MD$AlertType.warning);
      expect(MD$AlertType.tryParse('nope'), isNull);
    });

    test('every type has a marker and a title', () {
      for (final type in MD$AlertType.values) {
        expect(type.marker, isNotEmpty);
        expect(type.title, isNotEmpty);
      }
    });
  });

  group('MD\$ListItem', () {
    final list = markdownDecoder
        .convert('- a with **bold**\n  - b\n    - c')
        .blocks
        .single as MD$List;

    test('toString renders nested children with indentation', () {
      final rendered = list.items.single.toString();
      expect(rendered, contains('a with'));
      expect(rendered, contains('b'));
      expect(rendered, contains('c'));
      expect(rendered, contains('\n'));
    });

    test('toString of a childless item is its text', () {
      const leaf = MD$ListItem(marker: '-', text: 'leaf', spans: []);
      expect(leaf.toString(), 'leaf');
    });

    test('copyWith overrides only provided fields', () {
      final item = list.items.single;
      final copy = item.copyWith(
        marker: '*',
        checked: true,
        children: const <MD$ListItem>[],
      );
      expect(copy.marker, '*');
      expect(copy.checked, isTrue);
      expect(copy.isTask, isTrue);
      expect(copy.children, isEmpty);
      // Untouched fields are preserved.
      expect(copy.text, item.text);
      expect(copy.indent, item.indent);
    });

    test('copyWith without children keeps the originals', () {
      final item = list.items.single;
      final copy = item.copyWith(indent: 9);
      expect(copy.indent, 9);
      expect(copy.children, same(item.children));
      expect(copy.marker, item.marker);
    });
  });

  group('MD\$TableRow', () {
    test('toString returns the row text', () {
      final table = markdownDecoder
          .convert('| x | y |\n| - | - |\n| 1 | 2 |')
          .blocks
          .single as MD$Table;
      expect(table.header.toString(), table.header.text);
      expect(table.header.toString(), contains('x'));
    });
  });

  group('MD\$Table.alignmentFor', () {
    test('returns none out of range and the value in range', () {
      final table = markdownDecoder
          .convert('| L | R |\n| :-- | --: |\n| 1 | 2 |')
          .blocks
          .single as MD$Table;
      expect(table.alignmentFor(0), MD$TableColumnAlign.left);
      expect(table.alignmentFor(1), MD$TableColumnAlign.right);
      expect(table.alignmentFor(99), MD$TableColumnAlign.none);
      expect(table.alignmentFor(-1), MD$TableColumnAlign.none);
    });
  });

  group('Markdown facade', () {
    test('isEmpty / isNotEmpty', () {
      expect(const Markdown.empty().isEmpty, isTrue);
      expect(const Markdown.empty().isNotEmpty, isFalse);
      final md = markdownDecoder.convert('hello');
      expect(md.isNotEmpty, isTrue);
      expect(md.isEmpty, isFalse);
    });

    test('toString returns the original source', () {
      expect(markdownDecoder.convert('# Title').toString(), '# Title');
    });

    test('text flattens list item spans', () {
      final text = markdownDecoder.convert('- alpha\n- beta').text;
      expect(text, contains('alpha'));
      expect(text, contains('beta'));
    });

    test('empty markdown text falls back to the source', () {
      expect(const Markdown.empty().text, isEmpty);
    });

    test('text traverses every block type without error', () {
      final text = markdownDecoder.convert(_doc).text;
      expect(text, contains('Heading'));
      expect(text, contains('Alert body'));
      expect(text, contains('code();'));
    });
  });
}
