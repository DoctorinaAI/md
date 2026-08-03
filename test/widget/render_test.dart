import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a [MarkdownWidget] for [source] inside a sized, themed scaffold and
/// returns the tester for further inspection.
Future<void> _pumpMarkdown(
  WidgetTester tester,
  String source, {
  MarkdownThemeData? theme,
  void Function(String title, String url)? onLinkTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownTheme(
          data: theme ??
              MarkdownThemeData(
                textStyle: const TextStyle(fontSize: 14),
                onLinkTap: onLinkTap,
              ),
          child: Center(
            child: SizedBox(
              width: 400,
              child: MarkdownWidget(markdown: Markdown.fromString(source)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Size _mdSize(WidgetTester tester) =>
    tester.renderObject<RenderBox>(find.byType(MarkdownWidget)).size;

void main() {
  group('MarkdownWidget rendering', () {
    testWidgets('renders a rich document without exceptions', (tester) async {
      const source = '# Heading\n\n'
          'A paragraph with **bold**, _italic_, `code`, ~~strike~~, '
          '==mark==, ||spoiler|| and a [link](https://example.com).\n\n'
          '> A blockquote\n\n'
          '```dart\nvoid main() {}\n```\n\n'
          '- one\n- two\n  - nested\n\n'
          '1. first\n2. second\n\n'
          '| A | B |\n|:--|--:|\n| 1 | 2 |\n\n'
          '---\n';
      await _pumpMarkdown(tester, source);
      expect(tester.takeException(), isNull);
      expect(_mdSize(tester).height, greaterThan(0));
    });

    testWidgets('empty markdown produces zero size', (tester) async {
      await _pumpMarkdown(tester, '');
      expect(tester.takeException(), isNull);
      // Width is constrained by the parent SizedBox; the content height is 0.
      expect(_mdSize(tester).height, 0);
    });

    group('GitHub alerts render', () {
      for (final type in ['NOTE', 'TIP', 'IMPORTANT', 'WARNING', 'CAUTION']) {
        testWidgets('$type alert', (tester) async {
          await _pumpMarkdown(
            tester,
            '> [!$type]\n> Body of the $type alert with **bold**.',
          );
          expect(tester.takeException(), isNull);
          expect(_mdSize(tester).height, greaterThan(0));
        });
      }

      testWidgets('marker-only alert still lays out', (tester) async {
        await _pumpMarkdown(tester, '> [!WARNING]');
        expect(tester.takeException(), isNull);
        expect(_mdSize(tester).height, greaterThan(0));
      });
    });

    testWidgets('task lists render without exceptions', (tester) async {
      await _pumpMarkdown(
        tester,
        '- [ ] todo\n- [x] done\n- normal item\n  - [ ] nested todo',
      );
      expect(tester.takeException(), isNull);
      expect(_mdSize(tester).height, greaterThan(0));
    });

    testWidgets('aligned tables render without exceptions', (tester) async {
      await _pumpMarkdown(
        tester,
        '| Left | Center | Right |\n'
        '| :--- | :----: | ----: |\n'
        '| a    | b      | c     |\n'
        '| longer text | x | y |',
      );
      expect(tester.takeException(), isNull);
      expect(_mdSize(tester).height, greaterThan(0));
    });

    testWidgets('inline math renders', (tester) async {
      await _pumpMarkdown(tester, r'The angle $\alpha \leq \beta$ holds.');
      expect(tester.takeException(), isNull);
      expect(_mdSize(tester).height, greaterThan(0));
    });

    testWidgets('thematic break variants render', (tester) async {
      await _pumpMarkdown(tester, 'a\n\n---\n\nb\n\n***\n\nc\n\n___\n\nd');
      expect(tester.takeException(), isNull);
      expect(_mdSize(tester).height, greaterThan(0));
    });

    testWidgets('tapping a link invokes onLinkTap', (tester) async {
      final tapped = <String>[];
      await _pumpMarkdown(
        tester,
        '[click me](https://example.com)',
        onLinkTap: (title, url) => tapped.add(url),
      );
      // The whole first line is the link; tap near its start.
      final topLeft = tester.getTopLeft(find.byType(MarkdownWidget));
      await tester.tapAt(topLeft + const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(tapped, ['https://example.com']);
    });

    testWidgets('updating markdown relayouts', (tester) async {
      await _pumpMarkdown(tester, 'short');
      final firstHeight = _mdSize(tester).height;
      await _pumpMarkdown(tester, 'line one\n\nline two\n\nline three');
      expect(tester.takeException(), isNull);
      expect(_mdSize(tester).height, greaterThan(firstHeight));
    });

    testWidgets('custom link style is applied via theme', (tester) async {
      await _pumpMarkdown(
        tester,
        '[styled](https://example.com)',
        theme: MarkdownThemeData(
          textStyle: const TextStyle(fontSize: 14),
          linkStyle: const TextStyle(
              color: Colors.red, decoration: TextDecoration.underline),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_mdSize(tester).height, greaterThan(0));
    });
  });
}
