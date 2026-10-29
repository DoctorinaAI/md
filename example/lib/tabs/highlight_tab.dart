import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/highlight.dart';
import 'package:flutter_md/highlight/all.dart';
import 'package:flutter_md/highlight/themes.dart';

/// Showcases syntax highlighting across many popular languages. The whole
/// registry ([allHighlightLanguages]) is used here on purpose — a real app
/// would list only the languages it needs so the rest tree-shakes away.
class HighlightTab extends StatefulWidget {
  /// Creates the highlighting showcase tab.
  const HighlightTab({super.key});

  @override
  State<HighlightTab> createState() => _HighlightTabState();
}

class _HighlightTabState extends State<HighlightTab> {
  late final MarkdownSelectionController _controller =
      MarkdownSelectionController();
  // Built once; the whole registry is shared between both theme variants.
  final SyntaxHighlighter _dark = MarkdownHighlighter(
    languages: allHighlightLanguages,
    theme: HighlightThemes.githubDark,
  );
  final SyntaxHighlighter _light = MarkdownHighlighter(
    languages: allHighlightLanguages,
    theme: HighlightThemes.githubLight,
  );

  final Markdown _doc = Markdown.fromString(_showcase);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.setDocuments(<MarkdownDocumentRef>[
      MarkdownDocumentRef(id: 'main', model: _doc),
    ]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = MarkdownThemeData.mergeTheme(
      Theme.of(context),
      highlighter: isDark ? _dark : _light,
      spanFilter: (span) => !span.style.contains(MD$Style.image),
    );
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: MarkdownSelectionScope(
          controller: _controller,
          child: MarkdownWidget(
            markdown: _doc,
            documentId: 'main',
            theme: theme,
          ),
        ),
      ),
    );
  }
}

const String _showcase = r'''
# Syntax highlighting

Fenced code blocks are tokenized and colored with the GitHub theme (follow the
light/dark switch above). Selection and copy stay aligned with the source — the
highlighter only *partitions* text into spans, it never edits it.

## Dart

```dart
import 'dart:math' as math;

Future<int> roll(int sides) async {
  final r = math.Random();
  return r.nextInt(sides) + 1; // 1..sides
}
```

## Python

```python
from dataclasses import dataclass

@dataclass
class Point:
    x: float = 0.0
    y: float = 0.0

    def dist(self) -> float:
        return (self.x ** 2 + self.y ** 2) ** 0.5  # hypot
```

## JavaScript

```js
const memo = new Map();
export const fib = (n) =>
  n < 2 ? n : (memo.get(n) ?? memo.set(n, fib(n - 1) + fib(n - 2)).get(n));
```

## TypeScript

```typescript
interface User { id: number; name: string; }

async function load<T>(url: string): Promise<T> {
  const res = await fetch(`/api/${url}`);
  return (await res.json()) as T;
}
```

## Rust

```rust
fn main() {
    let nums = vec![1, 2, 3, 4];
    let sum: i32 = nums.iter().filter(|&&x| x % 2 == 0).sum();
    println!("even sum = {sum}");
}
```

## Go

```go
package main

import "fmt"

func main() {
    ch := make(chan int, 3)
    go func() { ch <- 42 }()
    fmt.Println(<-ch)
}
```

## Java

```java
record Point(int x, int y) {
    static Point origin() { return new Point(0, 0); }
}
```

## Kotlin

```kotlin
fun main() {
    val squares = (1..5).map { it * it }
    println(squares.joinToString(prefix = "[", postfix = "]"))
}
```

## Swift

```swift
let names = ["Ada", "Alan", "Grace"]
let greeting = names.map { "Hello, \($0)!" }.joined(separator: "\n")
print(greeting)
```

## C++

```cpp
#include <vector>
#include <numeric>

int sum(const std::vector<int>& v) {
    return std::accumulate(v.begin(), v.end(), 0);
}
```

## C#

```csharp
public record Money(decimal Amount, string Currency) {
    public override string ToString() => $"{Amount:F2} {Currency}";
}
```

## Ruby

```ruby
def fizzbuzz(n)
  (1..n).map { |i| i % 15 == 0 ? "FizzBuzz" : i.to_s }
end
```

## PHP

```php
<?php
function greet(string $name): string {
    return "Hello, {$name}!";
}
echo greet("world");
```

## HTML

```html
<!doctype html>
<html lang="en">
  <body class="home">
    <h1 id="title">Hello &amp; welcome</h1>
  </body>
</html>
```

## CSS

```css
:root { --accent: #0969da; }
.button:hover {
  color: var(--accent);
  transition: color 120ms ease-in-out;
}
```

## SQL

```sql
SELECT u.name, COUNT(o.id) AS orders
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.active = TRUE
GROUP BY u.name;
```

## YAML

```yaml
service:
  name: web
  ports: [80, 443]
  env:
    DEBUG: false   # production
```

## JSON

```json
{
  "name": "flutter_md",
  "version": "0.2.0",
  "keywords": ["markdown", "rendering"],
  "stable": true
}
```

## Bash

```bash
#!/usr/bin/env bash
set -euo pipefail
for f in *.log; do
  echo "rotating ${f}"
  mv -- "$f" "${f}.$(date +%s)"
done
```
''';
