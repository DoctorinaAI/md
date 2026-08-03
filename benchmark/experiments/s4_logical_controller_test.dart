// SPIKE S4 — Controller-anchored LOGICAL selection over the immutable model.
//
// The core idea: selection is a pair of logical anchors (docId, blockIndex,
// renderedOffset) into the immutable Markdown model. Text is derived from the
// MODEL (always retained by the app), so extraction is completely independent
// of which widgets are currently mounted. This is what makes disposal survival
// and streaming reconciliation fall out.
//
// Proves:
//   T1 cross-document extraction from the model (with block/doc separators).
//   T2 DISPOSAL SURVIVAL: extraction is identical before/after scrolling items
//      out of a ListView (i.e. after their widgets are disposed).
//   T3 STREAMING: append-only reconcile keeps the anchor; and index-only anchors
//      BREAK on a front-insert — the evidence for the index-vs-stable-id call.
//   T4 SCREEN ORDER: a geometry comparator (vertical, then horizontal flipped
//      for RTL) orders MOUNTED docs; registry order governs unmounted ones.
//
// Uses the REAL flutter_md model. Throwaway spike; outside lib/ and test/.
// Run: flutter test benchmark/experiments/s4_logical_controller_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

// --- shared block linearization (seed for the real MarkdownBlockText helper) --
String renderedBlockText(MD$Block b) => b.map(
      paragraph: (p) => p.spans.map((s) => s.text).join(),
      heading: (h) => h.spans.map((s) => s.text).join(),
      quote: (q) => q.spans.map((s) => s.text).join(),
      alert: (a) => a.spans.map((s) => s.text).join(),
      code: (c) => c.text,
      list: (l) => l.items.map((i) => i.spans.map((s) => s.text).join()).join('\n'),
      table: (t) => <String>[
        t.header.cells.map((c) => c.map((s) => s.text).join()).join('\t'),
        for (final r in t.rows)
          r.cells.map((c) => c.map((s) => s.text).join()).join('\t'),
      ].join('\n'),
      divider: (_) => '', // structural, no selectable text
      spacer: (_) => '', // structural, no selectable text (policy: Phase 2)
    );

// --- logical model ---
@immutable
class MdPos {
  const MdPos(this.doc, this.block, this.offset);
  final Object doc;
  final int block;
  final int offset;
}

@immutable
class MdSel {
  const MdSel(this.base, this.extent);
  final MdPos base;
  final MdPos extent;
}

class MdDoc {
  MdDoc(this.id, this.model);
  final Object id;
  Markdown model;
}

/// Append-only fast path, else clamp. Returns null to drop an anchor.
MdPos reconcile(MdPos anchor, Markdown oldM, Markdown newM) {
  final oldB = oldM.blocks, newB = newM.blocks;
  bool prefixUnchanged() {
    if (anchor.block >= newB.length) return false;
    for (var i = 0; i < anchor.block; i++) {
      if (i >= newB.length || renderedBlockText(oldB[i]) != renderedBlockText(newB[i])) {
        return false;
      }
    }
    // anchor block itself: old rendered text must be a prefix of the new one.
    final oldT = renderedBlockText(oldB[anchor.block]);
    final newT = renderedBlockText(newB[anchor.block]);
    return newT.startsWith(oldT) || oldT.startsWith(newT);
  }

  if (anchor.block < oldB.length && prefixUnchanged()) return anchor; // keep
  // clamp
  final block = anchor.block.clamp(0, newB.length - 1);
  final len = renderedBlockText(newB[block]).length;
  return MdPos(anchor.doc, block, anchor.offset.clamp(0, len));
}

class MdController extends ChangeNotifier {
  final List<MdDoc> docs = <MdDoc>[]; // registry order == reading order
  MdSel? selection;

  int _docIndex(Object id) => docs.indexWhere((d) => d.id == id);
  Markdown _model(Object id) => docs[_docIndex(id)].model;

  void updateDocument(Object id, Markdown next) {
    final d = docs[_docIndex(id)];
    final old = d.model;
    d.model = next;
    final sel = selection;
    if (sel != null) {
      selection = MdSel(
        sel.base.doc == id ? reconcile(sel.base, old, next) : sel.base,
        sel.extent.doc == id ? reconcile(sel.extent, old, next) : sel.extent,
      );
    }
    notifyListeners();
  }

  int _cmp(MdPos a, MdPos b) {
    final ai = _docIndex(a.doc), bi = _docIndex(b.doc);
    if (ai != bi) return ai.compareTo(bi);
    if (a.block != b.block) return a.block.compareTo(b.block);
    return a.offset.compareTo(b.offset);
  }

  String getPlainText({String blockSep = '\n', String docSep = '\n\n'}) {
    final sel = selection;
    if (sel == null) return '';
    var a = sel.base, b = sel.extent;
    if (_cmp(a, b) > 0) {
      final t = a;
      a = b;
      b = t;
    }
    final startDoc = _docIndex(a.doc), endDoc = _docIndex(b.doc);
    final docChunks = <String>[];
    for (var d = startDoc; d <= endDoc; d++) {
      final blocks = docs[d].model.blocks;
      final fromBlock = d == startDoc ? a.block : 0;
      final toBlock = d == endDoc ? b.block : blocks.length - 1;
      final blockChunks = <String>[];
      for (var bi = fromBlock; bi <= toBlock; bi++) {
        final text = renderedBlockText(blocks[bi]);
        if (text.isEmpty) continue; // skip structural blocks (spacer/divider)
        final from = (d == startDoc && bi == a.block) ? a.offset : 0;
        final to = (d == endDoc && bi == b.block) ? b.offset : text.length;
        blockChunks
            .add(text.substring(from.clamp(0, text.length), to.clamp(0, text.length)));
      }
      docChunks.add(blockChunks.join(blockSep));
    }
    return docChunks.join(docSep);
  }
}

// Screen-order comparator for MOUNTED surfaces (mirrors Flutter's
// _compareScreenOrder, with an RTL horizontal flip).
int compareScreenOrder(Rect a, Rect b, TextDirection dir) {
  const threshold = 4.0;
  if ((a.top - b.top).abs() > threshold) return a.top.compareTo(b.top);
  return dir == TextDirection.rtl ? b.left.compareTo(a.left) : a.left.compareTo(b.left);
}

void main() {
  final docA = Markdown.fromString('Alpha one\n\nAlpha two');
  final docB = Markdown.fromString('Bravo one\n\nBravo two');

  MdController freshController() =>
      MdController()..docs.addAll(<MdDoc>[MdDoc('a', docA), MdDoc('b', docB)]);

  // Block indices: 0 = paragraph, 1 = spacer (blank line), 2 = paragraph.
  test('T1 cross-document extraction with separators', () {
    final c = freshController();
    c.selection = const MdSel(MdPos('a', 0, 0), MdPos('b', 2, 9));
    expect(c.getPlainText(), 'Alpha one\nAlpha two\n\nBravo one\nBravo two');

    c.selection = const MdSel(MdPos('a', 2, 6), MdPos('b', 0, 5));
    expect(c.getPlainText(), 'two\n\nBravo'); // 'Alpha two'[6:]='two'
  });

  testWidgets('T2 DISPOSAL SURVIVAL: extraction unchanged after scroll-off',
      (tester) async {
    final c = MdController();
    for (var i = 0; i < 8; i++) {
      c.docs.add(MdDoc('d$i', Markdown.fromString('Message number $i')));
    }
    // Select from d0 through d7 (whole conversation).
    c.selection = const MdSel(MdPos('d0', 0, 0), MdPos('d7', 0, 16));
    final before = c.getPlainText();
    expect(before, contains('Message number 0'));
    expect(before, contains('Message number 7'));

    final scroll = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 200,
          child: ListView.builder(
            controller: scroll,
            cacheExtent: 0,
            itemCount: c.docs.length,
            itemBuilder: (_, i) => SizedBox(
              height: 80,
              child: Text(c.docs[i].model.blocks.map(renderedBlockText).join()),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    scroll.jumpTo(80.0 * 6); // dispose the first several messages
    await tester.pumpAndSettle();
    expect(find.text('Message number 0'), findsNothing); // truly disposed

    // The controller reads the MODEL, not live widgets → identical text.
    expect(c.getPlainText(), before);
    expect(c.getPlainText(), contains('Message number 0'));
  });

  test('T3 STREAMING: append keeps anchor; front-insert breaks index-only', () {
    // Anchor extent inside docB block 2 ("Bravo two"), offset 9 = end.
    final c = freshController();
    c.selection = const MdSel(MdPos('a', 0, 0), MdPos('b', 2, 9));
    final base = c.getPlainText();

    // (a) Append-only streaming: grow the last block + add a new block.
    c.updateDocument(
        'b', Markdown.fromString('Bravo one\n\nBravo two three\n\nBravo appended'));
    // block 2 grew as a prefix ("Bravo two" -> "Bravo two three"), so the fast
    // path keeps the anchor; the originally-selected text is unchanged.
    expect(c.selection!.extent.block, 2);
    expect(c.selection!.extent.offset, 9);
    expect(c.getPlainText(), base); // selection content preserved verbatim

    // (b) Front-insert: prepend a new first block. With INDEX-only anchors the
    // fast path fails (block 0 changed) and clamp keeps block index 1 — which
    // now points at a DIFFERENT block. The selected text changes => WRONG.
    final c2 = freshController();
    c2.selection = const MdSel(MdPos('b', 0, 0), MdPos('b', 0, 9));
    final beforeInsert = c2.getPlainText(); // "Bravo one"
    c2.updateDocument(
        'b', Markdown.fromString('INSERTED HEADER\n\nBravo one\n\nBravo two'));
    final afterInsert = c2.getPlainText();
    expect(beforeInsert, 'Bravo one');
    expect(afterInsert, isNot('Bravo one'),
        reason: 'index-only anchors mis-track a front-insert → needs stable id');
  });

  test('T4 SCREEN ORDER: vertical, then horizontal with RTL flip', () {
    const vTop = Rect.fromLTWH(0, 0, 100, 40);
    const vBot = Rect.fromLTWH(0, 60, 100, 40);
    expect(compareScreenOrder(vTop, vBot, TextDirection.ltr) < 0, isTrue);

    const left = Rect.fromLTWH(0, 0, 100, 40);
    const right = Rect.fromLTWH(120, 1, 100, 40); // same row (±threshold)
    expect(compareScreenOrder(left, right, TextDirection.ltr) < 0, isTrue,
        reason: 'LTR: left comes first');
    expect(compareScreenOrder(left, right, TextDirection.rtl) > 0, isTrue,
        reason: 'RTL: right comes first');
  });
}
