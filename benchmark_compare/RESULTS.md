# Benchmark results

Head-to-head numbers for **flutter_md** vs **flutter_markdown** vs
**gpt_markdown**. Machine-specific — regenerate with the commands in
[`README.md`](README.md). All three libraries use the same normalized styles
([`lib/styles.dart`](lib/styles.dart)). **Lower is better** throughout.

## Environment

|                   |                                            |
| ----------------- | ------------------------------------------ |
| CPU               | 13th Gen Intel Core i7-13700K (24 threads) |
| OS                | Linux 7.1.3 (CachyOS)                      |
| Flutter           | 3.41.6 (stable)                            |
| Dart              | 3.11.4                                     |
| flutter_md        | 0.2.0 (path `../`)                         |
| flutter_markdown  | 0.7.7+1                                    |
| gpt_markdown      | 1.1.8                                      |
| markdown (engine) | 7.3.1                                      |

## Parser (µs per parse)

Parse only, AOT-compiled: `flutter_md.Markdown.fromString` vs the `markdown`
package (flutter_markdown's engine). gpt_markdown has no separable parser.
`speedup = markdown-pkg / flutter_md`.

| scenario      | bytes | flutter_md | flutter_md MB/s | markdown-pkg |    speedup |
| ------------- | ----: | ---------: | --------------: | -----------: | ---------: |
| simple        |   340 |       3.08 |           110.2 |        87.01 |     28.21x |
| inline        |   388 |       4.52 |            85.9 |       100.71 |     22.29x |
| lists         |   344 |       5.72 |            60.1 |       100.09 |     17.49x |
| table         |   471 |       7.94 |            59.4 |       105.08 |     13.24x |
| code          |   290 |       1.39 |           208.0 |        23.99 |     17.21x |
| quotes        |   315 |       3.22 |            97.8 |        71.15 |     22.08x |
| complex       |  1030 |      16.76 |            61.4 |       275.78 |     16.45x |
| complex_large |  8256 |     130.53 |            63.3 |      2318.79 |     17.76x |
| **TOTAL**     |       | **173.17** |                 |  **3082.62** | **17.80x** |

## Render — end-to-end (µs per string → painted pixels)

Parse + build + layout + paint, headless widget test at 400 px width. Absolute
µs include a fixed `flutter_test` per-frame overhead — compare via the ratios.

| document      | flutter_md | flutter_markdown | gpt_markdown |
| ------------- | ---------: | ---------------: | -----------: |
| simple        |     1147.3 |           1717.3 |       1335.3 |
| inline        |     1142.0 |           1619.3 |       1475.8 |
| lists         |     1321.5 |           3991.3 |       7077.5 |
| table         |     1521.5 |           3804.5 |       4452.0 |
| code          |      818.5 |           2498.8 |       4014.8 |
| quotes        |      818.8 |           1292.5 |       1316.3 |
| complex       |     1447.3 |           5087.0 |      11339.8 |
| complex_large |     2678.0 |          17696.8 |      41847.5 |

Relative to flutter_md (× = library / flutter_md):

| document      | flutter_md | flutter_markdown | gpt_markdown |
| ------------- | ---------: | ---------------: | -----------: |
| simple        |      1.00x |            1.50x |        1.16x |
| inline        |      1.00x |            1.42x |        1.29x |
| lists         |      1.00x |            3.02x |        5.36x |
| table         |      1.00x |            2.50x |        2.93x |
| code          |      1.00x |            3.05x |        4.91x |
| quotes        |      1.00x |            1.58x |        1.61x |
| complex       |      1.00x |            3.51x |        7.84x |
| complex_large |      1.00x |            6.61x |       15.63x |

## Rendered height (px)

At 376 px width. Confirms the normalized styles give the same vertical rhythm;
the remaining spread is structural chrome (list indent, table borders,
gpt_markdown's code-block header).

| document      | flutter_md | flutter_markdown | gpt_markdown |
| ------------- | ---------: | ---------------: | -----------: |
| simple        |        294 |              254 |          296 |
| inline        |        294 |              294 |          296 |
| quotes        |        274 |              280 |          294 |
| lists         |        348 |              582 |          424 |
| table         |        382 |              582 |          250 |
| code          |        380 |              340 |          514 |
| complex       |       1352 |             1548 |         1525 |
| complex_large |       5520 |             6234 |         6148 |

## Profile mode — scroll frame timings (ms)

Profile build on the Linux desktop device, flinging the feed up and down;
`TimelineSummary`, mean of 2 runs. 60 Hz frame budget = 16.7 ms.

**Mixed feed** (60 messages cycling through the corpus):

| metric               | flutter_md | flutter_markdown | gpt_markdown |
| -------------------- | ---------: | ---------------: | -----------: |
| frame build avg      |       0.31 |             0.49 |         0.67 |
| frame build 90th pct |       0.70 |             0.70 |         0.94 |
| frame build 99th pct |       1.59 |             4.78 |         9.38 |
| frame build worst    |       3.80 |             6.41 |        13.11 |
| raster avg           |       1.10 |             0.89 |         0.95 |
| raster 90th pct      |       1.85 |             1.54 |         1.53 |
| raster 99th pct      |       2.79 |             2.18 |         2.57 |
| missed frames        |          0 |                0 |            0 |

**Prose feed** (one prose document repeated → identical content per frame in all
three, so no density or chrome differences):

| metric               | flutter_md | flutter_markdown | gpt_markdown |
| -------------------- | ---------: | ---------------: | -----------: |
| frame build avg      |       0.36 |             1.00 |         0.62 |
| frame build 90th pct |       0.89 |             2.51 |         2.16 |
| frame build 99th pct |       1.98 |             6.03 |         4.08 |
| frame build worst    |       2.84 |             7.56 |         6.61 |
| raster avg           |       1.45 |             1.98 |         1.75 |
| raster 90th pct      |       2.35 |             2.97 |         2.77 |
| raster 99th pct      |       3.62 |             4.61 |         4.33 |
| missed frames        |          0 |                0 |            0 |

## Regenerate

```shell
dart compile exe benchmark/parser_benchmark.dart -o /tmp/pb && /tmp/pb
flutter test test/render_benchmark_test.dart

flutter drive --driver=test_driver/perf_driver.dart \
  --target=integration_test/scroll_perf_test.dart --profile -d linux
dart run tool/summarize_timeline.dart

# identical content per frame:
flutter drive --driver=test_driver/perf_driver.dart \
  --target=integration_test/scroll_perf_test.dart --profile -d linux \
  --dart-define=FEED=prose
```
