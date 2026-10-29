// Inline images and link icons: the MarkdownImage interface, offset mapping
// between the model (alt text) and the painter (one placeholder), ownership
// and reuse of resolved pictures, and the ImageProvider-backed defaults.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/src/render.dart';
import 'package:flutter_test/flutter_test.dart';

const String _obj = '￼';

/// A controllable picture: fixed [size], records layouts and paints.
class _FakeImage extends MarkdownImage {
  _FakeImage(this.request, this.size);

  final MarkdownImageRequest request;
  Size size;
  int layouts = 0;
  final List<Rect> paints = <Rect>[];
  MarkdownImageConstraints? lastConstraints;
  bool disposed = false;
  bool notifyDuringLayout = false;

  @override
  Size layout(MarkdownImageConstraints constraints) {
    layouts++;
    lastConstraints = constraints;
    if (notifyDuringLayout) {
      notifyDuringLayout = false;
      notifyListeners();
    }
    return size;
  }

  @override
  void paint(Canvas canvas, Rect rect, MarkdownImageConstraints constraints) =>
      paints.add(rect);

  void resize(Size value) {
    size = value;
    notifyListeners();
  }

  void touch() => notifyListeners();

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

/// Resolves every image (and, with [icons], every link) to a [_FakeImage].
class _FakeResolver {
  _FakeResolver({this.icons = false});

  final bool icons;
  static const Size imageSize = Size(40, 30);
  final List<MarkdownImageRequest> requests = <MarkdownImageRequest>[];
  final List<_FakeImage> images = <_FakeImage>[];

  MarkdownImage? call(MarkdownImageRequest request) {
    requests.add(request);
    if (request.kind == MarkdownImageKind.linkIcon && !icons) return null;
    final image = _FakeImage(
      request,
      request.kind == MarkdownImageKind.linkIcon
          ? const Size(16, 14)
          : imageSize,
    );
    images.add(image);
    return image;
  }
}

MarkdownThemeData _theme(
  MarkdownImageResolver? resolver, {
  void Function(String title, String url)? onLinkTap,
}) =>
    MarkdownThemeData(
      textStyle: const TextStyle(fontSize: 14),
      imageResolver: resolver,
      onLinkTap: onLinkTap,
    );

T _first<T extends MD$Block>(String source) =>
    Markdown.fromString(source).blocks.whereType<T>().first;

BlockPainter$Paragraph _paragraph(String source, MarkdownThemeData theme) =>
    BlockPainter$Paragraph(
      spans: _first<MD$Paragraph>(source).spans,
      theme: theme,
    )..layout(400);

Widget _host(Widget child, {double width = 300}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    );

MarkdownRenderObject _ro(WidgetTester tester) =>
    tester.renderObject<MarkdownRenderObject>(find.byType(MarkdownWidget));

/// Encodes a [width] × [height] PNG.
Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF2196F3),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Resolves when [image] next notifies.
Future<void> _changed(MarkdownImage image) {
  final completer = Completer<void>();
  void listener() {
    image.removeListener(listener);
    completer.complete();
  }

  image.addListener(listener);
  return completer.future.timeout(const Duration(seconds: 5));
}

const MarkdownImageConstraints _constraints = MarkdownImageConstraints(
  maxWidth: 100,
  textStyle: TextStyle(fontSize: 10),
);

void main() => group('Inline images', () {
      setUp(() => imageCache
        ..clear()
        ..clearLiveImages());

      group('requests', () {
        test('carry kind, url, alt text and title', () {
          final resolver = _FakeResolver(icons: true);
          _paragraph(
            'a ![cat](img/cat.png "Cat") [site](https://x.dev "T") b',
            _theme(resolver.call),
          );
          expect(resolver.requests, const <MarkdownImageRequest>[
            MarkdownImageRequest(
              kind: MarkdownImageKind.image,
              url: 'img/cat.png',
              text: 'cat',
              title: 'Cat',
            ),
            MarkdownImageRequest(
              kind: MarkdownImageKind.linkIcon,
              url: 'https://x.dev',
              text: 'site',
              title: 'T',
            ),
          ]);
          expect(resolver.requests.first.toString(), contains('image'));
          expect(
            resolver.requests.first.hashCode,
            resolver.requests.first.hashCode,
          );
        });

        test('constraints compare by value and scale the font size', () {
          const a = MarkdownImageConstraints(
            maxWidth: 10,
            textStyle: TextStyle(fontSize: 10),
            textScaler: TextScaler.linear(2),
          );
          const b = MarkdownImageConstraints(
            maxWidth: 10,
            textStyle: TextStyle(fontSize: 10),
            textScaler: TextScaler.linear(2),
          );
          expect(a, b);
          expect(a.hashCode, b.hashCode);
          expect(a.fontSize, 20);
          expect(
            const MarkdownImageConstraints(maxWidth: 1, textStyle: TextStyle())
                .fontSize,
            kDefaultFontSize,
          );
        });
      });

      group('without a resolver', () {
        test('an image renders as its alt text', () {
          final p = _paragraph('a ![cat](c.png) b', _theme(null));
          expect(p.painter.plainText, 'a cat b');
          expect(p.renderedText, 'a cat b');
          expect(p.selectionHighlightAboveCachedContent, isFalse);
        });

        test('a resolver returning null keeps the alt text', () {
          final p = _paragraph('a ![cat](c.png) b', _theme((_) => null));
          expect(p.painter.plainText, 'a cat b');
        });
      });

      group('paragraph with an image', () {
        test('the alt text becomes one placeholder in the painter', () {
          final resolver = _FakeResolver();
          final p = _paragraph('a ![cat](c.png) b', _theme(resolver.call));
          expect(p.painter.plainText, 'a $_obj b');
          // Selection still sees the model text.
          final block = _first<MD$Paragraph>('a ![cat](c.png) b');
          expect(p.renderedText, markdownBlockRenderedText(block));
          expect(p.renderedText, 'a cat b');
          expect(p.selectionHighlightAboveCachedContent, isTrue);
          // The slot is the image's size, so the line grows to fit it.
          expect(p.size.height, greaterThanOrEqualTo(30));
          final image = resolver.images.single;
          expect(image.lastConstraints!.maxWidth, 400);
          expect(image.lastConstraints!.fontSize, 14);
        });

        test('any part of the alt text highlights the whole picture', () {
          final resolver = _FakeResolver();
          final p = _paragraph('a ![cat](c.png) b', _theme(resolver.call));
          final whole = p.boxesForRange(2, 5);
          final part = p.boxesForRange(3, 4);
          expect(part, isNotEmpty);
          expect(part.single.width, closeTo(40, 0.01));
          expect(part, whole);
          // Before / after the picture map one to one.
          expect(p.boxesForRange(0, 1).single.left, 0);
          expect(p.boxesForRange(6, 7).single.left, greaterThan(40));
        });

        test('hit positions map back to model offsets', () {
          final resolver = _FakeResolver();
          final p = _paragraph('a ![cat](c.png) b', _theme(resolver.call));
          final slot = p.boxesForRange(2, 5).single;
          final after = p.positionAndAffinityForLocal(
            Offset(slot.right - 1, slot.center.dy),
          );
          expect(after.$1, 5); // past the whole alt text
          final before = p.offsetForLocalPosition(
            Offset(slot.left + 1, slot.center.dy),
          );
          expect(before, 2);
          final end = p.offsetForLocalPosition(Offset(399, slot.center.dy));
          expect(end, p.renderedText.length);
          // A word boundary on the picture spans its alt text.
          final word = p.wordBoundaryForLocal(slot.center);
          expect(word, const TextRange(start: 2, end: 5));
          // Carets on either side of the picture.
          final caretBefore = p.caretRectFor(2, TextAffinity.downstream);
          final caretAfter = p.caretRectFor(5, TextAffinity.downstream);
          expect(caretAfter.left - caretBefore.left, closeTo(40, 0.01));
          // An offset inside the alt text snaps to the picture's start.
          expect(p.caretRectFor(3, TextAffinity.downstream), caretBefore);
          expect(p.hitsRenderedTextAt(slot.center), isTrue);
        });

        test('paints the picture into its slot', () {
          final resolver = _FakeResolver();
          final p = _paragraph('a ![cat](c.png) b', _theme(resolver.call));
          final recorder = ui.PictureRecorder();
          p.paint(Canvas(recorder), const Size(400, 100), 10);
          recorder.endRecording().dispose();
          final slot = p.boxesForRange(2, 5).single;
          expect(
              resolver.images.single.paints.single,
              slot.shift(
                const Offset(0, 10),
              ));
        });

        test('an image with empty alt text still gets a slot', () {
          final resolver = _FakeResolver();
          final p = _paragraph('a ![](c.png) b', _theme(resolver.call));
          expect(p.renderedText, 'a  b');
          expect(p.painter.plainText, 'a $_obj b');
          expect(p.boxesForRange(0, 4), isNotEmpty);
        });

        test('selection copies the alt text', () async {
          final resolver = _FakeResolver();
          final controller = MarkdownSelectionController();
          addTearDown(controller.dispose);
          final markdown = Markdown.fromString('x ![cat](c.png) y');
          controller.putDocument('d', markdown);
          controller.selectAll();
          expect(controller.getText(), 'x cat y');
          expect(resolver.requests, isEmpty); // the model needs no pictures
        });
      });

      group('link icons', () {
        test('add a slot before the label without changing the text', () {
          final resolver = _FakeResolver(icons: true);
          final p = _paragraph(
            'see [docs](https://x.dev) now',
            _theme(resolver.call, onLinkTap: (_, __) {}),
          );
          expect(p.painter.plainText, 'see ${_obj}docs now');
          expect(p.renderedText, 'see docs now');
          // Selecting the label covers the icon too.
          final label = p.boxesForRange(4, 8);
          expect(label.first.width, closeTo(16, 0.01));
          expect(label.last.right - label.first.left, greaterThan(16));
          // Offsets after the link shift by the icon.
          final caret = p.caretRectFor(4, TextAffinity.downstream);
          final icon = resolver.images.single.paints;
          expect(icon, isEmpty);
          expect(caret.left, closeTo(label.first.left, 0.01));
          // Plain text next to a picture keeps its word boundaries.
          expect(
            p.wordBoundaryForLocal(Offset(1, label.first.center.dy)),
            const TextRange(start: 0, end: 3),
          );
          // The icon is a word of its own with no model text.
          expect(
            p.wordBoundaryForLocal(label.first.center),
            const TextRange(start: 4, end: 4),
          );
          // Upstream right after the icon resolves to the icon.
          expect(
            p.painter.text!.getSpanForPosition(
              const TextPosition(offset: 5, affinity: TextAffinity.upstream),
            ),
            isA<MarkdownImageSpan>(),
          );
        });

        test('a tap on the icon opens the link', () {
          final taps = <String>[];
          final resolver = _FakeResolver(icons: true);
          final p = _paragraph(
            '[docs](https://x.dev)',
            _theme(resolver.call, onLinkTap: (_, url) => taps.add(url)),
          );
          final iconCenter = Offset(8, p.size.height / 2);
          expect(p.isLinkAtLocal(iconCenter), isTrue);
          p
            ..handleTapDown(PointerDownEvent(position: iconCenter))
            ..handleTapUp(PointerUpEvent(position: iconCenter));
          expect(taps, <String>['https://x.dev']);
        });

        test('appear in headings, quotes, alerts, lists and tables', () {
          final resolver = _FakeResolver(icons: true);
          final theme = _theme(resolver.call, onLinkTap: (_, __) {});
          const link = '[l](https://x.dev)';
          final painters = <SelectableBlockPainter>[
            BlockPainter$Heading(
              level: 2,
              spans: _first<MD$Heading>('## $link').spans,
              theme: theme,
            ),
            BlockPainter$Quote(
              spans: _first<MD$Quote>('> $link').spans,
              indent: 1,
              theme: theme,
            ),
            BlockPainter$Alert(
              alert: MD$AlertType.note,
              spans: _first<MD$Alert>('> [!NOTE]\n> $link').spans,
              theme: theme,
            ),
            BlockPainter$List(
              items: _first<MD$List>('- $link\n  - $link').items,
              theme: theme,
            ),
            BlockPainter$Table(
              header: _first<MD$Table>('| $link |\n| - |\n| $link |').header,
              rows: _first<MD$Table>('| $link |\n| - |\n| $link |').rows,
              alignments: const <MD$TableColumnAlign>[],
              theme: theme,
            ),
          ];
          for (final painter in painters) {
            painter.layout(300);
            final recorder = ui.PictureRecorder();
            painter.paint(Canvas(recorder), const Size(300, 400), 0);
            recorder.endRecording().dispose();
            expect(painter.renderedText, isNot(contains(_obj)));
            expect(painter.boxesForRange(0, 1), isNotEmpty);
            expect(painter.selectionHighlightAboveCachedContent, isTrue);
            painter.dispose();
          }
          expect(
            resolver.images.where((i) => i.paints.isNotEmpty),
            hasLength(resolver.images.length),
          );
        });

        test('list and table text keeps the model offsets', () {
          final resolver = _FakeResolver();
          final theme = _theme(resolver.call);
          final list = BlockPainter$List(
            items: _first<MD$List>('- a ![x](1.png)\n- b').items,
            theme: theme,
          )..layout(300);
          expect(list.renderedText, 'a x\nb');
          expect(list.fragments.first.length, 3);
          final slot = list.boxesForRange(2, 3).single;
          expect(slot.width, closeTo(40, 0.01));
          expect(list.offsetForLocalPosition(slot.centerRight), 3);
          expect(
            list.wordBoundaryForLocal(slot.center),
            const TextRange(start: 2, end: 3),
          );
          expect(list.caretRectFor(3, TextAffinity.downstream).left,
              closeTo(slot.right, 0.01));

          final table = _first<MD$Table>('| ![x](1.png) | b |\n| - | - |');
          final tp = BlockPainter$Table(
            header: table.header,
            rows: table.rows,
            alignments: table.alignments,
            theme: theme,
          )..layout(300);
          expect(tp.renderedText, 'x\tb');
          expect(tp.boxesForRange(0, 1).single.width, closeTo(40, 0.01));
          list.dispose();
          tp.dispose();
        });
      });

      group('custom painters', () {
        test('a plain TextPainter.layout reserves a text-sized slot', () {
          final resolver = _FakeResolver();
          final painter = TextPainter(
            text: paragraphFromMarkdownSpans(
              spans: _first<MD$Paragraph>('a ![x](1.png) b').spans,
              theme: _theme(resolver.call),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          expect(painter.plainText, 'a $_obj b');
          expect(painter.inlinePlaceholderBoxes, hasLength(1));
          expect(painter.inlinePlaceholderBoxes!.single.toRect().width, 14);
          painter.dispose();
        });

        test('layoutMarkdownText sizes foreign placeholders as empty', () {
          final painter = TextPainter(
            text: const TextSpan(
              text: 'a',
              children: <InlineSpan>[
                WidgetSpan(child: SizedBox()),
                TextSpan(text: 'b'),
              ],
            ),
            textDirection: TextDirection.ltr,
          );
          layoutMarkdownText(painter);
          expect(markdownModelText(painter), 'a${_obj}b');
          final recorder = ui.PictureRecorder();
          paintMarkdownText(painter, Canvas(recorder), Offset.zero);
          recorder.endRecording().dispose();
          painter.dispose();
        });

        test('baseline-aligned pictures sit on the baseline', () {
          final image = _BaselineImage();
          final painter = TextPainter(
            text: TextSpan(
              style: const TextStyle(fontSize: 14),
              children: <InlineSpan>[
                const TextSpan(text: 'a'),
                MarkdownImageSpan(
                  image: image,
                  request: const MarkdownImageRequest(
                    kind: MarkdownImageKind.image,
                    url: 'u',
                  ),
                  modelText: 'alt',
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            textDirection: TextDirection.ltr,
          );
          layoutMarkdownText(painter);
          final box = painter.inlinePlaceholderBoxes!.single;
          final baseline =
              painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
          expect(box.bottom, closeTo(baseline, 0.5));
          // A zero-sized slot keeps a hairline so SkParagraph places it.
          image.size = Size.zero;
          painter.markNeedsLayout();
          layoutMarkdownText(painter);
          expect(painter.inlinePlaceholderBoxes!.single.toRect().width,
              closeTo(0.01, 0.001));
          painter.dispose();
          image.dispose();
        });

        test('image spans compare by identity of their picture', () {
          final image = _FakeImage(
            const MarkdownImageRequest(kind: MarkdownImageKind.image, url: 'u'),
            const Size(1, 1),
          );
          MarkdownImageSpan span() => MarkdownImageSpan(
                image: image,
                request: image.request,
                modelText: 'a',
                textStyle: const TextStyle(),
              );
          final a = span(), b = span();
          expect(a, b);
          expect(a.hashCode, b.hashCode);
          expect(a.compareTo(a), RenderComparison.identical);
          expect(a.compareTo(b), RenderComparison.layout);
          expect(a.getSpanForPosition(const TextPosition(offset: 0)), a);
          expect(a.codeUnitAt(0), PlaceholderSpan.placeholderCodeUnit);
          expect(a.debugAssertIsValid(), isTrue);
          expect(a.visitDirectChildren((_) => false), isTrue);
          final tree = TextSpan(children: <InlineSpan>[a, b]);
          expect(tree.getSpanForPosition(const TextPosition(offset: 1)), b);
          expect(a.constraints, isNull);
          image.dispose();
        });
      });

      group('ownership', () {
        test('streaming updates reuse the resolved picture', () {
          final resolver = _FakeResolver();
          final theme = _theme(resolver.call);
          final painter = MarkdownPainter(
            markdown: Markdown.fromString('![a](1.png) x'),
            theme: theme,
          )..layout(maxWidth: 300);
          final first = resolver.images.single;
          painter
            ..update(
              markdown: Markdown.fromString('![a](1.png) xy'),
              theme: theme,
            )
            ..layout(maxWidth: 300);
          expect(resolver.images, <_FakeImage>[first]);
          expect(resolver.requests, hasLength(1));
          expect(first.disposed, isFalse);
          // The image disappears from the document: disposed after layout.
          painter
            ..update(
              markdown: Markdown.fromString('text'),
              theme: theme,
            )
            ..layout(maxWidth: 300);
          expect(first.disposed, isTrue);
          expect(painter.debugImages.length, 0);
          painter.dispose();
        });

        test('repeated pictures share one image', () {
          final resolver = _FakeResolver();
          final painter = MarkdownPainter(
            markdown: Markdown.fromString(
              '![a](1.png) ![a](1.png)\n\n'
              '- ![a](1.png)\n\n'
              '| ![a](1.png) |\n| - |',
            ),
            theme: _theme(resolver.call),
          )..layout(maxWidth: 300);
          painter.layout(maxWidth: 200); // lists / tables rebuild on layout
          expect(resolver.images, hasLength(1));
          expect(painter.debugImages.length, 1);
          painter.dispose();
          expect(resolver.images.single.disposed, isTrue);
        });

        test('a resolver handing out the same instance twice is shared', () {
          final shared = _FakeImage(
            const MarkdownImageRequest(kind: MarkdownImageKind.image, url: ''),
            const Size(5, 5),
          );
          final painter = MarkdownPainter(
            markdown: Markdown.fromString('![a](1.png) ![b](2.png)'),
            theme: _theme((_) => shared),
          )..layout(maxWidth: 300);
          expect(painter.debugImages.length, 1);
          painter.dispose();
          expect(shared.disposed, isTrue);
        });

        test('a different resolver drops loaded pictures', () {
          final first = _FakeResolver();
          final second = _FakeResolver();
          final markdown = Markdown.fromString('![a](1.png)');
          final painter = MarkdownPainter(
            markdown: markdown,
            theme: _theme(first.call),
          )..layout(maxWidth: 300);
          painter
            ..update(markdown: markdown, theme: _theme(second.call))
            ..layout(maxWidth: 300);
          expect(first.images.single.disposed, isTrue);
          expect(second.images, hasLength(1));
          painter.dispose();
        });

        test('font changes rebuild painters but keep pictures', () {
          final resolver = _FakeResolver();
          final painter = MarkdownPainter(
            markdown: Markdown.fromString('![a](1.png)'),
            theme: _theme(resolver.call),
          )..layout(maxWidth: 300);
          painter
            ..invalidateLayout()
            ..layout(maxWidth: 300);
          expect(resolver.images, hasLength(1));
          expect(resolver.images.single.disposed, isFalse);
          painter.dispose();
        });

        test('RTL relayout records the final constraints', () {
          final resolver = _FakeResolver();
          final painter = MarkdownPainter(
            markdown: Markdown.fromString('![a](1.png)'),
            theme: MarkdownThemeData(
              textStyle: const TextStyle(fontSize: 14),
              textDirection: TextDirection.rtl,
              imageResolver: resolver.call,
            ),
          )..layout(maxWidth: 300);
          expect(resolver.images.single.lastConstraints!.maxWidth, 40);
          painter.dispose();
        });
      });

      group('change notifications', () {
        testWidgets('a size change re-lays out the widget', (tester) async {
          final resolver = _FakeResolver();
          await tester.pumpWidget(_host(MarkdownWidget(
            markdown: Markdown.fromString('![a](1.png)'),
            theme: _theme(resolver.call),
          )));
          final ro = _ro(tester);
          final before = ro.size.height;
          final image = resolver.images.single;
          expect(image.paints, isNotEmpty);
          image.resize(const Size(40, 120));
          expect(ro.debugNeedsLayout, isTrue);
          await tester.pump();
          expect(ro.size.height, greaterThan(before));
          expect(image.paints.last.height, closeTo(120, 0.01));
        });

        testWidgets('a same-size change only repaints', (tester) async {
          final resolver = _FakeResolver();
          await tester.pumpWidget(_host(MarkdownWidget(
            markdown: Markdown.fromString('![a](1.png)'),
            theme: _theme(resolver.call),
          )));
          final ro = _ro(tester);
          final image = resolver.images.single;
          final cached = ro.debugPainter.debugCachedPicture;
          expect(cached, isNotNull);
          final paints = image.paints.length;
          image.touch();
          expect(ro.debugNeedsLayout, isFalse);
          expect(ro.debugNeedsPaint, isTrue);
          expect(ro.debugPainter.debugCachedPicture, isNull);
          await tester.pump();
          expect(image.paints.length, paints + 1);
        });

        testWidgets('a notification during layout is deferred', (tester) async {
          final resolver = _FakeResolver();
          final relayouts = <bool>[];
          final painter = MarkdownPainter(
            markdown: Markdown.fromString('![a](1.png)'),
            theme: _theme(resolver.call),
            onImageChanged: relayouts.add,
          )..layout(maxWidth: 300);
          final image = resolver.images.single..notifyDuringLayout = true;
          painter.layout(maxWidth: 250);
          expect(relayouts, isEmpty);
          await tester.pump();
          expect(relayouts, <bool>[false]);
          painter.dispose();
          expect(image.disposed, isTrue);
        });

        testWidgets('disposed widgets ignore late notifications',
            (tester) async {
          final resolver = _FakeResolver();
          await tester.pumpWidget(_host(MarkdownWidget(
            markdown: Markdown.fromString('![a](1.png)'),
            theme: _theme(resolver.call),
          )));
          final image = resolver.images.single;
          final ro = _ro(tester);
          await tester.pumpWidget(const SizedBox());
          expect(image.disposed, isTrue);
          // The render object is gone; its pool no longer listens.
          expect(() => ro.debugPainter.debugImages.length, returnsNormally);
        });
      });

      group('MarkdownProviderImage', () {
        testWidgets('loads, sizes and paints an image', (tester) async {
          final bytes = (await tester.runAsync(() => _png(200, 100)))!;
          final image = MarkdownProviderImage(
            MemoryImage(bytes),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          );
          // While loading: a text-sized placeholder.
          final loading = image.layout(_constraints);
          expect(loading, const Size.square(10));
          final recorder = ui.PictureRecorder();
          image.paint(Canvas(recorder), Offset.zero & loading, _constraints);
          if (image.imageInfo == null) {
            await tester.runAsync(() => _changed(image));
          }
          expect(image.imageInfo, isNotNull);
          expect(image.hasError, isFalse);
          // Scaled down to the line width, keeping the aspect ratio.
          expect(image.layout(_constraints), const Size(100, 50));
          expect(
            image.layout(const MarkdownImageConstraints(
              maxWidth: double.infinity,
              textStyle: TextStyle(fontSize: 10),
            )),
            const Size(200, 100),
          );
          recorder.endRecording().dispose();
          final loaded = ui.PictureRecorder();
          image.paint(
            Canvas(loaded),
            const Rect.fromLTWH(0, 0, 100, 50),
            _constraints,
          );
          loaded.endRecording().dispose();
          image.dispose();
        });

        testWidgets('maxHeight caps the image', (tester) async {
          final bytes = (await tester.runAsync(() => _png(40, 80)))!;
          final image =
              MarkdownProviderImage(MemoryImage(bytes), maxHeight: 20);
          image.layout(_constraints);
          if (image.imageInfo == null) {
            await tester.runAsync(() => _changed(image));
          }
          expect(image.layout(_constraints), const Size(10, 20));
          // Synchronous re-resolve from the cache does not notify.
          final again = MarkdownProviderImage(MemoryImage(bytes));
          var notified = false;
          again.addListener(() => notified = true);
          again.layout(_constraints);
          expect(again.imageInfo, isNotNull);
          expect(notified, isFalse);
          image.dispose();
          again.dispose();
        });

        testWidgets('an icon is text sized and collapses on error',
            (tester) async {
          final icon = MarkdownProviderImage.icon(
            MemoryImage(Uint8List.fromList(<int>[1, 2, 3, 4])),
            iconScale: 1.5,
          );
          expect(icon.layout(_constraints), const Size(19, 15));
          // RTL puts the icon on the right of its slot, the gap on the left.
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          icon.paint(
            canvas,
            const Rect.fromLTWH(0, 0, 19, 15),
            const MarkdownImageConstraints(
              maxWidth: 100,
              textStyle: TextStyle(fontSize: 10),
              textDirection: TextDirection.rtl,
            ),
          );
          icon.paint(
            canvas,
            const Rect.fromLTWH(0, 0, 19, 15),
            _constraints,
          );
          recorder.endRecording().dispose();
          await tester.runAsync(() => _changed(icon));
          expect(icon.hasError, isTrue);
          expect(icon.layout(_constraints), Size.zero);
          icon.dispose();
          // Loading after dispose is a no-op.
          expect(() => icon.layout(_constraints), returnsNormally);
        });

        testWidgets('a failed image keeps its placeholder', (tester) async {
          final image = MarkdownProviderImage(
            MemoryImage(Uint8List.fromList(<int>[9, 9, 9])),
            placeholderColor: null,
          );
          image.layout(_constraints);
          await tester.runAsync(() => _changed(image));
          expect(image.hasError, isTrue);
          expect(image.layout(_constraints), const Size.square(10));
          final recorder = ui.PictureRecorder();
          image.paint(
            Canvas(recorder),
            const Rect.fromLTWH(0, 0, 10, 10),
            _constraints,
          );
          recorder.endRecording().dispose();
          image.dispose();
        });

        test('an empty slot paints nothing', () {
          final image = MarkdownProviderImage(
            MemoryImage(Uint8List(0)),
          );
          final recorder = ui.PictureRecorder();
          image.paint(Canvas(recorder), Rect.zero, _constraints);
          recorder.endRecording().dispose();
          image.dispose();
        });

        testWidgets('end to end in a widget', (tester) async {
          final bytes = (await tester.runAsync(() => _png(60, 30)))!;
          final source = 'data:image/png;base64,${base64Encode(bytes)}';
          await tester.pumpWidget(_host(MarkdownWidget(
            markdown: Markdown.fromString('before\n\n![alt]($source)'),
            theme: _theme(const MarkdownProviderImageResolver().call),
          )));
          final ro = _ro(tester);
          final pool = ro.debugPainter.debugImages;
          expect(pool.length, 1);
          final before = ro.size.height;
          // Decode the image, then let the widget re-lay out.
          for (var i = 0; i < 20 && ro.size.height == before; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)),
            );
            await tester.pump();
          }
          expect(ro.size.height, greaterThan(before));
        });
      });

      group('MarkdownProviderImageResolver', () {
        const resolver = MarkdownProviderImageResolver(linkIcons: true);
        MarkdownImage? resolve(
          MarkdownImageResolver r,
          MarkdownImageKind kind,
          String url,
        ) =>
            r(MarkdownImageRequest(kind: kind, url: url));

        test('maps web and data images to providers', () {
          expect(
            MarkdownProviderImageResolver.defaultImageProvider(
              Uri.parse('https://x.dev/a.png'),
            ),
            isA<NetworkImage>(),
          );
          expect(
            MarkdownProviderImageResolver.defaultImageProvider(
              Uri.parse('data:image/png;base64,AAAA'),
            ),
            isA<MemoryImage>(),
          );
          for (final skipped in <String>[
            'data:text/plain;base64,AAAA',
            'file:///tmp/a.png',
            'https:///a.png',
            'asset:a.png',
          ]) {
            expect(
              MarkdownProviderImageResolver.defaultImageProvider(
                Uri.parse(skipped),
              ),
              isNull,
              reason: skipped,
            );
          }
        });

        test('favicons live at the root of web origins', () {
          expect(
            MarkdownProviderImageResolver.defaultFaviconUri(
              Uri.parse('https://x.dev:8443/a/b?c#d'),
            ),
            Uri.parse('https://x.dev:8443/favicon.ico'),
          );
          expect(
            MarkdownProviderImageResolver.defaultFaviconUri(
              Uri.parse('http://x.dev/a'),
            ),
            Uri.parse('http://x.dev/favicon.ico'),
          );
          expect(
            MarkdownProviderImageResolver.defaultFaviconUri(
              Uri.parse('mailto:a@b.c'),
            ),
            isNull,
          );
          expect(
            MarkdownProviderImageResolver.defaultFaviconUri(
              Uri.parse('https:///a'),
            ),
            isNull,
          );
        });

        test('resolves images and link icons', () {
          final image = resolve(
            resolver.call,
            MarkdownImageKind.image,
            'https://x.dev/a.png',
          );
          expect(image, isA<MarkdownProviderImage>());
          expect((image! as MarkdownProviderImage).iconScale, isNull);
          final icon = resolve(
            resolver.call,
            MarkdownImageKind.linkIcon,
            'https://x.dev/page',
          );
          expect((icon! as MarkdownProviderImage).iconScale, 1);
          expect(
            ((icon as MarkdownProviderImage).provider as NetworkImage).url,
            'https://x.dev/favicon.ico',
          );
          image.dispose();
          icon.dispose();
        });

        test('skips what it cannot or may not show', () {
          const off = MarkdownProviderImageResolver(images: false);
          expect(
            resolve(off.call, MarkdownImageKind.image, 'https://x.dev/a.png'),
            isNull,
          );
          // Link icons are opt-in.
          expect(
            resolve(off.call, MarkdownImageKind.linkIcon, 'https://x.dev'),
            isNull,
          );
          expect(
            resolve(resolver.call, MarkdownImageKind.linkIcon, 'mailto:a@b'),
            isNull,
          );
          expect(
            resolve(resolver.call, MarkdownImageKind.image, 'rel/a.png'),
            isNull,
          );
          expect(
            resolve(resolver.call, MarkdownImageKind.image, 'http://[::1'),
            isNull,
          );
          expect(
            resolve(resolver.call, MarkdownImageKind.image, 'file:///a.png'),
            isNull,
          );
          final noFavicon = MarkdownProviderImageResolver(
            linkIcons: true,
            faviconUri: (_) => Uri.parse('file:///icon.png'),
          );
          expect(
            resolve(noFavicon.call, MarkdownImageKind.linkIcon, 'https://x'),
            isNull,
          );
        });

        test('resolves relative sources against baseUri', () {
          final requested = <Uri>[];
          final based = MarkdownProviderImageResolver(
            baseUri: Uri.parse('https://x.dev/docs/'),
            imageProvider: (uri) {
              requested.add(uri);
              return MemoryImage(Uint8List(0));
            },
          );
          resolve(based.call, MarkdownImageKind.image, 'img/a.png')?.dispose();
          expect(requested, <Uri>[Uri.parse('https://x.dev/docs/img/a.png')]);
        });
      });

      test('theme copyWith, lerp and mergeTheme carry the resolver', () {
        MarkdownImage? resolver(MarkdownImageRequest r) => null;
        final theme = MarkdownThemeData(
          textStyle: const TextStyle(),
          imageResolver: resolver,
        );
        expect(theme.copyWith().imageResolver, resolver);
        final other = MarkdownThemeData(textStyle: const TextStyle());
        expect(
          (theme.lerp(other, 0.2) as MarkdownThemeData).imageResolver,
          resolver,
        );
        expect(
          (theme.lerp(other, 0.8) as MarkdownThemeData).imageResolver,
          isNull,
        );
        expect(
          MarkdownThemeData.mergeTheme(ThemeData(), imageResolver: resolver)
              .imageResolver,
          resolver,
        );
      });
    });

/// A baseline-aligned picture with a settable size.
class _BaselineImage extends MarkdownImage {
  Size size = const Size(10, 20);

  @override
  ui.PlaceholderAlignment get alignment => ui.PlaceholderAlignment.baseline;

  @override
  Size layout(MarkdownImageConstraints constraints) => size;

  @override
  void paint(Canvas canvas, Rect rect, MarkdownImageConstraints constraints) {}
}
