import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_md/src/render/markdown_render_object.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(MarkdownSelectionController controller, Widget child) =>
    MaterialApp(
      home: Scaffold(
        body: MarkdownSelectionScope(controller: controller, child: child),
      ),
    );

class _Doc extends StatelessWidget {
  const _Doc(this.id);
  final String id;

  @override
  Widget build(BuildContext context) {
    final controller = MarkdownSelectionScope.of(context);
    final model = controller.documents.firstWhere((d) => d.id == id).model;
    return MarkdownWidget(markdown: model, documentId: id);
  }
}

Offset _leaderSeparation(MarkdownHandleEndpoints e) {
  final start = Offset(e.startGlobal.left, e.startGlobal.bottom);
  final end = Offset(e.endGlobal.right, e.endGlobal.bottom);
  return start - end;
}

void main() {
  group('selectionHandleEndpoints', () {
    testWidgets(
      'multi-line selection keeps start/end leaders apart after scroll',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final md = Markdown.fromString(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
            'Sed do eiusmod tempor incididunt ut labore et dolore magna '
            'aliqua. Ut enim ad minim veniam, quis nostrud exercitation '
            'ullamco laboris.',
          );
          final controller = MarkdownSelectionController()
            ..setDocuments(
              <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)],
            );
          final scroll = ScrollController();

          await tester.pumpWidget(_wrap(
            controller,
            SizedBox(
              height: 180,
              child: ListView(
                controller: scroll,
                children: const <Widget>[
                  SizedBox(height: 120),
                  SizedBox(width: 280, child: _Doc('d')),
                  SizedBox(height: 400),
                ],
              ),
            ),
          ));
          await tester.pumpAndSettle();

          controller.selectAll();
          await tester.pump();

          expect(controller.getText().length, greaterThan(40));
          expect(
            _leaderSeparation(controller.selectionHandleEndpoints()!).distance,
            greaterThan(24),
            reason: 'initial multi-line leaders must not coincide',
          );

          scroll.jumpTo(80);
          await tester.pumpAndSettle();
          expect(
            _leaderSeparation(controller.selectionHandleEndpoints()!).distance,
            greaterThan(24),
            reason: 'leaders must stay apart after scroll',
          );

          scroll.jumpTo(160);
          await tester.pumpAndSettle();
          expect(
            _leaderSeparation(controller.selectionHandleEndpoints()!).distance,
            greaterThan(24),
            reason: 'leaders must stay apart after further scroll',
          );

          expect(find.byType(CompositedTransformFollower), findsNWidgets(2));
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'word-granular reverse expand keeps leaders apart across soft wrap',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final md = Markdown.fromString(
            'Curabitur pretium tincidunt lacus. Nulla gravida orci a odio. '
            'Nullam varius, turpis et commodo pharetra, est eros bibendum '
            'elit, nec luctus magna felis sollicitudin mauris.',
          );
          final controller = MarkdownSelectionController()
            ..setDocuments(
              <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)],
            );

          await tester.pumpWidget(_wrap(
            controller,
            const Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 220, child: _Doc('d')),
            ),
          ));
          await tester.pumpAndSettle();

          final rect = tester.getRect(find.byType(MarkdownWidget));
          // Long-press a word near the right of the first visual line, then
          // drag left/up so extendSelectionGranular reverses directed edges.
          final press = rect.topLeft + Offset(rect.width - 24, 10);
          final gesture = await tester.startGesture(press);
          await tester.pump(const Duration(milliseconds: 600));
          await gesture.moveBy(const Offset(-160, -4));
          await tester.pump();
          await gesture.moveBy(const Offset(-40, 40));
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();

          final endpoints = controller.selectionHandleEndpoints();
          expect(endpoints, isNotNull);
          expect(controller.selection!.isCollapsed, isFalse);
          expect(
            _leaderSeparation(endpoints!).distance,
            greaterThan(16),
            reason: 'left+right Material handles must not stack (peanut)',
          );
          expect(find.byType(CompositedTransformFollower), findsNWidgets(2));
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'unmount clears handle layer links on the detached render object',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          final key = GlobalKey();
          final md = Markdown.fromString(
            'Vivamus facilisis, erat vitae egestas rutrum, justo erat '
            'malesuada purus.',
          );
          final controller = MarkdownSelectionController()
            ..setDocuments(
              <MarkdownDocumentRef>[MarkdownDocumentRef(id: 'd', model: md)],
            );

          await tester.pumpWidget(_wrap(
            controller,
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                child: MarkdownWidget(
                  key: key,
                  markdown: md,
                  documentId: 'd',
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();

          controller.selectAll();
          await tester.pump();

          final ro =
              key.currentContext!.findRenderObject()! as MarkdownRenderObject;
          expect(ro.debugHasSelectionHandleLeaders, isTrue);

          await tester.pumpWidget(_wrap(
            controller,
            const SizedBox.shrink(),
          ));
          await tester.pump();

          expect(
            ro.debugHasSelectionHandleLeaders,
            isFalse,
            reason: 'detach must clear leader links so they cannot linger',
          );
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}
