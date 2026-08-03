import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_md/flutter_md.dart';

/// A chat-like tab: messages in a `ListView.builder` with cross-message text
/// selection driven by a single [MarkdownSelectionController]. Because the
/// selection is anchored on the immutable models, it survives messages being
/// scrolled off-screen (and disposed), and the whole selection can be copied at
/// any time.
///
/// The conversation is intentionally long and varied — headings, tables, code,
/// nested and task lists, block quotes, GitHub alerts and inline math — to
/// exercise selection across every block type. The "Stream" button appends a
/// new assistant reply and grows it token-by-token to show that streaming
/// updates keep any active selection anchored (content-based reconciliation).
class ChatTab extends StatefulWidget {
  /// Creates the chat demo tab.
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final MarkdownSelectionController _controller = MarkdownSelectionController();
  final ScrollController _scroll = ScrollController();
  late final List<_Msg> _messages = _seed();

  Timer? _streamTimer;
  List<String> _streamTokens = const <String>[];
  int _streamCursor = 0;
  String _streamBuffer = '';

  bool get _isStreaming => _streamTimer != null;

  @override
  void initState() {
    super.initState();
    _controller.setDocuments(_refs());
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<MarkdownDocumentRef> _refs() => <MarkdownDocumentRef>[
        for (final (i, m) in _messages.indexed)
          MarkdownDocumentRef(id: m.id, model: m.markdown, order: i),
      ];

  Future<void> _copy() async {
    final text = _controller.getText();
    if (text.isEmpty) {
      _toast('Nothing selected — drag across a few messages first.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    final preview = text.length > 160 ? '${text.substring(0, 160)}…' : text;
    _toast('Copied ${text.length} characters:\n$preview');
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));

  // --- streaming -----------------------------------------------------------

  void _toggleStream() {
    if (_isStreaming) {
      _stopStream();
      return;
    }
    final id = 'stream-${DateTime.now().microsecondsSinceEpoch}';
    _streamTokens = _streamAnswer.split(' ');
    _streamCursor = 0;
    _streamBuffer = '';
    setState(() => _messages.add(_Msg(id, false, const Markdown.empty())));
    _controller.putDocument(id, const Markdown.empty(), order: _messages.length - 1);
    _scrollToBottom();
    _streamTimer = Timer.periodic(const Duration(milliseconds: 55), (_) => _tick(id));
  }

  void _tick(String id) {
    if (_streamCursor >= _streamTokens.length) {
      _stopStream();
      return;
    }
    final token = _streamTokens[_streamCursor++];
    _streamBuffer = _streamBuffer.isEmpty ? token : '$_streamBuffer $token';
    final grown = Markdown.fromString(_streamBuffer);
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx < 0) {
      _stopStream();
      return;
    }
    setState(() => _messages[idx] = _messages[idx].withMarkdown(grown));
    // Reconciliation keeps any active selection anchored across the update.
    _controller.putDocument(id, grown, order: idx);
    _stickToBottom();
  }

  void _stopStream() {
    _streamTimer?.cancel();
    _streamTimer = null;
    if (mounted) setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// Keeps the view pinned to the bottom while streaming, but only if the user
  /// hasn't scrolled up to read/select earlier messages.
  void _stickToBottom() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.maxScrollExtent - pos.pixels < 120) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          Expanded(
            child: MarkdownSelectionScope(
              controller: _controller,
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, i) => _Bubble(message: _messages[i]),
              ),
            ),
          ),
          _SelectionBar(
            controller: _controller,
            isStreaming: _isStreaming,
            onCopy: _copy,
            onSelectAll: _controller.selectAll,
            onClear: _controller.clear,
            onStream: _toggleStream,
          ),
        ],
      );
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.controller,
    required this.isStreaming,
    required this.onCopy,
    required this.onSelectAll,
    required this.onClear,
    required this.onStream,
  });

  final MarkdownSelectionController controller;
  final bool isStreaming;
  final Future<void> Function() onCopy;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final VoidCallback onStream;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final n = controller.getText().length;
                      return Text(
                        n == 0
                            ? 'Drag / long-press-drag across messages · '
                                'Ctrl/Cmd+C copy · right-click or long-press '
                                'for the toolbar · handles on touch'
                            : 'Selected $n characters across messages',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Select all',
                  onPressed: onSelectAll,
                  icon: const Icon(Icons.select_all),
                ),
                IconButton(
                  tooltip: 'Clear selection',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                ),
                TextButton.icon(
                  onPressed: onStream,
                  icon: Icon(isStreaming ? Icons.stop : Icons.bolt),
                  label: Text(isStreaming ? 'Stop' : 'Stream'),
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _Msg message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!isUser) ...<Widget>[
            const _Avatar(isUser: false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints:
                  BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
              decoration: BoxDecoration(
                color: isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: message.markdown.isEmpty
                  ? const _TypingDots()
                  : MarkdownWidget(markdown: message.markdown, documentId: message.id),
            ),
          ),
          if (isUser) ...<Widget>[
            const SizedBox(width: 8),
            const _Avatar(isUser: true),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.isUser});
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? scheme.primary : scheme.secondary,
      foregroundColor: isUser ? scheme.onPrimary : scheme.onSecondary,
      child: Icon(isUser ? Icons.person : Icons.smart_toy_outlined, size: 18),
    );
  }
}

/// A small animated "typing" indicator shown while a streamed reply is empty.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox(
      width: 40,
      height: 16,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: 0.3 + 0.7 * _phase(i),
                  child: CircleAvatar(radius: 3, backgroundColor: color),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _phase(int i) {
    final t = (_c.value + i / 3) % 1.0;
    return t < 0.5 ? t * 2 : (1 - t) * 2;
  }
}

class _Msg {
  const _Msg(this.id, this.isUser, this.markdown);
  final String id;
  final bool isUser;
  final Markdown markdown;
  _Msg withMarkdown(Markdown m) => _Msg(id, isUser, m);
}

/// The answer streamed in token-by-token when the "Stream" button is pressed.
const String _streamAnswer =
    'Absolutely — here is a streamed reply. Because the selection is anchored '
    'on the **immutable model**, it stays put while these words arrive one '
    'at a time, and the parser re-runs on every token. Try selecting an '
    'earlier message first, then press Stream and watch the highlight hold.';

List<_Msg> _seed() {
  final data = <(bool, String)>[
    (
      true,
      'Hi! Can you give me a **quick tour** of what this Markdown renderer '
          'can display?',
    ),
    (
      false,
      '''
## Welcome 👋

`flutter_md` renders GitHub-Flavored Markdown on a **cached canvas** — no
per-glyph widgets — so long chats stay smooth. It supports:

- Headings, paragraphs, **bold**, _italic_, `inline code`, ~~strikethrough~~
- Ordered, unordered, **nested** and task lists
- Tables, block quotes, fenced code, thematic breaks
- GitHub alerts and opt-in inline math

> [!NOTE]
> Every block below is selectable — drag right across the bubbles.''',
    ),
    (true, 'Nice. Show me a **table** comparing the block types.'),
    (
      false,
      '''
Here you go:

| Block        | Example              | Selectable |
| ------------ | -------------------- | :--------: |
| Heading      | `# Title`            |     ✅     |
| Paragraph    | plain text           |     ✅     |
| List         | `- item`             |     ✅     |
| Table        | this one             |     ✅     |
| Code         | `fenced`             |     ✅     |
| Quote        | `> quote`            |     ✅     |

Try dragging from the header row down to the last cell.''',
    ),
    (true, 'How fast is it? Any `benchmarks`?'),
    (
      false,
      '''
The parser got roughly **45% faster** in `0.1.0`. Rough figures on a laptop:

| Scenario            | Before | After |
| ------------------- | -----: | ----: |
| Parse 50-block doc  | 1.8 ms | 1.0 ms |
| Paint (cache hit)   |  41 µs |  41 µs |
| Paint (cache miss)  | 6.5 ms | 6.5 ms |

> Headless timings are relative — real FPS is confirmed with
> `flutter run --profile` and DevTools.''',
    ),
    (true, 'Show me how to **embed** it.'),
    (
      false,
      '''
Three steps:

1. Add the dependency to `pubspec.yaml`.
2. Parse once, cache the result.
3. Hand the model to `MarkdownWidget`.

```dart
final md = Markdown.fromString('# Hello');

@override
Widget build(BuildContext context) => MarkdownWidget(
      markdown: md,
      documentId: 'msg-1', // opt into selection
    );
```

> [!TIP]
> Parse off the build method and reuse the `Markdown` instance — it is
> immutable and cheap to hold.''',
    ),
    (true, 'What about **math**? I write a lot of formulas.'),
    (
      false,
      r'''
Inline math is opt-in (`inlineMath: true`). Then `$...$` renders:
$\alpha$, $\beta$, $\pi \approx 3.14$, $x \rightarrow \infty$, with
superscripts and subscripts like $x^2$ and $H_2O$.

The quadratic roots are $x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$.''',
    ),
    (true, 'Do **nested** lists and **task** lists work?'),
    (
      false,
      '''
Both, to arbitrary depth:

- Parsing
    - Tokenize
    - Build the block tree
        - Inline spans
        - Source offsets
- Rendering
    - Layout
    - Paint

And a checklist:

- [x] Parser
- [x] GitHub alerts
- [x] Text selection
    - [x] Cross-block
    - [x] Cross-widget (this chat)
- [ ] Native mobile handles''',
    ),
    (true, 'Any **warnings** I should know about?'),
    (
      false,
      '''
> [!WARNING]
> Selection offsets are anchored on the *rendered* text, not the raw source —
> markup characters are not part of the offset space.

> [!CAUTION]
> Dropping text-bearing spans with a `spanFilter` shifts that offset space, so
> the highlight stays correct but copied text may drift. Avoid it when
> selection is on.''',
    ),
    (true, 'Give me a bigger table — say, common **HTTP status codes**.'),
    (
      false,
      '''
| Code | Meaning               | Category     |
| ---: | --------------------- | ------------ |
|  200 | OK                    | Success      |
|  201 | Created               | Success      |
|  301 | Moved Permanently     | Redirect     |
|  400 | Bad Request           | Client error |
|  401 | Unauthorized          | Client error |
|  404 | Not Found             | Client error |
|  418 | I'm a teapot          | Client error |
|  500 | Internal Server Error | Server error |
|  503 | Service Unavailable   | Server error |''',
    ),
    (
      true,
      'Great. And I can **select across all of this** — even the messages '
          "I've scrolled past?",
    ),
    (
      false,
      '''
Exactly. The selection lives in the controller as logical anchors
`(documentId, blockIndex, offset)` over the immutable models, so:

1. It **survives disposal** when a bubble scrolls out of the lazy list.
2. `Copy` always returns the *full* text, including off-screen messages.
3. Streaming updates **reconcile** — the anchor holds as text grows.

> Scroll to the top, start a drag, scroll back down, and finish it — then hit
> **Copy**. Press **Stream** to watch reconciliation in action.''',
    ),
    (true, 'Perfect, thanks! 🙏'),
    (
      false,
      'Anytime. Pro tip: **Select all** grabs the entire transcript at once, '
          'and **Clear** resets it. Happy hacking with `flutter_md`!',
    ),
  ];

  return <_Msg>[
    for (final (i, (isUser, text)) in data.indexed)
      _Msg('m$i', isUser, Markdown.fromString(text, inlineMath: true)),
  ];
}
