// Daily page views (Cloudflare Web Analytics) and DMG downloads (zone HTTP analytics).
// Usage: CLOUDFLARE_API_TOKEN=... node analytics.mjs [days, max 30]
// The token needs Account Analytics Read and Zone Analytics Read.
const ACCOUNT = '1378ab230486e0367cbcb49a0f4cec1d';
const ZONE = '7e7c0192109e230b01b942d0bfa4af7d';
const SITE = 'f914a14801ab490596877e92cc02eefa';
const DMG = '/downloads/Ticker-1.0-arm64.dmg';
const AUTOMATED = /bot|crawl|spider|scan|curl|wget|python|httpx|aiohttp|axios|go-http|okhttp|java\/|node|headless|lighthouse|preview|fetch/i;

const token = process.env.CLOUDFLARE_API_TOKEN;
if (!token) throw new Error('Set CLOUDFLARE_API_TOKEN (Account Analytics Read, Zone Analytics Read).');
const days = Math.min(Number(process.argv[2] || 7), 30); // zone HTTP analytics keeps 31 days
// Query at most 7 days per request: longer ranges with a user-agent breakdown are heavily sampled.
// Requests are kept few because the GraphQL rate-limit budget is small.
const today = new Date(new Date().toISOString().slice(0, 10));
const dates = Array.from({ length: days }, (_, i) => new Date(+today - (days - 1 - i) * 864e5));
const query = `query($account: String!, $zone: String!, $site: String!, $dmg: String!, $start: Time!, $end: Time!) {
  viewer {
    accounts(filter: {accountTag: $account}) {
      rumPageloadEventsAdaptiveGroups(limit: 10000, filter: {siteTag: $site, datetime_geq: $start, datetime_lt: $end}) {
        count
        sum { visits }
        avg { sampleInterval }
        dimensions { date userAgentBrowser }
      }
    }
    zones(filter: {zoneTag: $zone}) {
      httpRequestsAdaptiveGroups(limit: 10000, filter: {datetime_geq: $start, datetime_lt: $end, requestSource: "eyeball", clientRequestPath: $dmg, clientRequestHTTPMethodName: "GET", edgeResponseStatus_in: [200, 206]}) {
        count
        avg { sampleInterval }
        dimensions { date userAgent edgeResponseStatus }
      }
    }
  }
}`;
const pageGroups = [], downloadGroups = [];
for (let i = 0; i < days; i += 7) {
  const start = dates[i], end = new Date(+dates[Math.min(i + 7, days) - 1] + 864e5);
  const variables = { account: ACCOUNT, zone: ZONE, site: SITE, dmg: DMG, start: start.toISOString(), end: end.toISOString() };
  const res = await fetch('https://api.cloudflare.com/client/v4/graphql', {
    method: 'POST',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify({ query, variables }),
  });
  const { data, errors } = await res.json();
  if (errors?.length || !data) throw new Error(JSON.stringify(errors ?? res.status));
  pageGroups.push(...data.viewer.accounts[0].rumPageloadEventsAdaptiveGroups);
  downloadGroups.push(...data.viewer.zones[0].httpRequestsAdaptiveGroups);
}

const rows = new Map();
const row = date => rows.get(date) ?? rows.set(date, { date, pageViews: 0, visits: 0, automatedPageViews: 0, macDownloads: 0, otherDownloads: 0, automatedDownloads: 0, partialRequests: 0 }).get(date);
let sampled = false;
for (const g of pageGroups) {
  const r = row(g.dimensions.date);
  sampled ||= g.avg.sampleInterval > 1;
  if (AUTOMATED.test(g.dimensions.userAgentBrowser)) r.automatedPageViews += g.count;
  else { r.pageViews += g.count; r.visits += g.sum.visits; }
}
for (const g of downloadGroups) {
  const r = row(g.dimensions.date), ua = g.dimensions.userAgent;
  sampled ||= g.avg.sampleInterval > 1;
  if (g.dimensions.edgeResponseStatus === 206) r.partialRequests += g.count;
  else if (AUTOMATED.test(ua)) r.automatedDownloads += g.count;
  else if (/Macintosh/.test(ua)) r.macDownloads += g.count;
  else r.otherDownloads += g.count;
}

for (const d of dates) row(d.toISOString().slice(0, 10));
const table = [...rows.values()].sort((a, b) => a.date.localeCompare(b.date));
const total = { date: 'total' };
for (const key of Object.keys(table[0] ?? {}).filter(k => k !== 'date')) total[key] = table.reduce((n, r) => n + r[key], 0);
console.log(`macticker.app, last ${days} UTC days`);
console.table([...table, total]);
console.log(`pageViews/visits: browser page loads reported by the Web Analytics beacon; automated = headless browsers and bots.
macDownloads: full DMG responses (HTTP 200) to non-bot Mac browsers. This is the closest available estimate of installs; Ticker sends no install or launch signal.
otherDownloads: non-bot, non-Mac user agents (cannot run the app). partialRequests: HTTP 206 range responses, several can belong to one download.${sampled ? '\nSome counts are sampled estimates.' : ''}`);
