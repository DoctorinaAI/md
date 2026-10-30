# Benchmarks

Measured performance of `flutter_md`: what was run, on what, with which versions
and how to repeat it. **Lower is better** everywhere. Raw results of the runs
below are in
[`benchmark_compare/results/2026-10-30/`](../benchmark_compare/results/2026-10-30/).

## Summary

Baseline `72a1ac9` → the current render layer, medians on real devices in
profile mode:

| Scenario | iPad Pro (M2) | Galaxy S22 Ultra | MacBook Pro (M3 Max) |
| --- | ---: | ---: | ---: |
| Streamed chunk, p50 (µs) | 1536 → 283 | 5460 → 710 | 1974 → 273 |
| Streamed chunk, p99 (µs) | 4416 → 620 | 29528 → 2534 | 5373 → 633 |
| Relayout at a new width, `complex_large` (µs) | 1188 → 73 | 3905 → 160 | 1667 → 75 |
| First layout, `complex_large` (µs) | 2077 → 1996 | 6825 → 6549 | 2974 → 2858 |
| First-frame build, `complex_large` (ms) | 2.99 → 3.02 | 8.09 → 7.01 | 3.07 → 3.15 |

- **Streaming and resizing are where the gain is:** 5–8× per chunk and about
  16–24× per relayout. The shaped text of unchanged blocks is now reused.
- **The first frame barely changes.** Layout is 3–5% cheaper, which frame
  timings do not resolve from noise. What remains is almost all native
  `Paragraph` work (see [Where the time goes](#where-the-time-goes)).
- **Against other libraries the on-device lead is smaller than the headless
  one.** On `complex_large`, first-frame build is about 1.7–2.3× faster than
  `flutter_markdown` and `gpt_markdown`, against 6.4× and 7.5× in `flutter
  test`. Headless numbers use test fonts and a fixed test frame
  overhead, so treat them as a relative check only.
- **Small documents are roughly even.** A table renders no faster than the
  others on the iPad, where `flutter_md`'s raster time on lists and tables is
  also about twice theirs (0.5 vs 0.2 ms).
- **Scrolling:** no frame of `flutter_md` went over 16.7 ms on any device. The
  other two libraries stayed within it on the iPad and the Mac and missed about
  one frame per run on the phone.
  `flutter_md` has the lowest p99 build time on all three devices. The change
  has no measurable effect on scrolling (see [Limits](#limits-of-these-numbers)).

## Devices

| | iPad Pro 11" (4th gen) | Samsung Galaxy S22 Ultra | MacBook Pro |
| --- | --- | --- | --- |
| Model id | iPad14,3 | SM-S908B | Mac15,11 |
| SoC | Apple M2, 8 cores | Exynos 2200 (s5e9925), 8 cores | Apple M3 Max, 14 cores |
| Memory | not recorded | 11 GB | 36 GB |
| OS | iPadOS 26.6.1 (23G83) | Android 16 (API 36) | macOS 27.0.1 (26A434) |
| View, device pixel ratio | 1668×2388, 2.0 | 720×1544, 1.875 | 1600×1200, 2.0 |
| Max RSS in the run | 170 MB | 334 MB | 257 MB |

## Versions

| | |
| --- | --- |
| Date | 2026-10-30 |
| Flutter / Dart | 3.47.1 stable (`6655482ec0`) / 3.13.1 |
| Engine | `5d53178869` |
| flutter_md | 0.3.1; baseline commit `72a1ac9` |
| flutter_markdown | 0.7.7+1 (discontinued, last release) |
| gpt_markdown | 1.4.0 |
| markdown | 7.3.1 |
| Build mode | profile (`flutter drive --profile`), AOT |

The environment of each run is saved next to its results as `*.env.txt`.

## How it was measured

`benchmark_compare/integration_test/device_bench_test.dart` runs on the device:

- **Stages:** `flutter_md`'s pipeline taken apart at a 400 px width: parse, build
  the painters, lay out, record the picture, and lay the same painter out again
  at another width. Each number is a median of short batches.
- **Stream:** an 8 KB document revealed 48 bytes at a time, each chunk parsed,
  updated, laid out and recorded. 342 samples, ending with the whole document.
- **First frame:** the engine's `FrameTiming` for 40 frames that each build a
  message from its string, per library and document.
- **Scroll:** `FrameTiming` over 12 flings through a 60-message feed. This replaces
  `scroll_perf_test.dart` on phones and tablets, because `watchPerformance` has
  to reach the VM service over `localhost`, which a physical iOS device cannot.

All libraries get the same styles from `benchmark_compare/lib/styles.dart`.
Documents are in `benchmark_compare/lib/corpus.dart`; `complex_large` is 8256
bytes and 240 blocks.

Before/after comparisons are A/B/B/A: two rounds per device, with the order flipped
between rounds and both builds from the same benchmark sources. Tables show the
median over rounds. Devices ran one at a time, the iPad first, then the Mac, then
the phone, connected over USB.

## Results by device

### iPad Pro 11" (M2)

#### pipeline stages, before → after (µs)

| document | parse | build | layout | record | relayout |
| --- | ---: | ---: | ---: | ---: | ---: |
| simple | 4 → 4 | 1 → 1 | 28 → 28 | 20 → 21 | 5 → 5 |
| inline | 5 → 5 | 1 → 1 | 39 → 40 | 29 → 30 | 5 → 5 |
| lists | 7 → 7 | 1 → 1 | 111 → 109 | 29 → 30 | 91 → 2 |
| table | 9 → 10 | 0 → 0 | 191 → 185 | 33 → 33 | 216 → 3 |
| code | 2 → 2 | 1 → 1 | 22 → 22 | 12 → 12 | 1 → 1 |
| quotes | 4 → 4 | 1 → 2 | 28 → 28 | 20 → 19 | 4 → 4 |
| complex | 16 → 16 | 5 → 5 | 254 → 245 | 75 → 75 | 145 → 9 |
| complex_large | 128 → 127 | 43 → 43 | 2077 → 1996 | 595 → 595 | 1188 → 73 |

Streamed chunk (µs): p50 1536 → 283, p90 2785 → 422, p99 4416 → 620

#### first frame of a message, after (ms, build / raster)

| document | flutter_md | flutter_markdown | gpt_markdown |
| --- | ---: | ---: | ---: |
| simple | 0.92 / 0.44 | 1.72 / 0.44 | 1.31 / 0.47 |
| inline | 1.09 / 0.50 | 1.83 / 0.47 | 1.57 / 0.50 |
| lists | 1.57 / 0.47 | 2.02 / 0.20 | 1.81 / 0.23 |
| table | 2.03 / 0.52 | 1.99 / 0.21 | 1.78 / 0.24 |
| code | 0.86 / 0.44 | 1.67 / 0.47 | 1.68 / 0.35 |
| quotes | 0.98 / 0.47 | 1.68 / 0.43 | 1.31 / 0.47 |
| complex | 2.05 / 0.64 | 2.45 / 0.28 | 2.31 / 0.35 |
| complex_large | 3.02 / 0.39 | 6.75 / 0.30 | 5.11 / 0.29 |

#### scrolling a feed, after (ms)

| library | build p50 | build p99 | raster p50 | raster p99 | worst frame | over 16.7 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| flutter_md | 0.38 | 3.34 | 1.74 | 3.22 | 3.82 | 0.0 |
| flutter_markdown | 0.41 | 6.27 | 1.57 | 3.05 | 9.06 | 0.0 |
| gpt_markdown | 0.40 | 5.60 | 1.94 | 3.56 | 9.53 | 0.0 |

### Samsung Galaxy S22 Ultra (Exynos 2200)

#### pipeline stages, before → after (µs)

| document | parse | build | layout | record | relayout |
| --- | ---: | ---: | ---: | ---: | ---: |
| simple | 7 → 7 | 2 → 2 | 80 → 79 | 78 → 78 | 12 → 12 |
| inline | 10 → 10 | 3 → 3 | 119 → 118 | 121 → 120 | 8 → 8 |
| lists | 14 → 15 | 2 → 2 | 329 → 321 | 120 → 119 | 272 → 5 |
| table | 20 → 21 | 1 → 1 | 592 → 563 | 147 → 148 | 669 → 7 |
| code | 3 → 3 | 2 → 2 | 60 → 59 | 49 → 48 | 4 → 4 |
| quotes | 7 → 7 | 3 → 3 | 84 → 81 | 74 → 73 | 11 → 11 |
| complex | 35 → 35 | 13 → 13 | 795 → 770 | 322 → 319 | 454 → 18 |
| complex_large | 272 → 271 | 114 → 105 | 6825 → 6549 | 2768 → 2676 | 3905 → 160 |

Streamed chunk (µs): p50 5460 → 711, p90 10099 → 1165, p99 29528 → 2534

#### first frame of a message, after (ms, build / raster)

| document | flutter_md | flutter_markdown | gpt_markdown |
| --- | ---: | ---: | ---: |
| simple | 1.70 / 1.75 | 2.12 / 1.22 | 2.47 / 2.06 |
| inline | 2.26 / 2.22 | 2.16 / 1.49 | 2.10 / 1.36 |
| lists | 2.69 / 2.05 | 2.86 / 1.00 | 3.13 / 1.19 |
| table | 2.58 / 1.57 | 3.67 / 1.42 | 2.87 / 1.15 |
| code | 1.86 / 1.90 | 2.15 / 1.49 | 2.52 / 1.40 |
| quotes | 2.15 / 2.11 | 2.19 / 1.62 | 1.72 / 1.50 |
| complex | 3.18 / 1.57 | 5.26 / 1.79 | 5.49 / 1.47 |
| complex_large | 7.01 / 1.76 | 13.94 / 2.78 | 13.50 / 2.91 |

#### scrolling a feed, after (ms)

| library | build p50 | build p99 | raster p50 | raster p99 | worst frame | over 16.7 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| flutter_md | 0.67 | 6.61 | 3.62 | 10.19 | 12.50 | 0.0 |
| flutter_markdown | 0.72 | 14.01 | 3.49 | 9.92 | 16.96 | 0.5 |
| gpt_markdown | 0.74 | 15.00 | 3.93 | 11.08 | 18.60 | 0.5 |

### MacBook Pro (M3 Max)

#### pipeline stages, before → after (µs)

| document | parse | build | layout | record | relayout |
| --- | ---: | ---: | ---: | ---: | ---: |
| simple | 3 → 3 | 1 → 1 | 32 → 32 | 20 → 20 | 5 → 5 |
| inline | 5 → 5 | 1 → 1 | 45 → 44 | 30 → 30 | 6 → 6 |
| lists | 6 → 6 | 1 → 1 | 164 → 156 | 31 → 30 | 127 → 2 |
| table | 9 → 9 | 0 → 0 | 292 → 273 | 37 → 37 | 309 → 3 |
| code | 1 → 1 | 1 → 1 | 29 → 28 | 13 → 13 | 1 → 1 |
| quotes | 3 → 3 | 1 → 1 | 33 → 32 | 19 → 19 | 5 → 5 |
| complex | 14 → 14 | 5 → 5 | 369 → 350 | 79 → 78 | 206 → 8 |
| complex_large | 114 → 116 | 39 → 38 | 2975 → 2858 | 625 → 627 | 1667 → 75 |

Streamed chunk (µs): p50 1974 → 273, p90 3578 → 393, p99 5373 → 633

#### first frame of a message, after (ms, build / raster)

| document | flutter_md | flutter_markdown | gpt_markdown |
| --- | ---: | ---: | ---: |
| simple | 1.19 / 0.76 | 1.10 / 0.41 | 1.20 / 0.59 |
| inline | 1.58 / 0.90 | 0.96 / 0.34 | 1.44 / 0.55 |
| lists | 2.02 / 0.42 | 1.70 / 0.29 | 1.68 / 0.36 |
| table | 1.80 / 0.40 | 1.86 / 0.35 | 1.45 / 0.33 |
| code | 0.60 / 0.40 | 1.95 / 0.67 | 1.37 / 0.46 |
| quotes | 1.16 / 0.39 | 1.67 / 0.56 | 0.65 / 0.34 |
| complex | 1.48 / 0.40 | 2.14 / 0.27 | 2.21 / 0.33 |
| complex_large | 3.15 / 0.33 | 7.25 / 0.38 | 6.48 / 0.36 |

#### scrolling a feed, after (ms)

| library | build p50 | build p99 | raster p50 | raster p99 | worst frame | over 16.7 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| flutter_md | 0.38 | 3.37 | 1.29 | 2.04 | 9.53 | 0.0 |
| flutter_markdown | 0.32 | 6.15 | 1.27 | 2.04 | 9.63 | 0.0 |
| gpt_markdown | 0.34 | 5.97 | 1.36 | 2.19 | 12.39 | 0.0 |

## Headless (`flutter test`, MacBook Pro M3 Max)

Three rounds per build, median of min-of-batches. These include a fixed test
frame overhead and use test fonts, so compare ratios only.

| document | flutter_md before → after (µs) | flutter_markdown (µs) | gpt_markdown (µs) |
| --- | ---: | ---: | ---: |
| simple | 1087 → 1005 | 1531 | 1095 |
| inline | 1109 → 941 | 1508 | 1134 |
| lists | 1205 → 1166 | 4798 | 4434 |
| table | 1834 → 1648 | 4645 | 3501 |
| code | 710 → 685 | 2228 | 3975 |
| quotes | 654 → 622 | 1181 | 1032 |
| complex | 1420 → 1360 | 5469 | 6550 |
| complex_large | 2932 → 2770 | 17650 | 20884 |

## Parser (AOT, MacBook Pro M3 Max)

`Markdown.fromString` against the `markdown` package, which backs
`flutter_markdown`. `gpt_markdown` has no separable parser.

| scenario | bytes | flutter_md (µs) | MB/s | markdown (µs) | speedup |
| --- | ---: | ---: | ---: | ---: | ---: |
| simple | 340 | 3.03 | 112.2 | 111.35 | 36.74x |
| inline | 388 | 4.34 | 89.4 | 129.34 | 29.80x |
| lists | 344 | 5.82 | 59.1 | 129.79 | 22.30x |
| table | 471 | 8.14 | 57.9 | 143.63 | 17.65x |
| code | 290 | 1.36 | 212.5 | 32.61 | 23.89x |
| quotes | 315 | 3.30 | 95.6 | 101.44 | 30.77x |
| complex | 1030 | 13.88 | 74.2 | 375.91 | 27.07x |
| complex_large | 8256 | 108.51 | 76.1 | 3041.56 | 28.03x |
| **total** | | **148.39** | | **4065.65** | **27.40x** |

## Fenced code

Added after the runs above: suite `code` of the device benchmark, one run per
build on the same three devices, with a 400 px wide Dart fence. Before → after
merging highlighted tokens into one span per run of text painted alike.

| Scenario, with highlighting (ms) | iPad Pro (M2) | Galaxy S22 Ultra | MacBook Pro (M3 Max) |
| --- | ---: | ---: | ---: |
| First time seen, 100 lines | 3.8 → 3.0 | 11.3 → 8.0 | 3.9 → 3.0 |
| First time seen, 500 lines | 20.4 → 15.7 | 59.8 → 41.5 | 20.7 → 15.2 |
| Streamed chunk, 100 lines | 4.2 → 3.2 | 12.2 → 7.3 | 4.1 → 3.2 |
| Streamed chunk, 500 lines | 19.9 → 15.8 | 64.9 → 44.0 | 19.8 → 15.0 |

"First time seen" is building the painter (tokenizing), layout and recording.
Without a highlighter a chunk of the same fence takes 0.9 / 3.1 ms at 100 / 500
lines on the iPad and 1.6 / 7.6 ms on the Galaxy.

- **A long fence still being streamed is the remaining hot spot.** Every chunk
  tokenizes and shapes the whole fence again, so the cost grows with its length.
  It stays under a frame up to about 100 lines on the Galaxy, not at 500.
- **A block seen before costs no tokenizing:** `MarkdownHighlighter` keeps its
  latest results (up to 256 KB of code) for a list item scrolling back or a
  theme that rebuilds every painter on each chunk.
- **Pixels did not change:** 48 images (12 languages, 2 themes, 2 widths) were
  identical before and after, on macOS.
- **The parser is not the cost here.** Fence shapes grow linearly and stay near
  1 ms at 32 KB, already before PR #38. That PR fixed unclosed emphasis, backticks
  after `\\` and tables failing validation: 1118 / 642 / 4956 ms → 1.6 / 1.4 /
  2.7 ms at 64 KB on the Mac.

Headless, by language and size: `flutter test benchmark/code_benchmark.dart`.

## Parsing in slices

`Markdown.fromStringAsync` against `Markdown.fromString` while frames keep
running, in profile mode. A gap is the longest time between two frames, which
all three devices draw at about 8.3 ms when idle; medians of 7 runs, from one
build per device. Generated documents of mixed blocks, `SUITE=parse`, raw data in
`benchmark_compare/results/2026-10-30/*-parse.device.json`.

| Document | Device | Sync: total / gap, ms | Slices: total / gap, ms |
| --- | --- | ---: | ---: |
| 100 KB | iPad Pro (M2) | 7.5 / 8.5 | 12.1 / 8.4 |
| 100 KB | Galaxy S22 Ultra | 6.3 / 8.5 | 19.8 / 8.6 |
| 100 KB | Mac (M3 Max) | 2.7 / 8.3 | 9.0 / 8.4 |
| 1 MB | iPad Pro (M2) | 38.5 / 49.8 | 75.7 / 8.8 |
| 1 MB | Galaxy S22 Ultra | 61.7 / 65.9 | 175.9 / 24.9 |
| 1 MB | Mac (M3 Max) | 28.5 / 29.1 | 53.2 / 9.1 |
| 5 MB | iPad Pro (M2) | 128.8 / 129.3 | 278.2 / 19.2 |
| 5 MB | Galaxy S22 Ultra | 255.4 / 257.7 | 728.1 / 33.8 |
| 5 MB | Mac (M3 Max) | 120.2 / 120.6 | 262.5 / 16.2 |

Slices take 2-3 times longer in total, as they wait for frames. The gap still
grows with the document although each slice is 4 ms. It is the same with and
without tables, and the cause is not established; garbage collection is a
guess. A single block is never split: in `benchmark/async_benchmark.dart`, a
1 MB paragraph full of markup holds the event loop for about 30 ms either way on
a Mac.

## Where the time goes

On `complex_large` on the iPad, of about 2.76 ms of pipeline work, layout is 72%,
recording 22%, parsing 5% and building painters 2%.

A probe of one 63-character paragraph, in µs:

| | iPad Pro (M2) | MacBook Pro (M3 Max) |
| --- | ---: | ---: |
| Build and lay out, Skia paragraph cache hit | 5.8 | 7.8 |
| Same, cache miss (unique text) | 25.9 | 24.8 |
| Three style runs | 28.0 | 28.3 |
| In Menlo instead of the system font | 18.1 | 18.9 |
| Menlo plus the 6-font fallback chain | 19.2 | 20.6 |
| `TextPainter` around the same paragraph | 6.0 | 8.2 |

So `TextPainter` adds almost nothing, the length of the monospace fallback chain
does not matter, and the remaining first-frame cost is shaping in the engine. The
stage tables repeat the same text, so they mostly measure cache hits: a document
seen for the first time costs more.

## Limits of these numbers

- **Two rounds per device.** That is enough for the 5–24× effects, not for changes
  under about 10%. Treat the first-frame deltas as "no change".
- **Scroll noise.** On the iPad, raster p50 rose in the later runs for all three
  libraries, including the two this change does not touch (for example
  `gpt_markdown` 1.30 → 1.94 ms), so that drift comes from the session and not
  from the code. Temperature was not recorded for it.
- **`raster` in the raw results** is `Picture.toImage`, an offscreen path. On the
  Android device it reads 35 ms for `complex_large` while real scroll frames stay
  near 4 ms, so it is left out of the tables as unrepresentative.
- **One device per class,** all fast or flagship. Low-end Android is not covered.
- **The stream test has no selection, images or custom hooks.** A theme with
  `builder`, `imageResolver`, `blockFilter` or `spanFilter` rebuilds every painter
  as before, as does a theme that is recreated with a new inline `onLinkTap`.

## Repeating the runs

```shell
cd benchmark_compare
flutter pub get

# On-device, in profile mode. Generates the gitignored runners on first use.
tool/device_bench.sh macos results/<date> mac-new-1
tool/device_bench.sh <device-id> results/<date> ipad-new-1   # flutter devices
dart run tool/summarize_device.dart results/<date>           # the tables above

# Headless and parser:
flutter test test/render_benchmark_test.dart
dart compile exe benchmark/parser_benchmark.dart -o /tmp/pb && /tmp/pb
```

For a before/after comparison, run the same script from a `git worktree` of the
baseline, naming its runs `<device>-base-<round>`, and flip the order between
rounds. Keep a phone or tablet unlocked and awake for the whole run. A physical
iOS device needs a signing identity, which Flutter picks from the keychain.
