import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_md/flutter_md.dart';

/// A chat-like tab: messages in a `ListView.builder` with cross-message text
/// selection driven by a single [MarkdownSelectionController]. Because the
/// selection is anchored on the immutable models, it survives messages being
/// scrolled off-screen (and disposed), and the whole selection can be copied at
/// any time. The "Stream" button grows the last message to show that streaming
/// updates keep the selection anchored.
class ChatTab extends StatefulWidget {
  /// Creates the chat demo tab.
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final MarkdownSelectionController _controller = MarkdownSelectionController();
  late final List<_Msg> _messages = _seed();
  int _streamCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.setDocuments(<MarkdownDocumentRef>[
      for (final (i, m) in _messages.indexed)
        MarkdownDocumentRef(id: m.id, model: m.markdown, order: i),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final text = _controller.getText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(text.isEmpty ? 'Nothing selected' : 'Copied:\n$text'),
      ));
  }

  void _stream() {
    final last = _messages.last;
    _streamCount++;
    final grown = Markdown.fromString(
        '${last.markdown.markdown} …streamed token #$_streamCount');
    setState(() => _messages[_messages.length - 1] = last.withMarkdown(grown));
    // Reconciliation keeps any active selection anchored across the update.
    _controller.putDocument(last.id, grown, order: _messages.length - 1);
  }

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          Expanded(
            child: MarkdownSelectionScope(
              controller: _controller,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, i) => _Bubble(message: _messages[i]),
              ),
            ),
          ),
          _SelectionBar(
              controller: _controller, onCopy: _copy, onStream: _stream),
        ],
      );
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.controller,
    required this.onCopy,
    required this.onStream,
  });

  final MarkdownSelectionController controller;
  final Future<void> Function() onCopy;
  final VoidCallback onStream;

  @override
  Widget build(BuildContext context) => Material(
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final n = controller.getText().length;
                      return Text(n == 0
                          ? 'Drag (mouse) / long-press-drag (touch) across messages'
                          : 'Selected $n characters across messages');
                    },
                  ),
                ),
                TextButton.icon(
                  onPressed: onStream,
                  icon: const Icon(Icons.bolt),
                  label: const Text('Stream'),
                ),
                const SizedBox(width: 8),
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
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color:
              isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child:
            MarkdownWidget(markdown: message.markdown, documentId: message.id),
      ),
    );
  }
}

class _Msg {
  const _Msg(this.id, this.isUser, this.markdown);
  final String id;
  final bool isUser;
  final Markdown markdown;
  _Msg withMarkdown(Markdown m) => _Msg(id, isUser, m);
}

List<_Msg> _seed() {
  Markdown md(String s) => Markdown.fromString(s);
  return <_Msg>[
    for (var i = 0; i < 14; i++)
      _Msg(
        'm$i',
        i.isEven,
        md(i.isEven
            ? 'Question **#${i ~/ 2}**: how does cross-message selection work?'
            : 'Answer ${i ~/ 2}:\n\nSelection is anchored on the *immutable '
                'model*, so it survives `ListView` disposal. Try dragging across '
                'me and the next messages, scroll, then press **Copy**.\n\n'
                '- point one for message $i\n- point two for message $i'),
      ),
  ];
}
