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
  reconciliation (§). Also **cancels** a deferred remove for the same `id`
  (remount / heal after a dispose that raced ahead of detach).
- `removeDocument(id)` — removes and drops the selection if either endpoint was in
  that doc. **Deferred while a surface for `id` is still mounted:** the registry
  entry stays until `detachSurface`, so hit-testing / `rangeFor` cannot see a
  mounted body with no document (`di=-1`). Eager remove while the render object
  is still attached is unsafe — parent `State.dispose` can run before child
  detach.
- `documentCount` (prefer over `documents.length`, which allocates), `hasDocuments`,
  `documents`.
- **`MarkdownDocumentRef`** `{Object id, Markdown model, int? order}` — `order`
  null ⇒ registration order; supply e.g. the message index so **unmounted** docs
  still order correctly. Use **unique** `order` values that match visual reading
  order (`List.sort` is not stable on ties).

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
On attach (and when the controller / model is wired while already attached),
`MarkdownRenderObject` also `putDocument`s its current model so a mounted surface
is never missing from the registry (heals races where geometry attaches before
an app-level registration). `detachSurface` flushes any deferred
`removeDocument` for that id.

`rangeFor(documentId, blockIndex)` returns the selected `TextRange` within a block
(null if outside the selection) — the per-block highlight lookup during paint.
If either selection endpoint's document is **unregistered**, `rangeFor` returns
null for every block (and extraction yields empty): unregistered ids must not
sort as `-1` and paint every registered body between `0` and `endDoc`.

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

- **Gestures:** mouse uses `TapAndPanGestureRecognizer`; touch/stylus/trackpad
  use a content-gated `TapAndHorizontalDragGestureRecognizer` (SelectableRegion
  split) so consecutive-tap counting stays on one recognizer with **no**
  `DoubleTapGestureRecognizer` arena delay — **single** tap dismisses/clears on
  touch (caret on mouse), **double** selects the word on tap-down and shows
  chrome on tap-up, **triple** selects the block, `Shift`-click extends, and a
  drag after a double/triple keeps word/block granularity. The touch recognizer
  and long-press only join the arena on a selectable hit (or while a non-collapsed
  selection / toolbar is up). With an active selection, `eagerVictoryOnDrag` is
  on so horizontal swipes stay with selection (block dismissible); without a
  selection it stays off so edge swipes on chrome reach ancestors. Horizontal
  motion still yields vertical scrolling to ancestor scrollables. A
  content-gated long-press grabs the whole word then extends by word. A
  secondary-only recognizer shows the toolbar on right-click. Gesture **starts**
  (long-press, multi-tap, mouse caret) require a strict hit inside a mounted
  selectable surface — the host may wrap chrome + gaps, but presses on buttons
  / empty space do not clamp onto the nearest markdown. Nearest-neighbor clamp
  remains for **extend** while an active drag crosses gaps between surfaces.
  Word boundaries come from the mounted painter's `TextPainter.getWordBoundary`
  (via `MarkdownSelectionSurface.wordBoundaryForGlobal`), with the text-based
  `wordRangeIn` heuristic as an unmounted-document fallback.
- **Soft-wrap affinity:** hit-testing captures `TextAffinity` from
  `TextPainter.getPositionForOffset` and stores it ephemerally on the controller
  (not on model `MarkdownPosition`). Handle endpoints use
  `getOffsetForCaret` with that affinity so an end handle at a wrap stays on the
  visual line under the pointer instead of snapping to the next line's start.
  Word/block granular drag commits reading-start/end affinities (downstream /
  upstream) so reverse expansion does not leave stale wrap affinities. If
  directed carets still nearly coincide while the selection paints a span,
  `selectionHandleEndpoints` falls back to visible rect extremes.
- **Edge autoscroll:** while dragging a non-collapsed selection (mouse pan, long-
  press move, or handle drag) near the **visible clip** of the host union
  (mounted selectable bodies ∩ padded viewport),
  `applyMarkdownSelectionAutoscroll` jumps the scrollable. A `Ticker` keeps
  scrolling while the pointer stays in-band and the host-union edge is not yet
  flush; it pauses on hard-stop / leave-band / arming-gate. Configure via
  `MarkdownSelectionScope.autoscroll` (default `edgeZone: 48`).
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
  Flutter `SelectionOverlay` is driven from `controller.selectionHandleEndpoints()`
  on the directed base/extent edges (types flip when reversed); handle (and
  long-press) drags call `controller.moveSelectionEdgeToGlobal(...)` and update
  the magnifier. Android long-press defers showing handles until press-end.
  Overlay creation is skipped when there's no `Overlay` host. In-flight drag
  updates stay pointer-synchronous (not deferred to a later frame).
- **Toolbar:** `ContextMenuController` + `AdaptiveTextSelectionToolbar`; default
  items are Copy (non-collapsed selection) and Select-all (`hasDocuments`).
  Expanding (body or handle drag) hides the menu; it may re-show on drag end.
  Programmatic `controller.selectAll()` / assigning a non-collapsed
  `controller.selection` sets `toolbarWanted` and starts the toolbar lifecycle
  without a gesture (same restore path as scroll remount). Public ops:
  `copySelection`, `selectAll`, `clearSelection`, `showToolbar`, `hideToolbar`.

  **Anchors (`contextMenuAnchors`):** absolute global points derived from the
  intersection of painted selection rects with the scope bounds and any
  enclosing `RenderAbstractViewport` (same idea as
  `TextSelectionToolbarAnchors.fromSelection`). Default placement:

  | Visible geometry                                                     | Anchors                                                                                                                                                                              |
  | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
  | Both directed endpoints in the clip                                  | `visible.topCenter` / `visible.bottomCenter` (Material/Cupertino prefer above when it fits)                                                                                          |
  | Exactly one endpoint in the clip                                     | Bottom-only → prefer **below** that caret when there is room; top-only → stock above that caret                                                                                      |
  | Neither mounted endpoint in the clip (mid-viewport of a large range) | Pin near the **top** of the visible region (secondary only a short offset below) so the toolbar’s below-fallback cannot sink to the host bottom                                      |
  | Intersection empty (scrolled / virtualized away)                     | Overlay removed; `MarkdownSelectionController.toolbarWanted` keeps show intent until intentional `hideToolbar` — scrolling or remounting restores the menu when paint re-enters view |

  Endpoint-in-clip checks use **mounted, non-proxied** carets
  (`selectionEndpointGlobalRect`) — handle proxies onto visible paint must not
  look like a real edge. These rules are package defaults, not a public config.
  Customize placement or hide/show policy via `contextMenuBuilder` (read
  `contextMenuAnchors` or ignore them). Prefer a future single geometry policy
  object over ad-hoc knobs if a second host needs different mid-selection chrome.

  While the menu is up, scroll / size-changed rebuilds the overlay entry so
  anchors stay live (unlike handles, which follow surface `LeaderLayer`s
  without a rebuild). Two scroll paths: a descendant `NotificationListener`
  (when the scope **wraps** the scrollable) and an ancestor
  `ScrollNotificationObserver` (e.g. `Scaffold`, when the scope is a scrollable
  **child**). Prefer wrapping the scrollable with the host so both toolbar and
  gesture hit-testing stay aligned. Framework `SelectableRegion` often avoids
  rebuilds by wrapping the menu in a `CompositedTransformFollower` tied to a
  target that scrolls with the content; a host that wraps a whole scrollable
  cannot rely on a scope-level `LayerLink` alone. Rebuilds are deferred off the
  build/layout phase (same rule as `SelectionOverlay.markNeedsBuild`) so scroll
  notifications during a list tile rebuild cannot dirty `_OverlayEntryWidget`
  mid-build. `SizeChangedLayoutNotification` only schedules geometry / overlay
  work for after the frame — reading `localToGlobal` / `RenderBox.size`
  synchronously from that callback (including the drag-time handle sync path)
  runs during `performLayout` and asserts `sizeAccessAllowed`. Secondary-tap
  freeze is cleared when the selection moves. Focus loss while the app is
  resumed clears the selection.

- **`MarkdownSelectionGroup`:** pass the same group to several controllers and at
  most one has an active selection — a new non-collapsed selection clears the
  others. `clearExternal()` clears all (call when a non-Markdown `SelectableText`/
  `SelectionArea` starts its own selection).

## Opting a `MarkdownWidget` into selection

`MarkdownWidget` is selectable only when given a `documentId` **and** a resolvable
controller (explicit `controller:` or ambient `MarkdownSelectionScope.maybeOf`);
otherwise it's inert. Prefer an **app-owned** registry (`setDocuments` /
`putDocument` with stable ids and unique reading-order `order` values) so
Select-all / extraction stay correct for unmounted bodies. The render object
also heals with `putDocument` on attach so a mounted selectable body is never
absent from the registry; that heal alone is not a substitute for explicit
registration when documents outlive their widgets (virtualized lists).

## Gotchas / known limitations

- `selectionColor` setter repaints surfaces directly and must **not**
  `notifyListeners` — it's applied during build (`didChangeDependencies`), where
  notifying would trigger `setState`. (The `formatter` setter _does_ notify.)
- Alert **title** is not selectable (body only).
- Keyboard word/line extension is **block-approximate** (a whitespace scan / jump
  to block start-end within the linearized text, not visual lines). Only
  `extendSelectionToAdjacentLine` uses real on-screen geometry (and no-ops when the
  endpoint is unmounted).
- Handle anchors refresh on selection change, scroll, and mounted-surface layout
  change (`SizeChangedLayoutNotification`). Streaming reflow with no selection
  change still relies on those notifications (or the next selection update).
- Toolbar mid-selection geometry (neither mounted endpoint in clip → top-pin;
  bottom-only endpoint → prefer below that caret; both in clip → stock
  above/below anchors; empty intersection → hide + `toolbarWanted` restore) is
  intentional package default, not a public knob. Override via
  `contextMenuBuilder` if a host needs different chrome.
- `moveSelectionEdgeToGlobal` keeps a one-character minimum while dragging
  (nudges instead of collapsing) and allows directed edges to cross; handle
  overlays follow base/extent and flip types when reversed.
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
- Do not assume `removeDocument` drops the registry entry immediately: if a surface
  is still mounted, removal waits for `detachSurface`. A later `putDocument` for the
  same id cancels the pending remove (dispose → remount race).
- A selection whose base or extent points at an unregistered document paints nothing
  via `rangeFor` (safe empty) — do not rely on `-1` ordering.
