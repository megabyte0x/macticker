# Ticker launch verification

Verified October 1, 2026 at https://ticker.megabyte.sh. Cloudflare Pages project ticker-megabyte, production deployment bfdf8816. Vercel manages the ticker CNAME pointing to ticker-megabyte.pages.dev. Cloudflare custom-domain verification and certificate validation are active.

## Requirements and evidence

- Official shadcn UI: CLI-generated button and accordion sources are present in src/components/ui, with components.json. Button variants style the server-rendered download links; the accordion hydrates when visible.
- Technical SEO: eight HTML pages pass verify-site.mjs for unique titles and descriptions, canonical URLs, semantic headings, JSON-LD, internal links and assets. Live robots.txt and both sitemap files return HTTP 200. The missing-page route returns HTTP 404; its HTML is marked noindex. Articles are prerendered and readable without executing JavaScript.
- GEO/content: three original guides cover alternatives, Bitcoin setup and stale data. Product scope and limitations are explicit. Alternatives link to primary descriptions and state that there was no side-by-side benchmark. Article authorship, dates and SoftwareApplication metadata match visible content. No invented testimonials, ratings, search volumes or promises of AI citations.
- Direct download: the release DMG returns HTTP 200 with application/x-apple-diskimage and an attachment disposition. The downloaded SHA-256 is e2b6a2377c71e58f943fe594a0c96bd3f5f3536c6ce8dc4b323b9594c3539c3e. hdiutil verifies the image; mounting confirms Ticker.app and the Applications shortcut; codesign verification succeeds; the executable is ARM64.
- Publishing: HTTPS responds with HTTP 200 at ticker.megabyte.sh. Every product, download, privacy and guide route and social asset returns HTTP 200.
- Browser checks: desktop at 1440 px and mobile at 390 px have no horizontal overflow. Download buttons have white text on blue. FAQ expands in the browser. Production site renders at the requested hostname.
- Lighthouse: final custom-domain mobile lab run scores 100 performance, 100 accessibility, 100 best practices and 100 SEO. LCP 0.8 s, CLS 0.002, total blocking time 0 ms. Full report: lighthouse.json. These are lab measurements, not field Core Web Vitals or proof of rankings.

## Release limitations

Ticker 1.0 requires macOS 26+ on Apple Silicon. It is ad-hoc signed and not notarized; the installation page explains this. The homepage preview was replaced after user feedback with a native render of the unchanged TickerView source. Its quotes reflect capture-time CoinGecko data. Search indexing and ranking changes occur after publication and have not been claimed as measured outcomes.
