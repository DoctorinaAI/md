import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/src/render.dart' show MarkdownPainter;
import 'package:flutter_md/src/render/block_identity.dart';
import 'package:flutter_test/flutter_test.dart';

MarkdownThemeData _theme({
  void Function(String, String)? onLinkTap,
  bool Function(MD$Block)? blockFilter,
  TextDirection direction = TextDirection.ltr,
  double fontSize = 14,
}) =>
    MarkdownThemeData(
      textStyle: TextStyle(fontSize: fontSize, color: const Color(0xFF000000)),
      textDirection: direction,
      onLinkTap: onLinkTap,
      blockFilter: blockFilter,
    );

const _sample = '''
# Heading *i*

Paragraph **bold** `code` [link](https://a.b "t").

> quote

> [!NOTE]
> alert

```dart
void main() {}
```

- a
  - b
- [x] c

| A | B |
|:--|--:|
| 1 | 2 |

---
''';

Future<List<int>> _pixels(MarkdownPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    size.width.ceil(),
    size.height.ceil(),
  );
  final data = await image.toByteData();
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  group('markdownBlocksSame', () {
    test('two parses of one text match, block by block', () {
      final a = Markdown.fromString(_sample).blocks;
      final b = Markdown.fromString(_sample).blocks;
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(markdownBlocksSame(a[i], b[i]), isTrue, reason: '$i');
      }
    });

    for (final (name, left, right) in const <(String, String, String)>[
      ('paragraph text', 'a', 'b'),
      ('span style', '**a** b', '*a* b'),
      ('link url', '[a](u)', '[a](v)'),
      ('heading level', '# a', '## a'),
      ('code language', '```a\nx\n```', '```b\nx\n```'),
      ('code text', '```\nx\n```', '```\ny\n```'),
      ('list marker', '- a', '1. a'),
      ('task state', '- [ ] a', '- [x] a'),
      ('nested item', '- a\n  - b', '- a\n  - c'),
      ('quote body', '> a', '> b'),
      ('alert kind', '> [!NOTE]\n> a', '> [!TIP]\n> a'),
      ('table cell', '| a |\n|---|\n| b |', '| a |\n|---|\n| c |'),
      ('table alignment', '| a |\n|:--|\n| b |', '| a |\n|--:|\n| b |'),
      ('block kind', '---', 'a'),
    ]) {
      test('tells apart: $name', () {
        final a = Markdown.fromString(left).blocks.first;
        final b = Markdown.fromString(right).blocks.first;
        expect(markdownBlocksSame(a, b), isFalse);
      });
    }

    test('tells apart spans of one text', () {
      MD$Paragraph paragraph(MD$Style style, Map<String, Object?>? extra) =>
          MD$Paragraph(
            text: 'a',
            spans: <MD$Span>[
              MD$Span(start: 0, end: 1, text: 'a', style: style, extra: extra),
            ],
          );
      final plain = paragraph(MD$Style.none, null);
      expect(markdownBlocksSame(plain, paragraph(MD$Style.none, null)), isTrue);
      expect(
          markdownBlocksSame(plain, paragraph(MD$Style.bold, null)), isFalse);
      expect(
        markdownBlocksSame(plain, paragraph(MD$Style.none, {'url': 'u'})),
        isFalse,
      );
    });

    test('spacers differ by count', () {
      final a = MD$Spacer(count: 1), b = MD$Spacer(count: 2);
      expect(markdownBlocksSame(a, b), isFalse);
      expect(markdownBlocksSame(a, MD$Spacer(count: 1)), isTrue);
    });
  });

  group('MarkdownThemeData.paintsLike', () {
    test('equal values match across instances', () {
      expect(_theme().paintsLike(_theme()), isTrue);
    });
    test('a different value or hook does not', () {
      expect(_theme().paintsLike(_theme(fontSize: 15)), isFalse);
      expect(
        _theme().paintsLike(_theme(direction: TextDirection.rtl)),
        isFalse,
      );
      expect(_theme().paintsLike(_theme(onLinkTap: (_, __) {})), isFalse);
    });
    test('the same hook instance matches', () {
      void tap(String _, String __) {}
      expect(
        _theme(onLinkTap: tap).paintsLike(_theme(onLinkTap: tap)),
        isTrue,
      );
    });
  });

  group('MarkdownPainter.update', () {
    test('the same text and an equal theme change nothing', () async {
      final painter = MarkdownPainter(
        markdown: Markdown.fromString(_sample),
        theme: _theme(),
      );
      final size = painter.layout(maxWidth: 400);
      await _pixels(painter, Size(400, size.height));
      final picture = painter.debugCachedPicture;
      expect(
        painter.update(
          markdown: Markdown.fromString(_sample),
          theme: _theme(),
        ),
        isFalse,
      );
      expect(painter.needsLayout, isFalse);
      expect(painter.debugCachedPicture, same(picture));
      painter.dispose();
    });

    test('a pending layout is still reported', () {
      final painter = MarkdownPainter(
        markdown: Markdown.fromString(_sample),
        theme: _theme(),
      );
      expect(painter.needsLayout, isTrue);
      expect(
        painter.update(
          markdown: Markdown.fromString(_sample),
          theme: _theme(),
        ),
        isTrue,
      );
      painter.dispose();
    });

    test('new text reports a change and new model', () {
      final next = Markdown.fromString('$_sample\nmore');
      final painter = MarkdownPainter(
        markdown: Markdown.fromString(_sample),
        theme: _theme(),
      );
      painter.layout(maxWidth: 400);
      expect(painter.update(markdown: next, theme: _theme()), isTrue);
      expect(painter.markdown, same(next));
      expect(painter.needsLayout, isTrue);
      painter.dispose();
    });

    test('a changed theme value rebuilds the same text', () {
      final markdown = Markdown.fromString(_sample);
      final painter = MarkdownPainter(markdown: markdown, theme: _theme());
      final small = painter.layout(maxWidth: 400);
      expect(
        painter.update(markdown: markdown, theme: _theme(fontSize: 28)),
        isTrue,
      );
      expect(painter.layout(maxWidth: 400).height, greaterThan(small.height));
      painter.dispose();
    });

    test('hooks turn reuse off', () {
      bool keep(MD$Block _) => true;
      final markdown = Markdown.fromString(_sample);
      final painter = MarkdownPainter(
        markdown: markdown,
        theme: _theme(blockFilter: keep),
      );
      painter.layout(maxWidth: 400);
      expect(
        painter.update(
          markdown: Markdown.fromString(_sample),
          theme: _theme(blockFilter: keep),
        ),
        isTrue,
      );
      painter.dispose();
    });

    test('a host builder painter is not disposed by an update', () {
      final disposed = <BlockPainter>[];
      final theme = MarkdownThemeData(
        textStyle: const TextStyle(fontSize: 14),
        builder: (block, theme) => _Probe(disposed),
      );
      final painter = MarkdownPainter(
        markdown: Markdown.fromString('a\n\nb'),
        theme: theme,
      );
      painter.update(markdown: Markdown.fromString('c'), theme: theme);
      expect(disposed, isEmpty);
      painter.dispose();
      expect(disposed, isNotEmpty);
    });

    test('a streamed document paints what a fresh painter paints', () async {
      final blocks = List<String>.generate(
        120,
        (i) => i.isEven ? 'paragraph **$i** text' : '- item $i\n- `other`',
      );
      final theme = _theme();
      final painter = MarkdownPainter(
        markdown: Markdown.fromString(''),
        theme: theme,
      );
      var text = '', recorded = 0;
      for (final block in blocks) {
        text += '$block\n\n';
        painter.update(markdown: Markdown.fromString(text), theme: theme);
        final size = painter.layout(maxWidth: 300);
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), Size(300, size.height));
        recorder.endRecording().dispose();
        recorded = painter.debugPrefixBlocks;
      }
      expect(recorded, greaterThan(100), reason: 'the prefix is in use');

      final size = painter.layout(maxWidth: 300);
      final fresh = MarkdownPainter(
        markdown: Markdown.fromString(text),
        theme: theme,
      );
      final freshSize = fresh.layout(maxWidth: 300);
      expect(size, freshSize);
      // The cached picture is keyed by size: force a new recording of both.
      final streamed = await _pixels(painter, Size(300, size.height + 1));
      final expected = await _pixels(fresh, Size(300, size.height + 1));
      expect(streamed, expected);
      fresh.dispose();
      painter.dispose();
    });

    test('the prefix does not outlive a width or content change', () async {
      final theme = _theme();
      final body = List<String>.filled(60, 'some words\n\n').join();
      final painter = MarkdownPainter(
        markdown: Markdown.fromString(body),
        theme: theme,
      );
      painter.layout(maxWidth: 300);
      painter.update(markdown: Markdown.fromString('$body\nx'), theme: theme);
      final size = painter.layout(maxWidth: 300);
      await _pixels(painter, Size(300, size.height));
      expect(painter.debugPrefixBlocks, greaterThan(0));

      // Narrower: the text wraps differently.
      final narrow = painter.layout(maxWidth: 40);
      expect(painter.debugPrefixBlocks, 0);
      final fresh = MarkdownPainter(
        markdown: Markdown.fromString('$body\nx'),
        theme: theme,
      )..layout(maxWidth: 40);
      expect(
        await _pixels(painter, Size(40, narrow.height)),
        await _pixels(fresh, Size(40, narrow.height)),
      );
      fresh.dispose();

      // Different start of the document.
      painter.layout(maxWidth: 300);
      painter.update(markdown: Markdown.fromString('$body\ny'), theme: theme);
      final again = painter.layout(maxWidth: 300);
      await _pixels(painter, Size(300, again.height));
      expect(painter.debugPrefixBlocks, greaterThan(0));
      painter.update(markdown: Markdown.fromString('other'), theme: theme);
      expect(painter.debugPrefixBlocks, 0);
      painter.dispose();
    });
  });

  group('Relayout keeps the text painters', () {
    const list = '- a **bold** item that is long enough to wrap around\n'
        '  - nested\n1. first';
    const table = '| Header one | Header two |\n|---|---|\n'
        '| a cell with several words | short |';

    for (final (name, source) in const <(String, String)>[
      ('list', list),
      ('table', table),
    ]) {
      for (final direction in TextDirection.values) {
        test('$name ${direction.name} matches a fresh layout', () async {
          final theme = _theme(direction: direction);
          final painter = MarkdownPainter(
            markdown: Markdown.fromString(source),
            theme: theme,
          );
          for (final width in const <double>[400, 90, 900, 90, 400]) {
            final size = painter.layout(maxWidth: width);
            final fresh = MarkdownPainter(
              markdown: Markdown.fromString(source),
              theme: theme,
            );
            expect(size, fresh.layout(maxWidth: width), reason: '$width');
            expect(
              painter.localBoxesForRange(0, 0, 10),
              fresh.localBoxesForRange(0, 0, 10),
              reason: '$width',
            );
            expect(
              painter.positionForLocal(const Offset(20, 5)),
              fresh.positionForLocal(const Offset(20, 5)),
            );
            final area = Size(width, size.height.ceilToDouble());
            expect(await _pixels(painter, area), await _pixels(fresh, area));
            fresh.dispose();
          }
          painter.dispose();
        });
      }
    }
  });

  test('selection data is built on demand and stays right', () {
    const source = '- one\n- two\n\n> quote\n\n> [!NOTE]\n> body\n\n'
        '| a | b |\n|---|---|\n| c | d |\n\n> - nested\n> - list';
    final markdown = Markdown.fromString(source);
    final painter = MarkdownPainter(
      markdown: markdown,
      theme: _theme(),
    );
    painter.layout(maxWidth: 300);
    for (var i = 0; i < markdown.blocks.length; i++) {
      final block = markdown.blocks[i];
      if (block is MD$Spacer) continue;
      final text = markdownBlockRenderedText(block);
      expect(
        painter.localBoxesForRange(i, 0, text.length),
        isNotEmpty,
        reason: block.type,
      );
    }
    painter.dispose();
  });
}

class _Probe implements BlockPainter {
  _Probe(this.disposed);
  final List<BlockPainter> disposed;

  @override
  Size get size => Size.zero;

  @override
  Size layout(double width) => Size.zero;

  @override
  void paint(Canvas canvas, Size size, double offset) {}

  @override
  void handleTapDown(PointerDownEvent event) {}

  @override
  void handleTapUp(PointerUpEvent event) {}

  @override
  void dispose() => disposed.add(this);
}
