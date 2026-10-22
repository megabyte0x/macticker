import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
const root = path.resolve('dist');
const site = 'https://macticker.app';
function files(dir) { return fs.readdirSync(dir, { withFileTypes: true }).flatMap(e => e.isDirectory() ? files(path.join(dir, e.name)) : [path.join(dir, e.name)]); }
const pages = files(root).filter(f => f.endsWith('.html'));
const titles = new Set(), descriptions = new Set();
for (const file of pages) {
  const html = fs.readFileSync(file, 'utf8');
  assert.equal((html.match(/<h1\b/g) || []).length, 1, `${file}: one main heading`);
  const title = html.match(/<title>(.*?)<\/title>/s)?.[1];
  assert(title); assert(!titles.has(title)); titles.add(title);
  const description = html.match(/<meta name="description" content="([^"]+)"/)?.[1];
  assert(description); assert(!descriptions.has(description)); descriptions.add(description);
  assert.match(html, /<html lang="en"/);
  const canonical = html.match(/<link rel="canonical" href="([^"]+)"/)?.[1];
  assert(canonical?.startsWith(`${site}/`) && canonical.endsWith('/'), `${file}: canonical on ${site} with trailing slash`);
  assert(html.includes(`<meta property="og:url" content="${canonical}"`), `${file}: og:url matches canonical`);
  for (const tag of ['og:image" content="https://macticker.app/social.png', 'twitter:title', 'twitter:image', 'apple-touch-icon', 'http-equiv="content-security-policy"']) assert(html.includes(tag), `${file}: ${tag}`);
  const csp = html.match(/<meta http-equiv="content-security-policy" content="([^"]+)"/)?.[1];
  assert.match(csp || '', /script-src [^;]*https:\/\/static\.cloudflareinsights\.com(?:\s|;)/, `${file}: allow Cloudflare's injected analytics script`);
  assert(!html.includes('ticker.megabyte.sh'), `${file}: no old host`);
  for (const m of html.matchAll(/<script type="application\/ld\+json">(.*?)<\/script>/gs)) {
    const schema = JSON.parse(m[1]); assert.equal(schema['@context'], 'https://schema.org');
    for (const node of schema['@graph'] || [schema]) assert(node['@type'], `${file}: schema node type`);
  }
  for (const m of html.matchAll(/(?:href|src)="(\/[^"#?]*)/g)) {
    const url = m[1]; let p = path.join(root, url);
    if (url.endsWith('/')) p = path.join(p, 'index.html');
    assert(fs.existsSync(p), `${file}: missing ${url}`);
  }
  assert(!html.includes('—'), `${file}: avoid em dash copy`);
}
const home = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
for (const answer of ['M1 and later', 'requests USD prices every minute', 'does not include price alerts', 'notarized by Apple']) assert(home.includes(answer), `FAQ answer prerendered: ${answer}`);
assert(!home.includes('Ad-hoc'), 'homepage signing label matches the notarized release');
assert(fs.readFileSync(path.join(root, '_headers'), 'utf8').includes('Strict-Transport-Security'));
const sitemap = fs.readFileSync(path.join(root, 'sitemap-0.xml'), 'utf8');
for (const route of ['/', '/download/', '/guides/', '/privacy/', '/guides/mac-crypto-ticker-alternatives/', '/guides/bitcoin-price-mac-menu-bar/', '/guides/crypto-price-refresh-stale-data/']) {
  assert(sitemap.includes(`${site}${route}</loc>`), `sitemap ${route}`);
}
assert(fs.readFileSync(path.join(root, 'robots.txt'), 'utf8').includes(`Sitemap: ${site}/sitemap-index.xml`));
assert(fs.statSync(path.join(root, 'downloads/Ticker-1.0-arm64.dmg')).size > 100000);
console.log(`Verified ${pages.length} HTML pages, unique metadata, internal assets and links, JSON-LD, sitemap, robots and DMG.`);
