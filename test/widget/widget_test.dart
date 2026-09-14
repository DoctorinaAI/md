// Widget tests for `MarkdownWidget` that exercise the theme fallback used when
// neither an explicit `theme` nor a `MarkdownTheme` ancestor is provided — the
// branch that builds a default `MarkdownThemeData` from the build context in
// both `createRenderObject` and `updateRenderObject`.
import 'package:flutter/material.dart';
import 'package:flutter/src/services/mouse_cursor.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarkdownWidget without an explicit theme', () {
    // No MarkdownTheme ancestor and no `theme:` argument, so the widget must
    // derive a default theme from the surrounding context.
    Widget wrap(Markdown markdown) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: MarkdownWidget(markdown: markdown),
              ),
            ),
          ),
        );

    double heightOf(WidgetTester tester) =>
        tester.renderObject<RenderBox>(find.byType(MarkdownWidget)).size.height;

    testWidgets('builds a default theme from context', (tester) async {
      await tester.pumpWidget(
        wrap(Markdown.fromString('# Title\n\nBody with **bold** text.')),
      );
      expect(tester.takeException(), isNull);
      expect(heightOf(tester), greaterThan(0));
    });

    testWidgets('rebuilds with a default theme on update', (tester) async {
      await tester.pumpWidget(wrap(Markdown.fromString('first')));
      final first = heightOf(tester);
      await tester.pumpWidget(
        wrap(Markdown.fromString('second\n\nwith another paragraph here')),
      );
      expect(tester.takeException(), isNull);
      expect(heightOf(tester), greaterThan(0));
      // The taller document should not be smaller than the single line.
      expect(heightOf(tester), greaterThanOrEqualTo(first));
    });

    testWidgets('honors an explicitly passed theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: MarkdownWidget(
                markdown: Markdown.fromString('# Heading'),
                theme: MarkdownThemeData(
                  textStyle: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(heightOf(tester), greaterThan(0));
    });

    testWidgets('MarkdownWidget honors cursorResolver', (tester) async {
      SystemMouseCursor resolver(Offset offset, int? idx, MD$Block? block) =>
          SystemMouseCursors.click;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: MarkdownWidget(
                markdown: Markdown.fromString('Hello'),
                cursorResolver: resolver,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
