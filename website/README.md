# Ticker website

Static Astro site styled like a native Mac app page (system font, light and dark appearance), using official shadcn UI button variants and accordion components, React and Tailwind CSS. Canonical host: https://macticker.app, set once as `site` in astro.config.mjs. Cloudflare Pages project: macticker. The previous host, ticker.megabyte.sh, should 301 to macticker.app.

Run `npm ci`, then `ASTRO_TELEMETRY_DISABLED=1 npm run dev` for local development. Build with `ASTRO_TELEMETRY_DISABLED=1 npm run build`, then run `node verify-site.mjs` to check generated metadata, links, structured data, sitemap and the download artifact. Deploy with `npx wrangler pages deploy dist --project-name macticker --branch main --commit-dirty=true`. The latest technical SEO audit is audit/seo-audit-2026-10-21.md. The IndexNow key is the hex-named .txt file in public/.

Guide sources live in src/content/guides. Each article needs a unique title, description, category and ISO publication date. Published copy comes from the app implementation and primary product documentation. No keyword-volume or ranking claims are made. Search performance needs measurement after indexing; the site does not claim llms.txt or structured data guarantees AI citations.

The bundled DMG is Ticker 1.0 for Apple Silicon and macOS 26+. It is signed with the Developer ID of Yash Garg (team 9UR77TD484), notarized by Apple, and includes a stapled notarization ticket. Update the download filename, checksum, size, SoftwareApplication schema and installation page together when changing releases. The homepage image is rendered directly from the unchanged TickerView SwiftUI source using native macOS controls. Regenerate it with `./script/render_site_preview.sh`. Quotes are fetched from CoinGecko and the caption identifies them as capture-time values.

## Analytics and download counts

Cloudflare Web Analytics is enabled for the macticker.app zone using automatic script injection (site tag `f914a14801ab490596877e92cc02eefa`). Do not also add a beacon to the layout: that would risk duplicate page views. Astro's CSP explicitly allows `https://static.cloudflareinsights.com`. View visits and performance in the account's [Web Analytics dashboard](https://dash.cloudflare.com/1378ab230486e0367cbcb49a0f4cec1d/web-analytics).

The Web Analytics beacon does not run in DMG files. Use Cloudflare's HTTP request analytics separately to count successful file requests, including direct links and requests without JavaScript. Submit this query to `POST https://api.cloudflare.com/client/v4/graphql` with a token that has Zone Analytics Read access and ISO-8601 UTC `start` and `end` variables:

```graphql
query Downloads($start: Time!, $end: Time!) {
  viewer {
    zones(filter: {zoneTag: "7e7c0192109e230b01b942d0bfa4af7d"}) {
      httpRequestsAdaptiveGroups(
        limit: 10000
        filter: {
          datetime_geq: $start
          datetime_lt: $end
          requestSource: "eyeball"
          clientRequestHTTPHost: "macticker.app"
          clientRequestPath: "/downloads/Ticker-1.0-arm64.dmg"
          clientRequestHTTPMethodName: "GET"
          edgeResponseStatus_in: [200, 206]
        }
      ) {
        count
        dimensions { date edgeResponseStatus }
        avg { sampleInterval }
      }
    }
  }
}
```

Sum the status 200 groups for full-file responses. Report status 206 range responses separately: several ranges can belong to one download. HEAD requests, failures and redirects are excluded. These are request counts, not verified completed downloads, unique users or installations; repeat downloads, bots and our own release checks can be included. Adaptive sampling can make counts estimates (`sampleInterval` greater than 1). Query within the plan's retention and maximum query window, and export results before they expire if a long-term history is needed. This zone's history does not cover the previous ticker.megabyte.sh host or pages.dev URLs.
