# Ticker Website Implementation Plan

> Execute inline in this session, with checkpoints after build, download packaging and deployment.

**Goal:** Publish the approved product website and direct DMG download at ticker.megabyte.sh.
**Architecture:** Astro prerenders all product and guide pages. React shadcn controls render to HTML; browser JavaScript is limited to controls that need it. Cloudflare Pages serves static assets and the DMG.
**Tech Stack:** Astro, React, Tailwind CSS, shadcn UI, Cloudflare Pages, Vercel DNS.
**Spec:** docs/superpowers/specs/2026-10-01-ticker-site-design.md

## Global Constraints

macOS 26+, Apple Silicon download, truthful signing disclosure, original prose, no invented search volumes or rankings, preserve existing app sources and unrelated DNS.

- [x] Scaffold website/package.json and Astro configuration; install official shadcn button and accordion through CLI.
- [x] Build shared layout, homepage, download page, privacy page, guides index and original guide articles. Add canonical, metadata, JSON-LD, sitemap, robots and social image.
- [x] Build release binary; create app bundle and DMG with Applications shortcut; verify signature, architecture, mount contents and checksum.
- [x] Build static site; check all internal links, metadata and JSON-LD; inspect desktop and mobile rendering and download behavior.
- [x] Deploy website/dist to Cloudflare Pages; associate ticker.megabyte.sh; add Vercel CNAME; verify HTTPS, pages and downloaded artifact.
