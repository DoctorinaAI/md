## 0.2.0

- **ADDED**: Cross-block and cross-widget text selection. A
  `MarkdownSelectionController` anchors the selection on the immutable model, so
  it spans multiple blocks and multiple `MarkdownWidget`s and survives list
  disposal (e.g. chat scrolling). New public API: `MarkdownSelectionController`,
  `MarkdownSelectionScope`, `MarkdownSelectionGroup`, `MarkdownPosition`,
  `MarkdownSelection`, `MarkdownDocumentRef`, `MarkdownSelectedContent`
  (+ document/block), `MarkdownSelectionFormatter` /
  `MarkdownPlainTextFormatter`, `MarkdownReconciliationPolicy`,
  `MarkdownSelectionSurface`, `markdownBlockRenderedText`, and
  `SelectableBlockPainter` / `SelectableTextBlock`.
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
- **CHANGED**: `MarkdownWidget`'s render object now draws the selection
  highlight outside the cached content `Picture` and becomes a repaint boundary
  when selectable, so selection/drag repaints do not rebuild the glyph cache.
  The highlight color is now customizable via the controller / scope.
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
