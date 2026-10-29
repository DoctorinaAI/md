// Coverage for render-layer paths the scenario suites do not reach:
// render-object surface queries, partial handle-layer clears, cursor-only
// updates, list link hit-testing, nested alert hit-testing and custom
// selectable children inside host blocks.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/src/render.dart';
import 'package:flutter_test/flutter_test.dart';

final MarkdownThemeData _theme = MarkdownThemeData(
  textStyle: const TextStyle(fontSize: 14),
);

/// Links only get a tap recognizer (and so count as links) with a handler.
final MarkdownThemeData _linkTheme = _theme.copyWith(
  onLinkTap: (title, url) {},
);

Widget _host(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 300, child: child),
      ),
    );

MarkdownRenderObject _ro(WidgetTester tester) =>
    tester.renderObject<MarkdownRenderObject>(find.byType(MarkdownWidget));

T _first<T extends MD$Block>(String source) =>
    Markdown.fromString(source).blocks.whereType<T>().first;

/// A custom [SelectableTextBlock] that keeps the mixin defaults.
class _PlainText with SelectableTextBlock implements BlockPainter {
  _PlainText(String text)
      : selectionPainter = TextPainter(
          text: TextSpan(text: text, style: const TextStyle(fontSize: 14)),
          textDirection: TextDirection.ltr,
        );

  @override
  final TextPainter selectionPainter;

  @override
  Size size = Size.zero;

  @override
  void handleTapDown(PointerDownEvent event) {}

  @override
  void handleTapUp(PointerUpEvent event) {}

  @override
  Size layout(double width) {
    selectionPainter.layout(maxWidth: width);
    return size = selectionPainter.size;
  }

  @override
  void paint(Canvas canvas, Size size, double offset) {}

  @override
  void dispose() => selectionPainter.dispose();
}

/// A selectable painter that implements the interface directly: it has
/// rendered text but no text painter to expose as a fragment.
class _RawSelectable implements SelectableBlockPainter {
  _RawSelectable(this.renderedText);

  @override
  final String renderedText;

  @override
  Size size = Size.zero;

  @override
  Size layout(double width) => size = Size(width, 20);

  @override
  void paint(Canvas canvas, Size size, double offset) {}

  @override
  void handleTapDown(PointerDownEvent event) {}

  @override
  void handleTapUp(PointerUpEvent event) {}

  @override
  void dispose() {}

  @override
  int offsetForLocalPosition(Offset local) => 0;

  @override
  (int, TextAffinity) positionAndAffinityForLocal(Offset local) =>
      (0, TextAffinity.downstream);

  @override
  Rect caretRectFor(int offset, TextAffinity affinity) => Rect.zero;

  @override
  List<Rect> boxesForRange(int start, int end) => const <Rect>[];

  @override
  TextRange wordBoundaryForLocal(Offset local) =>
      const TextRange(start: 0, end: 0);

  @override
  bool isLinkAtLocal(Offset local) => false;

  @override
  bool hitsRenderedTextAt(Offset local) => false;

  @override
  bool get selectionHighlightAboveCachedContent => false;
}

void main() {
  group('render coverage', () {
    group('MarkdownRenderObject surface', () {
      testWidgets('positionForGlobal matches hitForGlobal', (tester) async {
        final controller = MarkdownSelectionController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            MarkdownWidget(
              markdown: Markdown.fromString('Hello world'),
              theme: _theme,
              controller: controller,
              documentId: 'd',
            ),
          ),
        );
        final ro = _ro(tester);
        final box = ro.localBoxesForRange(0, 6, 11).first;
        final at = ro.localToGlobal(box.centerLeft + const Offset(1, 0));
        final pos = ro.positionForGlobal(at)!;
        expect(pos.documentId, 'd');
        expect(pos.blockIndex, 0);
        expect(pos.offset, 6);
        expect(pos, ro.hitForGlobal(at)!.$1);
      });

      testWidgets('isLinkAtGlobal is glyph-tight over links only',
          (tester) async {
        final controller = MarkdownSelectionController();
        addTearDown(controller.dispose);
        final model = Markdown.fromString('see [link](u) here');
        await tester.pumpWidget(
          _host(
            MarkdownWidget(
              markdown: model,
              theme: _linkTheme,
              controller: controller,
              documentId: 'd',
            ),
          ),
        );
        final ro = _ro(tester);
        Offset center(int s, int e) =>
            ro.localToGlobal(ro.localBoxesForRange(0, s, e).first.center);
        expect(ro.isLinkAtGlobal(center(4, 8)), isTrue);
        expect(ro.isLinkAtGlobal(center(0, 3)), isFalse);
        // Outside the render object bounds.
        expect(ro.isLinkAtGlobal(const Offset(5, 500)), isFalse);
        expect(controller.isLinkAtGlobal(center(4, 8)), isTrue);
      });

      testWidgets('without a document id nothing is a link', (tester) async {
        await tester.pumpWidget(
          _host(
            MarkdownWidget(
              markdown: Markdown.fromString('[link](u)'),
              theme: _linkTheme,
            ),
          ),
        );
        final ro = _ro(tester);
        final at =
            ro.localToGlobal(ro.localBoxesForRange(0, 0, 4).first.center);
        expect(ro.isLinkAtGlobal(at), isFalse);
      });

      testWidgets('clearSelectionHandleLayersIfLinked clears only its own',
          (tester) async {
        final controller = MarkdownSelectionController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            MarkdownWidget(
              markdown: Markdown.fromString('Hello world'),
              theme: _theme,
              controller: controller,
              documentId: 'd',
            ),
          ),
        );
        final ro = _ro(tester);
        final start = LayerLink();
        final end = LayerLink();
        ro.setSelectionHandleLayers(
          startLink: start,
          startLocal: Offset.zero,
          endLink: end,
          endLocal: const Offset(20, 0),
        );
        expect(ro.hasSelectionHandleLeaders, isTrue);
        // Another overlay's links: nothing to clear.
        ro.clearSelectionHandleLayersIfLinked(
          startLink: LayerLink(),
          endLink: LayerLink(),
        );
        expect(ro.hasSelectionHandleLeaders, isTrue);
        // Only the start link is ours: the end leader survives.
        ro.clearSelectionHandleLayersIfLinked(
          startLink: start,
          endLink: LayerLink(),
        );
        expect(ro.hasSelectionHandleLeaders, isTrue);
        await tester.pump();
        expect(tester.takeException(), isNull);
        ro.clearSelectionHandleLayersIfLinked(
          startLink: LayerLink(),
          endLink: end,
        );
        expect(ro.hasSelectionHandleLeaders, isFalse);
        await tester.pump();
      });

      testWidgets('a resolver-only change keeps layout and re-resolves cursor',
          (tester) async {
        final model = Markdown.fromString('Hello');
        Widget app(MouseCursor cursor) => _host(
              MarkdownWidget(
                markdown: model,
                theme: _theme,
                cursorResolver: (_, __, ___) => cursor,
              ),
            );
        await tester.pumpWidget(app(SystemMouseCursors.grab));
        final gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: const Offset(500, 500));
        await gesture.moveTo(const Offset(10, 7));
        await tester.pump();
        MouseCursor? active() =>
            RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
        expect(active(), SystemMouseCursors.grab);
        final ro = _ro(tester);
        await tester.pumpWidget(app(SystemMouseCursors.help));
        expect(ro.debugNeedsLayout, isFalse);
        await tester.pump();
        expect(active(), SystemMouseCursors.help);
      });
    });

    group('MarkdownPainter', () {
      test('positionForLocal drops the affinity', () {
        final painter = MarkdownPainter(
          markdown: Markdown.fromString('Hello world'),
          theme: _theme,
        );
        addTearDown(painter.dispose);
        painter.layout(maxWidth: 300);
        final box = painter.localBoxesForRange(0, 6, 11).first;
        final at = box.centerLeft + const Offset(1, 0);
        expect(painter.positionForLocal(at), (0, 6));
        final full = painter.positionAndAffinityForLocal(at)!;
        expect(painter.positionForLocal(at), (full.$1, full.$2));
      });
    });

    group('block painter framework', () {
      test('SelectableTextBlock paints its highlight beneath by default', () {
        final plain = _PlainText('plain');
        expect(plain.selectionHighlightAboveCachedContent, isFalse);
        final q = _first<MD$Quote>('> a\n>\n> b');
        final quote = BlockPainter$Quote(
          spans: q.spans,
          indent: q.indent,
          theme: _theme,
          children: <BlockPainter>[plain],
        );
        addTearDown(quote.dispose);
        expect(quote.selectionHighlightAboveCachedContent, isFalse);
        quote.layout(300);
        expect(quote.renderedText, 'plain');
        expect(quote.fragments.single.painter, plain.selectionPainter);
      });

      test('a bare SelectableBlockPainter child keeps text, no fragment', () {
        final q = _first<MD$Quote>('> a');
        final quote = BlockPainter$Quote(
          spans: q.spans,
          indent: q.indent,
          theme: _theme,
          children: <BlockPainter>[
            _RawSelectable('raw'),
            BlockPainter$Paragraph(
              spans: _first<MD$Paragraph>('after').spans,
              theme: _theme,
            ),
          ],
        );
        addTearDown(quote.dispose);
        quote.layout(300);
        expect(quote.renderedText, 'raw\nafter');
        // Only the paragraph contributes a fragment, after 'raw\n'.
        expect(quote.fragments.single.textStart, 4);
        expect(quote.fragments.single.painter.plainText, 'after');
      });

      test('a list reports links inside items only', () {
        final l = _first<MD$List>('- see [go](u)\n- plain\n');
        final list = BlockPainter$List(items: l.items, theme: _linkTheme);
        addTearDown(list.dispose);
        list.layout(300);
        expect(list.renderedText, 'see go\nplain');
        final link = list.boxesForRange(4, 6).first.center;
        final see = list.boxesForRange(0, 3).first.center;
        final plain = list.boxesForRange(7, 12).first.center;
        expect(list.isLinkAtLocal(link), isTrue);
        expect(list.isLinkAtLocal(see), isFalse);
        expect(list.isLinkAtLocal(plain), isFalse);
        expect(list.isLinkAtLocal(const Offset(-50, -50)), isFalse);
        // Any point inside an item's layout box is rendered text; the gap
        // left of the bullets is not.
        expect(list.hitsRenderedTextAt(plain), isTrue);
        expect(list.hitsRenderedTextAt(Offset(1, plain.dy)), isFalse);
      });

      test('an alert with nested blocks hit-tests its children', () {
        final a = _first<MD$Alert>(
          '> [!NOTE]\n> ```\n> x\n> ```\n>\n> aaaa aaaa aaaa aaaa b',
        );
        expect(a.blocks, isNotEmpty);
        final alert = BlockPainter$Alert(
          alert: a.alert,
          spans: a.spans,
          theme: _theme,
          children: <BlockPainter>[
            for (final b in a.blocks)
              b is MD$Code
                  ? BlockPainter$Code(
                      text: b.text,
                      language: b.language,
                      theme: _theme,
                    )
                  : b is MD$Paragraph
                      ? BlockPainter$Paragraph(spans: b.spans, theme: _theme)
                      : BlockPainter$Spacer(
                          count: (b as MD$Spacer).count,
                          theme: _theme,
                        ),
          ],
          blocks: a.blocks,
        );
        addTearDown(alert.dispose);
        alert.layout(134);
        final para = alert.fragments.last;
        expect(para.painter.plainText, startsWith('aaaa'));
        expect(
          alert.hitsRenderedTextAt(para.origin + const Offset(4, 4)),
          isTrue,
        );
        // The gutter after the short wrapped last line is not text.
        final gutter = Offset(
          para.painter.width - 2,
          para.painter.height - 3,
        );
        expect(alert.hitsRenderedTextAt(para.origin + gutter), isFalse);
        // Nor is the title row.
        expect(alert.hitsRenderedTextAt(const Offset(30, 14)), isFalse);
      });
    });
  });
}
