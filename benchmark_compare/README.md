# Markdown benchmark comparison

A standalone, non-published package that pits **flutter_md** against two popular
alternatives — [`flutter_markdown`](https://pub.dev/packages/flutter_markdown)
and [`gpt_markdown`](https://pub.dev/packages/gpt_markdown) — on both **parsing**
and **rendering**.

It lives inside the repo (path dependency on `../`) but is excluded from
`flutter_md` publishing via the root `.pubignore`.

## Results at a glance

Measured on an i7-13700K (Flutter 3.41.6), all three libraries given identical
normalized styles. Full tables in **[`RESULTS.md`](RESULTS.md)**.

- **Parser:** flutter_md is **~18× faster** than the `markdown` package that
  backs flutter_markdown (gpt_markdown has no separable parser).
- **Render (string → painted pixels):** flutter_md is **1.4–15.6× faster**
  end-to-end — ~6.6× vs flutter_markdown and ~15.6× vs gpt_markdown on the large
  document.
- **Profile-mode scroll:** all three hold 60 fps with **0 dropped frames** on
  desktop; flutter_md has the lowest UI-thread build cost (99th-percentile frame
  build **1.6 ms** vs 4.8 / 9.4 ms) and, at equal on-screen content, the lowest
  raster time too.

## Layout

| File | What it measures | How to run |
| ---- | ---------------- | ---------- |
| `lib/corpus.dart` | Shared benchmark documents (simple → complex/large), common-denominator GFM only. | — |
| `lib/styles.dart` | Normalized styles shared by all three libraries: one base text style + explicit line height, matched heading sizes and block spacing. | — |
| `benchmark/parser_benchmark.dart` | **Parser** cost via `benchmark_harness`: `flutter_md` vs the `markdown` package (which `flutter_markdown` uses internally). | `dart run benchmark/parser_benchmark.dart` |
| `test/render_benchmark_test.dart` | **Render** cost via widget tests: end-to-end string → painted pixels for all three libraries (headless). | `flutter test test/render_benchmark_test.dart` |
| `integration_test/scroll_perf_test.dart` + `test_driver/perf_driver.dart` | **Profile-mode** confirmation: real frame build/raster times while scrolling a feed, captured as a `TimelineSummary`. | see below |
| `tool/summarize_timeline.dart` | Formats the profile-mode JSON into a table. | `dart run tool/summarize_timeline.dart` |

## Running

```shell
cd benchmark_compare
flutter pub get

# Parser — JIT is fine, AOT is the most stable:
dart run benchmark/parser_benchmark.dart
dart compile exe benchmark/parser_benchmark.dart -o /tmp/pb && /tmp/pb

# Render — must run under the Flutter test engine (needs real text layout):
flutter test test/render_benchmark_test.dart

# Profile-mode confirmation — real frame timings on a device (here: Linux
# desktop). Needs the platform runner: regenerate it once with
#   flutter create --platforms=linux --project-name md_benchmark_compare .
flutter drive --driver=test_driver/perf_driver.dart \
  --target=integration_test/scroll_perf_test.dart --profile -d linux
dart run tool/summarize_timeline.dart   # -> reads build/integration_response_data.json

# Controlled variants for an apples-to-apples raster comparison:
#   FEED=prose      one prose doc repeated -> identical content per frame
#   ITEM_MODE=fixed every item clipped to a constant height
flutter drive --driver=test_driver/perf_driver.dart \
  --target=integration_test/scroll_perf_test.dart --profile -d linux \
  --dart-define=FEED=prose
```

The parser and render entry points print ready-to-paste Markdown tables; the
profile-mode run writes `build/integration_response_data.json`, which
`tool/summarize_timeline.dart` turns into a table. A captured run of all three is
in [`RESULTS.md`](RESULTS.md).

> The generated `linux/` runner (and `.metadata`, `*.iml`, …) are gitignored as
> throwaway scaffolding — regenerate with the `flutter create` line above. Swap
> `-d linux` for another device (`-d chrome`, a mobile device/emulator) if you
> prefer; the harness is platform-agnostic.

## Methodology & fairness

**Corpus.** Documents stick to common-denominator GFM (headings, emphasis,
inline code, links, blockquotes, fenced code, ordered/unordered/task lists,
tables) so all three libraries render them without diverging on dialect-specific
extensions. Images are omitted so render timings measure text layout, not
network image stubs.

**Normalized styles.** All three libraries are configured from `lib/styles.dart`
with the same base text style (font size 14, explicit line `height` 1.4, same
color), the same heading sizes (base + {10,8,6,4,2,0}, bold) and matched block
spacing. An explicit line height makes every line box `fontSize × height`,
independent of font metrics, so text lays out at the same vertical rhythm for
every library and in both the headless-test and profile-desktop environments.
This removes layout *density* as a confound in the render/raster comparison — a
more compact renderer would otherwise rasterize more content per frame. Purely
structural chrome (code-block frames, table borders, list bullets/indents,
gpt_markdown's code header) is not unifiable through public style APIs and
remains; the render benchmark prints a height table that quantifies the residual.

**Parser.** `flutter_markdown` does no parsing of its own — on every build it
delegates to the `markdown` package (`md.Document(...).parse(source)`). So the
apples-to-apples parser comparison is `flutter_md`'s `Markdown.fromString`
against that same `markdown` package (a fresh single-use `Document` per parse,
exactly as `flutter_markdown` uses it). `gpt_markdown` has **no separable
parser** — it parses inline while building its widget tree — so it does not
appear in the parser table; its parse cost is folded into the render numbers
instead. Each `benchmark_harness` benchmark overrides `exercise()` to run once,
so the reported figure is microseconds **per single parse**.

**Render.** Measures the *end-to-end* cost of turning a Markdown **string** into
painted pixels — parse + build + layout + paint — which is what every library
does on the frame that first shows a message. A changing `ValueKey` forces a
full subtree teardown + rebuild each iteration, and wall-clock time is taken
around `tester.pump()` (min-of-batches, the most stable estimator). To keep it
fair:

- Every iteration reconstructs from the source string. For `flutter_md` that
  means `Markdown.fromString(src)` runs inside the builder too, so its parse
  cost is included on equal footing.
- All three render into the same fixed-width (400px) viewport inside a
  `SingleChildScrollView`, so layout covers the whole document while paint is
  clipped to the same visible region for every library.

**Interpreting the numbers.** Render microseconds (headless widget test) include
a fixed `flutter_test` per-frame overhead (~1 ms floor), so they are meaningful
only *relative to each other on the same machine* — use the ratios, and note
that the floor compresses the small-document ratios while the large/complex
documents show the true gap. The **profile-mode scroll benchmark** removes that
floor and confirms the ordering on a real device with true GPU rasterization
(same data you'd read off the DevTools Performance timeline, but automated).
Parser microseconds have no such floor and are directly comparable.
