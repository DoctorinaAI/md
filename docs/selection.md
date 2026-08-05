# Text selection

Files: `lib/src/selection.dart`, `lib/src/selection_scope.dart`,
`lib/src/widget.dart`, and the render side in
`lib/src/render/markdown_render_object.dart`. Selection spans **across blocks and
across multiple `MarkdownWidget`s** (a whole chat), including messages whose
widgets are scrolled off and disposed (issue #25).

## Controller-anchored architecture

`MarkdownSelectionController extends ChangeNotifier` is the single source of
truth. State is held as **logical anchors over immutable models**, never over
render objects.

- **`MarkdownPosition`** `{Object documentId, int blockIndex, int offset}` —
  `documentId` is app-defined (e.g. a chat message id); `blockIndex` indexes
  `Markdown.blocks` (the source list, not painter fragments); `offset` indexes the
  block's **rendered text** (§ linearization).
- **`MarkdownSelection`** `{MarkdownPosition base, extent}` (+ `.collapsed(at)`,
  `isCollapsed`). Direction is stored as authored; reading order is resolved
  lazily by the controller (`_ordered`/`_compare`), never normalized.

**Why anchor to the model:** text is derived from an app-supplied registry of
immutable `Markdown` models, so `getText()`/`selectedContent()` work even when a
widget is unmounted. A selection may span documents whose widgets a `ListView` has
disposed; only mounted docs contribute _geometry_, while _all_ in-range docs
contribute _text_. Flutter's `SelectableRegion`/custom delegates were rejected in
spikes (they glue without separators and drop disposed items).

## Document registry

The app registers each document's immutable model so text extraction is
mount-independent:

- `setDocuments(Iterable<MarkdownDocumentRef>)` — replace the whole registry
  (bulk/initial load); clamps a still-valid selection into the new docs, else
  drops it.
- `putDocument(id, model, {order})` — insert-or-update; **the streaming entry
  point**. No-op early return when neither model nor order changed (streaming can
  call once per token; the model check is `identical`). A model change triggers
  reconciliation (§).
- `removeDocument(id)` — removes and drops the selection if either endpoint was in
  that doc.
- `documentCount` (prefer over `documents.length`, which allocates), `hasDocuments`,
  `documents`.
- **`MarkdownDocumentRef`** `{Object id, Markdown model, int? order}` — `order`
  null ⇒ registration order; supply e.g. the message index so **unmounted** docs
  still order correctly.

Ordering is O(1): `_sort()` sorts `_docs` by `order` then `_reindex()` rebuilds a
`Map<Object,int> _indexById`, so `_orderIndex(id)` is a map lookup. This matters
because `_orderIndex` runs several times per selectable block on **every highlight
repaint** (via `rangeFor`) — a linear scan would scale with chat size and stall
drags. `_reindex` runs on set/order changes only, not on model-only updates.

## Surfaces (mounted geometry bridge)

`abstract interface class MarkdownSelectionSurface` is the controller's window
onto a live render object, **implemented by `MarkdownRenderObject`**:

- `documentId`, `Rect globalBounds`
- `MarkdownPosition? positionForGlobal(Offset)` — global point → logical position
- `List<Rect> globalSelectionRects()` / `localSelectionRects()` — highlight rects
  (screen / content-local); used for handles, magnifier, toolbar anchor
- `setSelectionHandleLayers({startLink, startLocal, endLink, endLocal})` — the
  handle `LayerLink`s the surface paints so the overlay's handles follow content
- `repaintSelection()` — repaint just the highlight; safe during build

The controller keeps a `Map<Object, MarkdownSelectionSurface>` keyed by
`documentId`; render objects `attachSurface`/`detachSurface` on attach/detach.
`rangeFor(documentId, blockIndex)` returns the selected `TextRange` within a block
(null if outside the selection) — the per-block highlight lookup during paint.

## Reconciliation (streaming)

When `putDocument` replaces a model, `MarkdownReconciliationPolicy.remap(anchor,
old, new)` relocates each endpoint in the changed doc (returning null drops the
whole selection). **No stable block id exists — remapping is content-based.**

- `appendFastPath()` — keep the block index verbatim when everything before the
  anchor is unchanged and the anchor block's new text is a prefix-superset; else
  clamp. Cheapest; correct for appends, drifts on front/mid inserts.
- **`contentAnchored()` — the default.** Append fast path, else relocate by
  matching the anchor block's rendered text in the new model, else clamp. Robust
  to inserts/reorders without an id.
- `clearOnChange()` — drop the selection on any change to the anchor's doc.

Set via `MarkdownSelectionController(reconciliation: …)`.

## Extraction & formatting

`selectedContent()` → `MarkdownSelectedContent { List<MarkdownSelectedDocument>
documents; isEmpty; toPlainText() }`, built from the models in reading order,
independent of what's mounted (empty slices skipped).

- `MarkdownSelectedDocument { documentId, List<MarkdownSelectedBlock> blocks }`
- `MarkdownSelectedBlock { int blockIndex, String type, String text, TextRange
renderedRange, TextRange? sourceRange /* currently always null */, MD$Block block }`

`getText([formatter])` = `(formatter ?? controller.formatter).format(selectedContent())`.

- `MarkdownSelectionFormatter` — `String format(MarkdownSelectedContent)`.
- `MarkdownPlainTextFormatter` (default) — joins block slices within a doc by
  `blockSeparator` (`'\n'`), docs by `documentSeparator` (`'\n\n'`); empty blocks
  skipped. Implement your own for "copy as Markdown" etc.

### `markdownBlockRenderedText(block)` — the linearization

This is the **single source of truth** shared by extraction and pointer
hit-testing (the space `TextPainter.getPositionForOffset` indexes). A selectable
block painter's `renderedText`/fragment offsets **must** match it:

- paragraph/heading/quote/alert → concatenated span text. **Alert = body only;
  the title contributes nothing.**
- code → raw `text`.
- **list** → items depth-first, joined by `'\n'` unconditionally (one line per
  item, even empty ones); checkbox glyphs contribute nothing.
- **table** → cells joined by `'\t'`, rows by `'\n'`.
- divider / spacer → `''` (structural blocks contribute no text).

## `MarkdownSelectionScope` — gestures, keyboard, handles, toolbar

`MarkdownSelectionScope` (a `StatefulWidget`) owns interaction for its subtree and
exposes the controller to descendant `MarkdownWidget`s via an inherited widget.
`MarkdownSelectionScopeState` is **public** so a custom toolbar can drive it.

Params: `controller` (required), `child`, `focusNode`, `enabled` (false ⇒ inert
but still exposes the controller), `selectionColor`, `contextMenuBuilder` (null ⇒
no toolbar), `magnifierConfiguration`, `selectionControls`, `onSelectionChanged`.
Statics: `MarkdownSelectionScope.of/maybeOf` (→ controller), `stateOf` (→ state).

- **Gestures:** a `TapAndPanGestureRecognizer` restricted to mouse/stylus/trackpad
  with `DragStartBehavior.down` handles both taps and drags from one recognizer so
  consecutive-tap counting stays intact — **single** click collapses/clears,
  **double** selects the word, **triple** selects the block, `Shift`-click extends,
  and a drag after a double/triple click keeps word/block granularity. On **touch**
  a `LongPressGestureRecognizer` grabs the whole word then extends by word, and a
  `DoubleTapGestureRecognizer` selects the word + pops the toolbar (both tap/press
  based, so a plain swipe still scrolls an enclosing `ListView`). A secondary-only
  `TapGestureRecognizer` shows the toolbar on right-click; with no primary
  callbacks it never competes with the tap-and-pan recognizer. Word boundaries
  come from the mounted painter's `TextPainter.getWordBoundary` (via
  `MarkdownSelectionSurface.wordBoundaryForGlobal`), with the text-based
  `wordRangeIn` heuristic as an unmounted-document fallback.
- **Cursor:** the `MarkdownWidget` render object is a `MouseTrackerAnnotation`; it
  shows the click (hand) cursor over an actionable link (a span with a tap
  recognizer, detected on hover via `handleEvent` → `markNeedsPaint` so
  `MouseTracker` re-reads the cursor), the text (I-beam) cursor while selectable,
  and otherwise `MouseCursor.defer`.
- **Keyboard:** an `Actions` map bound to the ambient `DefaultTextEditingShortcuts`
  Intents (installed by `WidgetsApp`/`MaterialApp`): Ctrl/Cmd+C copy, Ctrl/Cmd+A
  select-all, Shift+arrows extend (char/word/line/doc), Esc clear. Extension
  intents no-op when `collapseSelection` is true (unshifted arrows don't move it).
- **Native handles + magnifier:** touch platforms only (android/iOS/fuchsia). A
  Flutter `SelectionOverlay` is driven from `controller.selectionHandleEndpoints()`;
  handle drags call `controller.moveSelectionEdgeToGlobal(...)`. Overlay creation
  is skipped when there's no `Overlay` host.
- **Toolbar:** `ContextMenuController` + `AdaptiveTextSelectionToolbar`; default
  items are Copy (non-collapsed selection) and Select-all (`hasDocuments`).
  Public ops: `copySelection`, `selectAll`, `clearSelection`, `showToolbar`,
  `hideToolbar`.
- **`MarkdownSelectionGroup`:** pass the same group to several controllers and at
  most one has an active selection — a new non-collapsed selection clears the
  others. `clearExternal()` clears all (call when a non-Markdown `SelectableText`/
  `SelectionArea` starts its own selection).

## Opting a `MarkdownWidget` into selection

`MarkdownWidget` is selectable only when given a `documentId` **and** a resolvable
controller (explicit `controller:` or ambient `MarkdownSelectionScope.maybeOf`);
otherwise it's inert. **The app must register the document's model** with the
controller (`setDocuments`/`putDocument`) — the widget does not self-register.
Typical pattern: keep models in a list, feed them to the controller, and give each
`MarkdownWidget` its matching `documentId`.

## Gotchas / known limitations

- `selectionColor` setter repaints surfaces directly and must **not**
  `notifyListeners` — it's applied during build (`didChangeDependencies`), where
  notifying would trigger `setState`. (The `formatter` setter _does_ notify.)
- Alert **title** is not selectable (body only).
- Keyboard word/line extension is **block-approximate** (a whitespace scan / jump
  to block start-end within the linearized text, not visual lines). Only
  `extendSelectionToAdjacentLine` uses real on-screen geometry (and no-ops when the
  endpoint is unmounted).
- Handle anchors can lag after a **reflow with no selection change** (streaming to
  another block, font/scale change) until the next selection change — the overlay
  sync is driven by selection-change notifications only.
- `moveSelectionEdgeToGlobal` refuses a drag that would collapse the selection (to
  avoid disposing the overlay mid-gesture).
- `MarkdownSelectedBlock.sourceRange` is documented as best-effort but is currently
  always null.
- `MarkdownThemeData.blockFilter` drops whole blocks at render time, but selection
  **extraction is model-based** and does not see that filtering. A selection spanning
  _across_ a dropped block therefore copies the hidden block's text even though the
  block is never highlighted on screen. Avoid `blockFilter` when selection is enabled
  (same guidance as `spanFilter`, which shifts the painter's offset space).
- Keyboard **word** navigation indexes the block's rendered text by UTF-16 code unit,
  so it may split a surrogate pair (an emoji / other non-BMP character). Accepted v1
  limitation.
- Documents are ordered by their `order` key via `List.sort`, which is **not stable**,
  so documents sharing an identical `order` have unspecified relative order. Supply
  unique `order` values (e.g. the message index).
