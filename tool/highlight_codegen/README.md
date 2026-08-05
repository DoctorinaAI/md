# Syntax-highlight grammar codegen

Generates the tree-shakeable Dart grammars under `lib/highlight/` (consumed by
`package:flutter_md/highlight.dart`) from upstream
[Prism](https://prismjs.com/) grammar definitions. Dev-only tooling — not part
of the published package.

## Regenerate

```sh
cd tool/highlight_codegen
npm install                 # pins prismjs (see package.json)
node dump.cjs               # snapshot grammars -> grammars.json
node codegen.cjs            # emit lib/highlight/<lang>.dart (+ all.dart)
cd ../.. && dart format lib/highlight
```

The set of languages lives in `languages.json`. `dump.cjs` loads them via
Prism's `loadLanguages`, which pulls in every transitive dependency (e.g. `tsx`
drags in `jsx`, `typescript`, `javascript`, `markup`), and snapshots the **full
closure** — Prism resolves `extend` / `insertBefore` at load time, so the
snapshot is the fully built grammar. Each distinct grammar object becomes one
file named by its canonical name; aliases (js→javascript, sh→bash, …) are
recorded and surface only in `all.dart`.

To add languages, append to `languages.json` and re-run.

## Outputs

- `lib/highlight/<lang>.dart` — one `Highlight<Lang>.grammar` per language.
- `lib/highlight/all.dart` — a convenience `allHighlightLanguages` map (canonical
  names + aliases) that references **every** grammar. Referencing it prevents
  unused languages from tree-shaking; it's for demos/tooling (the example's
  Highlight tab).

## How it stays tree-shakeable

- Each language becomes its own library (`lib/highlight/<lang>.dart`) exposing a
  single `Highlight<Lang>.grammar`. Importing one never references the others.
- Grammars are hoisted into per-object lazy `final`s and referenced through
  thunks (`inside: () => _gN`), which handles self/cross-references and cyclic
  sub-grammars (e.g. bash) without a central registry.
- There is deliberately **no** `Map`/`enum`/`switch` that enumerates all
  languages: the app assembles the `{ 'lang': grammar }` map at its own call
  site, so only the grammars it names survive compilation.

## Notes / known limitations

- Regex sources are emitted as escaped Dart string literals. Dart's `RegExp`
  (Irregexp) is JS-compatible, so most patterns port verbatim; only the `i`
  flag appears in the current language set.
- The tokenizer relies on grammar ordering rather than a cross-segment `greedy`
  re-scan (the `greedy` flag is retained but advisory). This can mis-highlight
  rare pathological cases; it is correct for typical code.
- Grammar keys with `undefined` values (e.g. Dart's inherited `string` hole)
  are skipped.

## Attribution

Grammar definitions are adapted from [PrismJS](https://github.com/PrismJS/prism),
which is distributed under the MIT License.
