// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';

import 'tabs/chat_tab.dart';
import 'tabs/highlight_tab.dart';
import 'tabs/lorem_tab.dart';

void main() => runZonedGuarded<void>(
      () => runApp(ThemeModel(
          notifier: ValueNotifier<ThemeMode>(ThemeMode.dark),
          child: const App())),
      (e, s) => print(e),
    );

/// {@template app}
/// App widget.
/// {@endtemplate}
class App extends StatelessWidget {
  /// {@macro app}
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Markdown',
        themeMode: ThemeModel.of(context).value,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: const HomeScreen(),
        builder: (context, child) => MarkdownTheme(
          data: MarkdownThemeData.mergeTheme(
            Theme.of(context),
            // Exclude images from the markdown rendering,
            // so they are not rendered in the output.
            // Because image spans are not supported yet.
            spanFilter: (span) => !span.style.contains(MD$Style.image),
            onLinkTap: (title, url) {
              ScaffoldMessenger.maybeOf(context)
                ?..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Link "$title" tapped: $url'),
                    duration: const Duration(seconds: 2),
                  ),
                );
            },
          ),
          child: child!,
        ),
      );
}

/// {@template theme_model}
/// A widget that provides the [ThemeMode] to its descendants.
/// {@endtemplate}
class ThemeModel extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  /// {@macro theme_model}
  const ThemeModel({super.key, super.notifier, required super.child});

  /// The state from the closest instance of this class
  /// that encloses the given context, if any.
  /// e.g. `Theme.maybeOf(context)`.
  static ValueNotifier<ThemeMode>? maybeOf(BuildContext context,
          {bool listen = true}) =>
      listen
          ? context.dependOnInheritedWidgetOfExactType<ThemeModel>()?.notifier
          : context.getInheritedWidgetOfExactType<ThemeModel>()?.notifier;

  static Never _notFoundInheritedWidgetOfExactType() => throw ArgumentError(
        'Out of scope, not found inherited widget '
            'a ThemeModel of the exact type',
        'out_of_scope',
      );

  /// The state from the closest instance of this class
  /// that encloses the given context.
  /// e.g. `Theme.of(context)`
  static ValueNotifier<ThemeMode> of(BuildContext context,
          {bool listen = true}) =>
      maybeOf(context, listen: listen) ?? _notFoundInheritedWidgetOfExactType();

  @override
  bool updateShouldNotify(
      covariant InheritedNotifier<ValueNotifier<ThemeMode>> oldWidget) {
    return !identical(notifier, oldWidget.notifier);
  }
}

/// {@template home_screen}
/// HomeScreen widget: a tabbed showcase of the markdown renderer.
/// {@endtemplate}
class HomeScreen extends StatefulWidget {
  /// {@macro home_screen}
  const HomeScreen({
    super.key, // ignore: unused_element
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// State for widget HomeScreen.
class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Markdown'),
          actions: <Widget>[
            Switch.adaptive(
              value: ThemeModel.of(context).value == ThemeMode.dark,
              onChanged: (value) {
                ThemeModel.of(context).value =
                    value ? ThemeMode.dark : ThemeMode.light;
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabs,
            tabs: const <Widget>[
              Tab(text: 'Editor', icon: Icon(Icons.edit)),
              Tab(text: 'Selection', icon: Icon(Icons.text_fields)),
              Tab(text: 'Chat', icon: Icon(Icons.chat_bubble_outline)),
              Tab(text: 'Highlight', icon: Icon(Icons.code)),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabs,
            children: const <Widget>[
              EditorTab(),
              LoremTab(),
              ChatTab(),
              HighlightTab(),
            ],
          ),
        ),
      );
}

/// {@template editor_tab}
/// A split-pane live Markdown editor (source on one side, render on the other).
/// {@endtemplate}
class EditorTab extends StatefulWidget {
  /// {@macro editor_tab}
  const EditorTab({super.key});

  @override
  State<EditorTab> createState() => _EditorTabState();
}

/// State for widget EditorTab.
class _EditorTabState extends State<EditorTab> {
  final MultiChildLayoutDelegate _layoutDelegate = _HomeScreenLayoutDelegate();
  final TextEditingController _inputController =
      TextEditingController(text: _markdownExample);
  final ValueNotifier<Markdown> _outputController =
      ValueNotifier<Markdown>(const Markdown.empty());

  @override
  void initState() {
    super.initState();
    // `inlineMath` is opt-in (disabled by default); enabled here to showcase
    // the `$...$` LaTeX conversion.
    final initialMarkdown =
        Markdown.fromString(_inputController.text, inlineMath: true);
    _outputController.value = initialMarkdown;
    _inputController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _inputController.dispose();
    _outputController.dispose();
  }

  void _onInputChanged() {
    // Handle input changes
    final text = _inputController.text;
    if (text.isEmpty && _outputController.value.isNotEmpty) {
      _outputController.value = const Markdown.empty();
    } else if (text == _outputController.value.markdown) {
      return; // No change, no need to update
    } else {
      final markdown = Markdown.fromString(text, inlineMath: true);
      _outputController.value = markdown;
    }
  }

  @override
  Widget build(BuildContext context) => CustomMultiChildLayout(
        delegate: _layoutDelegate,
        children: <Widget>[
          LayoutId(
            id: 0,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Positioned.fill(
                      child: TextField(
                        controller: _inputController,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '____________________________________\n'
                              '______________________________\n'
                              '__________________________\n'
                              '______________________________\n'
                              '____________________________________\n'
                              '________________________\n'
                              '________________________________________\n'
                              '______________________________\n'
                              '________________________\n'
                              '__________________________________________\n'
                              '______________________________\n',
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            IconButton.filledTonal(
                              icon: const Icon(
                                Icons.refresh,
                              ),
                              onPressed: () =>
                                  _inputController.text = _markdownExample,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          LayoutId(
            id: 1,
            child: Align(
              alignment: Alignment.topLeft,
              child: Card(
                child: SingleChildScrollView(
                  primary: false,
                  padding: const EdgeInsets.all(8.0),
                  child: ValueListenableBuilder(
                    valueListenable: _outputController,
                    builder: (context, value, child) => MarkdownWidget(
                      markdown: value,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class _HomeScreenLayoutDelegate extends MultiChildLayoutDelegate {
  _HomeScreenLayoutDelegate();

  @override
  void performLayout(Size size) {
    if (size.width >= size.height) {
      final width = size.width / 2;
      final constraints =
          BoxConstraints.tightFor(width: width, height: size.height);
      layoutChild(0, constraints);
      layoutChild(1, constraints);
      positionChild(0, Offset.zero);
      positionChild(1, Offset(width, 0));
    } else {
      final height = size.height / 2;
      final constraints =
          BoxConstraints.tightFor(width: size.width, height: height);
      layoutChild(0, constraints);
      layoutChild(1, constraints);
      positionChild(0, Offset.zero);
      positionChild(1, Offset(0, height));
    }
  }

  @override
  bool shouldRelayout(covariant _HomeScreenLayoutDelegate oldDelegate) => false;
}

const String _markdownExample = r'''
# Markdown syntax guide

## Headers

# This is a Heading h1
## This is a Heading h2
### This is a Heading h3
#### This is a Heading h4
##### This is a Heading h5
###### This is a Heading h6

---

## Emphasis

*This text will be italic*
_This will also be italic_

**This text will be bold**

__This will be underline__

`This is inline code`

~~This text will be strikethrough~~

==This text will be highlighted==

_`You` **can** __combine__ ~~them~~_

---

## Paragraphs

  **Lorem ipsum** dolor sit amet, consectetur adipiscing elit.
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis ~~nostrud exercitation~~ ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in _reprehenderit in voluptate velit esse_ cillum dolore eu fugiat nulla pariatur.
**Excepteur sint occaecat cupidatat non proident**, sunt in culpa qui __officia deserunt mollit__ anim id `est laborum`.

---

## Lists

### Unordered

* Item 1
* Item 2
* Item 2a
* Item 2b
    * Item 3a
    * Item 3b

### Ordered

1. Item **1**
2. Item **2**
3. Item **3**
    1. Item **3a** with [link](https://example.com)
    2. Item **3b**

---

## Links

You may be using [Markdown Live Preview](https://markdownlivepreview.com/).

---

## Blockquotes

> Markdown is a lightweight markup language with plain-text-formatting syntax, created in 2004 by John Gruber with Aaron Swartz.
>
> Markdown is often used to format readme files, for writing messages in online discussion forums, and to create rich text using a plain text editor.

---

## Tables

| Left columns  | Right columns |
| ------------- |:-------------:|
| left foo      | right foo     |
| left bar      | right bar     |
| left baz      | right baz     |

---

## Blocks of code

```
let message = 'Hello world';
alert(message);
```

---

## Inline code

This example is using `package:flutter_md/flutter_md.dart`.

---

## Alerts

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

---

## Task lists

- [x] Write the parser
- [x] Add GitHub alerts
- [ ] Ship selection support
    - [x] Nested done
    - [ ] Nested todo

---

## Aligned tables

| Left   | Center | Right |
| :----- | :----: | ----: |
| a      | b      | c     |
| longer | text   | here  |

---

## Inline math (opt-in)

Enabled via `inlineMath: true`. Greek letters and operators: $\alpha$, $\beta$, $\pi \approx 3.14$, $x \rightarrow \infty$, plus superscripts and subscripts like $x^2$ and $H_2O$.

---

## Thematic breaks

Dashes, asterisks and underscores all produce a horizontal rule:

***
___

---

## Special symbols

> "Quotes" and 'single quotes' with 👉 <, >, &, ©, ®, ™, €, £, ¥, •, …, ±, §, ¶, †, ‡, ‰, µ, °

''';
