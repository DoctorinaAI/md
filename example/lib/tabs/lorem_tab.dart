import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_md/flutter_md.dart';

const String _loremMdA = '''
# Cross-block selection

**Lorem ipsum** dolor sit amet, consectetur _adipiscing_ elit. Drag from this
heading straight down through every block below — headings, quotes, lists,
tables and code all join into one selection with sensible separators.

> Ut enim ad minim veniam, quis nostrud exercitation `ullamco` laboris nisi ut
> aliquip ex ea commodo consequat.

A nested list:

- alpha item
    - alpha one
    - alpha two
- beta item
- gamma item

And a table — its cells are selectable too:

| Lang   | Typing   | Year |
| ------ | -------- | ---: |
| Dart   | static   | 2011 |
| Python | dynamic  | 1991 |
| Rust   | static   | 2010 |

```dart
void main() => print('selectable code block');
```

> [!TIP]
> Selecting Markdown clears the plain `SelectableText` below, and vice-versa.''';

const String _loremMdB = '''
## A different document

Duis aute irure dolor in `reprehenderit` in voluptate velit esse cillum dolore
eu fugiat nulla pariatur — this block belongs to a **second** controller, so
selecting here clears the selection above.

| Column A | Column B |
| -------- | -------- |
| one      | two      |
| three    | four     |''';

const String _loremPlain =
    'This is a plain SelectableText (not Markdown). Selecting here clears the '
    'Markdown selections above — and selecting Markdown clears this one.';

/// Demonstrates cross-block selection within a single [MarkdownWidget], several
/// independent controllers that reset one another via a shared
/// [MarkdownSelectionGroup], and coordination with a plain `SelectableText`.
class LoremTab extends StatefulWidget {
  /// Creates the lorem-ipsum selection demo tab.
  const LoremTab({super.key});

  @override
  State<LoremTab> createState() => _LoremTabState();
}

class _LoremTabState extends State<LoremTab> {
  final MarkdownSelectionGroup _group = MarkdownSelectionGroup();
  late final MarkdownSelectionController _a = MarkdownSelectionController(group: _group);
  late final MarkdownSelectionController _b = MarkdownSelectionController(group: _group);
  final Markdown _docA = Markdown.fromString(_loremMdA);
  final Markdown _docB = Markdown.fromString(_loremMdB);

  // Bumping this key recreates the SelectionArea, clearing its selection when a
  // Markdown selection starts (the Markdown -> plain direction of the reset).
  int _plainEpoch = 0;
  bool _mdActive = false;

  @override
  void initState() {
    super.initState();
    _a.setDocuments(<MarkdownDocumentRef>[MarkdownDocumentRef(id: 'A', model: _docA)]);
    _b.setDocuments(<MarkdownDocumentRef>[MarkdownDocumentRef(id: 'B', model: _docB)]);
    _a.addListener(_onMarkdownSelection);
    _b.addListener(_onMarkdownSelection);
  }

  bool _isActive(MarkdownSelectionController c) =>
      c.selection != null && !c.selection!.isCollapsed;

  void _onMarkdownSelection() {
    final active = _isActive(_a) || _isActive(_b);
    setState(() {
      if (active && !_mdActive) _plainEpoch++; // clear the plain SelectableText
      _mdActive = active;
    });
  }

  @override
  void dispose() {
    _a
      ..removeListener(_onMarkdownSelection)
      ..dispose();
    _b
      ..removeListener(_onMarkdownSelection)
      ..dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final text = _isActive(_a) ? _a.getText() : (_isActive(_b) ? _b.getText() : '');
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Copied:\n$text')));
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );

  /// A custom [contextMenuBuilder] that appends a "Copy LOUD" action to the
  /// default Copy / Select-all buttons.
  Widget _loudContextMenu(
    BuildContext context,
    MarkdownSelectionScopeState state,
  ) =>
      AdaptiveTextSelectionToolbar.buttonItems(
        anchors: state.contextMenuAnchors,
        buttonItems: <ContextMenuButtonItem>[
          ...state.contextMenuButtonItems,
          ContextMenuButtonItem(
            label: 'Copy LOUD',
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: state.controller.getText().toUpperCase()));
              state.hideToolbar();
            },
          ),
        ],
      );

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _label('Markdown A — custom toolbar (right-click / '
                      'long-press for a "Copy LOUD" action)'),
                  MarkdownSelectionScope(
                    controller: _a,
                    contextMenuBuilder: _loudContextMenu,
                    child: MarkdownWidget(markdown: _docA, documentId: 'A'),
                  ),
                  const Divider(height: 40),
                  _label('Markdown B — custom selection color '
                      '(selecting one clears the other)'),
                  MarkdownSelectionScope(
                    controller: _b,
                    selectionColor: Colors.amber.withValues(alpha: 0.4),
                    child: MarkdownWidget(markdown: _docB, documentId: 'B'),
                  ),
                  const Divider(height: 40),
                  _label('Plain SelectableText — resets with the Markdown ones'),
                  SelectionArea(
                    key: ValueKey<int>(_plainEpoch),
                    onSelectionChanged: (content) {
                      if ((content?.plainText ?? '').isNotEmpty) {
                        _group.clearExternal();
                      }
                    },
                    child: const Text(_loremPlain,
                        style: TextStyle(fontSize: 16, height: 1.4)),
                  ),
                ],
              ),
            ),
          ),
          Material(
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _mdActive
                            ? 'Selection active — Ctrl/Cmd+C to copy, '
                                'right-click for the toolbar, Esc to clear'
                            : 'Drag to select · Ctrl/Cmd+A all · '
                                'Shift+arrows extend · right-click toolbar',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}
