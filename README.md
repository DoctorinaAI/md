# flutter_md - Markdown Parser and Renderer for Flutter

[![Checkout](https://github.com/DoctorinaAI/md/actions/workflows/checkout.yml/badge.svg)](https://github.com/DoctorinaAI/md/actions/workflows/checkout.yml)
[![Pub Package](https://img.shields.io/pub/v/flutter_md.svg)](https://pub.dev/packages/flutter_md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)

A high-performance, lightweight Markdown parser and renderer specifically designed for Flutter applications. Perfect for displaying formatted text from AI assistants like ChatGPT, Gemini, and other LLMs.

## 🌟 Features

- **🚀 High Performance**: Hand-tuned single-pass parser with minimal allocations
- **🎨 Fully Customizable**: Theme-based styling with complete control over appearance
- **📱 Flutter Native**: Built from the ground up for Flutter with custom render objects
- **🔗 Interactive Elements**: Clickable links with customizable tap handlers
- **✂️ Text Selection**: Cross-block and cross-widget (chat) selection via a
  controller that survives list disposal and streaming updates
- **🌊 Streaming Parser**: `StreamingMarkdownParser` parses LLM token output
  incrementally — completed blocks are frozen, only the live tail re-parses
- **🌐 Cross Platform**: Works on all Flutter-supported platforms
- **📝 GitHub Flavored**: Alerts (`> [!NOTE]`), task lists (`- [x]`), tables with
  column alignment, thematic breaks, strikethrough, and more
- **🧮 Inline Math**: Opt-in `$...$` LaTeX → Unicode (commands + super/subscripts)
- **🌈 Syntax Highlighting**: Opt-in, dependency-free code-block highlighting —
  65+ languages and GitHub light/dark themes; only the languages you import are
  bundled (the rest tree-shake away)
- **🎯 AI-Optimized**: Specifically designed for AI-generated content display
- **🔧 Extensible**: Easy to extend with custom block and span renderers
- **✅ Well Tested**: 370+ tests; parser and node model at ~100% line coverage

## 📋 Supported Markdown Syntax

### Text Formatting

- **Bold**: `**text**`
- **Underline**: `__text__`
- _Italic_: `*text*` or `_text_`
- ~~Strikethrough~~: `~~text~~`
- `Inline code`: `` `code` ``
- ==Highlight==: `==text==`
- ||Spoiler||: `||text||`
- Inline math (**opt-in**): `$\alpha$`, `$\pi \approx 3.14$`, `$x^2$`, `$H_2O$`
  (common LaTeX commands + super/subscripts → Unicode)

Emphasis follows CommonMark-inspired flanking rules, so stray markers
(`5 * 6 = 30`), intraword underscores (`snake_case`), and unterminated markers
(`**oops`) are left as literal text instead of leaking styles.

#### Inline math (opt-in)

Inline `$...$` LaTeX math is **disabled by default** (so prices like `$5` and
shell variables like `$HOME` are never altered). Enable it per parse or per
decoder:

```dart
// Per parse:
final md = Markdown.fromString(r'The angle $\alpha$ and $x^2 + y^2$.',
    inlineMath: true);

// Or a reusable decoder, optionally extending the command table:
const decoder = MarkdownDecoder(
  inlineMath: true,
  mathReplacements: {...kMarkdownMathCommands, r'\R': 'ℝ'},
);
```

It converts LaTeX commands (`\alpha`, `\rightarrow`, ...) and super/subscripts
(`x^2`, `H_2O`, `x^{10}`), is code-span and code-block safe, and treats `\$` as
a literal dollar. Write `\$\alpha\$` to keep a literal `$\alpha$`.

### Headers

```markdown
# H1 Header

## H2 Header

### H3 Header

#### H4 Header

##### H5 Header

###### H6 Header
```

### Lists

```markdown
- Unordered list item
- Another item
  - Nested item
    - Deep nested item

1. Ordered list item
2. Another numbered item
   1. Nested numbered item
   2. Another nested item

- [x] Completed task-list item
- [ ] Pending task-list item
```

Task-list state is exposed on `MD$ListItem.checked` (`true`/`false`/`null`) and
`MD$ListItem.isTask`, and rendered as a checkbox.

### Blockquotes

```markdown
> This is a blockquote
> It can span multiple lines
>
> And have multiple paragraphs
```

### Alerts (Admonitions)

GitHub-style alerts are rendered from blockquotes with a type marker:

```markdown
> [!NOTE]
> Highlights information that users should take into account.

> [!TIP]
> Optional information to help a user be more successful.

> [!IMPORTANT]
> Crucial information necessary for users to succeed.

> [!WARNING]
> Critical content demanding immediate user attention.

> [!CAUTION]
> Negative potential consequences of an action.
```

Each alert becomes an `MD$Alert` block (`MD$AlertType.note`, `.tip`,
`.important`, `.warning`, `.caution`). Per-type accent colors are configurable
via `MarkdownThemeData.alertColors` / `alertColorFor`.

### Code Blocks

````markdown
```dart
void main() {
  print('Hello, Markdown!');
}
```
````

Code blocks can be syntax-highlighted — see
[Syntax Highlighting](#-syntax-highlighting).

### Tables

Column alignment is supported via the delimiter row (`:---` left, `:--:`
center, `---:` right):

```markdown
| Left     |  Center  |  Right |
| :------- | :------: | -----: |
| Cell 1   |  Cell 2  | Cell 3 |
| **Bold** | _Italic_ | `Code` |
```

### Links and Images

```markdown
[Link text](https://example.com)
![Image alt text](https://example.com/image.png)
```

Images currently not displayed!

### Horizontal Rules

Any of `---`, `***`, or `___` (optionally spaced, e.g. `- - -`) produce a rule:

```markdown
---
---

---
```

## 🚀 Quick Start

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_md: ^x.x.x # Replace with the latest version
```

Then run:

```bash
flutter pub get
```

> **Upgrading from 0.0.x?** See the
> [Migration guide: 0.0.x → 0.2.x](docs/migration/0.0.x-to-0.2.x.md). The upgrade
> is almost entirely backward compatible — most apps need no code changes.

## ✂️ Text Selection

Selection is anchored on the immutable Markdown model, not on the render
objects, so it spans multiple blocks (heading → paragraph → list → table cell)
**and** multiple `MarkdownWidget`s (e.g. chat messages), and it survives widgets
being scrolled off-screen and disposed. Wrap a group of widgets in a
`MarkdownSelectionScope`, give each a stable `documentId`, and register the
models with the controller:

```dart
final controller = MarkdownSelectionController();

// Register the documents in reading order (a chat feeds this from its list).
controller.setDocuments([
  for (final (i, m) in messages.indexed)
    MarkdownDocumentRef(id: m.id, model: m.markdown, order: i),
]);

MarkdownSelectionScope(
  controller: controller,
  child: ListView.builder(
    itemCount: messages.length,
    itemBuilder: (context, i) => MarkdownWidget(
      documentId: messages[i].id,
      markdown: messages[i].markdown,
    ),
  ),
);

// Any time — even for messages scrolled off-screen:
final String text = controller.getText();                 // default formatter
final String md = controller.getText(const MarkdownMarkupFormatter()); // as Markdown
final MarkdownSelectedContent structured = controller.selectedContent();
```

- **Every block is selectable.** Paragraphs, headings, quotes, code, alerts,
  lists and tables — a drag can start or end inside a list item or table cell,
  and copied text preserves the list `\n` / table `\t` separators.
- **Get the text your way.** `getText()` uses the default
  `MarkdownPlainTextFormatter` (configurable block/document separators). For
  richer output pass the built-in `MarkdownMarkupFormatter` ("Copy as
  Markdown"): it re-emits heading `#`s, nested list markers with task
  checkboxes, blockquote/alert `>` prefixes, fenced code and pipe tables for
  fully-selected blocks (partially-selected edges fall back to plain text). Or
  implement your own `MarkdownSelectionFormatter`. `selectedContent()` returns
  the structured per-document / per-block result each formatter consumes.
- **Streaming stays anchored.** Call `controller.putDocument(id, newModel)` when
  a message grows; the default `MarkdownReconciliationPolicy.contentAnchored`
  keeps the selection (append fast-path, else relocate by content, else clamp).
- **One selection at a time.** Share a `MarkdownSelectionGroup` between
  controllers so selecting in one clears the others; call `group.clearExternal()`
  when a plain `SelectableText`/`SelectionArea` starts its own selection.
- **Gestures.** A mouse/trackpad/stylus drag selects; on touch a
  long-press-then-drag selects (so a plain swipe still scrolls the list).
- **Native handles, magnifier & toolbar.** On touch platforms the selection
  shows draggable handles and a magnifier (they follow the content as it
  scrolls, even across widgets); right-click (desktop) or long-press (mobile)
  shows an adaptive Copy / Select-all toolbar.
- **Keyboard shortcuts.** When the scope is focused: `Ctrl/Cmd+C` copies,
  `Ctrl/Cmd+A` selects all, `Shift`+arrows extend (character / word / line /
  document, plus vertical), `Esc` clears — using the ambient
  `DefaultTextEditingShortcuts`.
- **Customizable like `SelectableText`.** `MarkdownSelectionScope` takes
  `selectionColor`, `contextMenuBuilder`, `magnifierConfiguration`,
  `selectionControls`, `focusNode`, `enabled` and `onSelectionChanged`; its
  public `MarkdownSelectionScopeState` exposes `copySelection` / `selectAll` /
  `clearSelection` / `showToolbar` / `contextMenuButtonItems` /
  `contextMenuAnchors` for a fully custom menu.
- **Opt-in & compatible.** A `MarkdownWidget` with no `documentId`/controller is
  inert — existing usage is unchanged.

```dart
MarkdownSelectionScope(
  controller: controller,
  selectionColor: Colors.amber.withValues(alpha: 0.3),
  onSelectionChanged: (sel) => debugPrint('selection: $sel'),
  contextMenuBuilder: (context, state) => AdaptiveTextSelectionToolbar.buttonItems(
    anchors: state.contextMenuAnchors,
    buttonItems: [
      ...state.contextMenuButtonItems, // Copy, Select all
      ContextMenuButtonItem(
        label: 'Copy LOUD',
        onPressed: () => Clipboard.setData(
            ClipboardData(text: state.controller.getText().toUpperCase())),
      ),
    ],
  ),
  child: /* ... */,
);
```

See the runnable **Selection** and **Chat** tabs in `example/`.

## 🌊 Streaming (LLM output)

LLM replies arrive token by token. Re-parsing the whole accumulated buffer on
every token is `O(N²)` and janks long messages. `StreamingMarkdownParser` keeps
the accumulated source and only re-parses the still-growing **tail**: once a
block is provably complete (terminated by a blank line, and not inside an open
code fence) it is _frozen_ and never parsed again.

```dart
final parser = StreamingMarkdownParser();

llmTokenStream.listen((token) {
  final Markdown md = parser.add(token); // cheap, incremental
  setState(() => _message = md);
});
```

Or transform a `Stream<String>` directly — each event emits the grown document:

```dart
llmTokenStream
    .toMarkdown() // Stream<String> → Stream<Markdown>
    .listen((md) => setState(() => _message = md));
```

- **Exact, never approximate.** The result of `add()` / `current` is always
  identical, block for block, to `Markdown.fromString(everythingReceivedSoFar)`.
  Blocks whose type still depends on input that hasn't arrived — an unterminated
  code fence, a table header still missing its delimiter row, a list that may
  continue — stay in the live tail and are re-evaluated, so they never freeze
  into the wrong shape.
- **Same options as batch.** Pass a configured decoder to match
  `Markdown.fromString`:
  `StreamingMarkdownParser(decoder: const MarkdownDecoder(inlineMath: true))`
  (or `.toMarkdown(decoder: ...)`).
- **Fast.** Replaying a whole message token-by-token is **3–14× faster** than
  the full-reparse approach, and the gap grows with message length
  (`benchmark/streaming_benchmark.dart`).
- **Reusable.** `parser.reset()` clears state for the next message;
  `parser.source` is the raw text accumulated so far, `parser.current` the
  parsed model without adding anything.

Pair it with selection: feed each grown model to `controller.putDocument(id, md)`
and the active selection stays anchored as the message streams in (see the
**Chat** tab in `example/`).

## 🌈 Syntax Highlighting

Fenced code blocks can be syntax-highlighted with a **tree-shakeable,
dependency-free** highlighter — 65+ languages and ready-made GitHub light/dark
themes. Highlighting is **opt-in** and off by default (code renders as plain
monospace): assign a `SyntaxHighlighter` to `MarkdownThemeData.highlighter`.

```dart
import 'package:flutter_md/highlight.dart';        // engine + MarkdownHighlighter
import 'package:flutter_md/highlight/dart.dart';   // one import per language
import 'package:flutter_md/highlight/sql.dart';
import 'package:flutter_md/highlight/themes.dart';  // HighlightThemes

final theme = MarkdownThemeData.mergeTheme(
  Theme.of(context),
  highlighter: MarkdownHighlighter(
    // You assemble the map, so only these grammars are compiled in.
    languages: {
      'dart': HighlightDart.grammar,
      'sql': HighlightSql.grammar,
    },
    theme: isDark ? HighlightThemes.githubDark : HighlightThemes.githubLight,
  ),
);

MarkdownWidget(markdown: doc, theme: theme);
```

- **Only the languages you import ship.** Each language is its own library
  exposing a single grammar, referenced through lazy thunks with **no central
  registry/`Map`/`enum`**. Importing `highlight/dart.dart` never references any
  other language, so unused grammars are removed by tree-shaking — a Dart-only
  app adds ~0 beyond the engine, and all 65 languages together add ~62 KB
  (gzipped) only if you deliberately bundle them all.
- **Selection- and copy-safe.** The highlighter only *partitions* the source
  into colored spans; the concatenated text is byte-identical, so cross-block
  selection, offsets and "Copy as Markdown" stay aligned.
- **Themes.** Use `HighlightThemes.githubDark` / `githubLight`, or implement
  `CodeHighlightTheme` (a `switch` from token type → `TextStyle`) for your own
  palette. Its `background` is applied to the code-block surface.
- **Demos & tooling.** `import 'package:flutter_md/highlight/all.dart';` exposes
  `allHighlightLanguages`, a ready map of every grammar keyed by tag and alias
  (`js`, `ts`, `sh`, …). It references everything, so unused languages can no
  longer be tree-shaken away — use it for demos, not production.
- **Robust.** Unknown languages fall back to plain text; a pattern Dart's regex
  engine rejects disables just that one rule instead of breaking the language.

The grammars are generated by `tool/highlight_codegen` (see its README to
regenerate or add languages). See the runnable **Highlight** tab in `example/`.

> Syntax grammars are adapted from [Prism](https://prismjs.com) (MIT License).

```dart
// Custom theme: map token types to styles.
final class MyCodeTheme implements CodeHighlightTheme {
  const MyCodeTheme();
  @override
  Color? get background => const Color(0xFF1E1E1E);
  @override
  Color? get foreground => const Color(0xFFD4D4D4);
  @override
  TextStyle? styleFor(String tokenType) => switch (tokenType) {
        'comment' => const TextStyle(color: Color(0xFF6A9955)),
        'keyword' => const TextStyle(color: Color(0xFF569CD6)),
        'string' || 'string-literal' => const TextStyle(color: Color(0xFFCE9178)),
        _ => null,
      };
}
```

## 🎨 Customization

### Theme Configuration

```dart
MarkdownTheme(
  data: MarkdownThemeData(
    textStyle: TextStyle(fontSize: 16.0, color: Colors.black87),
    h1Style: TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: Colors.blue,
    ),
    h2Style: TextStyle(
      fontSize: 22.0,
      fontWeight: FontWeight.bold,
      color: Colors.blueGrey,
    ),
    quoteStyle: TextStyle(
      fontSize: 14.0,
      fontStyle: FontStyle.italic,
      color: Colors.grey[600],
    ),
    // Customize link text styling (merged on top of linkColor)
    linkStyle: const TextStyle(
      decoration: TextDecoration.underline,
    ),
    // Per-type accent colors for GitHub alert blocks
    alertColors: const {
      MD$AlertType.warning: Color(0xFF9A6700),
    },
    // Handle link taps
    onLinkTap: (title, url) {
      print('Tapped link: $title -> $url');
      // Launch URL or navigate
    },
    // Filter blocks (e.g., hide code blocks)
    blockFilter: (block) => block is! MD$Code,
    // Filter spans (e.g., exclude images or certain styles)
    spanFilter: (span) => !span.style.contains(MD$Style.image),
  ),
  child: MarkdownWidget(
    markdown: yourMarkdown,
  ),
)
```

Or you can use the `MarkdownThemeData.mergeTheme(Theme.of(context))` factory to create a theme that inherits from the application's theme.
This approach allows you to easily support both light and dark themes, and keeps your markdown styling consistent with the rest of your application.

### Custom Block Painters

For advanced customization, you can provide custom block painters:

```dart
MarkdownThemeData(
  builder: (block, theme) {
    if (block is MD$Code && block.language == 'dart') {
      // Return custom painter for Dart code blocks
      return CustomDartCodePainter(block: block, theme: theme);
    }
    return null; // Use default painter
  },
)
```

### Performance Optimization

For large markdown documents or frequently changing content:

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final Markdown _markdown;

  @override
  void initState() {
    super.initState();
    // Parse markdown once during initialization
    _markdown = Markdown.fromString(yourMarkdownString);
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownWidget(markdown: _markdown);
  }
}
```

## 📊 Performance

`flutter_md` is built for speed: a single-pass, lookup-table parser (regex-free
hot path with a plain-text fast path) and a custom render object that lays the
whole document into one cached `ui.Picture` instead of a deep tree of per-block
widgets.

Head-to-head against `flutter_markdown` and `gpt_markdown` on the same machine
(i7-13700K) with identical styles — full tables and methodology in
[`benchmark_compare/RESULTS.md`](benchmark_compare/RESULTS.md):

- **Parsing** — **~18× faster** than the `markdown` package that backs
  `flutter_markdown` (`gpt_markdown` has no standalone parser), sustaining
  ~60 MB/s on mixed documents.
- **Rendering** (string → painted pixels) — **~6.6× faster than
  `flutter_markdown` and ~15.6× faster than `gpt_markdown`** on a large document
  (1.2–1.6× on small chat bubbles).
- **Scrolling** — 60 fps with **zero dropped frames** in profile mode, and the
  lowest UI-thread frame-build cost of the three (99th-percentile frame build
  **1.6 ms** vs 4.8 / 9.4 ms).

```bash
# In-repo parser micro-benchmarks:
dart run benchmark/parser_benchmark.dart    # multi-scenario, vs. `markdown`
dart run benchmark/compare.dart --save      # low-noise before/after tool

# Head-to-head vs flutter_markdown & gpt_markdown (parser + render):
cd benchmark_compare && flutter pub get
dart run benchmark/parser_benchmark.dart
flutter test test/render_benchmark_test.dart
```

## 🔧 Advanced Features

### Custom Styles

```dart
// Access individual style components
final span = MD$Span(
  text: 'Custom text',
  style: MD$Style.bold | MD$Style.italic, // Combine styles
);

// Check for specific styles
if (span.style.contains(MD$Style.link)) {
  // Handle link styling
}
```

### Block Filtering

```dart
MarkdownThemeData(
  blockFilter: (block) {
    // Only show paragraphs and headers
    return block is MD$Paragraph || block is MD$Heading;
  },
)
```

### Span Filtering

```dart
MarkdownThemeData(
  spanFilter: (span) {
    // Exclude images and spoilers
    return !span.style.contains(MD$Style.image) &&
           !span.style.contains(MD$Style.spoiler);
  },
)
```

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

```bash
git clone https://github.com/DoctorinaAI/md.git md
cd md
flutter pub get
flutter test
```

### Running the Example

```bash
cd example
flutter run
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Documentation](https://pub.dev/documentation/flutter_md/latest/)
- [Example App](https://github.com/DoctorinaAI/md/tree/main/example)
- [Issue Tracker](https://github.com/DoctorinaAI/md/issues)
- [Pub.dev Package](https://pub.dev/packages/flutter_md)

## 💡 Why Choose md?

Unlike other Markdown packages that rely on HTML rendering or web views, `flutter_md` is built specifically for Flutter using custom render objects. This provides:

- **Better Performance**: No HTML parsing or web view overhead
- **Native Feel**: Fully integrated with Flutter's rendering pipeline
- **Customization**: Complete control over styling and behavior
- **Reliability**: Consistent rendering across all platforms
- **Small Size**: Minimal package size with no external dependencies

Perfect for chat applications, documentation viewers, note-taking apps, and any Flutter application that needs to display rich formatted text from AI assistants or user input.
