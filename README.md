# Ticker

A native SwiftUI menu bar crypto ticker for macOS 26 or newer. No dependencies or API keys.

[Download the latest notarized DMG for Apple Silicon](https://github.com/megabyte0x/macticker/releases/latest).

The starred token's USD price appears in the menu bar. Click it to see your watchlist. Use the bottom selector for 1-hour, 24-hour, or 1-week percentage changes. Use the star to switch the menu bar token, the × button that appears when you hover over a row to remove one, and + (⌘N) to search and add tokens. Search replaces the watchlist in the same popup; use Back or Escape to return. Choices and the selected change period persist between launches. Prices refresh every minute through CoinGecko; a tilde in the menu bar and a Stale label identify outdated prices.

To start Ticker automatically when you sign in to your Mac, open its **⋯** menu and turn on **Launch at Login**. It’s off by default; select it again to turn it off. If macOS requires approval, allow Ticker in System Settings → General → Login Items & Extensions.

Choose **⋯ → Check for Updates…** to check GitHub for a newer stable release. Ticker asks before installing and relaunching, and only installs notarized updates signed by the current developer team.

Run `./script/build_and_run.sh` to build and launch the app bundle, or `swift test` to check watchlist persistence and price formatting.

Run `./script/build_and_run.sh --dmg` to build `dist/Ticker.dmg` for local testing. It contains Ticker and an Applications shortcut and is not notarized for distribution.

To prepare a release on an Apple Silicon Mac, find the **Developer ID Application** identity with `security find-identity -v -p codesigning`. Set `TICKER_SIGN_IDENTITY` to its fingerprint when building the DMG. Use a Keychain profile created with `xcrun notarytool store-credentials ticker-notary` to submit to Apple:

```sh
TICKER_VERSION=1.1.0 TICKER_SIGN_IDENTITY='<Developer ID Application fingerprint>' ./script/build_and_run.sh --dmg &&
xcrun notarytool submit dist/Ticker.dmg --keychain-profile ticker-notary --wait
```

After Apple reports `Accepted`, staple the ticket and verify the release image before distributing it:

```sh
xcrun stapler staple dist/Ticker.dmg &&
xcrun stapler validate dist/Ticker.dmg &&
spctl --assess --type open --context context:primary-signature -vv dist/Ticker.dmg
```

For in-app updates, attach the signed and stapled image as **`Ticker.dmg`** to a stable GitHub release. The release tag must match `TICKER_VERSION` (for example `v1.1.0`), and future releases need a higher version. Use the Developer ID Application certificate from team `9UR77TD484`.

Run `TICKER_LIVE_CHECK=1 swift test` to also verify the live price and search endpoints. CoinGecko's public service can rate-limit requests; retained prices are marked stale if a refresh fails.

Built with Apple's [MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra) and native SwiftUI controls. Prices come from [CoinGecko](https://docs.coingecko.com/demo/reference/coins-markets).
