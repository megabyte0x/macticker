# Ticker

Ticker is a native macOS menu bar app that shows the USD price of your starred cryptocurrency. It requires Apple Silicon and macOS 26 or later.

[Download Ticker](https://github.com/megabyte0x/macticker/releases/latest) · [Installation guide](https://macticker.app/download/)

Open the DMG, drag Ticker to Applications, and launch it. Click the menu bar price to open your watchlist. Use **+** or **⌘N** to add a token, and star a token to put its price in the menu bar. The watchlist shows price changes over 1 hour, 24 hours, or 1 week.

Prices refresh every minute through CoinGecko. A tilde in the menu bar or a **Stale** label indicates an older quote. The **⋯** menu includes **Launch at Login** and **Check for Updates…**.

## Build and test

Use Swift 6.2 or later on macOS 26 or later.

```sh
./script/build_and_run.sh        # Build and launch Ticker
swift test                      # Run the local test suite
./script/build_and_run.sh --dmg # Build a local test installer in dist/
```

Set `TICKER_LIVE_CHECK=1` when running `swift test` to include the live CoinGecko checks.

## Release

Use a Developer ID Application identity from team `9UR77TD484` and save your Apple notarization credentials with `xcrun notarytool store-credentials ticker-notary`. Set the version and signing fingerprint before building.

```sh
TICKER_VERSION='<release version>' TICKER_SIGN_IDENTITY='<certificate fingerprint>' ./script/build_and_run.sh --dmg &&
xcrun notarytool submit dist/Ticker.dmg --keychain-profile ticker-notary --wait
```

Once Apple accepts the image, staple and verify it.

```sh
xcrun stapler staple dist/Ticker.dmg &&
xcrun stapler validate dist/Ticker.dmg &&
spctl --assess --type open --context context:primary-signature -vv dist/Ticker.dmg
```

Publish the DMG as `Ticker.dmg` on a stable GitHub release with tag `v<release version>`. The updater expects that filename, a matching bundle version, and a version greater than the installed one. Update the website installer, download links, version, file size, and SHA-256 checksum together.

## Website

From `website/`, run `npm ci` followed by `npm run dev` for local development. To deploy to Cloudflare Pages, run `npm run build && npm run verify`, then `npx wrangler pages deploy dist --project-name macticker --branch main`.

Guide content lives in `website/src/content/guides/`. Run `npm run analytics` with a `CLOUDFLARE_API_TOKEN` that has Account Analytics Read and Zone Analytics Read permissions to report page views and DMG downloads.
