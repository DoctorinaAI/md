// Snapshot Prism grammars (the full dependency closure of the requested
// languages) into grammars.json for the Dart codegen.
const fs = require('fs');
const Prism = require('prismjs');
const loadLanguages = require('prismjs/components/');

const requested = require('./languages.json');
loadLanguages(requested);

// Canonical name per distinct grammar object (first key wins), plus aliases.
const canonical = new Map(); // object -> canonical name
const aliases = {}; // alias name -> canonical name
for (const name of Object.keys(Prism.languages)) {
  const g = Prism.languages[name];
  if (!g || typeof g !== 'object' || Array.isArray(g)) continue; // skip fns
  if (!canonical.has(g)) canonical.set(g, name);
  else aliases[name] = canonical.get(g);
}

function isRegExp(o) { return o instanceof RegExp; }
function isToken(o) {
  return o && typeof o === 'object' && !Array.isArray(o) && !isRegExp(o) &&
    'pattern' in o;
}
function isGrammar(o) {
  return o && typeof o === 'object' && !Array.isArray(o) && !isRegExp(o) &&
    !('pattern' in o);
}

let skippedFns = 0;

// Build one language's id-hoisted grammar table.
function build(rootName) {
  const root = Prism.languages[rootName];
  const ids = new Map();
  const defs = [];

  function grammarId(g) {
    if (ids.has(g)) return ids.get(g);
    const id = defs.length;
    ids.set(g, id);
    defs.push(null);
    const entries = [];
    let rest = null;
    for (const key of Object.keys(g)) {
      if (key === 'rest') { rest = grammarRef(g[key]); continue; }
      const v = ser(g[key]);
      if (v.t === 'skip') continue;
      entries.push({ name: key, value: v });
    }
    defs[id] = { entries, rest };
    return id;
  }

  // A reference to a whole grammar (used by `inside` and `rest`).
  function grammarRef(g) {
    if (!isGrammar(g)) return null;
    if (canonical.has(g)) return { langref: canonical.get(g) };
    return { ref: grammarId(g) };
  }

  function ser(node) {
    if (isRegExp(node)) return { t: 're', s: node.source, f: node.flags };
    if (Array.isArray(node)) {
      return {
        t: 'arr',
        items: node.map((x) => ser(x)).filter((x) => x.t !== 'skip'),
      };
    }
    if (isToken(node)) {
      if (!isRegExp(node.pattern)) { skippedFns++; return { t: 'skip' }; }
      return {
        t: 'tok', s: node.pattern.source, f: node.pattern.flags,
        lb: !!node.lookbehind, g: !!node.greedy,
        alias: node.alias ?? null,
        inside: grammarRef(node.inside),
      };
    }
    if (isGrammar(node)) return grammarRef(node) ?? { t: 'skip' };
    if (typeof node === 'function') { skippedFns++; return { t: 'skip' }; }
    return { t: 'skip' }; // primitive/undefined hole
  }

  grammarId(root);
  return { rootName, defs };
}

const languages = {};
for (const g of canonical.values()) languages[g] = build(g);

fs.writeFileSync('grammars.json', JSON.stringify({ languages, aliases }));

const count = Object.keys(languages).length;
console.log(`requested ${requested.length}; closure of ${count} languages`);
console.log(`aliases: ${Object.keys(aliases).length}; skipped fn/primitive: ${skippedFns}`);
