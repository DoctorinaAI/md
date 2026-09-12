# AGENTS.md

High-signal orientation for LLMs/agents working in **`flutter_md`**. Read this
first, every time. Deep detail lives in [`docs/`](docs/) — linked per section.

`flutter_md` is a Flutter Markdown package: a hand-rolled **parser** → an
immutable **node model** → a **canvas render layer** (one `RenderBox`, no
widget-per-block) → cross-block/cross-widget **text selection**. Repo:
`DoctorinaAI/md`, package `flutter_md`, currently `0.2.0`, branch
`feat/text-selection`.

## Commands (these are the CI gates — run before you claim done)

```shell
# Tests — test/unit_test.dart is the single aggregate entrypoint CI runs.
flutter test test/unit_test.dart
flutter test --coverage --concurrency=40 test/unit_test.dart   # CI form

# Analyzer — INFO-level lints FAIL (--fatal-infos). A missing doc comment fails CI.
dart analyze --fatal-infos --fatal-warnings lib/ test/

# Format — 80 columns, strict, exactly as CI checks it:
find lib test -name "*.dart" ! -name "*.*.dart" -print0 \
  | xargs -0 dart format --set-exit-if-changed --line-length 80 -o none
# to actually format: dart format lib test example   (analysis_options pins page_width: 80)
```

Benchmarks and the example app: see [`docs/development.md`](docs/development.md).
The render benchmark runs under `flutter test` (needs `dart:ui`); parser
benchmarks run under `dart run`.

## Module map (`lib/src/`)

| Path | What | Doc |
|---|---|---|
| `parser.dart` | `MarkdownDecoder` (a `Converter<String, Markdown>`); one hand-rolled line loop, perf-tuned | [parser](docs/parser.md) |
| `nodes.dart` | `MD$*` immutable node tree, `MD$Style` bitmask, `.map()` dispatch | [parser](docs/parser.md) |
| `markdown.dart` | `Markdown` model + `Markdown.fromString(...)` entry point | [parser](docs/parser.md) |
| `theme.dart` | `MarkdownThemeData` (a `ThemeExtension`), `MarkdownTheme`; `builder`/`blockFilter`/`spanFilter` hooks | [rendering](docs/rendering.md) |
| `render.dart` | **re-export barrel** for `render/` (keeps `src/render.dart` imports working) | [rendering](docs/rendering.md) |
| `render/block_painter.dart` | `BlockPainter` framework: interfaces + mixins (`SelectableTextBlock`, `MultiPainterSelectable`, `ParagraphGestureHandler`, `SelectableFragment`) | [rendering](docs/rendering.md) |
| `render/span_builder.dart` | `paragraphFromMarkdownSpans(...)` — the public span→`TextSpan` helper | [rendering](docs/rendering.md) |
| `render/markdown_painter.dart` | `MarkdownPainter` orchestrator (`@meta.internal`): block list, layout, cached `ui.Picture`, hit-test | [rendering](docs/rendering.md) |
| `render/markdown_render_object.dart` | `MarkdownRenderObject` (`@meta.internal`) — the `RenderBox`, also a `MarkdownSelectionSurface` | [rendering](docs/rendering.md) |
| `render/blocks/*.dart` | `BlockPainter$Paragraph … $Table` — the 9 default painters | [rendering](docs/rendering.md) |
| `selection.dart` | `MarkdownSelectionController`, `MarkdownPosition/Selection`, registry, reconciliation, formatters, `markdownBlockRenderedText` | [selection](docs/selection.md) |
| `selection_scope.dart` | `MarkdownSelectionScope` — gestures, keyboard, handles, toolbar; `MarkdownSelectionGroup` | [selection](docs/selection.md) |
| `widget.dart` | `MarkdownWidget` (`LeafRenderObjectWidget`) — the public entry widget | [rendering](docs/rendering.md) |

Public API is the barrel `lib/flutter_md.dart` (`export … show …`). See
[`docs/architecture.md`](docs/architecture.md) for the full data flow.

## Hard rules (violating these breaks CI or the architecture)

1. **80-col + `--fatal-infos`.** No line > 80 chars. Every public member needs a
   `///` doc (`public_member_api_docs: true`). Infos are fatal in CI.
2. **Imports:** relative inside `lib/` (`../nodes.dart`), `package:flutter_md/…`
   in `test/`. `prefer_relative_imports` + `avoid_relative_lib_imports` enforce this.
3. **`$` is the public naming convention** for variant families: `MD$Block`,
   `MD$Span`, `BlockPainter$Paragraph`. Not a typo — keep it.
4. **`@meta.internal`** marks non-user-facing types (`MarkdownPainter`,
   `MarkdownRenderObject`). They are reachable only via `src/render.dart`, never
   in the `flutter_md.dart` `show` list. Everything else in the `show` list is
   supported public API — treat additions as permanent.
5. **One test entrypoint:** a new `test/**/foo_test.dart` must be wired into
   `test/unit_test.dart` (import + `main()` inside `group('Unit', …)`) or CI won't run it.
6. **CHANGELOG discipline:** the `version:` in `pubspec.yaml` must have a matching
   `# <version>` heading in `CHANGELOG.md` or the CI setup step fails.

## Load-bearing invariants (don't break silently)

- **Render is canvas-painter based**, not widget-per-block. One `MarkdownPainter`
  holds a `List<BlockPainter>`; blocks stack vertically (no implicit gaps — a
  `MD$Spacer` supplies them); block hit-testing is a binary search over
  `_blockOffsets` by `dy`.
- **Glyphs are cached in a `ui.Picture` keyed by size.** It is reused on repaint
  and only invalidated by `update`/`invalidateLayout`. Do not route selection or
  scroll repaints through it.
- **Selection highlight is painted OUTSIDE that cached Picture**, beneath the
  glyphs. This is why a drag/streaming update never rebuilds the glyph cache and
  why `isRepaintBoundary => controller != null`. Preserve this if you touch paint.
- **Selection is controller-anchored on immutable models**, not on render objects,
  as `(documentId, blockIndex, renderedOffset)`. So selected text survives
  `ListView` disposal (scrolled-off chat messages). A block's on-screen offset
  space **must** match `markdownBlockRenderedText(block)` (lists join items with
  `\n`, tables join cells with `\t` / rows with `\n`) — hit-testing, highlight,
  and copied text all depend on that agreement.
- **The span offset invariant:** concatenating a block's `MD$Span.text` reproduces
  its rendered text; `MD$Span.start/end` index that visible text (see caveats for
  escapes/math/links in [`docs/parser.md`](docs/parser.md)). Selection relies on it.

## Gotchas quick-reference

- `MarkdownThemeData.spanFilter` dropping **text-bearing** spans desyncs selection
  offsets (highlight stays right, copied text drifts). Avoid with selection on.
- `MarkdownSelectionController.selectionColor` setter repaints surfaces directly
  and must **not** `notifyListeners` (it's applied during build → would `setState`).
- `removeDocument` while a surface is mounted is deferred until `detachSurface`;
  `putDocument` cancels a pending remove. Unregistered selection endpoints must
  not paint via `-1` ordering — `rangeFor` returns null. Supply unique `order`
  values for co-hosted bodies.
- Alert **title** is not selectable (body only). Keyboard word/line extension is
  block-approximate. `MarkdownSelectedBlock.sourceRange` is currently always null.
- `__x__` = **underline**, not bold. Soft line breaks are preserved inside
  paragraphs. Inline `$…$` math is **opt-in** (`inlineMath: true`).
- `example/` is a separate package (`md_example`, `path: ../`).

## The docs

- [`docs/architecture.md`](docs/architecture.md) — modules, data flow, invariants, public API surface.
- [`docs/parser.md`](docs/parser.md) — parser pipeline, node model, `MD$Style`, GFM + nonstandard choices, offset invariant.
- [`docs/rendering.md`](docs/rendering.md) — render flow, the `BlockPainter` framework, **writing a custom block painter**, theme customization.
- [`docs/selection.md`](docs/selection.md) — controller-anchored selection, registry, surfaces, reconciliation, extraction, the scope widget.
- [`docs/development.md`](docs/development.md) — commands, CI pipeline, lint rules, conventions, benchmarks, layout.
