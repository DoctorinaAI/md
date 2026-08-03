import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => group('Parse', () {
      test('Should returns normally', () {
        expect(
          () => markdownDecoder.convert(_testSample).blocks,
          returnsNormally,
        );
        expect(
          markdownDecoder.convert(_testSample),
          isA<Markdown>()
              .having(
                (md) => md.blocks,
                'blocks',
                allOf(
                  isList,
                  isNotEmpty,
                  hasLength(greaterThan(0)),
                  everyElement(isA<MD$Block>()),
                ),
              )
              .having(
                (md) => md.text,
                'text',
                allOf(
                  isA<String>(),
                  isNotEmpty,
                  contains('Markdown Parser Test'),
                ),
              ),
        );
      });

      test('Should returns normally for cyrillic', () {
        expect(
          () => markdownDecoder.convert(_testCyrillicSample).blocks,
          returnsNormally,
        );
        expect(
          markdownDecoder.convert(_testCyrillicSample),
          isA<Markdown>()
              .having(
                (md) => md.blocks,
                'blocks',
                allOf(
                  isList,
                  isNotEmpty,
                  hasLength(greaterThan(0)),
                  everyElement(isA<MD$Block>()),
                ),
              )
              .having(
                (md) => md.text,
                'text',
                allOf(
                  isA<String>(),
                  isNotEmpty,
                  contains('Тест Markdown-парсера'),
                ),
              ),
        );
      });

      test('Should contain three blocks', () {
        const text = '# Header\n'
            '---\n'
            'This is a paragraph with **bold** text.\n'
            'And another line.\n';
        final markdown = markdownDecoder.convert(text);
        markdown.text; // Force text computation
        expect(
          markdown.blocks,
          allOf(
            isNotEmpty,
            hasLength(equals(3)),
            everyElement(isA<MD$Block>()),
          ),
        );
      });

      test('Quote', () {
        const text = '> A\n'
            '> B\n'
            '> C';
        final markdown = markdownDecoder.convert(text);
        markdown.text; // Force text computation
        expect(
          markdown.blocks,
          allOf(
            isNotEmpty,
            hasLength(equals(1)),
            everyElement(isA<MD$Quote>()),
          ),
        );
        expect(
          markdown.markdown,
          allOf(
            isA<String>(),
            isNotEmpty,
            contains('A'),
            contains('B'),
            contains('C'),
            equals('> A\n> B\n> C'),
          ),
        );
        expect(
          markdown.text,
          allOf(
            isA<String>(),
            isNotEmpty,
            contains('A'),
            contains('B'),
            contains('C'),
            equals('A\nB\nC'),
          ),
        );
      });

      test('Urls', () {
        var markdown = markdownDecoder.convert('[text](url)');
        expect(
          markdown.text,
          allOf(
            isNotEmpty,
            equals('text'),
          ),
        );
        expect(
          markdown.blocks,
          allOf(
            isNotEmpty,
            hasLength(equals(1)),
            everyElement(isA<MD$Paragraph>()),
          ),
        );
        expect(
          markdown.blocks.single,
          isA<MD$Paragraph>().having(
            (p) => p.spans,
            'spans',
            allOf(
              isNotEmpty,
              hasLength(equals(1)),
              everyElement(isA<MD$Span>()
                  .having((s) => s.style, 'style', equals(MD$Style.link))
                  .having((s) => s.extra, 'extra', containsPair('url', 'url'))),
            ),
          ),
        );

        // Should be with url: `url()`
        markdown = markdownDecoder.convert('[text](url(with)brackets)');
        expect(
          markdown.text,
          allOf(
            isNotEmpty,
            equals('text'),
          ),
        );
        expect(
          markdown.blocks,
          allOf(
            isNotEmpty,
            hasLength(equals(1)),
            everyElement(isA<MD$Paragraph>()),
          ),
        );
        expect(
          markdown.blocks.single,
          isA<MD$Paragraph>().having(
            (p) => p.spans,
            'spans',
            allOf(
              isNotEmpty,
              hasLength(equals(1)),
              everyElement(isA<MD$Span>()
                  .having((s) => s.style, 'style', equals(MD$Style.link))
                  .having((s) => s.extra, 'extra',
                      containsPair('url', 'url(with)brackets'))),
            ),
          ),
        );
      });

      test('Empty input', () {
        expect(markdownDecoder.convert('').blocks, isEmpty);
      });

      test('Paragraph+Space+Paragraph', () {
        const text = 'a\n\na';
        final markdown = markdownDecoder.convert(text);
        expect(
          markdown.blocks,
          allOf(
            isNotEmpty,
            hasLength(equals(3)),
            everyElement(isA<MD$Block>()),
          ),
        );
      });

      test('Divider', () {
        expect(
          markdownDecoder.convert('---\n---').blocks,
          allOf(
            isNotEmpty,
            hasLength(equals(2)),
            everyElement(isA<MD$Divider>()),
          ),
        );
      });

      test('Space', () {
        expect(
          markdownDecoder.convert(' ').blocks,
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
          markdownDecoder.convert('\n\n\n').blocks,
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

        final markdown = markdownDecoder.convert(sample);
        expect(
            markdown.blocks,
            allOf(
              isNotEmpty,
              hasLength(equals(1)),
              everyElement(isA<MD$Block>()),
            ));
        expect(
          markdown.blocks.single,
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

        final markdown = markdownDecoder.convert(sample);
        expect(
            markdown.blocks,
            allOf(
              isNotEmpty,
              hasLength(equals(1)),
              everyElement(isA<MD$Block>()),
            ));
        expect(
          markdown.blocks.single,
          isA<MD$List>().having(
            (list) => list.items.length,
            'items length',
            equals(3),
          ),
        );
      });

      test('Parse links', () {
        expect(
          markdownDecoder.convert('[link](https://example.com/path)').blocks,
          allOf(
            isNotEmpty,
            hasLength(equals(1)),
            everyElement(
              isA<MD$Paragraph>().having(
                (s) => s.spans,
                'spans',
                allOf(
                  isNotEmpty,
                  hasLength(equals(1)),
                  everyElement(
                    isA<MD$Span>()
                        .having(
                          (l) => l.style,
                          'style',
                          equals(MD$Style.link),
                        )
                        .having(
                          (l) => l.extra,
                          'extra',
                          allOf(
                            isA<Map<String, Object?>>(),
                            isNotEmpty,
                            containsPair('url', 'https://example.com/path'),
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
        );
      });

      test('Parse images', () {
        expect(
          markdownDecoder.convert('![](https://example.com/image.jpg)').blocks,
          allOf(
            isNotEmpty,
            hasLength(equals(1)),
            everyElement(
              isA<MD$Paragraph>().having(
                (s) => s.spans,
                'spans',
                allOf(
                  isNotEmpty,
                  hasLength(equals(1)),
                  everyElement(
                    isA<MD$Span>()
                        .having(
                          (l) => l.style,
                          'style',
                          equals(MD$Style.image),
                        )
                        .having(
                          (l) => l.extra,
                          'extra',
                          allOf(
                            isA<Map<String, Object?>>(),
                            isNotEmpty,
                            containsPair(
                                'url', 'https://example.com/image.jpg'),
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
        );
      });

      test('Inline code should treat inline code as literal', () {
        // A map of markdown syntax to its expected literal representation
        // inside a code block.
        const List<String> syntaxes = [
          '*italic*',
          '_italic_',
          '**bold**',
          '__underline__',
          '~~strike~~',
          '==highlight==',
          '||spoiler||',
          r'\* \_ \`',
          '!alt',
          '* Item 1',
          '# Header',
          '---',
          '1. Item **1**',
          '[Markdown Live Preview](https://markdownlivepreview.com/)',
          'package:flutter_md/flutter_md.dart'
        ];

        final text = syntaxes.map((syntax) => '`$syntax`').join();
        final markdown = markdownDecoder.convert(text);

        expect(markdown.blocks,
            allOf(isNotEmpty, hasLength(1), everyElement(isA<MD$Paragraph>())));

        final paragraph = markdown.blocks.first as MD$Paragraph;
        final spans = paragraph.spans;

        for (var i = 0; i < syntaxes.length; i++) {
          final expectedText = syntaxes.elementAt(i);

          final codeSpan = spans[i];
          expect(codeSpan.text, expectedText);
          expect(codeSpan.style, MD$Style.monospace,
              reason:
                  'Span for "$expectedText" should only have monospace style');
        }
      });

      group('Parse escaped characters', () {
        const escapedCharacterTests = {
          r'\\': r'\', // Backslash
          r'\`': '`', // Backtick
          r'\*': '*', // Asterisk
          r'\_': '_', // Underscore
          r'\{': '{', // Left curly brace
          r'\}': '}', // Right curly brace
          r'\[': '[', // Left square bracket
          r'\]': ']', // Right square bracket
          r'\(': '(', // Left parenthesis
          r'\)': ')', // Right parenthesis
          r'\#': '#', // Hash mark
          r'\+': '+', // Plus sign
          r'\-': '-', // Minus sign (hyphen)
          r'\.': '.', // Period
          r'\!': '!', // Exclamation mark
        };

        for (final entry in escapedCharacterTests.entries) {
          test('should correctly unescape "${entry.key}"', () {
            final markdown = markdownDecoder.convert(entry.key);
            expect(markdown.text, entry.value);
          });
        }

        test('should not escape non-special characters', () {
          const input = r'\no esc\aped strin\g';
          final markdown = markdownDecoder.convert(input);
          expect(markdown.text, input);
        });
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

const String _testCyrillicSample = r'''
# Тест Markdown-парсера

Это **жирный** абзац с *курсивом*, **подчёркнутым**, ~~зачёркнутым~~, `моноширинным` и [ссылкой](https://example.com).

Это выделенный ==текст== в одной строке.

---

## Многострочный абзац

Lorem ipsum dolor sit amet,
consectetur adipiscing elit.
Sed do eiusmod **tempor** incididunt
*ut labore* et dolore `magna aliqua`.

---

### Цитата

> Это простая цитата.
>
> Она может содержать **несколько строк**,
> и даже вложенное форматирование, как `код` или [ссылки](https://example.com).
>
---

### Блоки кода

Вот пример ограждённого блока кода:

```javascript
function helloWorld() {
  console.log("Hello, world!");
}
```

Встроенный код тоже работает вот так: `let x = 42;`

---

### Списки

#### Неупорядоченный

* Первый элемент
* Второй элемент с *курсивом*
  * Подэлемент с **жирным**
    * Третий уровень ~~зачёркнутый~~
* Четвёртый элемент

#### Упорядоченный

1. Первый шаг
2. Второй шаг
   1. Подшаг 2.1
   2. Подшаг 2.2
3. Финальный шаг

---

### Горизонтальная линия

---

### Таблица

| Имя     | Возраст | Роль         |
| ------- | ------- | ------------ |
| Alice   | 25      | Разработчик  |
| **Bob** | 30      | *Дизайнер*   |
| Charlie | 35      | ~~Менеджер~~ |

---

### Пустые строки ниже

Эти строки выше оставлены намеренно пустыми.

---

### Изображения

![Alt text](https://example.com/image.png)
`![Code style alt](https://example.com/image2.png)`

Можно также использовать **жирные подписи к изображениям**.

---

На этом всё для *тестового* документа.
''';
