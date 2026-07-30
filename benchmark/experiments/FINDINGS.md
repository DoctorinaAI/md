# Selection spikes — Phase 1 findings

Throwaway experiments for issue #25 (cross-block + cross-widget text selection).
All headless spikes are `flutter test`-driven and pass (16 tests). S6 is an
interactive app to run on-device. Nothing here is in `lib/` or `test/`, so CI
(format / analyze / `unit_test.dart`) is untouched and still green (371 tests).

Run: `flutter test benchmark/experiments/` · `flutter test benchmark/render_benchmark.dart`

## What each spike established

| Spike | Result |
|-------|--------|
| **S1** stock `SelectionArea` | GLUE confirmed — adjacent selectables concatenate with **no separator** (`AlphaBravoCharlie`). On disposal, `onSelectionChanged` does **not** re-fire → the app's selection value goes stale with no retrieval path. |
| **S2** custom delegate | Separators work **only** for selectables that register directly (a `Column`). A **`ListView` interposes its own private `_ScrollableSelectionContainerDelegate`** (scrollable.dart:1157) → a delegate above it sees one pre-glued child and is powerless. `Text` also wraps itself in a `SelectionContainer`, and a dying child yields `null`, so you must **cache content while alive**. Screen-Y snapshot keys **collide on reflow** (remove-middle → wrong text). ⇒ pure-delegate route is a dead end for chat. |
| **S3** canvas `Selectable` | A single `RenderBox` with `Selectable`+`SelectionRegistrant` maps a drag to **rendered-text** offsets across internal blocks, paints the highlight under glyphs, extracts text **with separators natively** (`Heading\nBody paragraph\nThird line`), and stays one `RenderBox`. Gotcha: guard `markNeedsPaint` against post-dispose callbacks. |
| **S4** logical controller | Selection as logical anchors `(docId, blockIndex, renderedOffset)` over the immutable model → extraction is **mount-independent** (disposal survival is free). Append-only streaming keeps the anchor via a prefix fast-path; **index-only anchors break on front/mid insert** (needs a stable id or content-anchored remap). Screen-order comparator handles vertical + horizontal + **RTL**. Non-text blocks (spacer/divider) occupy indices and must be skipped. |
| **S5** cross-widget topology | Recommended topology: `MarkdownSelectionScope(controller)` → a normal `ListView.builder` of message widgets that register as **surfaces**. Selection spans multiple widgets and **survives disposal** (`before == after` after scroll-off). **No `SelectableRegion`** → the single-child `add` assert is a non-issue. |
| **S7** caching | A 30-frame selection drag rebuilt the content `ui.Picture` **exactly once** (overlay drawn outside it). Content/size changes do rebuild. `isRepaintBoundary => true` **isolates** repaint to the changed widget (neighbour did not repaint). |
| **S6** platforms | Interactive app (`example/lib/experiments/s6_platforms.dart`) — **run on device** to judge touch handles, magnifier, native menus, keyboard, and link-tap-vs-drag arena. Headless mechanics already covered by S1–S5,S7. |

## Render benchmark (relative, headless — `benchmark/.render_baseline.txt`)

| tier | µs/op | note |
|------|-------|------|
| layout_large | ~6400 | full layout of a 50-block doc |
| paint_miss | ~6800 | fresh painter: layout + records Picture |
| **paint_hit** | **~41** | same painter+size → reuses Picture (**~160× cheaper**) |
| stream_append | ~5700 | `update()` + relayout |
| scroll_frame | ~2900 | wall time per drag+pump (noisy) |

The ~160× cache payoff is why the highlight **must** be drawn outside the cached
Picture. (A `selection_drag` tier asserting the S7 zero-rebuild invariant is
added once the overlay lands in `lib/`.)

## Decisions for Phase 2

1. **Substrate → keep canvas + custom `Selectable`/controller.** S3+S5+S7 confirm
   it meets every requirement while preserving the Picture cache and keeping
   `MarkdownWidget` a `LeafRenderObjectWidget` (so the single-RenderBox tests
   survive). Stock widgets+`SelectionArea` fail glue + disposal (S1/S2).
2. **Cross-widget → scope-owned controller, not `SelectableRegion`.** (S2/S5.)
3. **Repaint → `isRepaintBoundary => true` + highlight overlay outside the
   Picture; `alwaysNeedsCompositing` when handle `LeaderLayer`s are pushed.** (S7.)
4. **Model identity → OPEN.** index + append-fast-path covers streaming append
   (dominant chat case) but breaks on front/mid inserts (S4). Options: (a) accept
   index+clamp for v1; (b) add a stable id to `MD$Block` (`nodes.dart`); (c)
   content-anchored remap. **Needs a decision.**
5. **Separator / spacer policy → OPEN.** block separator (`\n`?), document
   separator (`\n\n`?), table cell separator (`\t`?), and whether spacer/divider
   contribute to copied text. **Needs a decision.**
