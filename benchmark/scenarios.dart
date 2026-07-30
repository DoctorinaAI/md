/// Shared benchmark corpus used by `parser_benchmark.dart` (benchmark_harness)
/// and `compare.dart` (fast min-of-batches comparison tool).
library;

/// The benchmark scenarios, keyed by a short name. Each value is a few KB of
/// Markdown so that per-op timings are stable and throughput is meaningful.
final Map<String, String> scenarios = <String, String>{
  'prose': _repeat(_prose, 8),
  'inline': _repeat(_inline, 8),
  'links': _repeat(_links, 8),
  'lists': _repeat(_lists, 6),
  'table': _repeat(_table, 6),
  'code': _repeat(_code, 6),
  'quotes': _repeat(_quotes, 8),
  'escapes': _repeat(_escapes, 10),
  'currency': _repeat(_currency, 10),
  'pathological': _pathological,
  'mixed': mixed,
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

const _prose = '''
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo.

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore
eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident,
sunt in culpa qui officia deserunt mollit anim id est laborum. 5 * 6 = 30 and
a_b_c stays literal while 3 < 4 and x > y hold true here.''';

const _inline = '''
This has **bold**, *italic*, __underline__, ~~strike~~, `code`, ==mark== and
||spoiler|| all mixed together in **one _deeply *nested* emphasis_ chain** to
stress the inline parser with `several inline code` spans and *many* markers.''';

const _links = '''
See [the docs](https://example.com/docs "Docs") and [the repo](https://x.io)
plus an image ![alt text](https://cdn.example.com/pic.png "caption") inline.
Also [a](b) [c](d) [e](f) [g](h) short links and <https://auto.example.com>.''';

const _lists = '''
- First item with **bold**
- Second item with [a link](https://x.io)
  - Nested item one
  - Nested item two with `code`
    - Deep item
- [ ] Pending task
- [x] Completed task

1. Ordered one
2. Ordered two
   1. Sub one
   2. Sub two
3. Ordered three''';

const _table = '''
| Name    | Age | Role         | Notes            |
| :------ | --: | :----------: | ---------------- |
| Alice   |  25 | Developer    | Likes **bold**   |
| Bob     |  30 | *Designer*   | Uses `tools`     |
| Charlie |  35 | ~~Manager~~  | [link](https://) |''';

const _code = '''
```dart
void main() {
  final greeting = 'Hello, world!';
  for (var i = 0; i < 10; i++) {
    print('\$greeting \$i');
  }
}
```

Some text between the code blocks to break them apart cleanly here.

~~~python
def fib(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a
~~~''';

const _quotes = '''
> This is a blockquote that spans
> several lines and contains **bold**
> and `code` and [a link](https://x.io).

> [!NOTE]
> A GitHub-style alert with some *emphasis* inside the body text here.

> [!WARNING]
> Another alert to exercise the alert parsing branch of the block loop.''';

const _escapes = r'''
Escaped \*asterisks\* and \_underscores\_ and \`backticks\` stay literal.
A path C:\\Users\\name and a \[bracket\] and \(paren\) plus \# and \! here.
Money like $5 and $10 is preserved but $\alpha$ becomes a Greek letter now.''';

const _currency = '''
The subscription costs \$9.99 per month or \$99 per year, saving you \$20.
Enterprise plans start at \$499 and scale to \$4,999 for large teams here.
A one-time setup fee of \$5 applies, with volume discounts above \$10,000.
Refunds up to \$1,000 are processed within 30 days for orders over \$250.''';

/// Worst-case-ish input: long runs of emphasis markers and stray delimiters
/// that stress the closer-lookahead scans without producing much output.
final String _pathological = <String>[
  '*' * 300,
  '',
  '_' * 300,
  '',
  '${'a * b ' * 100}c',
  '',
  '${'x_y_' * 150}z',
  '',
  '`' * 200,
].join('\n');

/// A representative mixed document (also used for the head-to-head comparison
/// against the `markdown` package).
const String mixed = r'''
# Markdown parser test

This is a **bold** paragraph with *italic*, __underline__, ~~strike~~,
`monospace` and [a link](https://example.com).

This is a ==highlighted== text on one line.

---

## Multiline paragraph

Lorem ipsum dolor sit amet,
consectetur adipiscing elit.
Sed do eiusmod **tempor** incididunt
*ut labore* et dolore `magna aliqua`.

### Quote

> This is a simple quote.
>
> It may contain **several lines**,
> and even nested formatting like `code` or [links](https://example.com).

> [!TIP]
> Use alerts to draw attention.

### Code blocks

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

| Name    | Age | Role         |
| :------ | --: | :----------: |
| Alice   |  25 | Developer    |
| **Bob** |  30 | *Designer*   |
| Charlie |  35 | ~~Manager~~  |

### Images

![Alt text](https://example.com/image.png)

That is all for the *test* document.
''';
