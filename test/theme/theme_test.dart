import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => group('MarkdownThemeData', () {
      MarkdownThemeData base() =>
          MarkdownThemeData(textStyle: const TextStyle(fontSize: 14));

      group('Alert colors', () {
        test('defaults to the GitHub palette', () {
          final theme = base();
          expect(
              theme.alertColorFor(MD$AlertType.note), const Color(0xFF0969DA));
          expect(theme.alertColorFor(MD$AlertType.warning),
              const Color(0xFF9A6700));
          expect(theme.alertColorFor(MD$AlertType.caution),
              const Color(0xFFCF222E));
        });

        test('respects overrides while keeping defaults for the rest', () {
          final theme = MarkdownThemeData(
            textStyle: const TextStyle(fontSize: 14),
            alertColors: const <MD$AlertType, Color>{
              MD$AlertType.note: Color(0xFF123456),
            },
          );
          expect(
              theme.alertColorFor(MD$AlertType.note), const Color(0xFF123456));
          // Unspecified types still use the default palette.
          expect(
              theme.alertColorFor(MD$AlertType.tip), const Color(0xFF1A7F37));
        });
      });

      group('linkStyle', () {
        test('is merged into link spans', () {
          final theme = MarkdownThemeData(
            textStyle: const TextStyle(fontSize: 14),
            linkColor: Colors.blue,
            linkStyle: const TextStyle(
              color: Colors.red,
              decoration: TextDecoration.underline,
            ),
          );
          final linkStyle = theme.textStyleFor(MD$Style.link);
          expect(linkStyle.color, Colors.red); // linkStyle overrides linkColor
          expect(linkStyle.decoration, TextDecoration.underline);
        });

        test('non-link styles are unaffected by linkStyle', () {
          final theme = MarkdownThemeData(
            textStyle: const TextStyle(fontSize: 14),
            linkStyle: const TextStyle(color: Colors.red),
          );
          expect(theme.textStyleFor(MD$Style.bold).color, isNot(Colors.red));
        });
      });

      group('copyWith', () {
        test('preserves builder and onLinkTap (regression)', () {
          var called = false;
          final theme = MarkdownThemeData(
            textStyle: const TextStyle(fontSize: 14),
            onLinkTap: (_, __) => called = true,
          );
          final copy = theme.copyWith();
          expect(copy.onLinkTap, isNotNull);
          copy.onLinkTap!('t', 'u');
          expect(called, isTrue);
        });

        test('overrides provided fields', () {
          final copy = base().copyWith(
            linkColor: Colors.green,
            linkStyle: const TextStyle(fontStyle: FontStyle.italic),
          );
          expect(copy.linkColor, Colors.green);
          expect(copy.linkStyle?.fontStyle, FontStyle.italic);
        });
      });

      group('lerp', () {
        test('identical returns the same instance', () {
          final theme = base();
          expect(identical(theme.lerp(theme, 0.5), theme), isTrue);
        });

        test('interpolates the text style', () {
          final a = MarkdownThemeData(textStyle: const TextStyle(fontSize: 10));
          final b = MarkdownThemeData(textStyle: const TextStyle(fontSize: 20));
          final mid = a.lerp(b, 0.5) as MarkdownThemeData;
          expect(mid.textStyle.fontSize, 15);
        });
      });

      testWidgets('mergeTheme derives from ThemeData', (tester) async {
        late MarkdownThemeData derived;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                derived = MarkdownThemeData.mergeTheme(
                  Theme.of(context),
                  linkStyle: const TextStyle(color: Colors.purple),
                );
                return const SizedBox();
              },
            ),
          ),
        );
        expect(derived.linkStyle?.color, Colors.purple);
        expect(
            derived.alertColorFor(MD$AlertType.note), const Color(0xFF0969DA));
      });

      group('headingStyleFor', () {
        test('derives a distinct style for each level 1-6', () {
          final theme = base();
          final sizes = <double?>[
            for (var level = 1; level <= 6; level++)
              theme.headingStyleFor(level).fontSize,
          ];
          // Every level resolves to a size and they decrease h1 > ... > h6.
          expect(sizes.every((s) => s != null), isTrue);
          for (var i = 1; i < sizes.length; i++) {
            expect(sizes[i]!, lessThan(sizes[i - 1]!));
          }
          for (var level = 1; level <= 6; level++) {
            expect(theme.headingStyleFor(level).fontWeight, FontWeight.bold);
          }
        });

        test('levels outside 1-6 fall back to the base text style', () {
          final theme = base();
          expect(theme.headingStyleFor(7).fontSize, theme.textStyle.fontSize);
        });

        test('caches the resolved style', () {
          final theme = base();
          expect(
            identical(theme.headingStyleFor(2), theme.headingStyleFor(2)),
            isTrue,
          );
        });

        test('honors explicit per-level overrides', () {
          final theme = MarkdownThemeData(
            textStyle: const TextStyle(fontSize: 14),
            h2Style: const TextStyle(fontSize: 99),
          );
          expect(theme.headingStyleFor(2).fontSize, 99);
        });
      });

      group('type and toString', () {
        test('type is the data class', () {
          expect(base().type, MarkdownThemeData);
        });

        test('toString is stable', () {
          expect(base().toString(), 'MarkdownThemeData{}');
        });
      });

      group('MarkdownTheme inherited widget', () {
        testWidgets('of / maybeOf find the nearest data', (tester) async {
          final data = MarkdownThemeData(textStyle: const TextStyle());
          late MarkdownThemeData viaOf;
          late MarkdownThemeData viaOfNoListen;
          late MarkdownThemeData? viaMaybe;
          await tester.pumpWidget(MarkdownTheme(
            data: data,
            child: Builder(builder: (context) {
              viaOf = MarkdownTheme.of(context);
              viaOfNoListen = MarkdownTheme.of(context, listen: false);
              viaMaybe = MarkdownTheme.maybeOf(context, listen: false);
              return const SizedBox();
            }),
          ));
          expect(identical(viaOf, data), isTrue);
          expect(identical(viaOfNoListen, data), isTrue);
          expect(identical(viaMaybe, data), isTrue);
        });

        testWidgets('maybeOf returns null without an ancestor', (tester) async {
          MarkdownThemeData? maybe = base();
          await tester.pumpWidget(Builder(builder: (context) {
            maybe = MarkdownTheme.maybeOf(context);
            return const SizedBox();
          }));
          expect(maybe, isNull);
        });

        testWidgets('of throws without an ancestor', (tester) async {
          await tester.pumpWidget(Builder(builder: (context) {
            expect(() => MarkdownTheme.of(context), throwsArgumentError);
            return const SizedBox();
          }));
        });

        test('updateShouldNotify compares data identity', () {
          final a = MarkdownTheme(data: base(), child: const SizedBox());
          final same = MarkdownTheme(data: a.data, child: const SizedBox());
          final different =
              MarkdownTheme(data: base(), child: const SizedBox());
          expect(a.updateShouldNotify(same), isFalse);
          expect(a.updateShouldNotify(different), isTrue);
        });
      });
    });
