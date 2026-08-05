/// Shared benchmark corpus used by both the parser benchmark
/// (`benchmark/parser_benchmark.dart`) and the render benchmark
/// (`test/render_benchmark_test.dart`).
///
/// The documents deliberately stick to **common-denominator GFM** (headings,
/// emphasis, inline code, links, blockquotes, fenced code, ordered/unordered/
/// task lists, tables) so that all three libraries — flutter_md,
/// flutter_markdown and gpt_markdown — render them without diverging on
/// dialect-specific extensions. Images are intentionally omitted so the render
/// numbers measure text layout, not network image stubs.
library;

/// The benchmark documents, keyed by a short name and ordered from the smallest
/// / simplest to the largest / most complex.
final Map<String, String> corpus = <String, String>{
  'simple': _simple,
  'inline': _inline,
  'lists': _lists,
  'table': _table,
  'code': _code,
  'quotes': _quotes,
  'complex': _complex,
  // A large document: the kitchen-sink `complex` doc repeated so per-op timings
  // are stable and the O(n) cost of each library is visible.
  'complex_large': _repeat(_complex, 8),
};

/// The subset used for the render benchmark. Rendering a very large document
/// through three widget trees is slow, so we cap the large tier at a smaller
/// repeat count than the parser benchmark uses.
final Map<String, String> renderCorpus = <String, String>{
  'simple': _simple,
  'inline': _inline,
  'lists': _lists,
  'table': _table,
  'code': _code,
  'quotes': _quotes,
  'complex': _complex,
  'complex_large': _repeat(_complex, 4),
};

String _repeat(String block, int times) {
  final buffer = StringBuffer();
  for (var i = 0; i < times; i++) {
    buffer
      ..write(block)
      ..write('\n\n');
  }
  return buffer.toString();
}

/// Simple rich text: a couple of paragraphs with inline emphasis, code and a
/// link — the "chat bubble" case.
const String _simple = '''
Hello **world**, this is a *simple* rich-text paragraph with some `inline code`
and [a link](https://example.com) mixed into ordinary prose to exercise the
common inline formatting path.

A second paragraph follows with a bit more **bold**, some _italic_ and a final
~~struck-through~~ span so the inline parser has a little of everything.
''';

/// Emphasis-heavy inline stress: many markers on every line.
const String _inline = '''
This line has **bold**, *italic*, ***bold italic***, `code`, ~~strike~~ and a
[link](https://example.com) all packed together to stress the inline scanner.

Nested **bold with *italic* and `code` inside** it, then *italic with **bold**
inside* and a trailing `code span` — repeated markers keep the closer lookahead
busy across the whole paragraph without producing much block structure.
''';

/// Nested and task lists.
const String _lists = '''
- First item with **bold**
- Second item with [a link](https://example.com)
  - Nested item one
  - Nested item two with `code`
    - Deep item with *italic*
- Back to the top level

1. Ordered one
2. Ordered two
   1. Sub one
   2. Sub two
3. Ordered three

- [x] Completed task
- [ ] Pending task
- [ ] Another pending task with **emphasis**
''';

/// GFM tables with alignment and inline formatting inside cells.
const String _table = '''
| Name    | Age | Role       | Notes            |
| :------ | --: | :--------: | ---------------- |
| Alice   |  25 | Developer  | Likes **bold**   |
| Bob     |  30 | Designer   | Uses `tools`     |
| Charlie |  35 | Manager    | ~~former~~ lead  |

| Metric      | Q1   | Q2   | Q3   | Q4   |
| ----------- | ---- | ---- | ---- | ---- |
| Revenue     | 100  | 120  | 140  | 180  |
| Growth      | 10%  | 20%  | 17%  | 29%  |
| Active users| 1.2k | 1.5k | 1.9k | 2.4k |
''';

/// Fenced code blocks in a couple of languages.
const String _code = '''
```dart
void main() {
  final greeting = 'Hello, world!';
  for (var i = 0; i < 10; i++) {
    print(greeting);
  }
}
```

Some prose between two code blocks to break them apart cleanly.

```python
def fib(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a
```
''';

/// Blockquotes, including nested formatting.
const String _quotes = '''
> This is a blockquote that spans several lines and contains **bold** text,
> some `inline code` and [a link](https://example.com) inside the body.

> A second quote paragraph.
>
> It has multiple paragraphs and even a bit of *emphasis* to keep the inline
> parser working while inside a block-level quote context.
''';

/// The kitchen-sink document: every common block type, in one place. Used both
/// on its own (`complex`) and repeated to form the large tier.
const String _complex = '''
# Markdown rendering benchmark

This is a **bold** paragraph with *italic*, `monospace`, ~~strike~~ and
[a link](https://example.com) mixed into a normal sentence.

## Multiline paragraph

Lorem ipsum dolor sit amet,
consectetur adipiscing elit.
Sed do eiusmod **tempor** incididunt
*ut labore* et dolore `magna aliqua`.

### Quote

> This is a simple quote.
>
> It may contain **several lines**, and even nested formatting like `code`
> or [links](https://example.com).

### Code

```javascript
function helloWorld() {
  console.log("Hello, world!");
}
```

Inline code works like this: `let x = 42;`

### Lists

- First item
- Second item with *italic*
  - Subitem with **bold**
    - Third level ~~strike~~
- [x] Done task
- [ ] Pending task

1. First step
2. Second step
   1. Substep 2.1
   2. Substep 2.2
3. Final step

### Table

| Name    | Age | Role       |
| :------ | --: | :--------: |
| Alice   |  25 | Developer  |
| Bob     |  30 | Designer   |
| Charlie |  35 | Manager    |

That is all for the *test* document.
''';
