---
title: "Why a crypto ticker can show an old price"
description: "Understand one-minute refresh attempts, CoinGecko rate limits and Ticker's stale-price indicators before relying on a menu bar quote."
date: "2026-10-01"
category: "Price data"
---
A crypto price can remain visible after the app loses access to fresh data. Ticker retains the last successful quotes when a refresh fails, then marks them as outdated. A tilde beside the menu bar price is a reason to check the popup, not an extra decimal or an estimate of price movement.

## Refresh frequency and quote age are different

Ticker attempts to fetch USD prices every 60 seconds. That interval describes the app's requests. It does not guarantee that CoinGecko has a new quote each time or that your internet connection completes every request.

A quote includes a provider timestamp. Ticker treats a quote as stale when that timestamp is more than three minutes old, missing or unreadable. It also flags the menu bar price after a refresh error. This keeps the last known value available while making its limitations visible.

The percentage-change selector is independent. Choosing 1h, 24h or 1w changes the comparison period displayed in your watchlist. It does not turn one-minute polling into hourly, daily or weekly polling.

## What can interrupt an update?

Your Mac may be offline, the service may be unavailable, or the public API may reject a request. CoinGecko documents its API behavior and rate limits in its [official reference](https://docs.coingecko.com/reference/common-errors-rate-limit). A rate-limited request does not mean your saved watchlist has been deleted.

Ticker uses the public endpoints without asking you for an API key. That is convenient for setup, but it means a refresh is subject to the service's availability and public-access constraints. This guide does not promise a fixed request allowance because the provider can change its limits.

## What to check in Ticker

Open the popup and read its status. “Prices unavailable” means a refresh failed. A Stale label identifies an old or invalid quote timestamp. If your watchlist is empty, add a token before expecting prices.

Once your connection is working, use Refresh Prices in the options menu. Ticker also keeps retrying every minute. Repeated manual clicks are unlikely to fix a provider rate limit; allow time for access to recover.

For tokens with no usable price, the app shows an unavailable value rather than manufacturing a number. Very small positive USD prices use additional decimal precision, and values below the formatting threshold are displayed as less than $0.000001. Those formatting choices should not be confused with stale data.

## Choose a tool for the data you need

A compact ticker is useful for an occasional glance. If your workflow requires exchange-specific bid and ask prices, streaming updates or orders, verify those capabilities in a purpose-built tool. Ticker has no exchange connection or trading interface.

Read the [Mac crypto ticker comparison](/guides/mac-crypto-ticker-alternatives/) for differences in app scope, or the [Bitcoin setup guide](/guides/bitcoin-price-mac-menu-bar/) for the controls that determine what Ticker displays.
