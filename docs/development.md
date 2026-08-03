# Development

Commands, CI, conventions, benchmarks, and repo layout. Package `flutter_md`
(`0.2.0`); Dart `>=3.6.0 <4.0.0`, Flutter `>=3.29.0`.

## Commands

```shell
# Tests — test/unit_test.dart is the single aggregate entrypoint.
flutter test test/unit_test.dart
flutter test --coverage --concurrency=40 test/unit_test.dart   # CI form; LCOV → coverage/lcov.info

# Analyzer — INFO-level lints FAIL (--fatal-infos). A missing doc comment fails CI.
dart analyze --fatal-infos --fatal-warnings lib/ test/

# Format gate — exactly as CI runs it (80 cols; the ! -name "*.*.dart" skips generated files):
find lib test -name "*.dart" ! -name "*.*.dart" -print0 \
  | xargs -0 dart format --set-exit-if-changed --line-length 80 -o none
dart format lib test example                                    # to actually apply (page_width: 80)

# Example app (separate package md_example, depends on flutter_md via path: ../):
cd example && flutter pub get && flutter run
```

### Benchmarks

Parser benchmarks are pure Dart; the render benchmark needs the Flutter test
engine (real `dart:ui` text layout + `PictureRecorder`).

```shell
dart run benchmark/parser_benchmark.dart      # multi-scenario table + head-to-head vs `markdown` pkg
dart run benchmark/parse_benchmark.dart       # single mixed doc vs Google `markdown` pkg
dart run benchmark/compare.dart --save        # write baseline → benchmark/.baseline.txt (uncommitted)
dart run benchmark/compare.dart               # compare current vs saved baseline, prints delta %
dart compile exe benchmark/parser_benchmark.dart -o /tmp/pb && /tmp/pb   # stabler AOT numbers

flutter test benchmark/render_benchmark.dart                                    # vs benchmark/.render_baseline.txt
flutter test benchmark/render_benchmark.dart --dart-define=RENDER_BASELINE=save # record new baseline
```

Render tiers (doc = 50 mixed blocks, width 400): `layout_large`, `paint_miss`
(fresh painter → records a `Picture`), `paint_hit` (re-paint → replays cached
`Picture`), `stream_append` (`update()` + relayout each iter), `selection_drag`
(grow a highlight over the **reused** content Picture), `scroll_frame` (40
drag+pump frames over a `ListView`). The test **asserts** `paint_hit < paint_miss`
and `selection_drag < paint_miss / 3` — regressions fail. Timings are relative
(headless engine); confirm real FPS with `flutter run --profile` + DevTools.

Parser scenarios live in `benchmark/scenarios.dart` (`prose, inline, links, lists,
table, code, quotes, escapes, currency, pathological, mixed`). `compare.dart` uses
warmup + auto-calibrated iterations + min-of-batches for low-noise deltas.

Selection spikes S1–S7 (`benchmark/experiments/`, findings in `FINDINGS.md`) are
throwaway and not in CI.

## CI pipeline (`.github/workflows/`)

**`checkout.yml`** (name `Checkout`) — runs on push to `main`/`master` and PRs to
`main|master|dev|develop|feature/**|…`, path-filtered to Dart/config files. Single
job, steps in order (any non-zero fails):

1. Checkout.
2. **Setup** (`./.github/actions/setup`): sparse-checkout, `flutter pub get`, and a
   **CHANGELOG check** — the `version:` in `pubspec.yaml` must appear as a
   `# <version>` heading in `CHANGELOG.md`, else exit 1.
3. **Check code format** — the format gate command above.
4. **Check analyzer** — `dart analyze --fatal-infos --fatal-warnings lib/ test/`.
5. **Run unit tests** — `flutter test --coverage --concurrency=40 test/unit_test.dart`.
6. Codecov upload (present but commented out).

**`deploy.yml`** (name `Deploy to Pub.dev`) — on `workflow_dispatch` and version
tags `[0-9]+.[0-9]+.[0-9]+*`; delegates to `dart-lang/setup-dart` publish workflow
(OIDC). Benchmarks are never run in CI.

## Lint rules that bite (`analysis_options.yaml`)

Base `package:flutter_lints/flutter.yaml`, plus `strict-casts`, `strict-raw-types`,
`strict-inference` (all true). The ones you'll actually trip on:

- **`public_member_api_docs: true`** — every public member needs a `///`. With
  `--fatal-infos`, a missing doc fails CI. (`{@template}`/`{@macro}` is used for
  boilerplate.)
- **`lines_longer_than_80_chars: true`** — 80-col lint on top of the format gate.
- **`prefer_relative_imports: true`** (+ `avoid_relative_lib_imports: error`) —
  inside `lib/` imports are **relative** (`../nodes.dart`); tests use
  `package:flutter_md/flutter_md.dart`.
- **`prefer_const_*` / `use_named_constants`** — const is enforced.

`errors:` overrides — hard **errors**: `always_use_package_imports`,
`avoid_relative_lib_imports`, `avoid_slow_async_io`, `avoid_types_as_parameter_names`,
`valid_regexps`, `always_require_non_null_named_parameters`. **Ignored**: `todo`,
`curly_braces_in_flow_control_structures` (single-line `if` bodies allowed).
`example/analysis_options.yaml` is identical to root.

## Conventions

- **Relative imports inside `lib/`**; `package:` imports in `test/`. The barrel
  `lib/flutter_md.dart` re-exports via `export 'src/…'`.
- **`$` separator** in public variant names — `MD$Block`, `MD$Span`,
  `BlockPainter$Paragraph`, even benchmark `Current$Benchmark`. Deliberate style.
- **`@meta.internal`** (imported `as meta show internal`) marks non-user-facing
  types (`MarkdownPainter`, `MarkdownRenderObject`); `@protected` for subclass-only
  members. Public model/nodes import `package:meta/meta.dart` plain.
- **One test entrypoint:** `test/unit_test.dart` imports each suite's `main()`
  inside `group('Unit', …)`. A new `*_test.dart` must be wired there or CI skips it.
- **Doc comments required** on all public members (see the lint above).
- **CHANGELOG discipline:** bump `pubspec.yaml` `version:` and add the matching
  `# <version>` heading in `CHANGELOG.md` together.

## Dependencies

- `dependencies`: `flutter` (sdk), `meta: ^1.16.0`.
- `dev_dependencies`: `flutter_test` (sdk), `flutter_lints: >=5.0.0 <7.0.0`,
  `markdown: ^7.3.0` (benchmark comparison only), `benchmark_harness: ^2.3.1`.

## Repo layout

```
lib/flutter_md.dart          public barrel (export 'src/…' [+ show for render.dart])
lib/src/
  markdown.dart nodes.dart parser.dart   # model + parser        → docs/parser.md
  theme.dart                             # MarkdownThemeData, MarkdownTheme
  widget.dart                            # MarkdownWidget (LeafRenderObjectWidget)
  render.dart  render/**                 # canvas render layer    → docs/rendering.md
  selection.dart selection_scope.dart    # text selection         → docs/selection.md
test/
  parser/ nodes/ selection/ theme/ widget/   (aggregated by test/unit_test.dart)
benchmark/                    parser + render benchmarks, compare.dart, scenarios.dart,
                              .render_baseline.txt, experiments/ (spikes + FINDINGS.md)
example/                      md_example app: lib/main.dart (Editor/Selection/Chat tabs), lib/tabs/*
AGENTS.md  docs/              this documentation set
```

`build/`, `coverage/`, `.dart_tool/` are gitignored; `.baseline.txt` is
uncommitted (the render baseline `.render_baseline.txt` is committed).
