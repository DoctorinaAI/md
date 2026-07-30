import 'package:flutter/painting.dart' show TextRange;
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

class _UpperFormatter implements MarkdownSelectionFormatter {
  const _UpperFormatter();
  @override
  String format(MarkdownSelectedContent content) => content.documents
      .expand((d) => d.blocks)
      .map((b) => b.text.toUpperCase())
      .join(' | ');
}

void main() {
  group('selection core', () {
    // Block indices: 0 = paragraph, 1 = spacer, 2 = paragraph.
    final docA = Markdown.fromString('Alpha one\n\nAlpha two');
    final docB = Markdown.fromString('Bravo one\n\nBravo two');

    MarkdownSelectionController two() => MarkdownSelectionController()
      ..setDocuments(<MarkdownDocumentRef>[
        MarkdownDocumentRef(id: 'a', model: docA),
        MarkdownDocumentRef(id: 'b', model: docB),
      ]);

    const full = MarkdownSelection(
      base: MarkdownPosition(documentId: 'a', blockIndex: 0, offset: 0),
      extent: MarkdownPosition(documentId: 'b', blockIndex: 2, offset: 9),
    );

    test('block linearization', () {
      expect(markdownBlockRenderedText(docA.blocks[0]), 'Alpha one');
      expect(markdownBlockRenderedText(docA.blocks[1]), ''); // spacer
      expect(markdownBlockRenderedText(docA.blocks[2]), 'Alpha two');
      final table = Markdown.fromString('| a | b |\n|---|---|\n| 1 | 2 |')
          .blocks
          .firstWhere((b) => b.type == 'table');
      expect(markdownBlockRenderedText(table), 'a\tb\n1\t2');

      final list = Markdown.fromString('- one\n- two\n  - nested\n- three')
          .blocks
          .firstWhere((b) => b.type == 'list');
      expect(markdownBlockRenderedText(list), 'one\ntwo\nnested\nthree');

      final tasks = Markdown.fromString('- [x] done\n- [ ] todo')
          .blocks
          .firstWhere((b) => b.type == 'list');
      expect(markdownBlockRenderedText(tasks), 'done\ntodo');

      // An empty leading item still occupies its own line, so the model offset
      // space matches the painter's one-fragment-per-item layout.
      final emptyLead = Markdown.fromString('- [ ]\n- [x] Done')
          .blocks
          .firstWhere((b) => b.type == 'list');
      expect(markdownBlockRenderedText(emptyLead), '\nDone');
    });

    test('cross-document extraction with default formatter', () {
      final c = two()..selection = full;
      expect(c.getText(), 'Alpha one\nAlpha two\n\nBravo one\nBravo two');
      final content = c.selectedContent();
      expect(content.documents.length, 2);
      expect(content.documents.first.blocks.map((b) => b.text).toList(),
          <String>['Alpha one', 'Alpha two']); // spacer skipped
      expect(content.documents.first.blocks.first.type, 'paragraph');
    });

    test('partial slice', () {
      final c = two()
        ..selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'a', blockIndex: 2, offset: 6),
          extent: MarkdownPosition(documentId: 'b', blockIndex: 0, offset: 5),
        );
      expect(c.getText(), 'two\n\nBravo');
    });

    test('custom formatter is used', () {
      final c = two()..selection = full;
      expect(c.getText(const _UpperFormatter()),
          'ALPHA ONE | ALPHA TWO | BRAVO ONE | BRAVO TWO');
    });

    test('reconcile: append keeps the anchor verbatim', () {
      final c = two()..selection = full;
      final before = c.getText();
      c.putDocument(
          'b', Markdown.fromString('Bravo one\n\nBravo two three\n\nEnd'));
      expect(c.selection!.extent.blockIndex, 2);
      expect(c.selection!.extent.offset, 9);
      expect(c.getText(), before);
    });

    test('reconcile: content-anchored survives a front-insert', () {
      final c = MarkdownSelectionController()
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'b', model: docB)])
        ..selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'b', blockIndex: 2, offset: 0),
          extent: MarkdownPosition(documentId: 'b', blockIndex: 2, offset: 9),
        );
      expect(c.getText(), 'Bravo two');
      c.putDocument(
          'b', Markdown.fromString('HEADER\n\nBravo one\n\nBravo two'));
      expect(c.getText(), 'Bravo two'); // relocated by content, not index
    });

    test('reconcile: appendFastPath drifts on a front-insert', () {
      final c = MarkdownSelectionController(
        reconciliation: const MarkdownReconciliationPolicy.appendFastPath(),
      )
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'b', model: docB)])
        ..selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'b', blockIndex: 0, offset: 0),
          extent: MarkdownPosition(documentId: 'b', blockIndex: 0, offset: 9),
        );
      expect(c.getText(), 'Bravo one');
      c.putDocument(
          'b', Markdown.fromString('HEADER LINE\n\nBravo one\n\nBravo two'));
      expect(c.getText(), isNot('Bravo one')); // clamped to new block 0
    });

    test('reconcile: clearOnChange drops the selection', () {
      final c = MarkdownSelectionController(
        reconciliation: const MarkdownReconciliationPolicy.clearOnChange(),
      )
        ..setDocuments(
            <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'b', model: docB)])
        ..selection = const MarkdownSelection(
          base: MarkdownPosition(documentId: 'b', blockIndex: 0, offset: 0),
          extent: MarkdownPosition(documentId: 'b', blockIndex: 2, offset: 9),
        );
      c.putDocument('b', Markdown.fromString('Bravo one\n\nBravo two four'));
      expect(c.selection, isNull);
    });

    test('selectAll and clear', () {
      final c = two()..selectAll();
      expect(c.getText(), 'Alpha one\nAlpha two\n\nBravo one\nBravo two');
      c.clear();
      expect(c.selection, isNull);
      expect(c.getText(), '');
    });

    test('rangeFor', () {
      final c = two()..selection = full;
      expect(c.rangeFor('a', 0), const TextRange(start: 0, end: 9));
      expect(c.rangeFor('b', 0), const TextRange(start: 0, end: 9));
      expect(c.rangeFor('missing', 0), isNull);
    });

    test('removeDocument drops a touching selection', () {
      final c = two()..selection = full;
      c.removeDocument('a');
      expect(c.selection, isNull);
    });

    test('notifies listeners on selection change', () {
      final c = two();
      var n = 0;
      c.addListener(() => n++);
      c.selection = full;
      c.clear();
      expect(n, 2);
    });
  });
}
