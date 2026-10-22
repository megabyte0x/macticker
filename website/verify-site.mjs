import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
const root = path.resolve('dist');
const site = 'https://macticker.app';
function files(dir) { return fs.readdirSync(dir, { withFileTypes: true }).flatMap(e => e.isDirectory() ? files(path.join(dir, e.name)) : [path.join(dir, e.name)]); }
const pages = files(root).filter(f => f.endsWith('.html'));
const titles = new Set(), descriptions = new Set();
const indexable = new Set();
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
  const noindex = html.includes('<meta name="robots" content="noindex"');
  assert.equal(noindex, file === path.join(root, '404.html'), `${file}: only the error page is noindex`);
  if (!noindex) {
    const route = `/${path.relative(root, file).split(path.sep).join('/').replace(/index\.html$/, '')}`;
    assert.equal(canonical, `${site}${route}`, `${file}: self-referencing canonical`);
    indexable.add(canonical);
  }
  for (const tag of ['og:image" content="https://macticker.app/social.png', 'twitter:title', 'twitter:image', 'apple-touch-icon', 'http-equiv="content-security-policy"']) assert(html.includes(tag), `${file}: ${tag}`);
  const csp = html.match(/<meta http-equiv="content-security-policy" content="([^"]+)"/)?.[1];
  assert.match(csp || '', /script-src [^;]*https:\/\/static\.cloudflareinsights\.com(?:\s|;)/, `${file}: allow Cloudflare's injected analytics script`);
  assert(!html.includes('ticker.megabyte.sh'), `${file}: no old host`);
  for (const m of html.matchAll(/<script type="application\/ld\+json">(.*?)<\/script>/gs)) {
    const schema = JSON.parse(m[1]); assert.equal(schema['@context'], 'https://schema.org');
    for (const node of schema['@graph'] || [schema]) {
      assert(node['@type'], `${file}: schema node type`);
      if (node['@type'] === 'Article') {
        assert.equal(node.mainEntityOfPage, canonical, `${file}: article identifies the canonical page`);
        const dates = [...html.matchAll(/<time datetime="([^"]+)">([^<]+)<\/time>/g)];
        assert.equal(dates[0]?.[1], node.datePublished, `${file}: visible publication date matches schema`);
        assert.equal(dates.at(-1)?.[1], node.dateModified, `${file}: visible modification date matches schema`);
        for (const [, iso, label] of dates) {
          const formatted = new Intl.DateTimeFormat('en-US', {dateStyle:'long', timeZone:'UTC'}).format(new Date(`${iso}T00:00:00Z`));
          assert.equal(label, formatted, `${file}: visible date label matches datetime`);
        }
        assert(node.dateModified >= node.datePublished, `${file}: modification follows publication`);
        assert(html.includes(`<meta property="article:published_time" content="${node.datePublished}"`));
        assert(html.includes(`<meta property="article:modified_time" content="${node.dateModified}"`));
        assert(html.includes('href="/about/"'), `${file}: publisher/editorial information is linked`);
      }
      if (node['@type'] === 'ItemList') {
        assert.equal(node.numberOfItems, node.itemListElement.length);
        node.itemListElement.forEach((item, i) => {
          assert.equal(item.position, i + 1);
          assert(html.includes(`href="${new URL(item.url).pathname}"`), `${file}: listed guide is visibly linked`);
        });
      }
    }
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
assert.equal([...home.matchAll(/<a\b[^>]*href="\/guides[^"]*"/g)].length, 1, 'homepage has only one guides entry point');
assert.match(home.match(/<footer\b[\s\S]*?<\/footer>/)?.[0] || '', /href="\/guides\/"/, 'guides entry point stays in the footer');
assert(fs.readFileSync(path.join(root, '_headers'), 'utf8').includes('Strict-Transport-Security'));
const sitemap = fs.readFileSync(path.join(root, 'sitemap-0.xml'), 'utf8');
const locations = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map(m => m[1]);
assert.equal(locations.length, indexable.size, 'sitemap has one entry per indexable page');
assert.deepEqual(new Set(locations), indexable, 'sitemap includes every indexable page and excludes 404');
for (const route of ['/about/', '/guides/ticker-vs-coin-tick/', '/guides/ticker-vs-crypto-pro/']) {
  assert(sitemap.includes(`${site}${route}</loc>`), `sitemap ${route}`);
}
const staleGuide = fs.readFileSync(path.join(root, 'guides/crypto-price-refresh-stale-data/index.html'), 'utf8');
assert(staleGuide.includes('more than ten minutes old') && !staleGuide.includes('more than three minutes old'), 'stale timestamp guidance matches the ten-minute app threshold');
assert(fs.readFileSync(path.join(root, 'robots.txt'), 'utf8').includes(`Sitemap: ${site}/sitemap-index.xml`));
assert(fs.statSync(path.join(root, 'downloads/Ticker-1.0-arm64.dmg')).size > 100000);
console.log(`Verified ${pages.length} HTML pages, unique metadata, internal assets and links, JSON-LD, article dates, footer-only guide discovery, sitemap, robots and DMG.`);
