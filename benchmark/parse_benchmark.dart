// ignore_for_file: avoid_print

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:md/md.dart';

/// This benchmark compares the performance of the `md` package against the
/// `markdown` package from Google.
///
/// To run this benchmark, use the following command:
/// ```shell
/// dart run benchmark/parse_benchmark.dart
/// ```
///
/// Or compile it to a native executable:
/// ```shell
/// dart compile exe benchmark/parse_benchmark.dart -o benchmark/parse_benchmark
/// ./benchmark/parse_benchmark
/// ```
void main() {
  final current = Current$Benchmark().measure();
  final google = Google$Benchmark().measure();

  if (current < google) {
    print('Current package ${(google / current).toStringAsFixed(2)}x faster\n'
        'Google package took ${google.toStringAsFixed(2)} us\n'
        'Current package took ${current.toStringAsFixed(2)} us');
  } else {
    print('Google package ${(current / google).toStringAsFixed(2)}x faster\n'
        'Google package took ${google.toStringAsFixed(2)} us\n'
        'Current package took ${current.toStringAsFixed(2)} us');
  }
}

class Current$Benchmark extends BenchmarkBase {
  Current$Benchmark() : super('Current package');

  Markdown? result;

  @override
  void run() {
    result = Markdown.fromString(_testSample);
  }

  @override
  void teardown() {
    super.teardown();
    // Ensure the result is not null after running the benchmark
    // to disable compilation optimizations that might skip the run.
    if (result == null)
      throw StateError('Result is null, did you run the benchmark?');
  }
}

class Google$Benchmark extends BenchmarkBase {
  Google$Benchmark() : super('Google package');

  List<markdown.Node>? result;

  @override
  void run() {
    result =
        markdown.Document(extensionSet: markdown.ExtensionSet.gitHubFlavored)
            .parse(_testSample);
  }

  @override
  void teardown() {
    super.teardown();
    // Ensure the result is not null after running the benchmark
    // to disable compilation optimizations that might skip the run.
    if (result == null)
      throw StateError('Result is null, did you run the benchmark?');
  }
}

const _testSample = r'''
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
