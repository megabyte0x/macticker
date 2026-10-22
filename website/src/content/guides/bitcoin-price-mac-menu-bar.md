---
title: "How to put Bitcoin's price in your Mac menu bar"
description: "Install Ticker, star Bitcoin and read its USD price from the menu bar. Includes Mac requirements, watchlist controls and refresh behavior."
date: "2026-10-01"
updated: "2026-10-22"
category: "Setup"
related: ["crypto-price-refresh-stale-data", "ticker-vs-coin-tick"]
---
To put Bitcoin's price in your Mac menu bar with Ticker, install the app and star Bitcoin in the watchlist. Bitcoin is included in the default watchlist alongside Ethereum and Solana. The selected token's symbol and USD price appear at the top of your screen.

Ticker requires an Apple Silicon Mac running macOS 26 or newer. This release is distributed as a Developer ID signed DMG download and is notarized by Apple. The [installation page](/download/) explains the release's signing status before you open it.

<img src="/ticker-native.webp" width="640" height="590" loading="lazy" alt="Ticker's native popup showing Bitcoin, Ethereum and Solana with USD prices and a change-period selector."/>

The popup above is rendered from Ticker's SwiftUI source. Quotes are capture-time examples, not live market data. Ticker uses one selected coin in the menu bar, not a separate always-visible menu bar item for every watchlist row.

## Install and find the app

1. Download the DMG from the [download page](/download/).
2. Open the disk image and drag Ticker to Applications.
3. Open Ticker from Applications. Follow the documented macOS security prompt only if you trust this download.
4. Look in the menu bar for the selected token's symbol. Before the first successful request, its price may be unavailable.

Ticker is a menu bar app. You do not need to keep a separate window open to see the selected price. Click the menu bar item to open your watchlist.

## Select Bitcoin, Ethereum or another token

Click the star on the Bitcoin row to select it. The menu bar then shows BTC and its USD price. Selecting Ethereum changes the symbol to ETH; the same control works for another token you have added.

Click + or press **⌘N** to search by name or symbol. Search results come from CoinGecko. Choose the token you meant to add, checking the full name rather than relying only on an abbreviated symbol. Symbols are not a unique identifier across all crypto assets.

Search replaces the watchlist inside the popup. Press Escape or click Back to return. Hover over a watchlist row to reveal the remove button. Removing the selected token makes Ticker select another remaining token.

## Read the change period correctly

The selector at the bottom changes the percentage figures in the watchlist between **1h**, **24h** and **1w**. It does not change the currency: displayed prices remain in USD. It also does not change the refresh interval.

Your watchlist, selected menu bar token and change-period choice persist between launches. You can close the popup and keep the menu bar price visible.

## What price are you seeing?

Ticker uses CoinGecko market data. It requests fresh prices every minute, but a request can fail or return data that is already old. A tilde beside the menu bar price and a Stale label flag outdated quotes. Open the options menu and choose Refresh Prices to try a manual refresh.

The displayed USD price is a market-data reference. Ticker does not submit an order, quote a guaranteed execution price or show your exchange's fees. If you need exchange-specific tools or price alerts, read the [alternatives comparison](/guides/mac-crypto-ticker-alternatives/). If the displayed value stops changing, start with the [refresh and stale-data guide](/guides/crypto-price-refresh-stale-data/).

## Can I show several coins or another currency?

Ticker shows one starred token in the menu bar and the rest in its popup. Prices remain in USD; there is no EUR, GBP or BTC display setting. If several always-visible prices or another quote currency are requirements, the [Coin Tick comparison](/guides/ticker-vs-coin-tick/) describes a better-matched alternative.

These instructions are checked against the [Ticker app controls](https://github.com/megabyte0x/macticker/blob/main/Sources/Ticker/TickerApp.swift) and [watchlist storage](https://github.com/megabyte0x/macticker/blob/main/Sources/Ticker/TokenStore.swift), rather than an exchange account or a browser extension.
