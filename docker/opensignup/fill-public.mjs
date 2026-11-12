// Fills in the NEXT_PUBLIC_* values OpenSignup bakes into its build.
//
// The image is built with placeholder words (see the Dockerfile); on start,
// icestore-init copies the untouched build to /app/.next and runs this to
// swap every placeholder for the value from the app settings.
//
//   node fill-public.mjs <dir>   with FILL_PAIRS='[["from","to"],...]'
//
// The values are already cleaned by icestore-init (no quotes, backslashes,
// < > or backticks), so they can go straight into JavaScript strings, JSON
// and HTML alike.
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const root = process.argv[2];
const pairs = JSON.parse(process.env.FILL_PAIRS || '[]');
const TEXT = /\.(js|mjs|cjs|json|html|rsc|body|meta|txt|xml|css|map)$/;
let changed = 0;

function walk(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name !== 'cache') walk(p);
    } else if (entry.isFile() && TEXT.test(entry.name)) {
      const before = readFileSync(p, 'utf8');
      let after = before;
      for (const [from, to] of pairs) after = after.split(from).join(to);
      if (after !== before) {
        writeFileSync(p, after);
        changed++;
      }
    }
  }
}

walk(root);
console.log(`[init] filled in the site settings in ${changed} files`);
