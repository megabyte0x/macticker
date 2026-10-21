# Ticker website

Static Astro site using official shadcn UI button variants and accordion components, React and Tailwind CSS. Canonical host: https://ticker.megabyte.sh. Cloudflare Pages project: ticker-megabyte. The ticker CNAME is managed in Vercel DNS for megabyte.sh.

Run `npm ci`, then `ASTRO_TELEMETRY_DISABLED=1 npm run dev` for local development. Build with `ASTRO_TELEMETRY_DISABLED=1 npm run build`, then run `node verify-site.mjs` to check generated metadata, links, structured data, sitemap and the download artifact. Deploy with `npx wrangler pages deploy dist --project-name ticker-megabyte --branch main --commit-dirty=true`.

Guide sources live in src/content/guides. Each article needs a unique title, description, category and ISO publication date. Published copy comes from the app implementation and primary product documentation. No keyword-volume or ranking claims are made. Search performance needs measurement after indexing; the site does not claim llms.txt or structured data guarantees AI citations.

The bundled DMG is Ticker 1.0 for Apple Silicon and macOS 26+. It is signed with the Developer ID of Yash Garg (team 9UR77TD484), notarized by Apple, and includes a stapled notarization ticket. Update the download filename, checksum, size, SoftwareApplication schema and installation page together when changing releases. The homepage image is rendered directly from the unchanged TickerView SwiftUI source using native macOS controls. Regenerate it with `./script/render_site_preview.sh`. Quotes are fetched from CoinGecko and the caption identifies them as capture-time values.
