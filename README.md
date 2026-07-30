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
- **🌐 Cross Platform**: Works on all Flutter-supported platforms
- **📝 GitHub Flavored**: Alerts (`> [!NOTE]`), task lists (`- [x]`), tables with
  column alignment, thematic breaks, strikethrough, and more
- **🧮 Inline Math**: Opt-in `$...$` LaTeX → Unicode (commands + super/subscripts)
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

### Tables

Column alignment is supported via the delimiter row (`:---` left, `:--:`
center, `---:` right):

```markdown
| Left     | Center   | Right    |
| :------- | :------: | -------: |
| Cell 1   | Cell 2   | Cell 3   |
| **Bold** | _Italic_ | `Code`   |
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
***
___
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

- **Parsing**: single-pass, lookup-table driven parser with a plain-text fast
  path and hand-rolled (regex-free) block/inline scanning. The hot path was
  rewritten for a ~45% speedup, and it parses typical AI responses roughly
  **10× faster** than the `markdown` package.
- **Rendering**: 120 FPS smooth scrolling for chat-like interfaces
- **Memory**: Minimal memory footprint with efficient span filtering

Benchmarks live in `benchmark/`:

```bash
dart run benchmark/parser_benchmark.dart   # multi-scenario, vs. `markdown`
dart run benchmark/compare.dart --save      # low-noise before/after tool
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
