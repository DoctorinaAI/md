// Emit tree-shakeable Dart grammar files from grammars.json.
const fs = require('fs');
const path = require('path');

const { languages, aliases } = require('./grammars.json');
const OUT_DIR = path.resolve(__dirname, '../../lib/highlight');
fs.mkdirSync(OUT_DIR, { recursive: true });

const pascal = (name) =>
  name.split(/[-_]/).map((s) => (s ? s[0].toUpperCase() + s.slice(1) : '')).join('');
const cls = (name) => `Highlight${pascal(name)}`;
// Dart file names must be lower_case_with_underscores.
const fileName = (name) => name.replace(/-/g, '_');

// Dart double-quoted string literal for an arbitrary regex source.
function dartStr(s) {
  let r = '';
  for (const ch of s) {
    if (ch === '\\') r += '\\\\';
    else if (ch === '"') r += '\\"';
    else if (ch === '$') r += '\\$';
    else if (ch === '\n') r += '\\n';
    else if (ch === '\r') r += '\\r';
    else if (ch === '\t') r += '\\t';
    else r += ch;
  }
  return `"${r}"`;
}

function regexExpr(node) {
  const args = [dartStr(node.s)];
  const f = node.f || '';
  if (f.includes('i')) args.push('caseSensitive: false');
  if (f.includes('m')) args.push('multiLine: true');
  if (f.includes('s')) args.push('dotAll: true');
  if (f.includes('u')) args.push('unicode: true');
  return `compileHighlightPattern(${args.join(', ')})`;
}

function refExpr(ref, rootName, externals) {
  if (!ref) return null;
  if (ref.ref !== undefined) return `() => _g${ref.ref}`;
  if (ref.langref !== undefined) {
    if (ref.langref === rootName) return '() => _g0';
    externals.add(ref.langref);
    return `() => ${cls(ref.langref)}.grammar`;
  }
  return null;
}

function tokensForEntry(name, value, rootName, externals) {
  const items = value.t === 'arr' ? value.items : [value];
  const out = [];
  for (const it of items) {
    if (it.t === 're') {
      out.push(`GrammarToken(${dartStr(name)}, ${regexExpr(it)}),`);
      continue;
    }
    if (it.t !== 'tok') continue;
    const parts = [dartStr(name), regexExpr(it)];
    if (it.lb) parts.push('lookbehind: true');
    if (it.g) parts.push('greedy: true');
    if (it.alias != null) {
      const a = Array.isArray(it.alias) ? it.alias[0] : it.alias;
      if (typeof a === 'string') parts.push(`alias: ${dartStr(a)}`);
    }
    const inside = refExpr(it.inside, rootName, externals);
    if (inside) parts.push(`inside: ${inside}`);
    out.push(`GrammarToken(${parts.join(', ')}),`);
  }
  return out;
}

function generate(lang) {
  const { rootName, defs } = languages[lang];
  const externals = new Set();
  const decls = defs.map((def, id) => {
    const lines = [];
    for (const e of def.entries) {
      for (const l of tokensForEntry(e.name, e.value, rootName, externals)) {
        lines.push(`  ${l}`);
      }
    }
    const rest = refExpr(def.rest, rootName, externals);
    const restArg = rest ? `, rest: ${rest}` : '';
    return `final Grammar _g${id} = Grammar([\n${lines.join('\n')}\n]${restArg});`;
  });

  externals.delete(lang);
  const imports = ["import '../highlight.dart';"];
  for (const ext of [...externals].sort()) {
    imports.push(`import '${fileName(ext)}.dart';`);
  }

  const header =
`// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering
`;
  const body =
`${imports.join('\n')}

/// Syntax grammar for \`${lang}\`.
///
/// Import this library only when you need \`${lang}\` highlighting; unused
/// languages are dropped from the build.
abstract final class ${cls(lang)} {
  /// The grammar for \`${lang}\`.
  static final Grammar grammar = _g0;
}

${decls.join('\n\n')}
`;
  fs.writeFileSync(path.join(OUT_DIR, `${fileName(lang)}.dart`), `${header}\n${body}`);
}

const names = Object.keys(languages);
for (const lang of names) generate(lang);

// Convenience registry — references EVERY grammar (defeats tree-shaking on
// purpose). For demos and tools only; production code should build its own map.
const sorted = [...names].sort();
const importLines = sorted.map((n) => `import '${fileName(n)}.dart';`).join('\n');
const exportLines = sorted.map((n) => `export '${fileName(n)}.dart';`).join('\n');
const entries = [];
for (const n of sorted) entries.push(`  '${n}': ${cls(n)}.grammar,`);
for (const [alias, target] of Object.entries(aliases).sort()) {
  entries.push(`  '${alias}': ${cls(target)}.grammar,`);
}
const allDart =
`// GENERATED CODE — do not modify by hand. Regenerate with tool/highlight_codegen.
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// ignore_for_file: prefer_single_quotes, require_trailing_commas, directives_ordering

import '../highlight.dart';
${importLines}
${exportLines}

/// Every bundled syntax grammar, keyed by language tag and common aliases.
///
/// Referencing this map pulls in ALL grammars, so unused languages can no longer
/// be removed by tree-shaking — use it for demos or tooling. Production code
/// should assemble a map with only the languages it needs.
final Map<String, Grammar> allHighlightLanguages = <String, Grammar>{
${entries.join('\n')}
};
`;
fs.writeFileSync(path.join(OUT_DIR, 'all.dart'), allDart);

console.log(`wrote ${names.length} language files + all.dart to lib/highlight/`);
