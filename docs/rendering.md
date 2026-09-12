# Rendering layer

Files: `lib/src/render.dart` (a re-export barrel), `lib/src/render/**`,
`lib/src/theme.dart`, `lib/src/widget.dart`. The layer paints the model onto a
canvas via one `RenderBox` and a list of `BlockPainter`s — **no widget per block**.

## File map (`lib/src/render/`)

`render.dart` is a **barrel** (`library;` + `export` lines) so legacy
`import 'src/render.dart'` keeps resolving; it has no code.

| File | Contents |
|---|---|
| `block_painter.dart` | The framework: `BlockPainter`, `SelectableBlockPainter`, mixins `SelectableTextBlock` / `MultiPainterSelectable` / `ParagraphGestureHandler`, class `SelectableFragment`, private `_distanceToRect`. |
| `span_builder.dart` | `paragraphFromMarkdownSpans({spans, theme, textStyle})` → `TextSpan`; private `_buildTapRecognizer` (link taps from `span.extra['url']`). |
| `markdown_painter.dart` | `MarkdownPainter` (`@meta.internal`) — the orchestrator. |
| `markdown_render_object.dart` | `MarkdownRenderObject` (`@meta.internal`) — the `RenderBox`, also a `MarkdownSelectionSurface`; plus `_paintNothing`. |
| `blocks/*.dart` | `BlockPainter$Paragraph, $Heading, $Quote, $Alert, $Code, $List` (+ private `_ListItemMetrics`), `$Table`, `$Divider`, `$Spacer`. |

## Render flow

`MarkdownWidget` (`LeafRenderObjectWidget`) → `createRenderObject` builds a
`MarkdownRenderObject` then `updateSelection(controller, documentId)`;
`updateRenderObject` calls `update(markdown, theme)` + `updateSelection(...)`.
Theme resolution: explicit `theme` → `MarkdownTheme.maybeOf(context)` → a default
from `DefaultTextStyle`/`Directionality`/`MediaQuery.textScaler`.

`MarkdownRenderObject` (a `RenderBox`, not `sizedByParent`) owns one
`MarkdownPainter`. `computeDryLayout`/`performLayout` both do
`constraints.constrain(_painter.layout(maxWidth: constraints.maxWidth))`.

`MarkdownPainter`:

- **Build** (`_rebuild`): reads `theme.blockFilter` and `theme.builder ??
  _defaultBlockBuilder`; for each non-filtered block appends
  `builder(block, theme) ?? _defaultBlockBuilder(block, theme)` to
  `_blockPainters`, records the true `Markdown.blocks` index in `_sourceIndices`,
  sizes `_blockOffsets`. `_defaultBlockBuilder` is a `block.map(...)` to the nine
  `BlockPainter$*` constructors.
- **Layout:** per-block, top-to-bottom. Writes each block's top-`y` into
  `_blockOffsets[i]`, calls `block.layout(maxWidth)`, accumulates height, tracks
  max width. **No inter-block spacing** is added — a `MD$Spacer` block supplies gaps.
- **Paint:** guarded by `!_needsLayout`. **Glyphs are cached in a `ui.Picture`
  keyed by size** — if `_lastSize == size`, the picture is replayed via
  `drawPicture`; otherwise it re-records (walking blocks, `painter.paint($canvas,
  size, offset)`, advancing `offset += painter.size.height`). The cache is nulled
  only by `update` (model/theme change) and `invalidateLayout` (system fonts). An
  overflow guard stops emitting blocks past the viewport height.
- **Hit-testing** (`_blockIndexForDy`): **binary search** over `_blockOffsets`.
  `positionForLocal` maps a content-local offset → `(sourceBlockIndex, textOffset)`
  (null if the hit block isn't a `SelectableBlockPainter`). `handleEvent` routes
  tap-down/up to the block, re-basing the pointer into block-local space (a manual
  `PointerEvent` clone, since `PointerEvent` has no `copyWith`).
- **System fonts:** `MarkdownRenderObject.attach` listens on
  `PaintingBinding.instance.systemFonts`; a change calls `invalidateLayout` (nulls
  the cache, disposes+rebuilds every block painter so `TextPainter`s re-layout) +
  `markNeedsLayout`.

## The `BlockPainter` framework

`BlockPainter` — every painter implements this:

```dart
abstract final Size size;                            // valid only after layout()
void handleTapDown(PointerDownEvent event);          // block-LOCAL coords
void handleTapUp(PointerUpEvent event);
Size layout(double width);                           // measure at width; sets size
void paint(Canvas canvas, Size size, double offset); // size = full content size; offset = block top-y
void dispose();
```

Coordinate contract: taps arrive in **block-local** space; `paint`'s `offset` is
the block's top-`y` in the content, and `size` is the full content size (blocks
use `size.width` for full-width backgrounds/rules and to bail when too narrow).

`SelectableBlockPainter implements BlockPainter` adds selection:

```dart
String get renderedText;                    // MUST equal markdownBlockRenderedText(block)
int offsetForLocalPosition(Offset local);   // block-local → rendered-text index
List<Rect> boxesForRange(int start, int end);// block-local highlight rects for [start, end)
bool get selectionHighlightAboveCachedContent; // true ⇒ also paint highlight above Picture
```

Two mixins implement it for you:

- **`SelectableTextBlock`** — a block backed by a **single `TextPainter`**. Supply
  `TextPainter get selectionPainter` and optionally override `Offset get
  selectionOrigin` (default `Offset.zero`) when glyphs aren't at the block origin.
  It derives `renderedText`, `offsetForLocalPosition`, `boxesForRange` for you.
- **`MultiPainterSelectable`** — a block whose text spans **several
  `TextPainter`s** at different origins (lists, tables). Supply
  `List<SelectableFragment> get fragments` (in rendered-text order, each
  `textStart` matching the linearization; the gaps are the `\n`/`\t` separators)
  and `renderedText`. `SelectableFragment` is `(TextPainter painter, Offset
  origin, int textStart)`.

`ParagraphGestureHandler` — mix in for link taps: `hitTestInlineSpanWithPointerEvent(event,
painter)` resolves the `InlineSpan` under a pointer so `handleTapDown`/`handleTapUp`
can match down and up on the same span before firing its recognizer.

`paragraphFromMarkdownSpans({spans, theme, textStyle})` → `TextSpan` — the public
helper that applies `theme.spanFilter`, maps each `MD$Span` via
`theme.textStyleFor(span.style)` (merged under `textStyle` if given), and attaches
a link recognizer (from `theme.onLinkTap` + `span.extra['url']`). **Use it** for
any custom text block so filters/styles/link-taps stay consistent.

### Recipe: a custom block painter

```dart
class MyBlock with ParagraphGestureHandler, SelectableTextBlock implements BlockPainter {
  MyBlock({required List<MD$Span> spans, required this.theme})
      : painter = TextPainter(
          text: paragraphFromMarkdownSpans(spans: spans, theme: theme),
          textDirection: theme.textDirection, textScaler: theme.textScaler);

  final MarkdownThemeData theme;
  final TextPainter painter;
  @override TextPainter get selectionPainter => painter;   // SelectableTextBlock hook

  Size _size = Size.zero;
  @override Size get size => _size;

  @override Size layout(double width) { painter.layout(maxWidth: width); return _size = painter.size; }
  @override void paint(Canvas c, Size s, double dy) { /* decorate */ painter.paint(c, Offset(0, dy)); }
  @override void handleTapDown(PointerDownEvent e) {/* see BlockPainter$Paragraph */}
  @override void handleTapUp(PointerUpEvent e) {/* ... */}
  @override void dispose() => painter.dispose();
}
```

Wire it in via the theme:

```dart
MarkdownThemeData(
  builder: (block, theme) => block is MD$Paragraph ? MyBlock(spans: block.spans, theme: theme) : null,
);
```

Returning `null` falls back to the default painter for that block. For
many-painter blocks (custom lists/tables), mix in `MultiPainterSelectable` instead
and expose `fragments` + `renderedText`.

> **Offset-space rule:** if your block is selectable, `renderedText` (and each
> fragment's `textStart`) must match `markdownBlockRenderedText(block)` (see
> [selection](selection.md)), or hit-testing, highlight, and copied text will
> disagree.

## Default block painters

- **`$Paragraph`** — one `TextPainter` from spans, painted at `(0, offset)`;
  selectable + link taps; no decoration.
- **`$Heading`** — like `$Paragraph`, styled by `theme.headingStyleFor(level)`.
- **`$Quote`** — body styled `theme.quoteStyle ?? textStyle`; one vertical accent
  bar per `indent` level (`lineIndent = 10`, `dividerColor`); text shifted right
  by `lineIndent + indent*lineIndent` (also its `selectionOrigin`).
- **`$Alert`** — GitHub admonition: tinted rounded background (accent α 0.10),
  left accent bar (width 4), bold colored title above body (`alert.title`,
  `alertColorFor(type)`); body selectable via `selectionOrigin`.
- **`$Code`** — monospace `TextPainter` (raw text, no span parsing); rounded
  `surfaceColor` background (radius = padding 8); taps are no-ops; **no link taps**.
- **`$List`** — recursive nested items (`_baseIndent = 8`, `_levelIndent = 16` per
  depth); bullet glyph `☑`/`☐` for task items, else `•`/ordered marker; each item
  is a bullet + content `TextPainter`; `MultiPainterSelectable`, items joined `\n`.
- **`$Table`** — per-cell `TextPainter` (bold header), per-column alignment;
  column widths via `_distributeWidths` (natural if they fit, else shrink toward
  per-column min = longest-word width, else overflow); zebra rows, cached inner
  grid + outer border; `MultiPainterSelectable`, cells joined `\t`, rows `\n`.
- **`$Divider`** — one horizontal line across `size.width`; not selectable.
- **`$Spacer`** — blank vertical gap `Size(0, fontSize * count)`; `paint` is a
  no-op; not selectable.

`$Divider`/`$Spacer` are not selectable; `$Code` is selectable but has no link
taps; only `$List`/`$Table` use `MultiPainterSelectable`.

## Theme customization (`MarkdownThemeData`)

`MarkdownThemeData implements ThemeExtension<MarkdownThemeData>` — put it in
`ThemeData.extensions` (it `lerp`s; non-lerpable fields switch at `t < 0.5`) or
provide it through the `MarkdownTheme` inherited widget (`MarkdownTheme.of/maybeOf`).
`MarkdownThemeData.mergeTheme(ThemeData, ...)` derives one from a Material theme.

Render-override hooks:

- **`builder`** `BlockPainter? Function(MD$Block, MarkdownThemeData)` — custom
  painter per block; `null` ⇒ default.
- **`blockFilter`** `bool Function(MD$Block)` — drop a whole block before painters
  are built; `_sourceIndices` keeps selection anchored to the real model index.
- **`spanFilter`** `bool Function(MD$Span)` — filter inline spans. **Caveat:
  dropping text-bearing spans shifts the painter's offset space vs the model, so
  the highlight stays right but copied text can misalign. Avoid dropping
  text-bearing spans when selection is enabled.**
- **`cursorResolver`** `MouseCursor? Function(Offset, int?, MD$Block?)` —
  dynamically resolves hover mouse cursors per local offset, hit block index,
  and hit block model, falling back to default link/text/defer cursors when null.
  Can also be supplied directly to `MarkdownWidget.cursorResolver`.

Styling: `textStyle`, per-level `h1Style..h6Style` (+ cached `headingStyleFor`),
`textStyleFor(MD$Style)` (cached mapping of the bitmask → bold/italic/underline/
strikethrough/monospace + highlight/monospace backgrounds + link color),
`linkColor`/`linkStyle`, `surfaceColor` (code/table/quote backgrounds),
`highlightBackgroundColor`, `monospaceBackgroundColor`, `dividerColor`,
`alertColors` (+ built-in GitHub palette fallback via `alertColorFor`),
`textDirection`, `textScaler`, and `onLinkTap`.

## Public vs internal

Public (in `flutter_md.dart`'s `show` list): the framework
(`BlockPainter`, `SelectableBlockPainter`, `SelectableTextBlock`,
`MultiPainterSelectable`, `SelectableFragment`, `ParagraphGestureHandler`,
`paragraphFromMarkdownSpans`) and the nine defaults (`BlockPainter$Paragraph …
$Spacer`). Internal (`@meta.internal`, only via `src/render.dart`):
`MarkdownPainter`, `MarkdownRenderObject`.

## Invariants (repeated from [architecture](architecture.md), owned here)

- Glyphs cached in a `ui.Picture` keyed by size; reused on repaint; nulled only on
  `update`/`invalidateLayout`.
- **Selection highlight is painted outside the glyph [Picture] cache**, in two
  passes matching `SelectableRegion` / `SelectionArea`: first **under** the
  content picture (sharp text — no washed-out overlay), then **above** only for
  blocks that paint opaque chrome (`selectionHighlightAboveCachedContent`, e.g.
  code fences, table zebra rows, and blocks whose spans use monospace/highlight
  backgrounds) so the tint stays visible there. Drags/streaming never rebuild
  the glyph cache. Color = `controller.selectionColor ?? _kSelectionColor`
  (`0x552196F3`).
- `isRepaintBoundary => controller != null`; `alwaysNeedsCompositing` when the
  surface owns a start and/or end handle `LeaderLayer`.
- Handle `LeaderLayer`s are pushed in `paint` via `LayerHandle` (only when a
  scope supplied start/end `LayerLink` + local offset) so native handles follow
  scrolling content. Links clear on detach so remount / virtualization cannot
  leave ghost leaders.
