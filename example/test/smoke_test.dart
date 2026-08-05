import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:md_example/main.dart';
import 'package:md_example/tabs/highlight_tab.dart';

void main() {
  testWidgets('all tabs build and selection drags do not crash',
      (tester) async {
    await tester.pumpWidget(ThemeModel(
      notifier: ValueNotifier<ThemeMode>(ThemeMode.light),
      child: const App(),
    ));
    await tester.pumpAndSettle();

    // Editor tab renders the preview.
    expect(find.byType(EditorTab), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Selection tab: drag across the first Markdown widget.
    await tester.tap(find.text('Selection'));
    await tester.pumpAndSettle();
    final md = find.byType(MarkdownWidget).first;
    final g = await tester.startGesture(
        tester.getTopLeft(md) + const Offset(2, 4),
        kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 150));
    await g.moveTo(tester.getCenter(md));
    await tester.pump(const Duration(milliseconds: 150));
    await g.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The live Plain-vs-Markdown preview appears once something is selected.
    expect(find.text('Plain (default)'), findsOneWidget);
    // "Copy as Markdown" shows as both the preview panel title and the button.
    expect(find.text('Copy as Markdown'), findsWidgets);

    // Chat tab builds and the Copy button is present.
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Highlight tab: every showcased language renders without crashing.
    await tester.tap(find.text('Highlight'));
    await tester.pumpAndSettle();
    expect(find.byType(HighlightTab), findsOneWidget);
    expect(find.byType(MarkdownWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
