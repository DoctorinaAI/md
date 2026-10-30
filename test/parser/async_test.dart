import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/src/yield_to_ui.dart' as plain;
import 'package:flutter_md/src/yield_to_ui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// A block's type and text, nested blocks included.
String _sig(List<MD$Block> blocks) => blocks.map((block) {
      final nested = switch (block) {
        MD$Quote(:final blocks) || MD$Alert(:final blocks) => _sig(blocks),
        _ => '',
      };
      final spans = switch (block) {
        MD$Paragraph(:final spans) ||
        MD$Heading(:final spans) ||
        MD$Quote(:final spans) ||
        MD$Alert(:final spans) =>
          spans.map((s) => '${s.start}-${s.end}:${s.style}').join(','),
        _ => '',
      };
      return '${block.type}|${block.text}|$spans|$nested';
    }).join('\n');

const String _mixed = '''
# Heading *one*

A paragraph that goes
over **two** lines.

- item
  - nested
- [x] task

1. ordered

| a | b |
|---|---|
| 1 | 2 |

| not a table |
|---|---|
| 1 | 2 |

```dart
final code = 1;

// A blank line above.
```

> A quote
> ```
> fenced
> ```

> [!NOTE]
> An alert

---

~~~
unclosed''';

void main() => group('Markdown.fromStringAsync', () {
      const documents = <String, String>{
        'empty': '',
        'blank': '\n\n\n',
        'one line': 'text',
        'no final newline': 'a\n\nb',
        'crlf': 'a\r\nb\r\n\r\n# c\r\n',
        'mixed': _mixed,
      };

      for (final MapEntry(key: name, value: source) in documents.entries) {
        for (final budget in const <Duration>[
          Duration.zero, // Pauses at every chance, so resumes from each line.
          Duration(microseconds: 50),
          Duration(days: 1), // Never pauses.
        ]) {
          test('$name equals the sync parse, budget $budget', () async {
            final expected = Markdown.fromString(source);
            final actual =
                await Markdown.fromStringAsync(source, budget: budget);
            expect(actual.markdown, expected.markdown);
            expect(_sig(actual.blocks), _sig(expected.blocks));
          });
        }
      }

      test('empty input gives the empty document', () async {
        expect(
          await Markdown.fromStringAsync(''),
          same(const Markdown.empty()),
        );
      });

      test('blocks cannot be changed', () async {
        final markdown = await Markdown.fromStringAsync('a');
        expect(() => markdown.blocks.clear(), throwsUnsupportedError);
      });

      test('passes on inlineMath', () async {
        const source = r'$\alpha$';
        expect(
          (await Markdown.fromStringAsync(source, inlineMath: true)).text,
          Markdown.fromString(source, inlineMath: true).text,
        );
        expect(
          (await Markdown.fromStringAsync(source)).text,
          Markdown.fromString(source).text,
        );
      });

      test('convertAsync uses mathReplacements', () async {
        const decoder = MarkdownDecoder(
          inlineMath: true,
          mathReplacements: <String, String>{r'\R': 'ℝ'},
        );
        expect((await decoder.convertAsync(r'$\R$')).text, contains('ℝ'));
      });

      test('other work runs between the slices of a long document', () async {
        var turns = 0;
        final timer = Timer.periodic(Duration.zero, (_) => turns++);
        addTearDown(timer.cancel);
        final source = List<String>.filled(2000, _mixed).join('\n\n');
        final markdown = await Markdown.fromStringAsync(
          source,
          budget: const Duration(microseconds: 200),
        );
        expect(markdown.blocks, isNotEmpty);
        expect(turns, greaterThan(0));
      });

      group('yieldToUi', () {
        test('without Flutter gives the event loop a turn', () async {
          var turned = false;
          Timer.run(() => turned = true);
          await plain.yieldToUi();
          expect(turned, isTrue);
        });

        testWidgets('waits for a frame that is on its way', (tester) async {
          SchedulerBinding.instance.scheduleFrame();
          var done = false;
          unawaited(yieldToUi().then((_) => done = true));
          await tester.pump(Duration.zero, EnginePhase.build);
          await tester.idle();
          expect(done, isTrue);
        });

        testWidgets('asks for no frame when none is needed', (tester) async {
          await tester.pumpAndSettle();
          expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
          var done = false;
          unawaited(yieldToUi().then((_) => done = true));
          expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
          // A turn of the event loop is enough: no frame is pumped.
          await tester.binding.delayed(Duration.zero);
          await tester.idle();
          expect(done, isTrue);
        });

        testWidgets('gives up on a frame that never comes', (tester) async {
          SchedulerBinding.instance.scheduleFrame();
          var done = false;
          unawaited(yieldToUi().then((_) => done = true));
          // Only time passes here; the test binding pumps no frame on its own.
          await tester.binding.delayed(const Duration(milliseconds: 50));
          await tester.idle();
          expect(done, isFalse);
          await tester.binding.delayed(const Duration(milliseconds: 100));
          await tester.idle();
          expect(done, isTrue);
          await tester.pump();
        });
      });
    });
