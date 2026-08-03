# Parser & node model

Files: `lib/src/parser.dart`, `lib/src/nodes.dart`, `lib/src/markdown.dart`.
The parser is stable, hot-path-optimized ground — behavior is locked by
`test/parser/**` (especially `regression_test.dart`). Preserve edge semantics.

## Entry points

Three ways from `String` to `Markdown`:

```dart
Markdown.fromString(src);                       // convenience factory; inlineMath: false
markdownDecoder.convert(src);                   // shared const MarkdownDecoder()
const MarkdownDecoder(inlineMath: true).convert(src);
```

- `MarkdownDecoder extends Converter<String, Markdown>` — `const
  MarkdownDecoder({bool inlineMath = false, Map<String, String>? mathReplacements})`.
  The whole parse is one `convert(String)` method: a hand-rolled line loop,
  branched on the **first code unit** of each line so plain prose runs zero
  regexes. Being a `dart:convert` `Converter`, it also gets `.fuse`/`.cast`/streaming.
- `Markdown` — `final class` with `String markdown` (original source),
  `List<MD$Block> blocks` (unmodifiable), `isEmpty`/`isNotEmpty`, and a lossy
  `String get text` (concatenated span text; expensive; tests only). `toString()`
  returns the raw source. Parsing is relatively expensive — do it outside build.

## Node model (`nodes.dart`)

`sealed class MD$Block` is the base of every block (`@immutable`), with abstract
`String type` and `String text`. Dispatch is a **`map`/`maybeMap` pattern**, not a
visitor object:

```dart
block.map<T>(
  paragraph: (p) => …, heading: (h) => …, quote: (q) => …, code: (c) => …,
  list: (l) => …, divider: (d) => …, table: (t) => …, alert: (a) => …, spacer: (s) => …,
);
// maybeMap<T>({... optional, required orElse}) fills unset handlers with orElse.
```

Because `MD$Block` is `sealed`, an exhaustive `switch` also works. **There are
nine block kinds — no image block** (`MD$Image` exists only commented-out); images
are inline spans. Adding a block kind means extending the `map`/`maybeMap`
signature — a breaking change to every override.

| Block | `type` | Key fields |
|---|---|---|
| `MD$Paragraph` | `paragraph` | `text`, `List<MD$Span> spans` |
| `MD$Heading` | `heading` | `int level` (1–6), `text`, `spans` |
| `MD$Quote` | `quote` | `int indent` (**always 1** — nested `>>` not modeled yet), `text`, `spans` |
| `MD$Alert` | `alert` | `MD$AlertType alert`, `text` (body), `spans` (body only) |
| `MD$Code` | `code` | `String? language` (may be `''`), `text` (raw, never span-parsed) |
| `MD$List` | `list` | `text` (raw slice), `List<MD$ListItem> items` |
| `MD$Divider` | `divider` | none; `text == '---'` |
| `MD$Table` | `table` | `MD$TableRow header`, `List<MD$TableRow> rows`, `List<MD$TableColumnAlign> alignments` + `alignmentFor(i)` |
| `MD$Spacer` | `spacer` | `int count` (collapsed blank lines); `text == '\n' * count` |

Supporting types:

- **`MD$Span`** — `int start`, `int end`, `String text`, `MD$Style style`,
  `Map<String, Object?>? extra`. `extra` carries link/image metadata: `'type'`
  (`link`/`image`), `'href'`/`'src'`, `'url'`, optional `'alt'`.
- **`MD$Style`** — a **bitmask**, `extension type const MD$Style(int value)
  implements int` (not an enum). Flags: `none`, `italic`, `bold`, `underline`,
  `strikethrough`, `monospace`, `link`, `image`, `highlight`, `spoiler`. Combine
  with `|`/`.add`; query with `.contains`. The parser stores combined masks
  (e.g. bold|link).
- **`MD$ListItem`** — `int indent` (leading-space **column width**, not a level
  ordinal), `bool? checked` (`null` = not a task; `false`/`true` = task state),
  `bool isTask`, `String marker` (literal source marker: `-`,`*`,`+`,`1.`,`1)`),
  `text`, `spans`, `List<MD$ListItem> children`, `copyWith(...)`.
- **`MD$TableRow`** — `text`, `List<List<MD$Span>> cells` (each cell its own span list).
- **`MD$TableColumnAlign`** — `none, left, center, right`.
- **`MD$AlertType`** — `note, tip, important, warning, caution`, each with a
  `marker` and a `title` (`Note`, `Tip`, …), plus `static tryParse(keyword)`
  (case-insensitive).

## The span offset invariant

Every `MD$Span.start/end` are **UTF-16 offsets into its block's `text`**, and
**`spans.map((s) => s.text).join()` reproduces the block's rendered (visible)
text** — markers, escapes, and link/image syntax removed. Locked by
`test/parser/regression_test.dart` ("Span offset invariants"):

- spans are ordered by ascending `start`; every span has `start <= end`;
- plain text with no markers is a single span `start=0`, `end=text.length`,
  `style=none`.

Selection depends on this to map a visible-text range back to positions/styles.
`start/end` index the **visible** text, so they can diverge from raw-source
offsets:

- **Escapes:** the backslash is removed from `text`; `end` is reduced by the
  number of removed backslashes, so `end - start != text.length`.
- **Inline math** (when enabled): offsets index the already-substituted Unicode
  string, not the `$…$` source.
- **Links/images:** offsets span the full `[..](..)` / `![..](..)` source range
  while `text` is only the label, so `text.length != end - start` there.

## GFM support & intentional/nonstandard choices

Emphasis (CommonMark-inspired flanking rules; stray/unterminated markers stay
literal and never leak style to end of line):

- `*x*` italic, `**x**` bold; `_x_` italic, **`__x__` = UNDERLINE, not bold**.
- `~~x~~` strikethrough, `==x==` highlight, `||x||` spoiler — all require the
  **double** marker; a single one is literal.
- `` `x` `` monospace, single backtick only (double backtick unsupported); inside
  a code span all markdown is literal.
- `_` cannot open/close intra-word (snake_case, Cyrillic preserved); `*` may
  emphasize intra-word (`a*b*c`).

Inline:

- **Soft line breaks preserved** — consecutive non-blank lines join into one
  paragraph with embedded `\n`; a blank line splits paragraphs and emits a
  `MD$Spacer`.
- **Escapes** for `` ! # $ ( ) * + - . [ \ ] _ ` { } ``; `\\` → `\`.
- **Links/images** `[text](url)`, `![alt](src)`; angle-bracket URLs, quoted/paren
  titles, balanced parens in bare URLs. **No reference-style links, no
  autolinks.** Emphasis wrapping a link merges masks (`**[x](u)**` → bold|link).
- **Inline math `$…$` is opt-in** (`inlineMath: false` by default, so `$5`,
  `$HOME` are untouched). When on, only `$…$` runs containing a recognized
  `\command` or `^`/`_` script convert to Unicode; currency and unmappable runs
  stay literal; inline/fenced code is protected; `\$` opts out. Command table is
  `kMarkdownMathCommands` (public, extensible via the `mathReplacements` ctor arg).

Block-level:

- **Task lists** `- [ ]` / `- [x]` / `- [X]` (also ordered); empty `[]` is not a task.
- **Tables** with a delimiter row encoding per-column alignment (`:--`, `:-:`,
  `--:`); malformed/ragged tables fall back to paragraph.
- **Alerts** — a blockquote whose first line is `[!NOTE|TIP|IMPORTANT|WARNING|CAUTION]`;
  unknown markers fall back to a plain quote.
- **Thematic breaks** `---`/`***`/`___` (3+ markers); **ATX headings** `#`–`######`
  (`#hashtag` and 7+ `#` are paragraphs; trailing `#` stripped); **fenced code**
  ` ``` ` / `~~~` with a language label; unterminated fences run to EOF.

## Gotchas for contributors

- `convert` gates on the first code unit; perf-critical scans (`_isBlank`,
  `_parseListLine`, `_parseLinkTarget`, escape range-copy, inline-math bails) were
  rewritten from regexes — `regression_test.dart` locks their exact semantics.
- The **inline fast path** returns a single unstyled full-width span when the text
  contains none of `` * _ ~ = | \ [ ` ``. Any new inline syntax must extend that
  special-character set or it becomes invisible to the parser.
- List `indent` is a **column width**, capped at 8; 9+ leading spaces end the list.
  Tree assembly is a recursive `traverse` over a flat list with a shared mutable
  offset closure (note the intermediate record misspells the field `intent`).
- `MD$Quote.indent` is hardcoded to 1; alert bodies are trimmed (`skip(1).join('\n').trim()`)
  while quote bodies keep raw `join('\n')`.
- `MD$Code.language` can be `''` (not null) for a bare fence; `MD$Code.text` is raw.
- `MD$Table.alignments` may be shorter than the column count — always use
  `alignmentFor(i)`, never index directly.
- `blocks` and most nested lists (`items`, `rows`, `cells`, `alignments`) are
  unmodifiable — don't mutate in place.
- Empty input → `const Markdown.empty()`; a doc ending in blank lines still emits a
  trailing `MD$Spacer`.

## Public API (via `flutter_md.dart`)

All of `markdown.dart` (`Markdown`), `nodes.dart` (every `MD$*`, `MD$Style`,
`MD$AlertType`, `MD$TableColumnAlign`, `MD$ListItem`, `MD$TableRow`, `MD$Span`),
and `parser.dart` (`MarkdownDecoder`, `markdownDecoder`, `kMarkdownMathCommands`).
