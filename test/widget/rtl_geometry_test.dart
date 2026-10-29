import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// One geometric primitive a block painted, in block-local coordinates.
///
/// Glyphs are the ink boxes of a `drawParagraph` call; chrome is everything
/// else (bars, borders, fills, rules).
class _Mark {
  _Mark(this.kind, this.rect);

  final String kind;
  final Rect rect;

  bool get isGlyph => kind == 'glyph';

  @override
  String toString() => '$kind $rect';
}

/// A [Canvas] that records what a block painter draws, resolving
/// `save` / `translate` / `restore` so nested children land where they are
/// really painted.
class _RecordingCanvas implements Canvas {
  final List<_Mark> marks = <_Mark>[];
  final List<Offset> _stack = <Offset>[];
  Offset _origin = Offset.zero;

  void _add(String kind, Rect rect) =>
      marks.add(_Mark(kind, rect.shift(_origin)));

  @override
  void save() => _stack.add(_origin);

  @override
  void restore() => _origin = _stack.removeLast();

  @override
  void translate(double dx, double dy) => _origin += Offset(dx, dy);

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    // One mark per line, from its line metrics: unlike glyph boxes these
    // leave out the whitespace hanging past a soft wrap, which has no ink
    // and may sit outside the line (even at negative x in mixed bidi text).
    for (final line in paragraph.computeLineMetrics()) {
      if (line.width <= 0) continue;
      final rect = Rect.fromLTWH(
        line.left,
        line.baseline - line.ascent,
        line.width,
        line.ascent + line.descent,
      );
      _add('glyph', rect.shift(offset));
    }
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) =>
      _add('line', Rect.fromPoints(p1, p2));

  @override
  void drawRect(Rect rect, Paint paint) => _add('rect', rect);

  @override
  void drawRRect(RRect rrect, Paint paint) => _add('rrect', rrect.outerRect);

  @override
  void drawRawPoints(ui.PointMode mode, Float32List points, Paint paint) {
    for (var i = 0; i + 3 < points.length; i += 4) {
      _add(
        'segment',
        Rect.fromPoints(
          Offset(points[i], points[i + 1]),
          Offset(points[i + 2], points[i + 3]),
        ),
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected canvas call: '
          '${invocation.memberName}');
}

/// Mirrors the default block builder of the render layer, nesting included.
BlockPainter _build(MD$Block block, MarkdownThemeData theme) =>
    block.map<BlockPainter>(
      paragraph: (p) => BlockPainter$Paragraph(spans: p.spans, theme: theme),
      heading: (h) =>
          BlockPainter$Heading(level: h.level, spans: h.spans, theme: theme),
      quote: (q) => BlockPainter$Quote(
        spans: q.spans,
        indent: q.indent,
        theme: theme,
        children: <BlockPainter>[
          for (final child in q.blocks)
            _build(child, BlockPainter$Quote.inheritFrom(theme, child)),
        ],
      ),
      code: (c) =>
          BlockPainter$Code(language: c.language, text: c.text, theme: theme),
      list: (l) => BlockPainter$List(items: l.items, theme: theme),
      divider: (d) => BlockPainter$Divider(theme: theme),
      table: (t) => BlockPainter$Table(
        header: t.header,
        rows: t.rows,
        alignments: t.alignments,
        theme: theme,
      ),
      alert: (a) => BlockPainter$Alert(
        alert: a.alert,
        spans: a.spans,
        theme: theme,
        children: <BlockPainter>[
          for (final child in a.blocks) _build(child, theme),
        ],
      ),
      spacer: (s) => BlockPainter$Spacer(count: s.count, theme: theme),
    );

MarkdownThemeData _theme(TextDirection direction) => MarkdownThemeData(
      textStyle: const TextStyle(fontSize: 14),
      textDirection: direction,
    );

/// A laid-out block painter and everything it painted at [width].
class _Painted {
  _Painted(String source, TextDirection direction, this.width) {
    final blocks = Markdown.fromString(source).blocks;
    expect(blocks, hasLength(1), reason: 'one block per sample: $source');
    painter = _build(blocks.single, _theme(direction));
    size = painter.layout(width);
    painter.paint(canvas, Size(width, size.height), 0);
  }

  final double width;
  late final BlockPainter painter;
  late final Size size;
  final _RecordingCanvas canvas = _RecordingCanvas();

  Iterable<_Mark> get glyphs => canvas.marks.where((m) => m.isGlyph);
  Iterable<_Mark> get chrome => canvas.marks.where((m) => !m.isGlyph);

  SelectableBlockPainter? get selectable => painter is SelectableBlockPainter
      ? painter as SelectableBlockPainter
      : null;
}

/// Samples whose painted geometry must be the exact mirror image of their LTR
/// layout once the theme turns right-to-left: one block each, every one
/// narrow enough to fit the widths below.
const Map<String, String> _mirrored = <String, String>{
  'paragraph': 'שלום עולם, משפט ארוך שעובר שורה כשהרוחב צר',
  'mixed paragraph': 'Hello עולם with מילים mixed in between them',
  'link paragraph': '[קישור](https://a.example) ועוד טקסט',
  'heading': '## כותרת משנה ארוכה',
  'leaf quote': '> ציטוט ארוך עם הרבה מילים כדי לעבור שורה',
  'nested quote': '> > ציטוט מקונן בתוך ציטוט',
  'quote with list': '> - אחד\n> - שתיים',
  'quote with heading': '> # כותרת\n> וטקסט',
  'leaf alert': '> [!WARNING]\n> גוף ההתראה הארוך עם הרבה מילים',
  'alert with list': '> [!TIP]\n> - אחד\n> - שתיים',
  'title-only alert': '> [!NOTE]',
  'bullet list': '- אחד\n- שתיים ארוך יותר עם מילים רבות',
  'nested list': '- אחד\n  - מקונן\n    - עמוק יותר\n- שתיים',
  'ordered list': '1. ראשון\n2. שני\n10. עשירי',
  'task list': '- [ ] משימה\n- [x] בוצע',
  'table': '| א | ב | ג |\n|---|---|---|\n| 1 | 2 | 3 |\n| ארוך | x | y |',
  'centered table': '| א | ב |\n|:-:|:-:|\n| 1 | 22 |',
  'divider': '---',
};

/// Samples checked for paint / selection agreement only: their layout is
/// deliberately not a mirror (code stays LTR, explicit `:--` / `--:` columns
/// keep their side).
const Map<String, String> _unmirrored = <String, String>{
  'code': '```\nprint(1)\nfinal x = 2;\n```',
  'quote with code': '> ```\n> code()\n> ```\n> ואחריו טקסט',
  'alert with code': '> [!CAUTION]\n> ```\n> x = 1\n> ```',
  'aligned table': '| א | ב | ג |\n|:--|:-:|--:|\n| 1 | 2 | 3 |',
};

const List<double> _widths = <double>[160, 237.5, 400];

/// Samples whose per-character boxes the text engine itself places off the
/// painted line: in an RTL paragraph that starts with a Latin run, a bare
/// [TextPainter] reports the last glyph of that run one advance past the
/// line's right edge. Their selection-vs-paint check would test the engine,
/// not this package, so only their mirroring is checked.
const Set<String> _engineBoxQuirks = <String>{'mixed paragraph'};

Rect _mirror(Rect r, double width) =>
    Rect.fromLTRB(width - r.right, r.top, width - r.left, r.bottom);

bool _near(Rect a, Rect b, [double tolerance = 0.51]) =>
    (a.left - b.left).abs() <= tolerance &&
    (a.top - b.top).abs() <= tolerance &&
    (a.right - b.right).abs() <= tolerance &&
    (a.bottom - b.bottom).abs() <= tolerance;

bool _inside(Rect inner, Rect outer, [double tolerance = 0.51]) =>
    inner.left >= outer.left - tolerance &&
    inner.top >= outer.top - tolerance &&
    inner.right <= outer.right + tolerance &&
    inner.bottom <= outer.bottom + tolerance;

/// Every selectable character's highlight box must cover ink that was really
/// painted there, and tapping that ink must resolve back to the character.
void _expectSelectionMatchesPaint(_Painted painted, String label) {
  final block = painted.selectable;
  if (block == null) return;
  final text = block.renderedText;
  final glyphs = painted.glyphs.map((g) => g.rect).toList();
  for (var i = 0; i < text.length; i++) {
    if (text[i] == '\n' || text[i] == '\t' || text[i] == ' ') continue;
    for (final box in block.boxesForRange(i, i + 1)) {
      if (box.width <= 0.5) continue;
      expect(
        glyphs.any((g) => _inside(box, g)),
        isTrue,
        reason: '$label: highlight of "${text[i]}" (#$i) at $box '
            'is not over painted glyphs',
      );
      final hit = block.offsetForLocalPosition(box.center);
      expect(
        hit,
        inInclusiveRange(i, i + 1),
        reason: '$label: tapping "${text[i]}" (#$i) at ${box.center} '
            'resolved to $hit',
      );
    }
  }
}

/// Nothing a block paints may leave the width it was laid out at.
void _expectWithinWidth(_Painted painted, String label) {
  for (final mark in painted.canvas.marks) {
    expect(mark.rect.left, greaterThanOrEqualTo(-0.51), reason: '$label $mark');
    expect(
      mark.rect.right,
      lessThanOrEqualTo(painted.width + 0.51),
      reason: '$label $mark',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Right-to-left geometry', () {
    for (final MapEntry(key: name, value: source) in _mirrored.entries) {
      for (final width in _widths) {
        test('$name at $width is the mirror of LTR', () {
          final ltr = _Painted(source, TextDirection.ltr, width);
          final rtl = _Painted(source, TextDirection.rtl, width);
          expect(rtl.size, ltr.size, reason: 'mirroring must not resize');

          // Chrome mirrors one to one, in paint order.
          final ltrChrome = ltr.chrome.toList();
          final rtlChrome = rtl.chrome.toList();
          expect(rtlChrome.length, ltrChrome.length);
          for (var i = 0; i < ltrChrome.length; i++) {
            expect(rtlChrome[i].kind, ltrChrome[i].kind);
            expect(
              _near(rtlChrome[i].rect, _mirror(ltrChrome[i].rect, width)),
              isTrue,
              reason: 'chrome #$i: RTL ${rtlChrome[i].rect} is not the mirror '
                  'of LTR ${ltrChrome[i].rect}',
            );
          }

          // Text keeps its extent and moves to the mirrored side. Bidi may
          // reorder runs within a line, so compare the overall ink bounds.
          Rect bounds(Iterable<_Mark> marks) =>
              marks.map((m) => m.rect).reduce((a, b) => a.expandToInclude(b));
          if (ltr.glyphs.isNotEmpty) {
            final mirrored = _mirror(bounds(ltr.glyphs), width);
            expect(
              _near(bounds(rtl.glyphs), mirrored),
              isTrue,
              reason: 'RTL ink ${bounds(rtl.glyphs)} vs mirrored $mirrored',
            );
          }
        });

        for (final direction in TextDirection.values) {
          test('$name at $width ${direction.name}: selection matches paint',
              () {
            final painted = _Painted(source, direction, width);
            if (!_engineBoxQuirks.contains(name)) {
              _expectSelectionMatchesPaint(painted, name);
            }
            _expectWithinWidth(painted, name);
          });
        }
      }
    }

    for (final MapEntry(key: name, value: source) in _unmirrored.entries) {
      for (final width in _widths) {
        for (final direction in TextDirection.values) {
          test('$name at $width ${direction.name}: selection matches paint',
              () {
            final painted = _Painted(source, direction, width);
            _expectSelectionMatchesPaint(painted, name);
            _expectWithinWidth(painted, name);
          });
        }
      }
    }

    test('code keeps its LTR layout inside an RTL document', () {
      const source = '```\nprint(1)\n```';
      final ltr = _Painted(source, TextDirection.ltr, 300);
      final rtl = _Painted(source, TextDirection.rtl, 300);
      expect(
        rtl.canvas.marks.map((m) => m.rect).toList(),
        ltr.canvas.marks.map((m) => m.rect).toList(),
      );
    });

    test('explicitly aligned columns keep their side', () {
      // `:--` and `--:` name a physical side, so RTL moves the columns but
      // not the alignment within each one.
      const source = '| a | b |\n|:--|--:|\n| x | y |';
      final rtl = _Painted(source, TextDirection.rtl, 300);
      final block = rtl.selectable!;
      // Rendered text is "a\tb\nx\ty"; column "a" is on the right in RTL.
      final a = block.boxesForRange(0, 1).single;
      final b = block.boxesForRange(2, 3).single;
      expect(a.center.dx, greaterThan(b.center.dx));
      // "x" is left-aligned inside the right-hand column, "y" right-aligned
      // inside the left-hand one: they sit at the inner edges, near the
      // vertical border between the two columns.
      final x = block.boxesForRange(4, 5).single;
      final y = block.boxesForRange(6, 7).single;
      expect(x.left, greaterThan(y.right));
      expect(x.left - y.right, lessThan(4 * BlockPainter$Table.padding));
    });

    group('a table wider than the width', () {
      // Too wide to fit: like an LTR table, it overflows past its end edge so
      // the columns read first stay in view.
      final source = '| ${List.filled(12, 'מילה').join(' | ')} |\n'
          '|${List.filled(12, '---').join('|')}|\n'
          '| ${List.filled(12, 'x').join(' | ')} |';
      const width = 120.0;

      test('keeps its first RTL column against the right edge', () {
        final rtl = _Painted(source, TextDirection.rtl, width);
        expect(rtl.size.width, greaterThan(width));
        final block = rtl.selectable!;
        final firstHeader = block.boxesForRange(0, 4).reduce(
              (a, b) => a.expandToInclude(b),
            );
        expect(firstHeader.left, greaterThanOrEqualTo(0));
        expect(firstHeader.right, lessThanOrEqualTo(width));
        // The border encloses the table and ends at the right edge.
        final border = rtl.chrome.where((m) => m.kind == 'rect').last.rect;
        expect(border.right, closeTo(width, 0.5));
        expect(border.left, closeTo(width - rtl.size.width, 0.5));
        _expectSelectionMatchesPaint(rtl, 'wide RTL table');
      });

      test('is the mirror of the LTR overflow', () {
        final ltr = _Painted(source, TextDirection.ltr, width);
        final rtl = _Painted(source, TextDirection.rtl, width);
        final ltrChrome = ltr.chrome.toList();
        final rtlChrome = rtl.chrome.toList();
        expect(rtlChrome.length, ltrChrome.length);
        for (var i = 0; i < ltrChrome.length; i++) {
          expect(
            _near(rtlChrome[i].rect, _mirror(ltrChrome[i].rect, width)),
            isTrue,
            reason: '#$i ${rtlChrome[i]} vs ${ltrChrome[i]}',
          );
        }
      });
    });

    for (final width in <double>[0, 1, 8, 24]) {
      test('degenerate width $width lays out and paints without throwing', () {
        for (final source in <String>[
          ..._mirrored.values,
          ..._unmirrored.values
        ]) {
          for (final direction in TextDirection.values) {
            final painted = _Painted(source, direction, width);
            expect(painted.size.height, greaterThanOrEqualTo(0));
            expect(painted.size.width.isFinite, isTrue);
          }
        }
      });
    }

    test('an infinite width falls back to the unmirrored layout', () {
      // Nothing to align against: mirroring is skipped rather than producing
      // infinite offsets.
      for (final source in _mirrored.values) {
        final blocks = Markdown.fromString(source).blocks;
        final rtl = _build(blocks.single, _theme(TextDirection.rtl));
        final ltr = _build(blocks.single, _theme(TextDirection.ltr));
        expect(rtl.layout(double.infinity), ltr.layout(double.infinity));
        final block = rtl is SelectableBlockPainter ? rtl : null;
        if (block == null || block.renderedText.isEmpty) continue;
        for (final box in block.boxesForRange(0, block.renderedText.length)) {
          expect(box.left.isFinite && box.right.isFinite, isTrue);
        }
      }
    });

    test('a re-layout at another width re-mirrors', () {
      // Painters are reused across layouts (resize, streaming): the mirrored
      // positions must follow the latest width, not the first one.
      const source = '> [!NOTE]\n> גוף';
      final blocks = Markdown.fromString(source).blocks;
      final painter = _build(blocks.single, _theme(TextDirection.rtl))
          as SelectableBlockPainter;
      (painter as BlockPainter).layout(400);
      final wide = painter.boxesForRange(0, 1).single;
      (painter as BlockPainter).layout(200);
      final narrow = painter.boxesForRange(0, 1).single;
      expect(wide.right - narrow.right, closeTo(200, 0.5));
    });
  });
}
