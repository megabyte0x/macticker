# Ticker

A native SwiftUI menu bar crypto ticker for macOS 26 or newer. No dependencies or API keys.

The starred token's USD price appears in the menu bar. Click it to see your watchlist. Use the bottom selector for 1-hour, 24-hour, or 1-week percentage changes. Use the star to switch the menu bar token, the × button that appears when you hover over a row to remove one, and + (⌘N) to search and add tokens. Search replaces the watchlist in the same popup; use Back or Escape to return. Choices and the selected change period persist between launches. Prices refresh every minute through CoinGecko; a tilde in the menu bar and a Stale label identify outdated prices.

Run `./script/build_and_run.sh` to build and launch the app bundle, or `swift test` to check watchlist persistence and price formatting. The options menu contains Refresh and Quit.

Run `TICKER_LIVE_CHECK=1 swift test` to also verify the live price and search endpoints. CoinGecko's public service can rate-limit requests; retained prices are marked stale if a refresh fails.

Built with Apple's [MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra) and native SwiftUI controls. Prices come from [CoinGecko](https://docs.coingecko.com/demo/reference/coins-markets).
