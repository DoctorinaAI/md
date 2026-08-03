# Architecture

`flutter_md` is four layers with a strict one-way dependency flow:

```
String ──► Parser ──► Node model ──► Render layer ──► Screen
                          │              ▲
                          └── Selection ─┘  (anchored on the model, geometry from the render layer)
```

1. **Parser** (`lib/src/parser.dart`) turns a `String` into an immutable
   `Markdown` (`lib/src/markdown.dart`) whose `blocks` are `MD$Block` nodes
   (`lib/src/nodes.dart`).
2. **Render layer** (`lib/src/render/`, driven by `MarkdownWidget` in
   `lib/src/widget.dart`) paints the model onto a canvas via one `RenderBox` and
   a list of `BlockPainter`s — there is no widget per block.
3. **Selection** (`lib/src/selection.dart`, `lib/src/selection_scope.dart`) holds
   the selection as logical anchors over the immutable models, and reads geometry
   from mounted render objects for hit-testing/highlight/handles.
4. **Theme** (`lib/src/theme.dart`) supplies styles and the customization hooks
   (`builder`, `blockFilter`, `spanFilter`) that the render layer reads.

The parser and node model are stable ground; the render layer was reorganized
into `lib/src/render/**` (see [rendering](rendering.md)). Selection is the newest
subsystem (issue #25).

## Data flow, end to end

`Markdown.fromString(src)` → `MarkdownDecoder.convert` → `Markdown{markdown,
blocks}`. You hand that `Markdown` to a `MarkdownWidget`:

```dart
MarkdownWidget(markdown: Markdown.fromString(src), theme: myTheme)
```

`MarkdownWidget` (a `LeafRenderObjectWidget`) creates a `MarkdownRenderObject`
(a `RenderBox`), which owns a `MarkdownPainter`. The painter builds a
`List<BlockPainter>` (one per non-filtered block, via `theme.builder ??`
defaults), lays them out top-to-bottom recording each block's top-`y` in
`_blockOffsets`, and paints them into a cached `ui.Picture` keyed by size.

For selection, the same widget opts in when given a `documentId` **and** a
resolvable `MarkdownSelectionController` (explicit or via an ambient
`MarkdownSelectionScope`). The render object then registers itself with the
controller as a `MarkdownSelectionSurface` and paints the selection highlight
(looked up from the controller) beneath the glyphs. See [selection](selection.md).

## Why the model is immutable and selection anchors to it

Selection must span multiple blocks and multiple `MarkdownWidget`s (e.g. an
entire chat), including messages whose widgets are scrolled off and disposed by a
`ListView`. So the selection is stored as `(documentId, blockIndex,
renderedOffset)` over an app-supplied registry of immutable `Markdown` models,
not over render objects. Text extraction reads the models directly and works even
when nothing is mounted; only mounted surfaces contribute geometry (highlight
rects, handles). This is the core design decision; the alternatives (Flutter's
`SelectableRegion`, a custom selection delegate) were ruled out in spikes
(`benchmark/experiments/FINDINGS.md`).

## Load-bearing invariants

These are cross-cutting; each subsystem doc repeats the ones it owns.

- **Glyph cache.** `MarkdownPainter` caches one `ui.Picture` keyed by paint size;
  it is reused on every repaint and only nulled by `update`/`invalidateLayout`
  (model/theme change or system-font change). Repaints from selection or scroll
  must not invalidate it.
- **Highlight outside the cache.** The selection highlight is drawn *before* and
  *outside* the cached `Picture`, so drags/streaming repaint only the highlight.
  `MarkdownRenderObject.isRepaintBoundary` is true whenever a controller is
  attached, isolating those repaints.
- **Offset-space agreement.** A `SelectableBlockPainter`'s `renderedText` and
  fragment offsets must equal `markdownBlockRenderedText(block)` (lists join items
  with `\n`; tables join cells with `\t`, rows with `\n`; dividers/spacers are
  empty). Hit-testing, highlight geometry, and copied text all index the same
  space. `blockFilter` may drop blocks, but `_sourceIndices` preserves the true
  `Markdown.blocks` index so anchors stay valid.
- **Span offsets.** Concatenating a block's `MD$Span.text` reproduces its rendered
  text; `start/end` index that visible text. See [parser](parser.md) for the
  escape/math/link caveats.

## Public API surface

Everything public is re-exported from `lib/flutter_md.dart`:

- **Whole-file exports:** `markdown.dart`, `nodes.dart`, `parser.dart`,
  `selection.dart`, `selection_scope.dart`, `theme.dart`, `widget.dart`.
- **Curated `show` from `render.dart`:** the `BlockPainter` framework
  (`BlockPainter`, `SelectableBlockPainter`, `SelectableTextBlock`,
  `MultiPainterSelectable`, `SelectableFragment`, `ParagraphGestureHandler`,
  `paragraphFromMarkdownSpans`) and the nine default painters
  (`BlockPainter$Paragraph … $Spacer`).

Deliberately **not** public (reachable only via `import 'package:flutter_md/src/render.dart'`,
annotated `@meta.internal`): `MarkdownPainter`, `MarkdownRenderObject`. Treat the
`show` list as the supported surface; additions to it are permanent commitments.

## Where to make a change

- New/changed Markdown syntax → `parser.dart` (+ maybe `nodes.dart`); add
  regression tests. See [parser](parser.md).
- Change how a block looks → a `BlockPainter$*` in `render/blocks/`, or supply
  `MarkdownThemeData.builder` for a custom painter. See [rendering](rendering.md).
- Selection behavior (gestures, keyboard, extraction, streaming) → `selection.dart`
  / `selection_scope.dart`. See [selection](selection.md).
- Tooling, CI, conventions → [development](development.md).
