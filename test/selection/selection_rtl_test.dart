import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// Material controls that remember which handle types were last built.
class _RecordingControls extends MaterialTextSelectionControls {
  final List<TextSelectionHandleType> built = <TextSelectionHandleType>[];

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    built.add(type);
    return super.buildHandle(context, type, textLineHeight, onTap);
  }

  /// The (start, end) types of the most recent handle pair.
  (TextSelectionHandleType, TextSelectionHandleType) get last =>
      (built[built.length - 2], built.last);
}

/// Runs [body] with [platform] forced (try/finally — the framework's
/// `debugAssertAllFoundationVarsUnset` check runs before user tear-downs).
Future<void> _withPlatform(
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

MarkdownThemeData _theme(
  TextDirection direction, {
  void Function(String title, String url)? onLinkTap,
}) =>
    MarkdownThemeData(
      textStyle: const TextStyle(fontSize: 14),
      textDirection: direction,
      onLinkTap: onLinkTap,
    );

/// A document widget that reads its model from the scope's controller and
/// lays out in [direction].
class _Doc extends StatelessWidget {
  const _Doc(this.id, this.direction);

  final String id;
  final TextDirection direction;

  @override
  Widget build(BuildContext context) {
    final controller = MarkdownSelectionScope.of(context);
    final model = controller.documents.firstWhere((d) => d.id == id).model;
    return MarkdownTheme(
      data: _theme(direction),
      child: MarkdownWidget(markdown: model, documentId: id),
    );
  }
}

Future<void> _pumpScope(
  WidgetTester tester,
  MarkdownSelectionController controller,
  Widget child, {
  TextDirection ambient = TextDirection.ltr,
  TextSelectionControls? controls,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Directionality(
      textDirection: ambient,
      child: Scaffold(
        body: MarkdownSelectionScope(
          controller: controller,
          selectionControls: controls,
          child: child,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

MarkdownSelectionController _controllerFor(
  Map<String, String> sources,
) =>
    MarkdownSelectionController()
      ..setDocuments(<MarkdownDocumentRef>[
        for (final (i, MapEntry(:key, :value)) in sources.entries.indexed)
          MarkdownDocumentRef(
            id: key,
            model: Markdown.fromString(value),
            order: i,
          ),
      ]);

MarkdownPosition _at(String doc, int offset) =>
    MarkdownPosition(documentId: doc, blockIndex: 0, offset: offset);

void main() {
  group('Right-to-left selection', () {
    group('handle types follow the text, not the ambient Directionality', () {
      const hebrew = 'שלום עולם, זהו משפט לבדיקה';

      Future<(TextSelectionHandleType, TextSelectionHandleType)> handles(
        WidgetTester tester, {
        required TextDirection text,
        required TextDirection ambient,
        bool reversed = false,
      }) async {
        final controls = _RecordingControls();
        final controller = _controllerFor(<String, String>{'d': hebrew});
        addTearDown(controller.dispose);
        await _pumpScope(
          tester,
          controller,
          SizedBox(width: 400, child: _Doc('d', text)),
          ambient: ambient,
          controls: controls,
        );
        controller.selection = MarkdownSelection(
          base: _at('d', reversed ? 9 : 2),
          extent: _at('d', reversed ? 2 : 9),
        );
        await tester.pumpAndSettle();
        expect(controls.built, isNotEmpty, reason: 'touch handles shown');
        return controls.last;
      }

      testWidgets('RTL text in an LTR app', (tester) async {
        await _withPlatform(TargetPlatform.android, () async {
          final (start, end) = await handles(
            tester,
            text: TextDirection.rtl,
            ambient: TextDirection.ltr,
          );
          expect(start, TextSelectionHandleType.right);
          expect(end, TextSelectionHandleType.left);
        });
      });

      testWidgets('LTR text in an RTL app', (tester) async {
        // An RTL-locale app whose markdown theme was never told about the
        // direction lays text out LTR; its handles must stay LTR too.
        await _withPlatform(TargetPlatform.android, () async {
          final (start, end) = await handles(
            tester,
            text: TextDirection.ltr,
            ambient: TextDirection.rtl,
          );
          expect(start, TextSelectionHandleType.left);
          expect(end, TextSelectionHandleType.right);
        });
      });

      testWidgets('a reversed RTL selection swaps them back', (tester) async {
        await _withPlatform(TargetPlatform.android, () async {
          final (start, end) = await handles(
            tester,
            text: TextDirection.rtl,
            ambient: TextDirection.rtl,
            reversed: true,
          );
          expect(start, TextSelectionHandleType.left);
          expect(end, TextSelectionHandleType.right);
        });
      });

      testWidgets('a reversed LTR selection swaps them', (tester) async {
        await _withPlatform(TargetPlatform.android, () async {
          final (start, end) = await handles(
            tester,
            text: TextDirection.ltr,
            ambient: TextDirection.ltr,
            reversed: true,
          );
          expect(start, TextSelectionHandleType.right);
          expect(end, TextSelectionHandleType.left);
        });
      });

      testWidgets('each end of a mixed selection follows its own document',
          (tester) async {
        await _withPlatform(TargetPlatform.android, () async {
          final controls = _RecordingControls();
          final controller = _controllerFor(<String, String>{
            'en': 'An English message',
            'he': hebrew,
          });
          addTearDown(controller.dispose);
          await _pumpScope(
            tester,
            controller,
            const SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _Doc('en', TextDirection.ltr),
                  _Doc('he', TextDirection.rtl),
                ],
              ),
            ),
            controls: controls,
          );
          controller.selection = MarkdownSelection(
            base: _at('en', 3),
            extent: _at('he', 6),
          );
          await tester.pumpAndSettle();
          final (start, end) = controls.last;
          expect(start, TextSelectionHandleType.left, reason: 'LTR start');
          expect(end, TextSelectionHandleType.left, reason: 'RTL end');
        });
      });
    });

    testWidgets('a scrolled-off RTL base proxies onto the reading start',
        (tester) async {
      await _withPlatform(TargetPlatform.android, () async {
        final sources = <String, String>{
          for (var i = 0; i < 30; i++) 'm$i': 'הודעה מספר $i עם טקסט',
        };
        final controller = _controllerFor(sources);
        addTearDown(controller.dispose);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        await _pumpScope(
          tester,
          controller,
          SizedBox(
            height: 200,
            width: 400,
            child: ListView.builder(
              controller: scroll,
              itemCount: sources.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: _Doc('m$i', TextDirection.rtl),
              ),
            ),
          ),
        );
        controller.selection = MarkdownSelection(
          base: _at('m0', 0),
          extent: _at('m12', 6),
        );
        await tester.pumpAndSettle();
        scroll.jumpTo(800);
        await tester.pumpAndSettle();

        expect(
          controller.selectionEndpointGlobalRect(base: true),
          isNull,
          reason: 'the true base caret is unmounted',
        );
        final endpoints = controller.selectionHandleEndpoints()!;
        // The proxy start sits at the right end of the topmost visible
        // selected line: where an RTL reader starts. Bidi splits a line into
        // several boxes (the LTR number is a run of its own), so take the
        // rightmost box of the top line.
        final rects = endpoints.startSurface.globalSelectionRects();
        final top = rects.map((r) => r.top).reduce((a, b) => a < b ? a : b);
        final right = rects
            .where((r) => r.top == top)
            .map((r) => r.right)
            .reduce((a, b) => a > b ? a : b);
        expect(endpoints.startGlobal.left, closeTo(right, 0.5));
        expect(endpoints.startGlobal.width, 0);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('a mouse drag from the right edge selects the reading start',
        (tester) async {
      const text = 'שלום עולם זהו טקסט ארוך';
      final controller = _controllerFor(<String, String>{'d': text});
      addTearDown(controller.dispose);
      await _pumpScope(
        tester,
        controller,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 400, child: _Doc('d', TextDirection.rtl)),
        ),
      );
      final box = find.byType(MarkdownWidget);
      final from = tester.getTopRight(box) + const Offset(-1, 7);
      final to = from - const Offset(14 * 4 + 7, 0); // ~4.5 glyphs leftwards
      final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 200));
      await g.moveTo(to);
      await tester.pump(const Duration(milliseconds: 200));
      await g.up();
      await tester.pumpAndSettle();
      expect(
          controller.getText(), text.substring(0, controller.getText().length));
      expect(controller.getText(), startsWith('שלום'));
    });

    testWidgets('copied text does not depend on the direction', (tester) async {
      const source = '# כותרת\n\n'
          'פסקה עם [קישור](https://x.example)\n\n'
          '- אחד\n- שתיים\n\n'
          '| א | ב |\n|---|---|\n| 1 | 2 |\n\n'
          '> ציטוט\n\n'
          '> [!NOTE]\n> ```\n> code()\n> ```\n> הערה\n\n'
          '```\nprint(1)\n```';
      final texts = <TextDirection, String>{};
      for (final direction in TextDirection.values) {
        final controller = _controllerFor(<String, String>{'d': source});
        addTearDown(controller.dispose);
        await _pumpScope(
          tester,
          controller,
          SingleChildScrollView(
            child: SizedBox(width: 400, child: _Doc('d', direction)),
          ),
        );
        controller.selectAll();
        await tester.pump();
        texts[direction] = controller.getText();
      }
      expect(texts[TextDirection.rtl], texts[TextDirection.ltr]);
      expect(texts[TextDirection.rtl], contains('code()'));
      expect(texts[TextDirection.rtl], contains('1\t2'));
    });
  });

  group('Right-to-left link taps', () {
    // Each sample holds one link whose label is "קישור"; the tap aims at the
    // middle of that label's highlight box, which the geometry tests pin to
    // the painted glyphs.
    const samples = <String, String>{
      'paragraph': 'טקסט [קישור](https://x.example) עוד',
      'heading': '## כותרת [קישור](https://x.example)',
      'list': '- אחד\n- שתיים [קישור](https://x.example)',
      'table': '| א | ב |\n|---|---|\n| 1 | [קישור](https://x.example) |',
      'quote': '> ציטוט [קישור](https://x.example)',
      'nested quote': '> - פריט [קישור](https://x.example)',
      'alert': '> [!TIP]\n> גוף [קישור](https://x.example)',
      // A fence in the body makes the body nested blocks rather than
      // inline spans; the link then sits in a child after it.
      'quote with children':
          '> ```\n> x\n> ```\n> גוף [קישור](https://x.example)',
      'quote with a list child':
          '> ```\n> x\n> ```\n> - פריט [קישור](https://x.example)',
      'alert with children':
          '> [!TIP]\n> ```\n> x\n> ```\n> גוף [קישור](https://x.example)',
      'quote with a nested quote child':
          '> ```\n> x\n> ```\n> > מקונן [קישור](https://x.example)',
      'alert with a table child': '> [!TIP]\n> ```\n> x\n> ```\n'
          '> | א | ב |\n> |---|---|\n> | 1 | [קישור](https://x.example) |',
      'alert with a list child':
          '> [!TIP]\n> ```\n> x\n> ```\n> - פריט [קישור](https://x.example)',
    };

    for (final MapEntry(key: name, value: source) in samples.entries) {
      for (final direction in TextDirection.values) {
        testWidgets('$name ${direction.name}', (tester) async {
          final tapped = <String>[];
          final controller = MarkdownSelectionController();
          addTearDown(controller.dispose);
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 400,
                  child: MarkdownTheme(
                    data: _theme(
                      direction,
                      onLinkTap: (_, url) => tapped.add(url),
                    ),
                    child: MarkdownWidget(
                      markdown: Markdown.fromString(source),
                    ),
                  ),
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();

          final render = tester.renderObject<RenderBox>(
            find.byType(MarkdownWidget),
          ) as MarkdownSelectionSurface;
          final block = Markdown.fromString(source).blocks.single;
          if (name.contains('child')) {
            // Guard the sample itself: it must really nest blocks of the
            // named kind, or this would only test the leaf path again.
            final nested = switch (block) {
              MD$Quote(:final blocks) || MD$Alert(:final blocks) => blocks,
              _ => const <MD$Block>[],
            };
            expect(nested, isNotEmpty, reason: 'no nested blocks');
            final kind = switch (name) {
              String n when n.contains('list') => MD$List,
              String n when n.contains('table') => MD$Table,
              String n when n.contains('quote child') => MD$Quote,
              _ => MD$Paragraph,
            };
            expect(
              nested.map((b) => b.runtimeType),
              contains(kind),
              reason: 'nested: $nested',
            );
          }
          final rendered = markdownBlockRenderedText(block);
          final start = rendered.indexOf('קישור');
          expect(start, greaterThanOrEqualTo(0), reason: rendered);
          final boxes = render.localBoxesForRange(0, start, start + 5);
          final label = boxes.reduce((a, b) => a.expandToInclude(b));
          final origin = tester.getTopLeft(find.byType(MarkdownWidget));

          // Miss first: past the end of the short line, where nothing is
          // painted, nothing opens.
          final empty = direction == TextDirection.rtl ? 1.0 : 399.0;
          await tester.tapAt(origin + Offset(empty, label.center.dy));
          await tester.pump();
          expect(tapped, isEmpty, reason: 'tap on empty space');

          await tester.tapAt(origin + label.center);
          await tester.pump();
          expect(tapped, <String>['https://x.example']);
        });
      }
    }
  });

  group('Right-to-left constraints', () {
    const source = 'שלום עולם';

    Future<RenderBox> pump(WidgetTester tester, Widget Function(Widget) wrap,
        {String text = source}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MarkdownTheme(
            data: _theme(TextDirection.rtl),
            child: Align(
              alignment: Alignment.topLeft,
              child: wrap(MarkdownWidget(markdown: Markdown.fromString(text))),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      return tester.renderObject<RenderBox>(find.byType(MarkdownWidget));
    }

    /// Right edge of the selectable text, in the widget's own coordinates.
    double textRight(RenderBox box, int length) {
      final surface = box as MarkdownSelectionSurface;
      return surface
          .localBoxesForRange(0, 0, length)
          .map((r) => r.right)
          .reduce((a, b) => a > b ? a : b);
    }

    testWidgets('loose constraints hug the content and keep it in view',
        (tester) async {
      final box = await pump(
        tester,
        (child) => ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: child,
        ),
      );
      expect(box.size.width, lessThan(400));
      expect(textRight(box, source.length), closeTo(box.size.width, 0.5));
    });

    testWidgets('minWidth widens the box and the text follows its edge',
        (tester) async {
      final box = await pump(
        tester,
        (child) => ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 300, maxWidth: 400),
          child: child,
        ),
      );
      expect(box.size.width, 300);
      expect(textRight(box, source.length), closeTo(300, 0.5));
    });

    testWidgets('an unbounded width lays out at the content width',
        (tester) async {
      final box = await pump(
        tester,
        (child) => SizedBox(
          width: 400,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: child,
          ),
        ),
      );
      expect(box.size.width.isFinite, isTrue);
      expect(textRight(box, source.length), closeTo(box.size.width, 0.5));
    });

    testWidgets('a streamed update stays against the right edge',
        (tester) async {
      Widget wrap(Widget child) => SizedBox(width: 400, child: child);
      var box = await pump(tester, wrap, text: 'שלום');
      expect(textRight(box, 4), closeTo(400, 0.5));
      box = await pump(tester, wrap, text: 'שלום עולם ועוד מילים');
      expect(textRight(box, 4), closeTo(400, 0.5));
    });

    testWidgets('an empty RTL document lays out to nothing', (tester) async {
      final box = await pump(
        tester,
        (child) => ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: child,
        ),
        text: '',
      );
      expect(box.size, Size.zero);
    });
  });

  group('Narrow widths', () {
    // Fenced code skips laying out its text when the width cannot fit its
    // padding; painting it anyway used to throw. Quotes and alerts narrow the
    // width further for their children.
    const sources = <String>[
      '```\nx\n```\n\ntext',
      '> ```\n> x\n> ```',
      '> [!NOTE]\n> ```\n> x\n> ```',
    ];
    for (final width in <double>[1, 10, 30, 50]) {
      for (final direction in TextDirection.values) {
        testWidgets('$width ${direction.name} paints without throwing',
            (tester) async {
          for (final source in sources) {
            await tester.pumpWidget(MaterialApp(
              home: MarkdownTheme(
                data: _theme(direction),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width,
                    child: MarkdownWidget(
                      markdown: Markdown.fromString(source),
                    ),
                  ),
                ),
              ),
            ));
            expect(tester.takeException(), isNull, reason: source);
          }
        });
      }
    }
  });

  testWidgets('a dry layout at another width does not move hit-testing',
      (tester) async {
    // A parent may measure a child at other constraints after laying it out.
    // Measuring lays the painter out, which in RTL moves every block; the
    // real layout must be restored or hit-testing, highlight and link taps
    // use the measured positions while the glyphs stay where they were.
    const text = 'טקסט רגיל [קישור](https://x.example)';
    final tapped = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: MarkdownTheme(
            data: _theme(
              TextDirection.rtl,
              onLinkTap: (_, url) => tapped.add(url),
            ),
            child: _MeasureAfterLayout(
              child: SizedBox(
                width: 400,
                child: MarkdownWidget(markdown: Markdown.fromString(text)),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final finder = find.byType(MarkdownWidget);
    final render = tester.renderObject<RenderBox>(finder);
    expect(render.size.width, 400);
    final boxes = (render as MarkdownSelectionSurface).localBoxesForRange(
      0,
      0,
      'טקסט רגיל קישור'.length,
    );
    final right = boxes.map((b) => b.right).reduce((a, b) => a > b ? a : b);
    expect(right, closeTo(400, 0.5), reason: 'laid out at the real width');

    // The start of the line is plain text: tapping it opens nothing.
    await tester.tapAt(tester.getTopRight(finder) + const Offset(-4, 7));
    await tester.pump();
    expect(tapped, isEmpty);
  });
}

/// Lays its child out, then dry-lays it out at a narrower width.
class _MeasureAfterLayout extends SingleChildRenderObjectWidget {
  const _MeasureAfterLayout({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureAfterLayout();
}

class _RenderMeasureAfterLayout extends RenderProxyBox {
  @override
  void performLayout() {
    child!.layout(constraints, parentUsesSize: true);
    child!.getDryLayout(const BoxConstraints(maxWidth: 100));
    size = child!.size;
  }
}
