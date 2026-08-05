import 'package:flutter/painting.dart' show TextRange;
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// Full-block selection of a single-document source, formatted as Markdown.
String _markup(String source,
    [MarkdownMarkupFormatter formatter = const MarkdownMarkupFormatter()]) {
  final c = MarkdownSelectionController()
    ..setDocuments(<MarkdownDocumentRef>[
      MarkdownDocumentRef(id: 'doc', model: Markdown.fromString(source)),
    ])
    ..selectAll();
  return c.getText(formatter);
}

void main() {
  group('MarkdownMarkupFormatter — whole-block reconstruction', () {
    test('nested unordered list keeps indentation and markers', () {
      expect(
        _markup('- one\n- two\n  - nested\n- three'),
        '- one\n- two\n  - nested\n- three',
      );
    });

    test('ordered list keeps numbers, nested indented one level', () {
      expect(
        _markup('1. first\n2. second\n   1. sub'),
        '1. first\n2. second\n  1. sub',
      );
    });

    test('task list keeps checkboxes', () {
      expect(_markup('- [x] done\n- [ ] todo'), '- [x] done\n- [ ] todo');
    });

    test('headings keep their level', () {
      expect(_markup('# Title'), '# Title');
      expect(_markup('### Deep'), '### Deep');
    });

    test('blockquote is prefixed', () {
      expect(_markup('> quoted line'), '> quoted line');
    });

    test('alert emits its marker and prefixed body', () {
      expect(
        _markup('> [!NOTE]\n> Body one\n> Body two'),
        '> [!NOTE]\n> Body one\n> Body two',
      );
    });

    test('code block is fenced with its language', () {
      expect(_markup('```dart\nvar x = 1;\n```'), '```dart\nvar x = 1;\n```');
    });

    test('code block without a language uses a bare fence', () {
      expect(_markup('```\nplain\n```'), '```\nplain\n```');
    });

    test('table becomes a pipe table with a delimiter row', () {
      expect(
        _markup('| a | b |\n|---|---|\n| 1 | 2 |'),
        '| a | b |\n| --- | --- |\n| 1 | 2 |',
      );
    });

    test('custom listIndent controls nesting width', () {
      expect(
        _markup(
          '- a\n  - b',
          const MarkdownMarkupFormatter(listIndent: '    '),
        ),
        '- a\n    - b',
      );
    });
  });

  group('MarkdownMarkupFormatter — separators', () {
    // Blocks: 0 = heading, 1 = spacer, 2 = paragraph.
    final doc = Markdown.fromString('# Heading\n\nA paragraph.');

    MarkdownSelectionController one() => MarkdownSelectionController()
      ..setDocuments(<MarkdownDocumentRef>[
        MarkdownDocumentRef(id: 'doc', model: doc),
      ]);

    test('blocks within a document join with a blank line by default', () {
      final c = one()..selectAll();
      expect(c.getText(const MarkdownMarkupFormatter()),
          '# Heading\n\nA paragraph.');
    });

    test('documents join with documentSeparator', () {
      final c = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'a', model: Markdown.fromString('# One')),
          MarkdownDocumentRef(id: 'b', model: Markdown.fromString('- x\n- y')),
        ])
        ..selectAll();
      expect(c.getText(const MarkdownMarkupFormatter()), '# One\n\n- x\n- y');
    });

    test('separators are configurable', () {
      final c = one()..selectAll();
      expect(
        c.getText(const MarkdownMarkupFormatter(blockSeparator: '\n')),
        '# Heading\nA paragraph.',
      );
    });
  });

  group('MarkdownMarkupFormatter — partial boundary fallback', () {
    test('a partially selected list falls back to plain sliced text', () {
      final c = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'doc',
              model: Markdown.fromString('- one\n- two\n  - nested\n- three')),
        ]);
      // Rendered text is 'one\ntwo\nnested\nthree'; select only 'one\ntwo'.
      c.selection = const MarkdownSelection(
        base: MarkdownPosition(documentId: 'doc', blockIndex: 0, offset: 0),
        extent: MarkdownPosition(documentId: 'doc', blockIndex: 0, offset: 7),
      );
      // No markers reconstructed — the plain slice is copied verbatim.
      expect(c.getText(const MarkdownMarkupFormatter()), 'one\ntwo');
    });

    test('fully selected boundary block still reconstructs', () {
      // A selection that ends exactly at the block length is "whole".
      final model = Markdown.fromString('- a\n- b');
      final c = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'doc', model: model),
        ]);
      final len = markdownBlockRenderedText(model.blocks.first).length;
      c.selection = MarkdownSelection(
        base:
            const MarkdownPosition(documentId: 'doc', blockIndex: 0, offset: 0),
        extent: MarkdownPosition(documentId: 'doc', blockIndex: 0, offset: len),
      );
      expect(c.getText(const MarkdownMarkupFormatter()), '- a\n- b');
    });
  });

  group('MarkdownMarkupFormatter — wiring', () {
    test('can be installed as the controller default formatter', () {
      final c = MarkdownSelectionController()
        ..formatter = const MarkdownMarkupFormatter()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'doc', model: Markdown.fromString('# Hi')),
        ])
        ..selectAll();
      // getText() with no argument now uses the markup formatter.
      expect(c.getText(), '# Hi');
    });

    test('differs from the default plain formatter', () {
      final markup = _markup('# Heading\n\n- a\n- b');
      final plain = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(
              id: 'doc', model: Markdown.fromString('# Heading\n\n- a\n- b')),
        ]);
      plain.selectAll();
      expect(markup, isNot(equals(plain.getText())));
      expect(markup.contains('# Heading'), isTrue);
      expect(markup.contains('- a'), isTrue);
    });

    test('implements the MarkdownSelectionFormatter interface', () {
      const MarkdownSelectionFormatter formatter = MarkdownMarkupFormatter();
      const content =
          MarkdownSelectedContent(documents: <MarkdownSelectedDocument>[]);
      expect(formatter.format(content), isEmpty);
    });

    test('an empty selection formats to an empty string', () {
      final c = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'doc', model: Markdown.fromString('# Hi')),
        ]);
      expect(c.getText(const MarkdownMarkupFormatter()), isEmpty);
    });
  });

  group('MarkdownMarkupFormatter — sanity of renderedRange assumptions', () {
    test('TextRange is exposed on selected blocks', () {
      final c = MarkdownSelectionController()
        ..setDocuments(<MarkdownDocumentRef>[
          MarkdownDocumentRef(id: 'doc', model: Markdown.fromString('hello')),
        ])
        ..selectAll();
      final seg = c.selectedContent().documents.single.blocks.single;
      expect(seg.renderedRange, const TextRange(start: 0, end: 5));
    });
  });
}
