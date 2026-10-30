## Unreleased

### Selection
- **FIXED**: "Looking up a deactivated widget's ancestor is unsafe" from
  `MarkdownSelectionScope`'s controller listener. Since the desktop-menu fix in
  0.3.0 it reads `Theme.of(context)` on every clear, and a host that clears the
  selection or re-registers documents from a widget's `dispose` (a chat body
  leaving a virtualized list) notifies while the scope above that body is
  deactivated. The scope now reads the platform in `didChangeDependencies`.

## 0.3.0

> **Upgrading from 0.2.x?** See the
> [migration guide](docs/migration/0.2.x-to-0.3.x.md). Ordinary
> `MarkdownWidget` / `MarkdownSelectionScope` users need no code changes; hosts
> that implement the render / selection extension points do. **Coming from
> pub.dev 0.0.8?** 0.1.0 and 0.2.0 were never published there — read the
> [0.0.x → 0.2.x guide](docs/migration/0.0.x-to-0.2.x.md) first, then this one.

### Breaking vs 0.2.0

Source-breaking only for hosts that implement the render / selection
extension points, reach into a default block painter's fields, or read the
quote / alert model directly. Ordinary `MarkdownWidget` /
`MarkdownSelectionScope` users are unaffected.

- **REMOVED**: `BlockPainter$Quote.painter` and `BlockPainter$Alert.bodyPainter`.
  Both painters now stack nested children, so a single body `TextPainter` no
  longer exists. Read `renderedText` / `fragments` (from
  `MultiPainterSelectable`) instead.
- **CHANGED**: `BlockPainter$Quote` and `BlockPainter$Alert` mix in
  `MultiPainterSelectable` instead of `SelectableTextBlock`. Subclasses that
  overrode `selectionPainter` / `selectionOrigin` must move to `fragments`.
  Both constructors gained an optional `children:` (the nested block
  painters) and `blocks:` (the matching child models, which keep selection
  offsets in sync when a child painter exposes no selectable text); a custom
  `builder` that rebuilds them must pass both for bodies with nested blocks.
  `BlockPainter$Quote.inheritFrom` gives a nested child the theme the default
  quote uses.
- **CHANGED**: A quote / alert whose body contains a fenced block now has
  empty `spans`; its content is in the new `MD$Quote.blocks` /
  `MD$Alert.blocks`. Code that builds `BlockPainter$Quote/Alert(spans: …)` in
  a custom `MarkdownThemeData.builder`, or otherwise walks `spans`, must handle
  `blocks`. Plain quotes / alerts keep the leaf shape (`spans`, empty
  `blocks`).
- **CHANGED**: `SelectableBlockPainter` gained `positionAndAffinityForLocal`,
  `caretRectFor`, `hitsRenderedTextAt` and
  `selectionHighlightAboveCachedContent`. Custom painters built on the
  `SelectableTextBlock` / `MultiPainterSelectable` mixins inherit working
  implementations; painters that `implements SelectableBlockPainter` directly
  must add all four.
- **CHANGED**: `MarkdownSelectionSurface` gained `textDirection`,
  `hitForGlobal`, `hitsSelectableGlyphs`, `isLinkAtGlobal`, `caretRectFor`,
  `localBoxesForRange`, `hasSelectionHandleLeaders` and
  `clearSelectionHandleLayersIfLinked`. Custom surfaces must implement them.
- **CHANGED**: `MarkdownSelectionController.startAtGlobal` /
  `selectWordAtGlobal` / `selectBlockAtGlobal` ignore points outside every
  mounted surface (new `requireContainment`, default `true`) instead of
  clamping onto the nearest markdown. Pass `requireContainment: false` for the
  old clamping.
- **CHANGED**: `ParagraphGestureHandler.hitTestInlineSpanWithPointerEvent`
  returns null for a point outside the painter's box. A tap in the empty space
  before right-to-left text used to snap onto the line's last glyph and open a
  link ending it.
- **CHANGED**: `MarkdownThemeData.copyWith` returns `MarkdownThemeData` instead
  of `ThemeExtension<MarkdownThemeData>` (callers gain, overriders must narrow).
- **CHANGED**: `MarkdownRenderObject.updateSelection` takes an optional
  `markdown:`. `@meta.internal`, but `MarkdownWidget` subclasses that call it
  must now invoke it **before** `update` (see the registry fix below).
- **CHANGED**: With an `imageResolver` set, `paragraphFromMarkdownSpans` may
  emit `MarkdownImageSpan` (a `PlaceholderSpan`) children, so
  `TextPainter.plainText` holds U+FFFC where the model has alt text.
  `SelectableTextBlock.renderedText` and `SelectableFragment.length` now come
  from the model text. Lay out / paint custom painters with
  `layoutMarkdownText` / `paintMarkdownText`.
- **CHANGED**: Code spans render in `Menlo` (iOS / macOS) / `Consolas`
  (Windows) instead of the unresolvable `'monospace'`, with a fallback chain on
  every platform (see *Monospace font resolution*). Expect golden diffs there.

### Inline images & link icons

- **ADDED**: `![alt](src)` images can render as pictures, and links can carry
  an icon in front of their label (a site favicon). Opt-in through
  `MarkdownThemeData.imageResolver` — without one, images keep rendering as
  their alt text, so nothing is fetched behind the host's back (tracking
  pixels).
- **ADDED**: `MarkdownImage`, the picture interface: it reports the size of
  its slot in the line (`layout`), paints itself into it (`paint`) and calls
  `notifyListeners` when it loads, fails or animates. Implement it to control
  sources, caching and appearance; `MarkdownImageResolver` maps a
  `MarkdownImageRequest` (`kind`, `url`, `text` — the alt text or link
  label — and `title`) to one; `MarkdownImageConstraints` carries the line's width and text style.
- **ADDED**: `MarkdownProviderImage` (any Flutter `ImageProvider` — network,
  file, asset, memory or a disk-cached third-party provider; `.icon` for a
  text-sized link icon) and the ready-made `MarkdownProviderImageResolver`
  (http(s) and `data:` images, `/favicon.ico` link icons, `baseUri` for
  relative sources, swappable `imageProvider` / `faviconUri`).
- **ADDED**: `MarkdownImageSpan`, `layoutMarkdownText` and
  `paintMarkdownText` for custom block painters whose text comes from
  `paragraphFromMarkdownSpans`; a painter that keeps calling plain
  `TextPainter.layout` still lays out (a text-sized empty slot per picture).
- Selection is unchanged: a picture counts as its alt text (a link icon as
  nothing), so offsets, highlight and copied text match
  `markdownBlockRenderedText` whether or not pictures are shown; a range
  touching the alt text highlights the whole picture, and a double tap on it
  selects it.
- Pictures are owned by the rendered document: a request seen before reuses
  the loaded image (streaming rebuilds and repeated images load once), and
  images that leave the document are disposed. A size change re-lays out the
  widget; any other change only repaints it.
- A resolver (or `imageProvider` callback) that throws is reported through
  `FlutterError.reportError` and the image falls back to its alt text; the
  rest of the document still renders. A `null` result is remembered for the
  request while it stays in the document. In-page anchors (`#section`) never
  get a link icon, and `data:` image MIME types match case-insensitively.
- Keep the resolver stable (a `const` resolver's `.call`, a field or a
  top-level function): a different resolver drops and reloads every picture.
- Known limitations: a failed load is not retried while its URL stays in the
  document; an animated image re-records the document's cached picture on
  every frame; a link icon that fails to load collapses, shifting its label
  once. Keyboard character steps walk an image's alt text one code unit at a
  time, so an endpoint can sit inside it — the whole picture highlights while
  the copy holds part of the alt text.

### Syntax highlighting
- **FIXED**: Grammar rules marked `greedy` (Prism's semantics) now match
  across tokens claimed by earlier rules. A comment marker inside a string
  (`"a # b"` in Python / Bash, `'http://…'` in JS) no longer turns the rest
  of the line into a comment, and Ruby / Elixir `#{…}` interpolation is
  highlighted inside strings. Highlighting stays lossless.
- **FIXED**: Tokenizing is linear in the number of tokens: each rule builds
  its result in one pass instead of splicing per match. A 10,000-line C block
  went from ~7 s to ~0.3 s; typical blocks are a little faster too. A greedy
  rule whose matches keep starting inside other tokens falls back to plain
  matching after a bounded number of tries.
- **FIXED**: `HighlightThemes.githubDark` / `githubLight` color diffs:
  inserted and deleted lines get GitHub's green / red, hunk headers (`coord`)
  the function color. Previously a diff rendered uncolored.

### Parser
- **FIXED**: List items at uneven indents are kept: in `- a` / `    - b` /
  `  - c`, `b` was dropped (the shallower `c` replaced `a`'s children instead
  of joining them).

### Quote / alert nested fenced code
- **FIXED**: Fenced code (` ```lang ` / `~~~`) inside a blockquote or GitHub
  alert is re-parsed as nested `MD$Code` in `MD$Quote.blocks` /
  `MD$Alert.blocks`, instead of being consumed as inline monospace by backtick
  pairing (` `` ` + monospace + ` `` `). The fenced code keeps its
  indentation, fences inside nested quotes (`> > ```…`) are nested code too,
  and a fence may follow the `>` after up to three spaces or a tab (lines
  inside the code keep their indentation verbatim). Blank `>` lines around an
  alert body add no extra gap.
- **ADDED**: Optional `blocks` on `MD$Quote` / `MD$Alert` (empty for leaf
  inline bodies). Render, `markdownBlockRenderedText` and `Markdown.text` walk
  nested children when present (`Markdown.text` yields the children's span
  text, not raw markup). Nested children route through
  `MarkdownThemeData.builder` like top-level blocks, so a host that replaces
  the code painter (a fence with a copy button, say) gets it inside `> …` too.
  Prose nested inside a quote (paragraphs / lists / headings beside a fence)
  uses `quoteStyle`; code / table chrome keeps the document theme. Links open
  on tap in every nested child kind, in either text direction.
- **FIXED**: A quote / alert whose nested table overflows still paints, and a
  host-supplied non-selectable nested painter keeps selection offsets in sync
  with `markdownBlockRenderedText`.

### Glyph-tight hit testing
- **CHANGED**: Hover I-beam and link hit-testing use rendered **line/glyph
  boxes**, not the full max-width layout of a paragraph. Empty horizontal
  gutter beside a short line (quote and alert bodies included) is no longer
  I-beam / click-to-open. Glyph boxes are cached per `TextPainter` layout, so
  hovering stays cheap over long fenced code blocks.
- **CHANGED**: Gesture *starts* (`hitsSelectableContent`) stay **surface-
  bounds**. A press inside the document or bubble arms text selection.
  Drag-extend may still clamp outside glyphs.
- **CHANGED**: Mouse single-click that misses selectable content while a
  non-collapsed range is active clears the selection, instead of leaving
  the old range.
- **ADDED**: `SelectableBlockPainter.hitsRenderedTextAt`,
  `MarkdownSelectionSurface.hitsSelectableGlyphs`, and
  `MarkdownSelectionController.hitsSelectableGlyphs`.

### Selection host gates
- **ADDED**: `MarkdownSelectionScope.canStartSelectionAt` — optional host gate
  so enclosing UIs can refuse selection starts on chrome (links, code headers)
  without the scope claiming the pointer. A refusal also un-arms the drag (the
  recognizers still join the arena while a range is live, so a chrome tap can
  dismiss it), so a long press / drag on refused chrome neither extends the
  active selection nor shows the toolbar.
- **ADDED**: `MarkdownSelectionScope.enableTouchGestures` — when false, touch /
  stylus / trackpad selection recognizers stay off; mouse multi-click, handles,
  toolbar, and keyboard remain. Focus loss also does not clear the range (host
  viewport may steal focus).
- **ADDED**: `MarkdownSelectionScope.enableTouchConsecutiveTaps` — when false
  (with `enableTouchGestures` true), touch long-press → word → drag-extend
  still arms, but touch multi-tap / horizontal-drag selection does not. Chat
  hosts use this so taps stay with the viewport while continuous text entry
  works. Focus loss also does not clear the range in that mode.
- **ADDED**: `MarkdownSelectionScope.ownsSelectionChrome` — optional host gate
  so only the scope that owns the selection’s document paints handles/toolbar
  when several scopes share one controller (chat per-body mounts). A
  non-owning or disabled sibling clears only handle leaders that reference its
  own `LayerLink`s, and removes its own adaptive toolbar when ownership moves
  away; `toolbarWanted` is left for the owning scope to restore on settle.
- **ADDED**: `MarkdownSelectionSurface.hasSelectionHandleLeaders`,
  `clearSelectionHandleLayersIfLinked`, and
  `MarkdownSelectionScopeState.selectionHandleLeadersAttached` for observing
  coherent handle-leader attachment across multi-scope hosts.
- **CHANGED**: Flipping `enabled` from false → true with an existing
  non-collapsed range restores handles; when `toolbarWanted` is set, restores
  the toolbar. While disabled, the scope stays inert for chrome (no toolbar /
  handles) but keeps `toolbarWanted` for that restore path. Disabling the
  scope mid-drag aborts the drag.

### Dynamic cursor resolution & span bounding boxes
- **ADDED**: `MarkdownThemeData.cursorResolver` and
  `MarkdownWidget.cursorResolver` (`MarkdownCursorResolver`) — unopinionated
  hook to dynamically resolve hover mouse cursors per local offset, block
  index, and block model, falling back to default link/text/defer cursors when
  returning null. The hover cursor survives rebuilds that pass a new resolver
  closure and re-resolves when the theme or resolver changes.
- **ADDED**: `MarkdownSelectionSurface.localBoxesForRange` (backed by the
  internal `MarkdownPainter.localBoxesForRange`) — fast query returning
  content-local bounding boxes for an arbitrary character range within a block,
  directly from cached block painters without re-layout.

### Registry / multi-body selection
- **FIXED**: `removeDocument` defers while a surface for that id is mounted
  and flushes on `detachSurface`; a later `putDocument` cancels the pending
  remove. Parent `State.dispose` can run before child detach — eager remove
  left hittable surfaces with no registry entry (`rangeFor` / ordering broken).
- **FIXED**: `rangeFor` and endpoint ordering ignore unregistered document ids
  instead of treating them as index `-1` (which painted every body from the
  start of the registry through the other endpoint).
- **CHANGED**: `MarkdownRenderObject` heals with `putDocument` on attach /
  when the controller is wired while already attached, so a mounted selectable
  surface is never missing from the registry. Prefer explicit app registration
  for unmounted docs and unique reading-order `order` values.
- **FIXED**: Recycling a `MarkdownWidget` element onto a different `documentId`
  (a virtualized chat list reusing a slot) overwrote the **outgoing** document's
  registry model with the incoming body. `MarkdownWidget` now rewires the
  selection registry before pushing the new model, and
  `MarkdownRenderObject.updateSelection` takes the incoming `markdown:` so the
  heal lands on the right id.
- **FIXED**: `putDocument` without an explicit `order` appended at `_docs.length`
  which sorted **ahead** of sparse explicit orders (chat hosts key `order` on
  the message id), so a healed body jumped to the front of the conversation and
  reversed extracted text. It now sorts after every registered document.
- **FIXED**: Documents sharing an `order` could swap places on any re-sort
  (`List.sort` is not stable), silently reversing extracted text. Ties now break
  on registration sequence.
- **FIXED**: `MarkdownSelectionScope.onSelectionChanged` fired synchronously
  from inside build / layout — a streaming `putDocument` reconciling the range
  away (from `MarkdownWidget.updateRenderObject`) or a deferred
  `removeDocument` flushing from `RenderObject.detach` threw
  "setState() called during build" in any host that rebuilds from the callback.
  Delivery is now coalesced to the end of the frame in those phases.
- **FIXED**: `selectAll` skips documents with no blocks, so an empty streaming
  message no longer turns it into a no-op.
- **FIXED**: Reconciling a range onto a document with a duplicated block keeps
  the copy nearest the old position.
- **FIXED**: A drag update that lands on the current position no longer
  notifies listeners.

### Selection chrome (SelectionArea parity)
- **ADDED**: Read-only selection chrome on the controller /
  `MarkdownSelectionScope` path brought up to Flutter `SelectableRegion` /
  `SelectionArea` quality without remounting SelectionArea:
  - Content-gated touch `TapAndHorizontalDragGestureRecognizer` + long-press
    (consecutive taps, no `DoubleTapGestureRecognizer` arena delay); mouse
    `TapAndPanGestureRecognizer`.
  - Gesture **starts** require a hit on mounted selectable markdown (chrome /
    empty space do not nearest-neighbor clamp); clamp remains for **extend**
    across gaps.
  - Soft-wrap affinity on handles; directed base/extent edges with reverse
    handle types; coincident-caret separation; handle proxies when an endpoint
    surface unmounts (virtualization), on the correct end for reversed
    selections too.
  - Native `SelectionOverlay` handles + magnifier on touch; LeaderLayer follow
    across scroll / multi-widget hosts.
  - Keyboard Copy / Select-all / Shift-extend / Esc; adaptive Copy / Select-all
    toolbar with live re-anchoring.
  - Word / block granular multi-tap and long-press; link hand cursor / I-beam on
    selectable content.
- **ADDED**: `MarkdownSelectionController.isSelectionReversed` (base after
  extent in reading order), `selectionEndpointGlobalRect({base})` (global
  caret rect of a mounted endpoint, null when unmounted, no proxying),
  `selectionEndpointOverlaps(rect, {base})` and
  `anySelectionEndpointOverlaps(rect)` (whether a mounted endpoint caret
  intersects a global rect), and `toolbarWanted` (the toolbar-restore intent;
  reset when the registry drops or collapses the range).
- **CHANGED**: Toolbar hides while expanding (body or handle drag) and may
  re-show on drag end; anchors recompute on selection change, host/ancestor
  scroll, and mounted-surface layout change. Scroll-driven restores are
  skipped while a drag is active.
- **CHANGED**: Toolbar placement — both endpoints in clip use stock
  above-preferring anchors; **bottom-only** endpoint prefers below that caret;
  neither endpoint in clip (tall mid-viewport) top-pins so the below-fallback
  cannot sink to the host bottom; empty intersection hides the overlay while
  `toolbarWanted` restores on scroll-back / remount.
- **CHANGED**: Desktop selection toolbar parity with stock Flutter:
  - On desktop (`macOS`, `Linux`, `Windows`), mouse drags, double/triple clicks,
    keyboard shortcuts (`Cmd/Ctrl+A`), and programmatic selection updates
    do not pop up the toolbar.
  - Right-click on desktop shows the context toolbar at the click coordinates
    without mutating the active selection (no select-word / caret collapse).
  - Desktop context menu preserves its right-click anchor when triggering
    actions such as "Select all", rather than jumping to selection endpoints.
  - Desktop context menu dismisses immediately upon scroll, but survives
    streamed updates, sibling updates and resizes, with or without a
    selection.
  - On mobile (`Android`, `iOS`), touch gestures and programmatic selection
    (`selectAll`, `selection = ...`) continue to present the adaptive toolbar
    and handles with action items.
- **FIXED**: Selection highlight stays outside the glyph `Picture` cache —
  under glyphs by default (sharp text), with a second pass **above** opaque
  chrome (`selectionHighlightAboveCachedContent`) for code fences, table zebra
  rows, and inline monospace / highlight backgrounds.
- **FIXED**: Focus loss does not clear selection while a pointer drag is active
  (list rebuilds during autoscroll); geometry walks defer off `performLayout`.
- **FIXED**: `Esc` with no selection is no longer swallowed by the scope, so it
  reaches ancestors (closing a dialog, say).

### Edge autoscroll while selecting
- **ADDED**: Edge-zone autoscroll while dragging (body / handle / long-press)
  near the padded viewport — host-union hard-stop, direction arming gate,
  past-viewport max velocity while the union still allows that direction
  (`MarkdownSelectionScope.autoscroll`, `MarkdownSelectionAutoscrollConfig`
  with `copyWith` / `==`, default `edgeZone: 48`). Edge bands are capped at
  half the viewport; speed is time-based, not tied to the pointer event rate;
  a vertical edge drag only drives a vertical `Scrollable`; pointer cancel and
  long-press cancel stop it. The scroll surface is resolved once per drag.
- **ADDED**: `MarkdownAutoscrollTarget` — the scroll surface autoscroll drives,
  behind three members (`viewport`, `canScroll`, `applyScrollDelta`). Deltas are
  **screen-space content movement** (positive moves content up), never scroll
  offsets, so reverse axes and inverted anchors are the adapter's problem.
- **ADDED**: `MarkdownScrollableAutoscrollTarget` — the built-in sliver adapter
  (`ScrollableState` / `ScrollPosition`), used when no resolver is configured.
  Handles `AxisDirection.up` / `.left` sign flipping.
- **ADDED**: `MarkdownSelectionAutoscrollConfig.targetResolver`
  (`MarkdownAutoscrollTargetResolver` + `MarkdownAutoscrollRequest`) so a host
  with its own scroll implementation — an anchored chat viewport, a `RenderBox`
  that positions children itself, a transform canvas — can be driven without a
  `Scrollable` anywhere in the tree. Plus `MarkdownCallbackAutoscrollTarget` and
  `MarkdownAutoscrollViewport` (global bounds + band inset) for closure hosts.
- **ADDED**: `MarkdownSelectionAutoscrollConfig.useHostUnionGate` (default
  `true`). Turn it off when the markdown bodies **are** the scrolling content
  and the host builds only what is visible: such a host's mounted union is
  barely larger than the viewport, so the gate would veto a drag that should
  keep paging through history. The target's `canScroll` and the delta it
  reports applying are then the only stops.

### Layout
- **FIXED**: `MarkdownWidget` reports its intrinsic height and max intrinsic
  width, so `IntrinsicHeight` (and similar) no longer collapses it to 0.
- **FIXED**: A fenced code block too narrow for its padding is inert for
  selection, so `selectAll` at tiny widths no longer crashes, and no longer
  throws `TextPainter.paint called when text geometry was not yet calculated`
  while painting (at widget widths of a few dozen pixels, less inside a quote
  or alert).

### Right-to-left layout
- **FIXED**: With `MarkdownThemeData.textDirection` set to
  `TextDirection.rtl`, blocks were still laid out left-to-right: paragraphs
  and headings sat against the left edge, list bullets, quote bars and the
  alert accent bar were on the left, and table columns ran left to right.
  Blocks now mirror: text aligns to the right edge, bullets and bars sit on
  the right, and the first table column is on the right (unaligned data
  cells start on the right; explicit `:--` / `--:` alignment stays physical).
  Link taps, hit testing and text selection follow the mirrored positions,
  under tight and min-width constraints too. Left-to-right layout is
  unchanged.
- **FIXED**: Selection handles on right-to-left text sit at the logical start
  (right edge) and end (left edge) of the selection. Each handle follows the
  `textDirection` of the document it sits on, not the ambient
  `Directionality`: the two can differ, and one selection can span documents
  of both directions. Proxy handles for a scrolled-off edge land on the
  reading start / end of the visible selection in either direction.
- **FIXED**: A table too wide to fit overflows past its end edge in either
  direction, so the columns read first stay in view (to the left of the
  widget for right-to-left text).
- **FIXED**: Link taps inside quotes account for the quote's indent.
- **CHANGED**: Under tight constraints (for example a fixed-width chat
  bubble), right-to-left content aligns to the full width, like `Text`. Under
  loose constraints the widget still sizes to its content.
- **CHANGED**: Fenced code blocks always render left-to-right, even in
  right-to-left documents.
- **ADDED**: `ParagraphGestureHandler.hitTestInlineSpanWithPointerEvent` takes
  an optional `origin`, for painters whose text is not painted at the block
  origin.
- **FIXED**: A dry layout at other constraints, made after the real layout,
  left hit testing, highlights and link taps at the measured positions while
  the glyphs stayed put. The real layout is now restored after measuring.

### Monospace font resolution
- **FIXED**: Inline `` `code` `` and fenced blocks pick a monospace family the
  host platform can actually resolve. Flutter hands the family straight to the
  platform font manager, and CoreText (iOS / macOS) and DirectWrite (Windows)
  do not know the CSS generic `'monospace'` — code silently rendered in the
  proportional body face there. Those two now get `Menlo` / `Consolas`.
  **Android, Fuchsia, Linux and web keep `'monospace'`**, so the primary face
  there is unchanged. Note that on web it is unchanged but still wrong:
  CanvasKit / skwasm reach no system fonts, so no family name resolves there
  and code has always rendered in the proportional default. Bundling a
  monospace asset and pointing `monospaceFontFamily` at it is the only fix,
  and that is a host decision.
- **CHANGED**: code spans now carry a `fontFamilyFallback` on every platform:
  the monospace chain followed by whatever `textStyle` already carried. A
  monospace face covers Latin and little else, so the body face's chain is
  appended rather than replaced — a host's CJK / emoji coverage keeps working
  inside `` `code` `` and fenced blocks.
- **ADDED**: `MarkdownThemeData.monospaceFontFamily` /
  `monospaceFontFamilyFallback` to pin a bundled face. Both default to the
  platform-resolved chain above and are resolved once, in the constructor. One
  knob covers both inline `` `code` `` and fenced blocks — there was previously
  no supported way to change the fenced-block face at all: `BlockPainter$Code`
  built its style in a static method reading a global, so even overriding
  `textStyleFor` moved inline code only. An empty fallback list means "no
  monospace fallbacks", not "unset" — `textStyle`'s own chain still applies.
- **CHANGED**: `MarkdownThemeData.mergeTheme` resolves the default face from
  `ThemeData.platform` rather than the global `defaultTargetPlatform`, so an
  app that adapts its Material theme to another platform gets that platform's
  face. `ThemeData.platform` defaults to `defaultTargetPlatform`, so this only
  moves for an app that deliberately overrode it.

## 0.2.0

> **Upgrading from 0.0.x?** See the
> [migration guide](docs/migration/0.0.x-to-0.2.x.md). 0.2.x is almost entirely
> backward compatible — the only required code change is a new `alert` branch
> for direct `MD$Block.map` / `switch` callers.

- **ADDED**: Opt-in, dependency-free syntax highlighting for fenced code blocks
  (65+ languages, GitHub light/dark themes). Assign a `SyntaxHighlighter` to the
  new `MarkdownThemeData.highlighter` field; the default (unset) renders code as
  plain monospace, so existing usage is unchanged. New public API on
  `package:flutter_md/highlight.dart`: `SyntaxHighlighter`, `MarkdownHighlighter`,
  `CodeHighlightTheme`, `Grammar`, `GrammarToken`, `compileHighlightPattern`
  (`SyntaxHighlighter` / `CodeHighlightTheme` are also re-exported from the main
  entrypoint). Each language is its own library
  (`package:flutter_md/highlight/<lang>.dart`, e.g. `HighlightDart.grammar`) with
  no central registry, so importing one never references the others and unused
  grammars tree-shake away — a Dart-only app adds ~0 beyond the engine; all 65
  add ~62 KB gzipped. `HighlightThemes.githubDark` / `githubLight`
  (`highlight/themes.dart`) provide ready themes; `allHighlightLanguages`
  (`highlight/all.dart`) is a convenience registry of every grammar for
  demos/tooling (it references all languages, so unused ones can no longer
  tree-shake away). The highlighter only partitions text — never edits it — so
  selection and copy stay aligned. Grammars are generated by
  `tool/highlight_codegen` (adapted from Prism, MIT).
- **ADDED**: Cross-block and cross-widget text selection. A
  `MarkdownSelectionController` anchors the selection on the immutable model, so
  it spans multiple blocks and multiple `MarkdownWidget`s and survives list
  disposal (e.g. chat scrolling). New public API: `MarkdownSelectionController`,
  `MarkdownSelectionScope`, `MarkdownSelectionGroup`, `MarkdownPosition`,
  `MarkdownSelection`, `MarkdownDocumentRef`, `MarkdownSelectedContent`
  (+ document/block), `MarkdownSelectionFormatter` /
  `MarkdownPlainTextFormatter` / `MarkdownMarkupFormatter`,
  `MarkdownReconciliationPolicy`, `MarkdownSelectionSurface`,
  `markdownBlockRenderedText`, and
  `SelectableBlockPainter` / `SelectableTextBlock`.
- **ADDED**: `StreamingMarkdownParser`, an incremental parser for streaming
  sources such as LLM token output. It freezes completed blocks (a block ends at
  a blank line, outside any open code fence) so only the still-growing tail is
  re-parsed as tokens arrive — turning the `O(N²)` cost of re-parsing the whole
  buffer on every token into roughly `O(tail)` (3–14× faster on a full message
  stream in `benchmark/streaming_benchmark.dart`). `parser.add(chunk)` returns
  the growing `Markdown`, always identical block-for-block to
  `Markdown.fromString(everythingSoFar)`, and a `Stream<String>.toMarkdown()`
  extension wires it into a stream transform. Pass a configured `MarkdownDecoder`
  (e.g. `inlineMath: true`) to match `Markdown.fromString`. The batch
  `MarkdownDecoder` hot path is byte-for-byte unchanged.
- **ADDED**: `MarkdownMarkupFormatter`, a built-in "Copy as Markdown" formatter.
  Pass it to `getText()` (or set `controller.formatter`) to reconstruct Markdown
  structure on copy — heading `#`s, nested list markers with task checkboxes,
  blockquote/alert `>` prefixes, fenced code and pipe tables — for blocks the
  selection covers in full; partially-selected boundary blocks fall back to the
  plain sliced text so nothing outside the selection is emitted. The default
  copy behaviour is unchanged (`MarkdownPlainTextFormatter`).
- **ADDED**: `MarkdownWidget` gains optional `documentId` and `controller`
  parameters (resolved from the ambient scope). Backward compatible: a widget
  with no `documentId` is inert.
- **ADDED**: Lists and tables are now interactively selectable. A new
  `MultiPainterSelectable` mixin (+ `SelectableFragment`) maps pointer positions
  and highlight boxes across the many `TextPainter`s of a list's items or a
  table's cells, so a drag can start or end inside a list item or table cell and
  the copied text keeps the `\n` / `\t` separators of `markdownBlockRenderedText`.
- **ADDED**: Keyboard shortcuts and a context toolbar on `MarkdownSelectionScope`,
  mirroring `SelectableRegion`/`SelectableText`. When focused: `Ctrl/Cmd+C`
  copies, `Ctrl/Cmd+A` selects all, `Shift`+arrows extend by character / word /
  line / document (and vertically by geometry), `Esc` clears. Right-click
  (desktop) / long-press (mobile) shows an adaptive Copy / Select-all toolbar.
  The scope is now a `StatefulWidget` with a public `MarkdownSelectionScopeState`
  (`copySelection` / `selectAll` / `clearSelection` / `showToolbar` /
  `hideToolbar` / `contextMenuButtonItems` / `contextMenuAnchors`). New
  customization params: `focusNode`, `enabled`, `selectionColor`,
  `contextMenuBuilder`, `magnifierConfiguration`, `selectionControls`,
  `onSelectionChanged`. New controller ops: `selectionColor`,
  `globalSelectionRects`, `moveSelectionEdgeToGlobal`, and the
  `extendSelectionBy*` family; `MarkdownPosition.copyWith`.
- **ADDED**: Native selection handles and a magnifier on touch platforms,
  driven by Flutter's `SelectionOverlay`. Selection endpoints push
  `LeaderLayer`s from the render objects so the handles follow the content as it
  scrolls (and across multiple `MarkdownWidget`s); dragging a handle adjusts the
  selection and shows the platform magnifier. Handles/magnifier respect the
  platform (`selectionControls`, `magnifierConfiguration`) and are absent on
  desktop, matching `SelectableText`. New surface geometry:
  `localSelectionRects`, `setSelectionHandleLayers`, `repaintSelection`, and
  `MarkdownSelectionController.selectionHandleEndpoints` /
  `MarkdownHandleEndpoints`.
- **ADDED**: Word- and block-granular selection gestures. Double-click/tap
  selects the word under the pointer, triple-click/tap selects the whole block,
  a single click collapses (clears) the selection, and `Shift`-click extends it.
  Dragging after a double/triple click keeps word/block granularity; a touch
  long-press grabs the whole word (then extends by word), and a touch
  double-tap selects the word and pops the toolbar. Word boundaries use the
  platform word segmentation (`TextPainter.getWordBoundary`), so double-click
  keeps intra-word punctuation like apostrophes (`can't`). New controller ops:
  `selectWordAtGlobal`, `selectBlockAtGlobal`, `wordSelectionAt`,
  `blockSelectionAt`, `extendSelectionGranular`, and `wordRangeIn`; new surface
  geometry `MarkdownSelectionSurface.wordBoundaryForGlobal`.
- **ADDED**: Mouse cursor feedback — a `MarkdownWidget` shows the click (hand)
  cursor over actionable links, the text (I-beam) cursor while it participates
  in a selection controller, and otherwise the default cursor.
- **CHANGED**: `MarkdownWidget`'s render object now draws the selection
  highlight outside the cached content `Picture` and becomes a repaint boundary
  when selectable, so selection/drag repaints do not rebuild the glyph cache.
  The highlight color is now customizable via the controller / scope. The
  highlight is painted on top of (rather than beneath) the glyphs, so a
  translucent selection stays visible over opaque backgrounds — code fences,
  `inline code`, and `==marked==` spans.
- **EXAMPLE**: Reworked the demo tabs — a longer, richer chat (tables, code,
  nested/task lists, alerts, math, token-by-token streaming with a typing
  indicator, Select-all/Clear) and a Selection tab that spans every block type.

## 0.1.0

- **ADDED**: GitHub-style alert blocks (`> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`,
  `> [!WARNING]`, `> [!CAUTION]`) via the new `MD$Alert` block and `MD$AlertType`.
- **ADDED**: GitHub task-list items (`- [ ]` / `- [x]`) via `MD$ListItem.checked`
  and `MD$ListItem.isTask`, rendered with a checkbox.
- **ADDED**: Table column alignment (`:---`, `:--:`, `---:`) captured on
  `MD$Table.alignments` and applied when rendering.
- **ADDED**: `linkStyle` on `MarkdownThemeData` to customize link text styling
  (thanks @inamhusain, #22).
- **ADDED**: Per-type alert accent colors via `MarkdownThemeData.alertColors`
  and `alertColorFor`.
- **ADDED**: Opt-in `$...$` inline LaTeX math conversion to Unicode, **disabled
  by default**. Enable with `MarkdownDecoder(inlineMath: true)` or
  `Markdown.fromString(text, inlineMath: true)`. Supports LaTeX commands
  (`\alpha`, `\rightarrow`, ...), superscripts/subscripts (`x^2`, `H_2O`,
  `x^{10}`), is code-span and code-block safe, and preserves currency (`$5`).
  The command table is configurable via `mathReplacements` (extend the
  exported `kMarkdownMathCommands`). Originally proposed in #21 by
  @ibragimov05.
- **FIXED**: `\$` is now a recognized backslash escape, producing a literal
  dollar sign (and opting a `$...$` run out of math conversion).
- **CHANGED**: Thematic breaks now support `***` and `___` (and spaced variants
  like `- - -`), and no longer greedily consume text after `---`.
- **CHANGED**: `~~~` fenced code blocks are now recognized in addition to ` ``` `.
- **FIXED**: Emphasis no longer leaks to the end of the line for stray or
  unterminated markers (e.g. `5 * 6 = 30`, `**bold never closed`).
- **FIXED**: Intraword underscores are no longer treated as emphasis
  (e.g. `snake_case`, `object_id` are preserved).
- **FIXED**: ATX headings require a space after `#`; `#hashtag` and 7+ `#`
  are no longer headings, and trailing `#` sequences are stripped.
- **FIXED**: Emphasis surrounding a link/image is now merged onto the link span.
- **FIXED**: Link/image targets support `<url>` and single-quoted titles.
- **FIXED**: `MarkdownThemeData.copyWith` no longer drops `builder` and `onLinkTap`.
- **BREAKING**: `MD$Block.map`/`maybeMap` gained an `alert` branch for the new
  `MD$Alert` block type.
- **PERFORMANCE**: Rewrote the parser hot path — a single-span fast path for
  plain text, first-code-unit guards that keep regexes off paragraph lines,
  hand-rolled list-line and link-target parsing (removing per-line / per-link
  `RegExp` allocation), lazy link-extraction gated on `[`, and a range-copy
  escape rebuild (no more per-character hash-set lookups). Together with math
  now being opt-in, the default parse path is roughly **45% faster** across
  representative workloads (links −68%, lists −61%, escapes −68%). Output is
  byte-identical, guarded by a golden snapshot test.
- **TESTS**: Added a golden characterization snapshot, a corner-case regression
  suite, span-offset invariants, and unit tests for the node model, theme, and
  widget; wired every test file into `test/unit_test.dart` so CI runs the full
  suite (**370+ tests**, previously only a fraction ran). `parser.dart`,
  `nodes.dart`, `markdown.dart`, `theme.dart`, and `widget.dart` are now at
  ~100% line coverage.
- **ADDED**: `benchmark/parser_benchmark.dart` (a multi-scenario
  `benchmark_harness` suite) and `benchmark/compare.dart` (a low-noise
  before/after comparison tool).
- **DOCS**: Documented alerts, task lists, table alignment, thematic-break
  variants, and opt-in inline math in the README.

## 0.0.8

- **CHANGED**: New table render
- **FIXED**: Invalidate and relayout render object after system fonts changed.

## 0.0.7

- **FIXED**: Preserved indentation on line breaks within list items [#4].
- **FIXED**: Inline code no longer processes inner Markdown syntax [#10].
- **CHANGED**: Improved theme support.
- **ADDED**: Dark mode support in the example app.

## 0.0.6

- **FIXED**: Fixed escaping of special characters. [#6]

## 0.0.5

- **FIXED**: Fixed parsing url such as `[text](https://domain.com/path(with)brackets)`.

## 0.0.4

- **CHANGED**: Improved link tap handling.

## 0.0.3

- **FIXED**: Links inside lists now work correctly.

## 0.0.2

- **ADDED**: All field in `MarkdownThemeData()` are now optional.
- **ADDED**: `MarkdownThemeData{}.headingStyleFor` method to customize heading styles.
- **FIXED**: Remove clipping for canvas. Fixes one line text trim at browsers.
- **FIXED**: Correctly apply styles to text in blocks.

## 0.0.1

- **ADDED**: Initial release with basic functionality.
