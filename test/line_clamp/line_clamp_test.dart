import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => group('clampMarkdownToLines', () {
      // Height 2.0 keeps every line exactly 20px tall, so expectations read as
      // line counts.
      final theme = MarkdownThemeData(
        textStyle: const TextStyle(fontSize: 10, height: 2),
      );

      MarkdownLineClamp clamp(String source, int maxLines,
              {double width = 300}) =>
          clampMarkdownToLines(
            markdown: Markdown.fromString(source),
            theme: theme,
            maxWidth: width,
            maxLines: maxLines,
          );

      test('content within the budget is not clamped', () {
        final result = clamp('one\n\ntwo', 6);

        expect(result.overflows, isFalse);
        expect(result.clampedHeight, result.height);
      });

      test('cuts on the boundary of the last allowed line', () {
        final result = clamp('one\ntwo\nthree\nfour', 2);

        expect(result.overflows, isTrue);
        expect(result.clampedHeight, 40);
        expect(result.height, 80);
      });

      test('counts wrapped lines of a single paragraph', () {
        // 10px glyphs at width 100 wrap roughly every 10 characters.
        final result = clamp('word ' * 40, 3, width: 100);

        expect(result.overflows, isTrue);
        expect(result.clampedHeight, 60);
      });

      test('counts list items as lines', () {
        final result = clamp('- one\n- two\n- three', 2);

        expect(result.overflows, isTrue);
        expect(result.clampedHeight, 40);
      });

      test('blank lines add height without spending the budget', () {
        final withBlank = clamp('one\n\ntwo\nthree', 2);
        final withoutBlank = clamp('one\ntwo\nthree', 2);

        expect(withBlank.overflows, isTrue);
        // Two text lines plus the blank line between them.
        expect(
            withBlank.clampedHeight, greaterThan(withoutBlank.clampedHeight));
      });

      test('dividers add height without spending the budget', () {
        final withDivider = clamp('one\n\n---\n\ntwo\nthree', 2);
        final withoutDivider = clamp('one\ntwo\nthree', 2);

        expect(withDivider.overflows, isTrue);
        expect(withDivider.clampedHeight,
            greaterThan(withoutDivider.clampedHeight));
      });

      test('a clamp of zero lines keeps nothing', () {
        expect(clamp('one\ntwo', 0).clampedHeight, 0);
      });

      test('empty markdown has no height', () {
        final result = clamp('', 6);

        expect(result.height, 0);
        expect(result.overflows, isFalse);
      });

      test('a negative budget keeps nothing', () {
        final result = clamp('one\ntwo', -5);

        expect(result.clampedHeight, 0);
        expect(result.overflows, isTrue);
      });

      test('table rows count as one line each', () {
        const source = '| a | b |\n|---|---|\n| 1 | 2 |\n| 3 | 4 |';
        final all = clamp(source, 100);
        final two = clamp(source, 2);

        expect(all.overflows, isFalse);
        expect(two.overflows, isTrue);
        expect(two.clampedHeight, greaterThan(0));
        expect(two.clampedHeight, lessThan(all.height));
      });

      test('a quote with a nested fence counts its child lines', () {
        const source = '> intro\n> ```\n> one\n> two\n> ```\n> outro';
        final all = clamp(source, 100);
        final two = clamp(source, 2);

        expect(all.height, greaterThan(0));
        expect(two.clampedHeight, greaterThan(0));
        expect(two.clampedHeight, lessThan(all.height));
      });

      test('a zero measuring width does not throw', () {
        final result = clamp('hello world', 2, width: 0);

        expect(result.height, greaterThanOrEqualTo(0));
        expect(result.clampedHeight, greaterThanOrEqualTo(0));
      });
    });
