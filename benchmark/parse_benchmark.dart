// ignore_for_file: avoid_print

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flutter_md/src/markdown.dart' show Markdown;
import 'package:markdown/markdown.dart' as markdown;

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
