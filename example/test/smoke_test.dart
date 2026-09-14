import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:md_example/main.dart';
import 'package:md_example/tabs/chat_tab.dart';
import 'package:md_example/tabs/highlight_tab.dart';
import 'package:md_example/tabs/lorem_tab.dart';

void main() {
  Widget wrapApp() => ThemeModel(
    notifier: ValueNotifier<ThemeMode>(ThemeMode.dark),
    child: const App(),
  );

  Future<void> pumpApp(WidgetTester tester) async {
    // Tall enough for TabBarView + content; wide for the Editor split pane.
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(wrapApp());
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('App boots on the Editor tab without exceptions', (tester) async {
    await pumpApp(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Markdown'), findsOneWidget);
    expect(find.byType(EditorTab), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(MarkdownWidget), findsWidgets);
  });

  testWidgets('theme switch toggles ThemeMode without exceptions', (
    tester,
  ) async {
    final mode = ValueNotifier<ThemeMode>(ThemeMode.dark);
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() {
      mode.dispose();
      return tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(ThemeModel(notifier: mode, child: const App()));
    await tester.pumpAndSettle();

    expect(mode.value, ThemeMode.dark);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(mode.value, ThemeMode.light);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every showcase tab builds without exceptions', (tester) async {
    await pumpApp(tester);

    await openTab(tester, 'Selection');
    expect(find.byType(LoremTab), findsOneWidget);
    expect(tester.takeException(), isNull);

    await openTab(tester, 'Chat');
    expect(find.byType(ChatTab), findsOneWidget);
    expect(find.text('Stream'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await openTab(tester, 'Highlight');
    expect(find.byType(HighlightTab), findsOneWidget);
    expect(find.byType(MarkdownWidget), findsWidgets);
    expect(tester.takeException(), isNull);

    await openTab(tester, 'Editor');
    expect(find.byType(EditorTab), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Editor refresh restores the sample markdown', (tester) async {
    await pumpApp(tester);

    final field = find.byType(TextField);
    await tester.enterText(field, '# scratch');
    await tester.pump();
    expect(find.text('# scratch'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(find.text('# scratch'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chat Stream starts and Stop cancels without exceptions', (
    tester,
  ) async {
    await pumpApp(tester);
    await openTab(tester, 'Chat');

    await tester.tap(find.text('Stream'));
    await tester.pump();
    expect(find.text('Stop'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(find.text('Stream'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
