// Render-object level checks for `MarkdownRenderObject` / `MarkdownPainter`:
// right-to-left hit width, hover cursor stability across rebuilds, intrinsic
// sizes, repaint-boundary toggling and the cached glyph picture invariant.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/src/render.dart';
import 'package:flutter_test/flutter_test.dart';

MarkdownThemeData _theme([TextDirection direction = TextDirection.ltr]) =>
    MarkdownThemeData(
      textStyle: const TextStyle(fontSize: 14),
      textDirection: direction,
    );

Widget _host(Widget child, {double? width = 300}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    );

MarkdownRenderObject _ro(WidgetTester tester) =>
    tester.renderObject<MarkdownRenderObject>(find.byType(MarkdownWidget));

MouseCursor? _activeCursor() =>
    RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);

void main() {
  group('MarkdownRenderObject', () {
    group('right-to-left hit width', () {
      test('glyphs right of the content width still hit', () {
        final painter = MarkdownPainter(
          markdown: Markdown.fromString('שלום'),
          theme: _theme(TextDirection.rtl),
        );
        addTearDown(painter.dispose);
        // Tight 400: the content is far narrower, glyphs hug x = 400.
        final size = painter.layout(maxWidth: 400, minWidth: 400);
        expect(size.width, lessThan(200));
        final glyph = painter.localBoxesForRange(0, 0, 4).first.center;
        expect(glyph.dx, greaterThan(size.width));
        expect(painter.isSelectableAtLocal(glyph), isTrue);
        expect(painter.blockAtLocal(glyph)?.$1, 0);
        // Past the laid-out width is still outside.
        expect(painter.isSelectableAtLocal(Offset(400, glyph.dy)), isFalse);
      });

      testWidgets('hitsSelectableGlyphs over right-aligned glyphs',
          (tester) async {
        final controller = MarkdownSelectionController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            width: 400,
            MarkdownWidget(
              markdown: Markdown.fromString('שלום'),
              theme: _theme(TextDirection.rtl),
              controller: controller,
              documentId: 'rtl',
            ),
          ),
        );
        final ro = _ro(tester);
        final local = ro.localBoxesForRange(0, 0, 4).first.center;
        expect(ro.hitsSelectableGlyphs(ro.localToGlobal(local)), isTrue);
      });
    });

    group('hover cursor', () {
      Widget app(MarkdownCursorResolver resolver, String text) => _host(
            MarkdownWidget(
              markdown: Markdown.fromString(text),
              theme: _theme(),
              cursorResolver: resolver,
            ),
          );

      Future<TestGesture> hover(WidgetTester tester) async {
        final gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: const Offset(500, 500));
        await gesture.moveTo(const Offset(10, 7));
        await tester.pump();
        return gesture;
      }

      testWidgets('survives a rebuild with a fresh resolver closure',
          (tester) async {
        await tester.pumpWidget(
          app((_, __, ___) => SystemMouseCursors.grab, 'Hello world'),
        );
        await hover(tester);
        expect(_activeCursor(), SystemMouseCursors.grab);
        // Streaming: the parent rebuilds with a new closure and more text.
        await tester.pumpWidget(
          app((_, __, ___) => SystemMouseCursors.grab, 'Hello world!'),
        );
        await tester.pump();
        expect(_activeCursor(), SystemMouseCursors.grab);
      });

      testWidgets('re-resolves when the resolver changes', (tester) async {
        await tester.pumpWidget(
          app((_, __, ___) => SystemMouseCursors.grab, 'Hello'),
        );
        await hover(tester);
        expect(_activeCursor(), SystemMouseCursors.grab);
        await tester.pumpWidget(
          app((_, __, ___) => SystemMouseCursors.help, 'Hello'),
        );
        await tester.pump();
        expect(_activeCursor(), SystemMouseCursors.help);
      });

      testWidgets('re-resolves when the theme resolver changes',
          (tester) async {
        Widget themed(MouseCursor cursor) => _host(
              MarkdownWidget(
                markdown: Markdown.fromString('Hello'),
                theme: _theme().copyWith(
                  cursorResolver: (_, __, ___) => cursor,
                ),
              ),
            );
        await tester.pumpWidget(themed(SystemMouseCursors.grab));
        await hover(tester);
        expect(_activeCursor(), SystemMouseCursors.grab);
        await tester.pumpWidget(themed(SystemMouseCursors.help));
        await tester.pump();
        expect(_activeCursor(), SystemMouseCursors.help);
      });
    });

    group('intrinsic sizes', () {
      testWidgets('match the laid-out content', (tester) async {
        await tester.pumpWidget(
          _host(
            MarkdownWidget(
              markdown: Markdown.fromString('hello\n\nworld'),
              theme: _theme(),
            ),
          ),
        );
        final ro = _ro(tester);
        final height = ro.size.height;
        expect(height, greaterThan(0));
        expect(ro.getMaxIntrinsicHeight(300), height);
        expect(ro.getMinIntrinsicHeight(300), height);
        final width = ro.getMaxIntrinsicWidth(double.infinity);
        expect(width, greaterThan(0));
        expect(width, lessThanOrEqualTo(300));
        expect(ro.getMinIntrinsicWidth(double.infinity), 0);
      });

      testWidgets('IntrinsicHeight / IntrinsicWidth size to content',
          (tester) async {
        final markdown = Markdown.fromString('hello\n\n---\n\nworld');
        await tester.pumpWidget(
          _host(
            IntrinsicHeight(
              child: MarkdownWidget(markdown: markdown, theme: _theme()),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final height = _ro(tester).size.height;
        expect(height, greaterThan(0));

        await tester.pumpWidget(
          _host(
            width: null,
            IntrinsicWidth(
              child: MarkdownWidget(markdown: markdown, theme: _theme()),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(_ro(tester).size.width, greaterThan(0));
        expect(_ro(tester).size.height, greaterThan(0));
      });
    });

    testWidgets('toggling the controller flips the repaint boundary',
        (tester) async {
      final controller = MarkdownSelectionController();
      addTearDown(controller.dispose);
      final markdown = Markdown.fromString('Hello **world**');
      final theme = _theme();
      Widget build(MarkdownSelectionController? c, Object? id) => _host(
            MarkdownWidget(
              markdown: markdown,
              theme: theme,
              controller: c,
              documentId: id,
            ),
          );

      await tester.pumpWidget(build(null, null));
      final ro = _ro(tester);
      expect(ro.isRepaintBoundary, isFalse);

      await tester.pumpWidget(build(controller, 'a'));
      expect(ro.isRepaintBoundary, isTrue);
      expect(ro.debugLayer, isNotNull);
      controller.selectAll();
      await tester.pump();

      await tester.pumpWidget(build(null, null));
      expect(ro.isRepaintBoundary, isFalse);

      await tester.pumpWidget(build(controller, 'b'));
      expect(tester.takeException(), isNull);
      expect(ro.isRepaintBoundary, isTrue);
      expect(controller.documents.map((d) => d.id), contains('b'));
    });

    testWidgets('a selection change does not rebuild the glyph picture',
        (tester) async {
      final controller = MarkdownSelectionController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          MarkdownWidget(
            markdown: Markdown.fromString('Hello **world**\n\nSecond'),
            theme: _theme(),
            controller: controller,
            documentId: 'doc',
          ),
        ),
      );
      final painter = _ro(tester).debugPainter;
      final picture = painter.debugCachedPicture;
      expect(picture, isNotNull);

      controller.selectAll();
      await tester.pump();
      expect(controller.selection, isNotNull);
      expect(identical(painter.debugCachedPicture, picture), isTrue);

      controller.clear();
      await tester.pump();
      expect(identical(painter.debugCachedPicture, picture), isTrue);
    });
  });
}
