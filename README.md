# flutter_md - Markdown Parser and Renderer for Flutter

[![Checkout](https://github.com/DoctorinaAI/md/actions/workflows/checkout.yml/badge.svg)](https://github.com/DoctorinaAI/md/actions/workflows/checkout.yml)
[![Pub Package](https://img.shields.io/pub/v/flutter_md.svg)](https://pub.dev/packages/flutter_md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)

A high-performance, lightweight Markdown parser and renderer specifically designed for Flutter applications. Perfect for displaying formatted text from AI assistants like ChatGPT, Gemini, and other LLMs.

## 🌟 Features

- **🚀 High Performance**: Optimized parsing with minimal memory footprint
- **🎨 Fully Customizable**: Theme-based styling with complete control over appearance
- **📱 Flutter Native**: Built from the ground up for Flutter with custom render objects
- **🔗 Interactive Elements**: Clickable links with customizable tap handlers
- **🌐 Cross Platform**: Works on all Flutter-supported platforms
- **📝 Rich Syntax Support**: Comprehensive Markdown syntax coverage
- **🎯 AI-Optimized**: Specifically designed for AI-generated content display
- **🔧 Extensible**: Easy to extend with custom block and span renderers

## 📋 Supported Markdown Syntax

### Text Formatting

- **Bold**: `**text**` or `__text__`
- _Italic_: `*text*` or `_text_`
- ~~Strikethrough~~: `~~text~~`
- `Inline code`: `` `code` ``
- ==Highlight==: `==text==`
- ||Spoiler||: `||text||`

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
```

### Blockquotes

```markdown
> This is a blockquote
> It can span multiple lines
>
> And have multiple paragraphs
```

### Code Blocks

````markdown
```dart
void main() {
  print('Hello, Markdown!');
}
```
````

### Tables

```markdown
| Header 1 | Header 2 | Header 3 |
| -------- | -------- | -------- |
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

```markdown
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
    // Handle link taps
    onLinkTap: (title, url) {
      print('Tapped link: $title -> $url');
      // Launch URL or navigate
    },
    // Filter blocks (e.g., exclude images)
    blockFilter: (block) => block is! MD$Image,
    // Filter spans (e.g., exclude certain styles)
    spanFilter: (span) => !span.style.contains(MD$Style.spoiler),
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

- **Parsing**: ~300 us for typical AI responses, 15x times faster than `markdown` package
- **Rendering**: 120 FPS smooth scrolling for chat-like interfaces
- **Memory**: Minimal memory footprint with efficient span filtering

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
