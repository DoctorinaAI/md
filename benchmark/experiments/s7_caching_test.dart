// SPIKE S7 — Caching: static content Picture vs dynamic selection overlay.
//
// Question: can the selection highlight be drawn as an overlay that changes
// every drag-frame WITHOUT rebuilding the cached content ui.Picture, and does a
// RepaintBoundary isolate one widget's selection repaint from its neighbours?
//
// Mirrors MarkdownPainter's cache (one ui.Picture keyed by size). The highlight
// is drawn OUTSIDE that Picture each paint. Instruments rebuild/paint counts.
//
// Throwaway spike; outside lib/ and test/.
// Run: flutter test benchmark/experiments/s7_caching_test.dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class CachingBox extends RenderBox {
  CachingBox(String text, this._contentRevision)
      : _painter = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
          ),
          textDirection: TextDirection.ltr,
        );

  TextPainter _painter;
  int _contentRevision;
  ui.Picture? _content;
  Size? _contentSize;
  int? _cachedRevision;

  Rect? _selectionRect;
  int contentRebuilds = 0;
  int paintCount = 0;

  @override
  bool get isRepaintBoundary => true; // candidate decision (Spike 7)

  set selectionRect(Rect? r) {
    if (r == _selectionRect) return;
    _selectionRect = r;
    markNeedsPaint(); // selection change => repaint only, no relayout
  }

  void setContent(String text, int revision) {
    if (revision == _contentRevision) return;
    _painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
      ),
      textDirection: TextDirection.ltr,
    );
    _contentRevision = revision;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    _painter.layout(maxWidth: constraints.maxWidth);
    size = constraints.constrain(Size(_painter.width, _painter.height + 20));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    paintCount++;
    // (Re)build the content Picture only when size or content changed.
    if (_content == null ||
        _contentSize != size ||
        _cachedRevision != _contentRevision) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      _painter.paint(canvas, Offset.zero);
      _content = recorder.endRecording();
      _contentSize = size;
      _cachedRevision = _contentRevision;
      contentRebuilds++;
    }
    final canvas = context.canvas..save();
    canvas.translate(offset.dx, offset.dy);
    // Dynamic overlay drawn fresh each paint, OUTSIDE the cached Picture.
    if (_selectionRect != null) {
      canvas.drawRect(_selectionRect!, Paint()..color = const Color(0x552196F3));
    }
    canvas.drawPicture(_content!);
    canvas.restore();
  }
}

class CacheWidget extends LeafRenderObjectWidget {
  const CacheWidget({
    required this.text,
    required this.revision,
    this.selectionRect,
    super.key,
  });
  final String text;
  final int revision;
  final Rect? selectionRect;

  @override
  CachingBox createRenderObject(BuildContext context) =>
      CachingBox(text, revision)..selectionRect = selectionRect;
  @override
  void updateRenderObject(BuildContext context, CachingBox ro) {
    ro
      ..setContent(text, revision)
      ..selectionRect = selectionRect;
  }
}

void main() {
  testWidgets('S7.1 selection drag => ZERO extra content-Picture rebuilds',
      (tester) async {
    Rect? sel;
    late StateSetter setOuter;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: StatefulBuilder(builder: (_, setState) {
            setOuter = setState;
            return CacheWidget(
                text: 'Selectable content here', revision: 0, selectionRect: sel);
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final box = tester.renderObject<CachingBox>(find.byType(CacheWidget));
    expect(box.contentRebuilds, 1); // built once
    final paintsAfterFirst = box.paintCount;

    // Simulate a 30-frame selection drag: only selectionRect changes.
    for (var i = 0; i < 30; i++) {
      setOuter(() => sel = Rect.fromLTWH(0, 0, 4.0 * i, 18));
      await tester.pump();
    }

    debugPrint('S7.1 contentRebuilds=${box.contentRebuilds} '
        'paints=${box.paintCount}');
    // The overlay redrew every frame (paints grew) but the Picture never rebuilt.
    expect(box.contentRebuilds, 1, reason: 'content Picture reused across drag');
    expect(box.paintCount, greaterThan(paintsAfterFirst));
  });

  testWidgets('S7.2 content or size change DOES rebuild the Picture', (tester) async {
    var text = 'first';
    var rev = 0;
    late StateSetter setOuter;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: StatefulBuilder(builder: (_, setState) {
            setOuter = setState;
            return CacheWidget(text: text, revision: rev);
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final box = tester.renderObject<CachingBox>(find.byType(CacheWidget));
    expect(box.contentRebuilds, 1);

    setOuter(() {
      text = 'second content that is different';
      rev = 1;
    });
    await tester.pumpAndSettle();
    debugPrint('S7.2 contentRebuilds=${box.contentRebuilds}');
    expect(box.contentRebuilds, 2, reason: 'content change rebuilds Picture');
  });

  testWidgets('S7.3 RepaintBoundary isolates per-widget selection repaint',
      (tester) async {
    Rect? selA;
    late StateSetter setOuter;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (_, setState) {
          setOuter = setState;
          return Column(
            children: <Widget>[
              CacheWidget(text: 'Message A', revision: 0, selectionRect: selA),
              const CacheWidget(text: 'Message B', revision: 0),
            ],
          );
        }),
      ),
    ));
    await tester.pumpAndSettle();

    final widgets = find.byType(CacheWidget);
    final a = tester.renderObject<CachingBox>(widgets.at(0));
    final b = tester.renderObject<CachingBox>(widgets.at(1));
    final aPaints = a.paintCount, bPaints = b.paintCount;

    // Change ONLY A's selection.
    setOuter(() => selA = const Rect.fromLTWH(0, 0, 40, 18));
    await tester.pump();

    debugPrint('S7.3 A paints ${aPaints}->${a.paintCount}, '
        'B paints ${bPaints}->${b.paintCount}');
    expect(a.paintCount, greaterThan(aPaints), reason: 'A repainted');
    expect(b.paintCount, bPaints, reason: 'B did NOT repaint (isolated)');
  });
}
