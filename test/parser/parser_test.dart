import 'package:flutter_test/flutter_test.dart';
import 'package:md/md.dart';

void main() => group('Parse', () {
      test('Should returns normally', () {
        expect(
          () => mdDecoder.convert(_testSample),
          returnsNormally,
        );
        expect(
          mdDecoder.convert(_testSample),
          allOf(
            isList,
            isNotEmpty,
            hasLength(greaterThan(0)),
            everyElement(isA<MD$Block>()),
          ),
        );
      });

      test('Empty input', () {
        expect(mdDecoder.convert(''), isEmpty);
      });

      test('Divider', () {
        expect(
          mdDecoder.convert('---\n---'),
          allOf(
            isNotEmpty,
            hasLength(equals(2)),
            everyElement(isA<MD$Divider>()),
          ),
        );
      });

      test('Space', () {
        expect(
          mdDecoder.convert(' '),
          allOf(
            isNotEmpty,
            hasLength(equals(1)),
            everyElement(isA<MD$Spacer>().having(
              (s) => s.count,
              'count',
              equals(1),
            )),
          ),
        );
      });

      test('Spacer', () {
        expect(
          mdDecoder.convert('\n\n\n'),
          allOf(
            isNotEmpty,
            hasLength(equals(1)),
            everyElement(isA<MD$Spacer>().having(
              (s) => s.count,
              'count',
              equals(3),
            )),
          ),
        );
      });

      test('Parse unordered lists', () {
        // TODO(plugfox): Fix this test
        // Mike Matiunin <plugfox@gmail.com>, 12 June 2025
        const sample = '- First item\n'
            '- Second item with *italic*\n'
            '  - Subitem with **bold**\n'
            '    - Third level ~~strikethrough~~\n'
            '- Fourth item';

        final blocks = mdDecoder.convert(sample);
        expect(
            blocks,
            allOf(
              isNotEmpty,
              hasLength(equals(1)),
              everyElement(isA<MD$Block>()),
            ));
        expect(
          blocks.single,
          isA<MD$List>().having(
            (list) => list.items.length,
            'items length',
            equals(3),
          ),
        );
      });

      test('Parse ordered lists', () {
        // TODO(plugfox): Fix this test
        // Mike Matiunin <plugfox@gmail.com>, 12 June 2025
        const sample = '1. First step\n'
            '2. Second step\n'
            '   1. Substep 2.1\n'
            '   2. Substep 2.2\n'
            '3. Final step';

        final blocks = mdDecoder.convert(sample);
        expect(
            blocks,
            allOf(
              isNotEmpty,
              hasLength(equals(1)),
              everyElement(isA<MD$Block>()),
            ));
        expect(
          blocks.single,
          isA<MD$List>().having(
            (list) => list.items.length,
            'items length',
            equals(3),
          ),
        );
      });
    });

const String _testSample = r'''
# Markdown Parser Test

This is a **bold** paragraph with _italic_, __underline__, ~~strikethrough~~, `monospace`, and a [link](https://example.com).

This is a highlighted ==text== in a single line.

---

## Multi-line Paragraph

Lorem ipsum dolor sit amet,
consectetur adipiscing elit.
Sed do eiusmod **tempor** incididunt
_ut labore_ et dolore `magna aliqua`.

---

### Blockquote

> This is a simple blockquote.
>
> It can have **multiple lines**,
> and even nested formatting like `code` or [links](https://example.com).
>
> > Nested blockquote level 2.

---

### Code Blocks

Here is a fenced code block:

```javascript
function helloWorld() {
  console.log("Hello, world!");
}
```

Inline code also works like this: `let x = 42;`

---

### Lists

#### Unordered

- First item
- Second item with *italic*
  - Subitem with **bold**
    - Third level ~~strikethrough~~
- Fourth item

#### Ordered

1. First step
2. Second step
   1. Substep 2.1
   2. Substep 2.2
3. Final step

---

### Horizontal Rule

---

### Table

| Name     | Age | Role         |
|----------|-----|--------------|
| Alice    | 25  | Developer    |
| **Bob**  | 30  | _Designer_   |
| Charlie  | 35  | ~~Manager~~  |

---

### Empty Lines Below



These lines above are intentionally empty.

---

### Images

![Alt text](https://example.com/image.png)
`![Code style alt](https://example.com/image2.png)`

You can also use **bold image captions**.

---

That’s all for the _test_ document.
''';
